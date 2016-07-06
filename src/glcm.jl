function glcm{T<:Real}(img::AbstractArray{T, 2}, distance::Integer, angle::Real, mat_size::Integer = 16)
	max_img = maximum(img)
	img_rescaled = map(i -> max(1, Int(ceil(i * mat_size / max_img))), img)
	_glcm(img_rescaled, distance, angle, mat_size)
end

function glcm{T<:Real, A<:Real}(img::AbstractArray{T, 2}, distances::Array{Int, 1}, angles::Array{A, 1}, mat_size::Integer = 16)
	max_img = maximum(img)
	img_rescaled = map(i -> max(1, Int(ceil(i * mat_size / max_img))), img)
	glcm_matrices = [_glcm(img_rescaled, d, a, mat_size) for d in distances, a in angles]
	glcm_matrices
end

function glcm{T<:Colorant}(img::AbstractArray{T, 2}, distance::Integer, angle::Real, mat_size::Integer = 16)
	img_rescaled = map(i -> max(1, Int(ceil((convert(Gray{U8}, i).val.i) * mat_size / 256))), img)
	_glcm(img_rescaled, distance, angle, mat_size)
end

function glcm{T<:Colorant, A<:Real}(img::AbstractArray{T, 2}, distances::Array{Int, 1}, angles::Array{A, 1}, mat_size::Integer = 16)
	img_rescaled = map(i -> max(1, Int(ceil((convert(Gray{U8}, i).val.i) * mat_size / 256))), img)	
	glcm_matrices = [_glcm(img_rescaled, d, a, mat_size) for d in distances, a in angles]
	glcm_matrices
end

glcm{T<:Union{Colorant, Real}, A<:Real}(img::AbstractArray{T, 2}, distances::Int, angles::Array{A, 1}, mat_size::Integer = 16) = glcm(img, [distances], angles, mat_size)
glcm{T<:Union{Colorant, Real}}(img::AbstractArray{T, 2}, distances::Array{Int, 1}, angles::Real, mat_size::Integer = 16) = glcm(img, distances, [angles], mat_size)

function _glcm{T}(img::AbstractArray{T, 2}, distance::Integer, angle::Number, mat_size::Integer)
	co_oc_matrix = zeros(Integer, mat_size, mat_size)

	R = CartesianRange(size(img))

	for I in R

	int_one = img[I]

	co_occuring_pixel = I + CartesianIndex(Int(round(sin(angle) * distance)), Int(round(cos(angle) * distance)))

	if co_occuring_pixel[1] > 1 && co_occuring_pixel[1] < size(img)[1] && co_occuring_pixel[2] > 1 && co_occuring_pixel[2] < size(img)[2]
		int_two = img[co_occuring_pixel]
		co_oc_matrix[int_one, int_two] += 1
	end

	end
	co_oc_matrix
end

function glcm_symmetric(img::AbstractArray, distance::Integer, angle::Real, mat_size)
	co_oc_matrix = glcm(img, distance, angle, mat_size)
	co_oc_matrix_trans = co_oc_matrix'
	co_oc_matrix_symm = co_oc_matrix + co_oc_matrix_trans
	co_oc_matrix_symm
end

function glcm_symmetric(img::AbstractArray, distances, angles, mat_size)
	co_oc_matrices = glcm(img, distances, angles, mat_size)
	co_oc_matrices_sym = map(gmat -> gmat + gmat', co_oc_matrices)
	co_oc_matrices_sym
end

function glcm_norm(img::AbstractArray, distance::Integer, angle::Real, mat_size)
	co_oc_matrix = glcm(img, distance, angle, mat_size)
	co_oc_matrix_norm = co_oc_matrix / sum(co_oc_matrix)
	co_oc_matrix_norm
end

function glcm_norm(img::AbstractArray, distances, angles, mat_size)
	co_oc_matrices = glcm(img, distances, angles, mat_size)
	co_oc_matrices_norm = map(gmat -> gmat /= sum(gmat), co_oc_matrices)
	co_oc_matrices_norm
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
