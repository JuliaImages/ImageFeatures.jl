function lbp_original(bit_pattern::Array{Bool, 1})
	sum([b * 2 ^ (i - 1) for (i, b) in enumerate(bit_pattern)])
end

UNIFORM_LBP_TABLE = Dict{Array{Bool, 1}, Int}()
UNIFORM_PATTERN_COUNT = 0
NON_UNIFORM_PATTERN = Array{Bool, 1}()

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

function _lbp{T<:Gray}(img::AbstractArray{T, 2}, P::Integer, offsets::Array, method::Function = lbp_original)

	global UNIFORM_LBP_TABLE, NON_UNIFORM_PATTERN, UNIFORM_PATTERN_COUNT
	
	UNIFORM_PATTERN_COUNT = 0
	UNIFORM_LBP_TABLE = Dict{Array{Bool, 1}, Int}()
	NON_UNIFORM_PATTERN = zeros(Bool, P)
	NON_UNIFORM_PATTERN[1:2:P] = true
	UNIFORM_LBP_TABLE[NON_UNIFORM_PATTERN] = P * (P - 1) + 2

	lbp_image = zeros(UInt, size(img))
	R = CartesianRange(size(img))
	for I in R
		bit_pattern = [img[I] < bilinear_interpolation(img, I[1] + o[1], I[2] + o[2]) ? false : true for o in offsets]
		lbp_image[I] = method(bit_pattern)
	end
	lbp_image

end

function lbp{T<:Gray}(img::AbstractArray{T, 2}, method::Function = lbp_original)

	offsets = [[- 1, - 1], [- 1, 0], [- 1, 1], [0, 1], [1, 1], [1, 0], [1, - 1], [0, - 1]]
	_lbp(img, 8, offsets, method)
	
end

function lbp{T<:Gray}(img::AbstractArray{T, 2}, points::Integer, radius::Number, method::Function = lbp_original)
	
	offsets = [(round(- radius * sin(2 * pi * i / points), 5), round(radius * cos(2 * pi * i / points), 5)) for i = 0:points - 1]
	_lbp(img, points, offsets, method)

end

function dlbp{T<:Gray}(img::AbstractArray{T, 2})
end

function mlbp{T<:Gray}(img::AbstractArray{T, 2})
end

function multi_block_lbp{T<:Gray}(img::AbstractArray{T, 2})
end
