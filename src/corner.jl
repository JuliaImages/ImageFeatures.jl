"""
```
orientations = corner_orientations(img)
orientations = corner_orientations(img, corners)
orientations = corner_orientations(img, corners, kernel)
```

Returns the orientations of corner patches in an image. The orientation of a corner patch
is denoted by the orientation of the vector between intensity centroid and the corner.
The intensity centroid can be calculated as `C = (m01/m00, m10/m00)` where mpq is defined as -

    `mpq = (x^p)(y^q)I(y, x) for each p, q in the corner patch`

The kernel used for the patch can be given through the `kernel` argument. The default kernel used is a gaussian kernel of size `5x5`.
"""
function corner_orientations(img::AbstractArray{T, 2}, corners::Keypoints, kernel::Array{K, 2}) where {T<:Gray, K<:Real}
    h, w = size(kernel)
    pre_y = ceil(Int, (h - 1) / 2)
    pre_x = ceil(Int, (w - 1) / 2)
    post_y = floor(Int, (h - 1) / 2)
       post_x = floor(Int, (w - 1) / 2)
       img_padded = parent(padarray(img, Fill(0, (pre_y, pre_x), (post_y, post_x))))
    orientations = Float64[]
    for c in corners
        m10 = zero(T)
        m01 = zero(T)
        for i in 1:w
            col_sum = zero(T)
            for j in 1:h
                pixel = img_padded[c + CartesianIndex(j - 1, i - 1)] * kernel[j, i]
                m01 += pixel * (j - pre_y - 1)
                col_sum += pixel
            end
            m10 += col_sum * (i - pre_x - 1)
        end
        push!(orientations, atan(Float64(m01), Float64(m10)))
    end
    orientations
end

corner_orientations(img::AbstractArray{T, 2}, corners::Keypoints, kernel::Array{K, 2}) where {T, K<:Real} = corner_orientations(convert(Array{Gray}, img), corners, kernel)

function corner_orientations(img::AbstractArray, kernel::Array{K, 2}) where K<:Real
    corners = imcorner(img)
    corner_indexes = Keypoints(corners)
    corner_orientations(img, corner_indexes, kernel)
end

function corner_orientations(img::AbstractArray)
    corners = imcorner(img)
    corner_indexes = Keypoints(corners)
    kernel = Kernel.gaussian((2,2), (5, 5))
    kernel /= maxfinite(kernel)
    corner_orientations(img, corner_indexes, parent(kernel))
end

function corner_orientations(img::AbstractArray, corners::Keypoints)
    kernel = Kernel.gaussian((2,2), (5, 5))
    kernel /= maxfinite(kernel)
    corner_orientations(img, corners, parent(kernel))
end
