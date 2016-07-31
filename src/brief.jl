type BRIEF <: DescriptorParams
	size::Int
	window::Int
	sigma::Float64
	sampling_type::Function
	seed::Int
end

function random_uniform(size::Int, window::Int, seed::Int)
	srand(seed)
	sample_one = CartesianIndex{2}[]
	sample_two = CartesianIndex{2}[]
	while true
		x_gen = floor(Int, window * rand() / 2)
		y_gen = floor(Int, window * rand() / 2)
		x_gen > -window / 2 || y_gen > -window / 2 || x_gen < (window - 1) / 2 || y_gen < (window - 1) / 2 || continue
		x_gen_2 = floor(Int, window * rand() / 2)
		y_gen_2 = floor(Int, window * rand() / 2)
		x_gen_2 > -window / 2 || y_gen_2 > -window / 2 || x_gen_2 < (window - 1) / 2 || y_gen_2 < (window - 1) / 2 || continue
		count += 1
		push!(sample_one, CartesianIndex{2}(y_gen, x_gen))
		push!(sample_two, CartesianIndex{2}(y_gen_2, x_gen_2))
		count == size || break
	end
	sample_one, sample_two
end

function random_coarse(size::Int, window::Int, seed::Int)
	srand(seed)
	gen = rand(ceil(Int, -window / 2): floor(Int, (window - 1) / 2), size * 4)
	sample_one = CartesianIndex{2}[]
	sample_two = CartesianIndex{2}[]
	for i in 1:size
		push!(sample_one, CartesianIndex{2}(gen[i], gen[2 * i]))
		push!(sample_two, CartesianIndex{2}(gen[3 * i], gen[4 * i]))
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
		x_gen > -window / 2 || y_gen > -window / 2 || x_gen < (window - 1) / 2 || y_gen < (window - 1) / 2 || continue
		count += 1
		push!(sample, CartesianIndex{2}(floor(Int, y_gen), floor(Int, x_gen)))
		count == size || break
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
		x_gen > -window / 2 || y_gen > -window / 2 || x_gen < (window - 1) / 2 || y_gen < (window - 1) / 2 || continue
		count += 1
		push!(sample, CartesianIndex{2}(y_gen, x_gen))
		count == size || break
	end
	sample
end

function centred(size::Int, window::Int, seed::Int)
	srand(seed)
	count = 0
	sample = CartesianIndex{2}[]
	while true
		x_gen = floor(Int, window * rand() / 2)
		y_gen = floor(Int, window * rand() / 2)
		x_gen > -window / 2 || y_gen > -window / 2 || x_gen < (window - 1) / 2 || y_gen < (window - 1) / 2 || continue
		count += 1
		push!(sample, CartesianIndex{2}(y_gen, x_gen))
		count == size || break
	end
	zeros(CartesianIndex{2}, size), sample
end

function BRIEF(; size::Integer = 128, window::Integer = 9, sigma::Float64 = 2 ^ 0.5, sampling_type::Function = gaussian, seed::Int = 123)
	BRIEF(size, window, gamma, sampling_type, seed)
end

function create_descriptor{T<:Gray}(img::AbstractArray{T, 2}, keypoints::Array{Keypoint}, params::BRIEF)
	img_smoothed = imfilter_gaussian(img, params.sigma)
	sample_one, sample_two = params.sampling_type(params.size, params.window, params.seed)
	descriptors = Array{Bool}[]	
	for k in keypoints
		checkbounds(Bool, img, k + s1) || checkbounds(Bool, img, k + s2) || continue
		push!(descriptors, map((s1, s2) -> img[k + s1] < img[k + s2], sample_one, sample_two))
	end
	descriptors
end