"""
```
brief_params = BRIEF([size = 128], [window = 9], [sigma = 2 ^ 0.5], [sampling_type = gaussian], [seed = 123])
```

| Argument | Type | Description |
| :------- | :--- | :---------- |
| **size** | Int | Size of the descriptor |
| **window** | Int | Size of sampling window |
| **sigma** | Float64 | Value of sigma used for initial gaussian smoothing of image |
| **sampling_type** | Function | Type of sampling used for building the descriptor (See [BRIEF Sampling Patterns](#brief-sampling-patterns)) |
| **seed** | Int | Random seed used for generating the sampling pairs. For matching two descriptors, the seed used to build both should be same. |

"""
mutable struct BRIEF{F} <: Params
    size::Int
    window::Int
    sigma::Float64
    sampling_type::F
    seed::Int
end

function BRIEF(; size::Integer = 128, window::Integer = 9, sigma::Float64 = 2 ^ 0.5, sampling_type::Function = gaussian, seed::Int = 123)
    BRIEF(size, window, sigma, sampling_type, seed)
end

"""
```
sample_one, sample_two = random_uniform(size, window, seed)
```

Builds sampling pairs using random uniform sampling.
"""
function random_uniform(size::Int, window::Int, seed::Int)
    seed!(seed)
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

"""
```
sample_one, sample_two = random_coarse(size, window, seed)
```

Builds sampling pairs using random sampling over a coarse grid.
"""
function random_coarse(size::Int, window::Int, seed::Int)
    seed!(seed)
    gen = rand(ceil(Int, ceil(-window / 2)): floor(Int, (window - 1) / 2), size * 4)
    sample_one = CartesianIndex{2}[]
    sample_two = CartesianIndex{2}[]
    for i in 1:size
        push!(sample_one, CartesianIndex(gen[i], gen[2 * i]))
        push!(sample_two, CartesianIndex(gen[3 * i], gen[4 * i]))
    end
    sample_one, sample_two
end

"""
```
sample_one, sample_two = gaussian(size, window, seed)
```

Builds sampling pairs using gaussian sampling.
"""
function gaussian(size::Int, window::Int, seed::Int)
    seed!(seed)
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

"""
```
sample_one, sample_two = gaussian_local(size, window, seed)
```

Pairs `(Xi, Yi)` are randomly sampled using a Gaussian distribution where first `X` is sampled with a standard deviation of `0.04*S^2` and
then the `Yi’s` are sampled using a Gaussian distribution – Each `Yi` is sampled with mean `Xi` and standard deviation of `0.01 * S^2`
"""
function gaussian_local(size::Int, window::Int, seed::Int)
    seed!(seed)
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

"""
```
sample_one, sample_two = center_sample(size, window, seed)
```

Builds sampling pairs `(Xi, Yi)` where `Xi` is `(0, 0)` and `Yi` is sampled uniformly from the window.
"""
function center_sample(size::Int, window::Int, seed::Int)
    seed!(seed)
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

function create_descriptor(img::AbstractArray{T, 2}, keypoints::Keypoints, params::BRIEF) where T<:Gray
    factkernel = KernelFactors.IIRGaussian([params.sigma, params.sigma])
    img_smoothed = imfilter(Float64, img, factkernel, NA())
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
