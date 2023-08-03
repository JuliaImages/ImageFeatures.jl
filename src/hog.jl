"""
```
hog_params = HOG([orientations = 9], [cell_size = 8], [block_size = 2], [block_stride = 1], [norm_method = "L2-norm"])
```

Histogram of Oriented Gradient (HOG) is a dense feature descriptor usually used for object detection. See "Histograms of Oriented Gradients for Human Detection" by Dalal and Triggs.

Parameters:
-    orientations   = number of orientation bins
-    cell_size      = size of a cell is cell_size x cell_size (in pixels)
-    block_size     = size of a block is block_size x block_size (in terms of cells)
-    block_stride   = stride of blocks. Controls how much adjacent blocks overlap.
-    norm_method    = block normalization method. Options: L2-norm, L2-hys, L1-norm, L2-sqrt.
"""
mutable struct HOG <: Params
    orientations::Int
    cell_size::Int
    block_size::Int
    block_stride::Int
    norm_method::String
end

function HOG(; orientations::Int = 9, cell_size::Int = 8, block_size::Int = 2, block_stride::Int = 1, norm_method::String = "L2-norm")
    HOG(orientations, cell_size, block_size, block_stride, norm_method)
end

function create_descriptor(img::AbstractArray{CT, 2}, params::HOG) where CT<:Images.NumberLike
    #compute gradient
    gx = imfilter(img, centered([-1 0 1]))
    gy = imfilter(img, centered([-1 0 1]'))
    mag = hypot.(gx, gy)
    phase = orientation.(gx, gy)

    create_hog_descriptor(mag, phase, params)
end

function create_descriptor(img::AbstractArray{CT, 2}, params::HOG) where CT<:Images.Color{T, N} where T where N
    #for color images, compute seperate gradient for each color channel and take one with largest norm as pixel's gradient vector
    rows, cols = size(img)
    gx = channelview(imfilter(img, centered([-1 0 1])))
    gy = channelview(imfilter(img, centered([-1 0 1]')))
    mag = hypot.(gx, gy)
    phase = orientation.(gx, gy)

    max_mag = zeros(rows, cols)
    max_phase = zeros(rows, cols)

    for j in axes(mag, 3)
        for i in axes(mag, 2)
            ind = argmax(view(mag, :, i, j))
            max_mag[i, j] = mag[ind, i, j]
            max_phase[i, j] = phase[ind, i, j]
        end
    end

    create_hog_descriptor(max_mag, max_phase, params)
end

function create_hog_descriptor(mag::AbstractArray{T, 2}, phase::AbstractArray{T, 2}, params::HOG) where T<:Images.NumberLike
    orientations = params.orientations
    cell_size = params.cell_size
    block_size = params.block_size
    block_stride = params.block_stride

    rows, cols = size(mag)
    if rows%cell_size!=0 || cols%cell_size!=0
        error("Height and Width of the image must be a multiple of cell_size.")
    end

    cell_rows::Int = rows/cell_size
    cell_cols::Int = cols/cell_size
    if (cell_rows-block_size)%block_stride!=0 || (cell_cols-block_size)%block_stride!=0
        error("Block size and block stride don't match.")
    end

    phase = abs.(phase*180/pi)

    #orientation binning for each cell
    hist = zeros(Float64, (orientations, cell_rows, cell_cols))
    R = CartesianIndices(axes(mag))

    for i in R
        trilinear_interpolate!(hist, mag[i], phase[i], orientations, i, cell_size, cell_rows, cell_cols, rows, cols)
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
    descriptor = Vector{Float64}(undef, descriptor_size)
    block_vector_size = block_size * block_size * orientations
    k = 1
    for j in 1:block_stride:cell_cols-block_size+1
        for i in 1:block_stride:cell_rows-block_size+1
            H = @view hist[:, i:i+block_size-1, j:j+block_size-1]
            h = @view H[:]
            descriptor[block_vector_size*(k-1)+1 : block_vector_size*k] = normalize(h, params.norm_method)
            k += 1
        end
    end

    return descriptor
end

function trilinear_interpolate!(hist, w, θ, orientations, i, cell_size, cell_rows, cell_cols, rows, cols)
    bin_θ1 = min(floor(Int, θ*orientations/180) + 1, orientations)
    bin_θ2 = bin_θ1%orientations + 1
    b_θ = 180/orientations

    if bin_θ1 != orientations
        θ1 = (bin_θ1-1)*180/orientations
        θ2 = (bin_θ2-1)*180/orientations
    else
        θ1 = (bin_θ1-1)*180/orientations
        θ2 = 180.0;
    end

    if (i[1]<=cell_size/2 || i[1]>=rows-cell_size/2) && (i[2]<=cell_size/2 || i[2]>=cols-cell_size/2)
        #linear interpolation for corner points
        bin_x = i[1] < cell_size/2 ? 1 : cell_rows
        bin_y = i[2] < cell_size/2 ? 1 : cell_cols

        hist[bin_θ1, bin_x, bin_y] += w*(1-(θ-θ1)/b_θ)
        hist[bin_θ2, bin_x, bin_y] += w*(1-(θ2-θ)/b_θ)

    elseif i[1]<=cell_size/2 || i[1]>=rows-cell_size/2
        #bilinear interpolation for (top/bottom) edge points
        bin_x = i[1] < cell_size/2 ? 1 : cell_rows
        bin_y1 = floor(Int, (i[2]+cell_size/2)/cell_size)
        bin_y2 = bin_y1 + 1

        y1 = (bin_y1-1)*cell_size+cell_size/2
        y2 = (bin_y2-1)*cell_size+cell_size/2
        b_y = cell_size

        hist[bin_θ1, bin_x, bin_y1] += w*(1-(θ-θ1)/b_θ)*(1-(i[2]-y1)/b_y)
        hist[bin_θ1, bin_x, bin_y2] += w*(1-(θ-θ1)/b_θ)*(1-(y2-i[2])/b_y)
        hist[bin_θ2, bin_x, bin_y1] += w*(1-(θ2-θ)/b_θ)*(1-(i[2]-y1)/b_y)
        hist[bin_θ2, bin_x, bin_y2] += w*(1-(θ2-θ)/b_θ)*(1-(y2-i[2])/b_y)

    elseif  i[2]<=cell_size/2 || i[2]>=cols-cell_size/2
        #bilinear interpolation for (left/right) edge points
        bin_x1 = floor(Int, (i[1]+cell_size/2)/cell_size)
        bin_x2 = bin_x1 + 1
        bin_y = i[2] < cell_size/2 ? 1 : cell_cols

        x1 = (bin_x1-1)*cell_size+cell_size/2
        x2 = (bin_x2-1)*cell_size+cell_size/2
        b_x = cell_size

        hist[bin_θ1, bin_x1, bin_y] += w*(1-(θ-θ1)/b_θ)*(1-(i[1]-x1)/b_x)
        hist[bin_θ1, bin_x2, bin_y] += w*(1-(θ-θ1)/b_θ)*(1-(x2-i[1])/b_x)
        hist[bin_θ2, bin_x1, bin_y] += w*(1-(θ2-θ)/b_θ)*(1-(i[1]-x1)/b_x)
        hist[bin_θ2, bin_x2, bin_y] += w*(1-(θ2-θ)/b_θ)*(1-(x2-i[1])/b_x)
    else
        #trilinear interpolation
        bin_x1 = floor(Int, (i[1]+cell_size/2)/cell_size)
        bin_x2 = bin_x1 + 1
        bin_y1 = floor(Int, (i[2]+cell_size/2)/cell_size)
        bin_y2 = bin_y1 + 1

        x1 = (bin_x1-1)*cell_size+cell_size/2
        x2 = (bin_x2-1)*cell_size+cell_size/2
        b_x = cell_size

        y1 = (bin_y1-1)*cell_size+cell_size/2
        y2 = (bin_y2-1)*cell_size+cell_size/2
        b_y = cell_size

        hist[bin_θ1, bin_x1, bin_y1] += w*(1-(θ-θ1)/b_θ)*(1-(i[1]-x1)/b_x)*(1-(i[2]-y1)/b_y)
        hist[bin_θ1, bin_x1, bin_y2] += w*(1-(θ-θ1)/b_θ)*(1-(i[1]-x1)/b_x)*(1-(y2-i[2])/b_y)
        hist[bin_θ1, bin_x2, bin_y1] += w*(1-(θ-θ1)/b_θ)*(1-(x2-i[1])/b_x)*(1-(i[2]-y1)/b_y)
        hist[bin_θ1, bin_x2, bin_y2] += w*(1-(θ-θ1)/b_θ)*(1-(x2-i[1])/b_x)*(1-(y2-i[2])/b_y)
        hist[bin_θ2, bin_x1, bin_y1] += w*(1-(θ2-θ)/b_θ)*(1-(i[1]-x1)/b_x)*(1-(i[2]-y1)/b_y)
        hist[bin_θ2, bin_x1, bin_y2] += w*(1-(θ2-θ)/b_θ)*(1-(i[1]-x1)/b_x)*(1-(y2-i[2])/b_y)
        hist[bin_θ2, bin_x2, bin_y1] += w*(1-(θ2-θ)/b_θ)*(1-(x2-i[1])/b_x)*(1-(i[2]-y1)/b_y)
        hist[bin_θ2, bin_x2, bin_y2] += w*(1-(θ2-θ)/b_θ)*(1-(x2-i[1])/b_x)*(1-(y2-i[2])/b_y)
    end
end
