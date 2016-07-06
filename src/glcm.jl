function glcm{T<:Colorant}(img::AbstractArray{T, 2}, distance::Integer, angle::Float64, mat_size::Integer = 16)
	img_rescaled = map(i -> max(1, Int(ceil((convert(Gray{U8}, i).val.i) * mat_size / 256))), img)
	_glcm(img_rescaled, distance, angle, mat_size)
end

function glcm{T<:Colorant}(img::AbstractArray{T, 2}, distances::Array{Integer, 1}, angles::Array{Float64, 1}, mat_size::Integer = 16)
	img_rescaled = map(i -> max(1, Int(ceil((convert(Gray{U8}, i).val.i) * mat_size / 256))), img)	
	glcm_matrices = [_glcm(img_rescaled, d, a, mat_size) for d in distances, a in angles]
	glcm_matrices
end

function glcm{T<:Number}(img::AbstractArray{T, 2}, distance::Integer, angle::Float64, mat_size::Integer = 16)
	img_rescaled = map(i -> max(1, Int(ceil(i * mat_size / maxfinite(img)))), img)
	_glcm(img_rescaled, distance, angle, mat_size)
end

function glcm{T<:Number}(img::AbstractArray{T, 2}, distances::Array{Integer, 1}, angles::Array{Float64, 1}, mat_size::Integer = 16)
	img_rescaled = map(i -> max(1, Int(ceil(i * mat_size / maxfinite(img)))), img)	
	glcm_matrices = [_glcm(img_rescaled, d, a, mat_size) for d in distances, a in angles]
	glcm_matrices
end

glcm{T}(img::AbstractArray{T, 2}, distances::Integer, angles::Array{Float64, 1}, mat_size::Integer = 16) = glcm(img, [distances], angles, mat_size)
glcm{T}(img::AbstractArray{T, 2}, distances::Array{Integer, 1}, angles::Float64, mat_size::Integer = 16) = glcm(img, distances, [angles], mat_size)

function _glcm{T}(img::AbstractArray{T, 2}, distance::Integer, angle::Float64, mat_size::Integer)
	co_oc_matrix = zeros(mat_size, mat_size)

	R = CartesianRange(size(img))

	for I in R

	int_one = img[I]

	co_occuring_pixel = I + CartesianIndex(Int(sin(angle) * distance), Int(cos(angle) * distance))

	if co_occuring_pixel in R
		int_two = img[co_occuring_pixel]
		co_oc_matrix[int_one, int_two] += 1
	end

	end
	co_oc_matrix
end

function glcm_symmetric(args...)
	glcm_matrices = glcm(args...)
end

function glcm_norm()
	glcm_matrices = glcm(args...)
end

function properties(glcm::Array{}, window, property::Function)
end

function homogeneity()
end

function contrast()
end

function dissimilarity()
end

function entropy()
end

function correlation()
end

function ASM()
end

function IDM()
end

function inertia()
end

function glcm_mean()
end

function glcm_var()
end

function sum_entropy()
end

function difference_entropy()
end

function shade()
end

function prominence()
end

function energy()
end
