"""
```
hog_params = HOG([orientations = 9], [cell_size = 8], [block_size = 2], [block_stride = 1], [norm_method = "L2-norm"])
```

Parameters:  
-    orientations   = number of orientation bins
-    cell_size      = size of a cell is cell_size x cell_size (in pixels)
-    block_size     = size of a block is block_size x block_size (in terms of cells)
-    block_stride   = stride of blocks. Controls how much adjacent blocks overlap.
-    norm_method    = block normalization method. Options: L2-norm, L2-hys, L1-norm, L2-sqrt. 
"""
type HOG <: Params
    orientations::Int 
    cell_size::Int
    block_size::Int
    block_stride::Int 
    norm_method::String
end

function HOG(; orientations::Int = 9, cell_size::Int = 8, block_size::Int = 2, block_stride::Int = 1, norm_method::String = "L2-norm")
    HOG(orientations, cell_size, block_size, block_stride, norm_method)
end

function create_descriptor{T<:Images.NumberLike}(img::AbstractArray{T, 2}, params::HOG)

    orientations = params.orientations
    cell_size = params.cell_size
    block_size = params.block_size
    block_stride = params.block_stride

    rows, cols = size(img)
    if rows%cell_size!=0 || cols%cell_size!=0
        error("Height and Width of the image must be a multiple of cell_size.")
    end

    cell_rows::Int = rows/cell_size
    cell_cols::Int = cols/cell_size
    if (cell_rows-block_size)%block_stride!=0 || (cell_cols-block_size)%block_stride!=0
        error("Block size and block stride don't match.")
    end

    #gradient computation
    gx = imfilter(img, centered([-1 0 1]))
    gy = imfilter(img, centered([-1 0 1]'))

    mag = hypot.(gx, gy)
    phase = orientation.(gx, gy)
    phase = abs.(phase*180/pi)

    #orientation binning for each cell
    hist = zeros(Float64, (orientations, cell_rows, cell_cols))
    R = CartesianRange(indices(img))

    for i in R
        lower = floor(Int, phase[i]*orientations/180) + 1
        upper = lower%orientations + 1

        cell_i::Int = floor((i[1] - 1)/cell_rows) + 1
        cell_j::Int = floor((i[2] - 1)/cell_cols) + 1

        #votes are weighted by gradient magnitude and linearly interpolated between neighboring bin centers
        if lower != orientations
            hist[lower, cell_i, cell_j] += mag[i]*(abs(phase[i] - (lower-1)*180/orientations))/(abs(phase[i] - (lower-1)*180/orientations) + abs(phase[i] - (upper-1)*180/orientations))
            hist[upper, cell_i, cell_j] += mag[i]*(abs(phase[i] - (upper-1)*180/orientations))/(abs(phase[i] - (lower-1)*180/orientations) + abs(phase[i] - (upper-1)*180/orientations))
        else
            hist[lower, cell_i, cell_j] += mag[i]*(abs(phase[i] - (lower-1)*180/orientations))/(abs(phase[i] - (lower-1)*180/orientations) + abs(phase[i] - 180))
            hist[upper, cell_i, cell_j] += mag[i]*(abs(phase[i] - 180))/(abs(phase[i] - (lower-1)*180/orientations) + abs(phase[i] - 180))
        end
    end

    function normalize(v, method)
        if method == "L2-norm"
            return v./sqrt(sum(abs2, v) + 1e-5)
        elseif method == "L2-hys"
            v = v./(sum(abs2, v) + 1e-5)
            v = min.(v, 0.2)
            return v./(sum(abs2, v) + 1e-5)
        elseif method == "L1-norm"
            return v./(sum(abs, v) + 1e-5)
        elseif method == "L1-sqrt"
            return sqrt.(v./(sum(abs, v) + 1e-5))
        end
    end

    #contrast normalization for each block
    descriptor_size::Int = ((cell_rows-block_size)/block_stride + 1) * ((cell_cols-block_size)/block_stride + 1) * (block_size*block_size) * orientations
    descriptor = Vector{Float64}(descriptor_size)
    block_vector_size = block_size * block_size * orientations
    k = 1
    for j in 1:block_stride:cell_cols-block_size+1
        for i in 1:block_stride:cell_rows-block_size+1
            descriptor[block_vector_size*(k-1)+1 : block_vector_size*k] = normalize(hist[:, i:i+block_size-1, j:j+block_size-1][:], params.norm_method)
            k += 1
        end
    end

    return descriptor
end