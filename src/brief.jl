type BRIEF{F} <: DescriptorParams
    size::Int
    window::Int
    sigma::Float64
    sampling_type::F
    seed::Int
end

function BRIEF(; size::Integer = 128, window::Integer = 9, sigma::Float64 = 2 ^ 0.5, sampling_type::Function = gaussian, seed::Int = 123)
    BRIEF(size, window, sigma, sampling_type, seed)
end

function random_uniform(size::Int, window::Int, seed::Int)
    srand(seed)
    sample_one = CartesianIndex{2}[]
    sample_two = CartesianIndex{2}[]
    count = 0
    while true
        x_gen = floor(Int, window * rand() / 2)
        y_gen = floor(Int, window * rand() / 2)
        (x_gen >= ceil(-window / 2) && x_gen <= floor((window - 1) / 2)) && (y_gen >= ceil(-window / 2) && y_gen <= floor((window - 1) / 2)) || continue
        x_gen_2 = floor(Int, window * rand() / 2)
        y_gen_2 = floor(Int, window * rand() / 2)
        (x_gen_2 >= ceil(-window / 2) && x_gen_2 <= floor((window - 1) / 2)) && (y_gen_2 >= ceil(-window / 2) && y_gen_2 <= floor((window - 1) / 2)) || continue
        count += 1
        push!(sample_one, CartesianIndex(y_gen, x_gen))
        push!(sample_two, CartesianIndex(y_gen_2, x_gen_2))
        count != size || break
    end
    sample_one, sample_two
end

function random_coarse(size::Int, window::Int, seed::Int)
    srand(seed)
    gen = rand(ceil(Int, ceil(-window / 2)): floor(Int, (window - 1) / 2), size * 4)
    sample_one = CartesianIndex{2}[]
    sample_two = CartesianIndex{2}[]
    for i in 1:size
        push!(sample_one, CartesianIndex(gen[i], gen[2 * i]))
        push!(sample_two, CartesianIndex(gen[3 * i], gen[4 * i]))
    end
    sample_one, sample_two
end

function gaussian(size::Int, window::Int, seed::Int)
    srand(seed)
    _gaussian(size, window), _gaussian(size, window)
end

function _gaussian(size::Int, window::Int)
    set = Normal(0, (window ^ 2) / 25)
    count = 0
    sample = CartesianIndex{2}[]
    while true
        x_gen , y_gen = rand(set, 2)
        (x_gen >= ceil(-window / 2) && x_gen <= floor((window - 1) / 2)) && (y_gen >= ceil(-window / 2) && y_gen <= floor((window - 1) / 2)) || continue
        count += 1
        push!(sample, CartesianIndex(floor(Int, y_gen), floor(Int, x_gen)))
        count != size || break
    end
    sample
end

function gaussian_local(size::Int, window::Int, seed::Int)
    srand(seed)
    _gaussian_local(size, window), _gaussian_local(size, window)
end

function _gaussian_local(size::Int, window::Int)
    x_set = Normal(0, (window ^ 2) / 25)
    count = 0
    sample = CartesianIndex{2}[]
    while true
        x_gen = floor(Int, rand(x_set))
        y_set = Normal(x_gen, (window ^ 2) / 100)
        y_gen = floor(Int, rand(y_set))
        (x_gen >= ceil(-window / 2) && x_gen <= floor((window - 1) / 2)) && (y_gen >= ceil(-window / 2) && y_gen <= floor((window - 1) / 2)) || continue
        count += 1
        push!(sample, CartesianIndex(y_gen, x_gen))
        count != size || break
    end
    sample
end

function centered(size::Int, window::Int, seed::Int)
    srand(seed)
    count = 0
    sample = CartesianIndex{2}[]
    while true
        x_gen = floor(Int, window * rand() / 2)
        y_gen = floor(Int, window * rand() / 2)
        (x_gen >= ceil(-window / 2) && x_gen <= floor((window - 1) / 2)) && (y_gen >= ceil(-window / 2) && y_gen <= floor((window - 1) / 2)) || continue
        count += 1
        push!(sample, CartesianIndex(y_gen, x_gen))
        count != size || break
    end
    zeros(CartesianIndex{2}, size), sample
end

function create_descriptor{T<:Gray}(img::AbstractArray{T, 2}, keypoints::Keypoints, params::BRIEF)
    img_smoothed = imfilter_gaussian(img, [params.sigma, params.sigma])
    sample_one, sample_two = params.sampling_type(params.size, params.window, params.seed)
    descriptors = BitArray{1}[]
    h, w = size(img_smoothed)
    ret_keypoints = Keypoint[]
    for k in keypoints
        (k[1] > floor(params.window / 2) && k[1] <= h - floor((params.window - 1) / 2)) && (k[2] > floor(params.window / 2) && k[2] <= w - floor((params.window - 1) / 2)) || continue
        temp = BitArray{1}([])
        for (s1, s2) in zip(sample_one, sample_two)
            push!(temp, img_smoothed[k + s1] < img_smoothed[k + s2])
        end
        push!(descriptors, temp)
        push!(ret_keypoints, k)
    end
    descriptors, ret_keypoints
end 