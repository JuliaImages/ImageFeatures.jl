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

"""
```
glcm = glcm(img, distance, angle, mat_size)
glcm = glcm(img, distances, angle, mat_size)
glcm = glcm(img, distance, angles, mat_size)
glcm = glcm(img, distances, angles, mat_size)
```

Calculates the GLCM (Gray Level Co-occurence Matrix) of an image. The `distances` and `angles` arguments may be 
a single integer or a vector of integers if multiple GLCMs need to be calculated. The `mat_size` argument is used
to define the granularity of the GLCM.
"""
function glcm{T<:Colorant, A<:Real}(img::AbstractArray{T, 2}, distances::Array{Int, 1}, angles::Array{A, 1}, mat_size::Integer = 16)
    img_rescaled = map(i -> max(1, Int(ceil((convert(Gray{U8}, i).val.i) * mat_size / 256))), img)  
    glcm_matrices = [_glcm(img_rescaled, d, a, mat_size) for d in distances, a in angles]
    glcm_matrices
end

glcm{T<:Union{Colorant, Real}, A<:Real}(img::AbstractArray{T, 2}, distances::Int, angles::Array{A, 1}, mat_size::Integer = 16) = glcm(img, [distances], angles, mat_size)
glcm{T<:Union{Colorant, Real}}(img::AbstractArray{T, 2}, distances::Array{Int, 1}, angles::Real, mat_size::Integer = 16) = glcm(img, distances, [angles], mat_size)

function _glcm{T}(img::AbstractArray{T, 2}, distance::Integer, angle::Number, mat_size::Integer)
    co_oc_matrix = zeros(Int, mat_size, mat_size)
    sin_angle = sin(angle)
    cos_angle = cos(angle)
    for j = 1:size(img, 1)
        j_off = j + Int(round(sin_angle * distance))
        checkbounds(Bool, img, j_off, 1) || continue
        for i = 1:size(img, 2)
            int_one = img[j, i]
            i_off = i + Int(round(cos_angle * distance))

            if checkbounds(Bool, img, j_off, i_off) 
                int_two = img[j_off, i_off]
                co_oc_matrix[int_one, int_two] += 1
            end
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

