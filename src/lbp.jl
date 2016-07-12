function lbp_original(bit_pattern::Array{Bool, 1})
	sum([b * 2 ^ (i - 1) for (i, b) in enumerate(bit_pattern)])
end

UNIFORM_LBP_TABLE = Dict{Array{Bool, 1}, Int}()
UNIFORM_PATTERN_COUNT = 0
NON_UNIFORM_PATTERN = Array{Bool, 1}()

function init_uniform_lbp_params(points::Integer)

	global UNIFORM_LBP_TABLE, NON_UNIFORM_PATTERN, UNIFORM_PATTERN_COUNT
	
	UNIFORM_PATTERN_COUNT = 0
	UNIFORM_LBP_TABLE = Dict{Array{Bool, 1}, Int}()
	NON_UNIFORM_PATTERN = zeros(Bool, points)
	NON_UNIFORM_PATTERN[1:2:points] = true
	UNIFORM_LBP_TABLE[NON_UNIFORM_PATTERN] = points * (points - 1) + 2

end

function lbp_uniform(bit_pattern::Array{Bool, 1})
	
	global UNIFORM_LBP_TABLE, NON_UNIFORM_PATTERN, UNIFORM_PATTERN_COUNT
	variations = sum([bit_pattern[i] != bit_pattern[i + 1] for i in 1:length(bit_pattern) - 1])
	if variations <= 2
		try 
			return UNIFORM_LBP_TABLE[bit_pattern] 
		catch KeyError 
			UNIFORM_PATTERN_COUNT += 1
			UNIFORM_LBP_TABLE[bit_pattern] = UNIFORM_PATTERN_COUNT
			return UNIFORM_PATTERN_COUNT 
		end
	else
		return UNIFORM_LBP_TABLE[NON_UNIFORM_PATTERN]	
	end

end

function lbp_rotation_invariant(bit_pattern::Array{Bool, 1})

end

function _lbp{T<:Gray}(img::AbstractArray{T, 2}, points::Integer, offsets::Array, method::Function = lbp_original)

	init_uniform_lbp_params(points)
	lbp_image = zeros(UInt, size(img))
	R = CartesianRange(size(img))
	for I in R
		bit_pattern = [img[I] < bilinear_interpolation(img, I[1] + o[1], I[2] + o[2]) ? false : true for o in offsets]
		lbp_image[I] = method(bit_pattern)
	end
	lbp_image

end

function original_offsets()

	return [[- 1, - 1], [- 1, 0], [- 1, 1], [0, 1], [1, 1], [1, 0], [1, - 1], [0, - 1]]
end

function circular_offsets(points::Integer, radius::Number)

	return [(round(- radius * sin(2 * pi * i / points), 5), round(radius * cos(2 * pi * i / points), 5)) for i = 0:points - 1]
end

lbp{T<:Gray}(img::AbstractArray{T, 2}, method::Function = lbp_original) = _lbp(img, 8, original_offsets(), method)

lbp{T<:Gray}(img::AbstractArray{T, 2}, points::Integer, radius::Number, method::Function = lbp_original) = _lbp(img, points, circular_offsets(), method)

function _modified_lbp{T<:Gray}(img::AbstractArray{T, 2}, points::Integer, offsets::Array, method::Function = lbp_original)

	init_uniform_lbp_params(points)
	lbp_image = zeros(UInt, size(img))
	R = CartesianRange(size(img))
	for I in R
		avg = (sum([bilinear_interpolation(img, I[1] + o[1], I[2] + o[2]) for o in offsets]) + img[I]) / (points + 1)
		bit_pattern = [avg < bilinear_interpolation(img, I[1] + o[1], I[2] + o[2]) ? false : true for o in offsets]
		lbp_image[I] = method(bit_pattern)
	end
	lbp_image

end

modified_lbp{T<:Gray}(img::AbstractArray{T, 2}, method::Function = lbp_original) = _modified_lbp(img, 8, original_offsets(), method)

modified_lbp{T<:Gray}(img::AbstractArray{T, 2}, points::Integer, radius::Number, method::Function = lbp_original) = _modified_lbp(img, points, circular_offsets(), method)

function dlbp{T<:Gray}(img::AbstractArray{T, 2})
end

function multi_block_lbp{T<:Gray}(img::AbstractArray{T, 2})
end