"""
```
glcm = glcm_symmetric(img, distance, angle, mat_size)
glcm = glcm_symmetric(img, distances, angle, mat_size)
glcm = glcm_symmetric(img, distance, angles, mat_size)
glcm = glcm_symmetric(img, distances, angles, mat_size)
```

Symmetric version of the [`glcm`](@ref) function.
"""
function glcm_symmetric(img::AbstractArray, distances, angles, mat_size)
    co_oc_matrices = glcm(img, distances, angles, mat_size)
    co_oc_matrices_sym = map(gmat -> gmat + gmat', co_oc_matrices)
    co_oc_matrices_sym
end

function glcm_norm(img::AbstractArray, distance::Integer, angle::Real, mat_size)
    co_oc_matrix = glcm(img, distance, angle, mat_size)
    co_oc_matrix_norm = co_oc_matrix / Float64(sum(co_oc_matrix))
    co_oc_matrix_norm
end

"""
```
glcm = glcm_norm(img, distance, angle, mat_size)
glcm = glcm_norm(img, distances, angle, mat_size)
glcm = glcm_norm(img, distance, angles, mat_size)
glcm = glcm_norm(img, distances, angles, mat_size)
```

Normalised version of the [`glcm`](@ref) function.
"""
function glcm_norm(img::AbstractArray, distances, angles, mat_size)
    co_oc_matrices = glcm(img, distances, angles, mat_size)
    co_oc_matrices_norm = map(gmat -> gmat /= Float64(sum(gmat)), co_oc_matrices)
    co_oc_matrices_norm
end

function glcm_prop{T<:Real}(gmat::Array{T, 2}, window_height::Integer, window_width::Integer, property::Function)
    k_h = Int(floor(window_height / 2))
    k_w = Int(floor(window_width / 2))
    glcm_size = size(gmat)
    R = CartesianRange(glcm_size)
    prop_mat = zeros(Float64, glcm_size)
    for I in R
        prop_mat[I] = property(gmat[max(1, I[1] - k_h) : min(glcm_size[1], I[1] + k_h), max(1, I[2] - k_w) : min(glcm_size[2], I[2] + k_w)])
    end
    prop_mat
end

glcm_prop{T<:Real}(gmat::Array{T, 2}, window_size::Integer, property::Function) = glcm_prop(gmat, window_size, window_size, property)

"""

Multiple properties of the obtained GLCM can be calculated by using the `glcm_prop` function which calculates the 
property for the entire matrix. If grid dimensions are provided, the matrix is divided into a grid and the property
is calculated for each cell resulting in a height x width property matrix.

```julia
prop = glcm_prop(glcm, property)
prop = glcm_prop(glcm, height, width, property)
```

Various properties can be calculated like `mean`, `variance`, `correlation`, `contrast`, `IDM` (Inverse Difference Moment),
 `ASM` (Angular Second Moment), `entropy`, `max_prob` (Max Probability), `energy` and `dissimilarity`.
"""
function glcm_prop{T<:Real}(gmat::Array{T, 2}, property::Function)
    property(gmat)
end

function contrast{T<:Real}(glcm_window::Array{T, 2})
    sum([(id[1] - id[2]) ^ 2 * glcm_window[id] for id in CartesianRange(size(glcm_window))])
end

function dissimilarity{T<:Real}(glcm_window::Array{T, 2})
    sum([glcm_window[id] * abs(id[1] - id[2]) for id in CartesianRange(size(glcm_window))])
end

function glcm_entropy{T<:Real}(glcm_window::Array{T, 2})
    -sum(map(i -> i * log(i), glcm_window))
end

function ASM{T<:Real}(glcm_window::Array{T, 2})
    sum(map(i -> i ^ 2, glcm_window))   
end

function IDM{T<:Real}(glcm_window::Array{T, 2})
    sum([glcm_window[id] / (1 + (id[1] - id[2]) ^ 2) for id in CartesianRange(size(glcm_window))])
end

function glcm_mean_ref{T<:Real}(glcm_window::Array{T, 2})
    sumref = sum(glcm_window, 2)
    meanref = sum([id * sumref[id] for id = 1:size(glcm_window)[1]])
    meanref
end

function glcm_mean_neighbour{T<:Real}(glcm_window::Array{T, 2})
    sumneighbour = sum(glcm_window, 1)
    meanneighbour = sum([id * sumneighbour[id] for id = 1:size(glcm_window)[2]])
    meanneighbour
end

function glcm_var_ref{T<:Real}(glcm_window::Array{T, 2})
    mean_ref = glcm_mean_ref(glcm_window)
    sumref = sum(glcm_window, 2)
    var_ref = sum([((id - mean_ref) ^ 2) * sumref[id] for id = 1:size(glcm_window)[1]])
    var_ref ^ 0.5
end

function glcm_var_neighbour{T<:Real}(glcm_window::Array{T, 2})
    mean_neighbour = glcm_mean_neighbour(glcm_window)
    sumneighbour = sum(glcm_window, 1)
    var_neighbour = sum([((id - mean_neighbour) ^ 2) * sumneighbour[id] for id = 1:size(glcm_window)[2]])
    var_neighbour ^ 0.5
end

function correlation{T<:Real}(glcm_window::Array{T, 2})
    mean_ref = glcm_mean_ref(glcm_window)
    var_ref = glcm_var_ref(glcm_window)
    mean_neighbour = glcm_mean_neighbour(glcm_window)
    var_neighbour = glcm_var_neighbour(glcm_window)
    if var_ref == 0 || var_neighbour == 0
        return 1
    end
    sum([glcm_window[i, j] * (i - mean_ref) * (j - mean_neighbour) for i = 1:size(glcm_window)[1], j = 1:size(glcm_window)[2]]) / (var_ref * var_neighbour)
end

function max_prob{T<:Real}(glcm_window::Array{T, 2})
    maxfinite(glcm_window)
end

function energy{T<:Real}(glcm_window::Array{T, 2})
    ASM(glcm_window) ^ 0.5
end