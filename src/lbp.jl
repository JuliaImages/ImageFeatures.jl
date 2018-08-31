mutable struct PatternCache
    table::Dict{BitArray{1}, Int}
    count::Int
    non_uniform_pattern::BitArray{1}
end

function PatternCache(points::Integer)
    temp_pattern = zeros(Bool, points)
    temp_pattern[1:2:points] .= true
    table = Dict{BitArray{1}, Int}()
    table[temp_pattern] = points * (points - 1) + 2
    PatternCache(table, 0, temp_pattern)
end

function lbp_original(bit_pattern::BitArray{1}, uniform_params::PatternCache)
    sum((b * 1) << (length(bit_pattern) - i) for (i, b) in enumerate(bit_pattern)), uniform_params
end

function lbp_uniform(bit_pattern::BitArray{1}, uniform_params::PatternCache)
    variations = sum(bit_pattern[i] != bit_pattern[i + 1] for i in 1:length(bit_pattern) - 1)
    if variations <= 2
        haskey(uniform_params.table, bit_pattern) && return uniform_params.table[bit_pattern], uniform_params
        uniform_params.count += 1
        uniform_params.table[copy(bit_pattern)] = uniform_params.count
        return uniform_params.count, uniform_params
    else
        return uniform_params.table[uniform_params.non_uniform_pattern], uniform_params
    end
end

function lbp_rotation_invariant(bit_pattern::BitArray{1}, uniform_params::PatternCache)
    mini, _ = lbp_original(bit_pattern, uniform_params)
    for i in 2:length(bit_pattern)
          mini = min(mini, lbp_original(vcat(bit_pattern[i:end], bit_pattern[1:i-1]), uniform_params)[1])
    end
    mini, uniform_params
end

function _lbp(img::AbstractArray{T, 2}, points::Integer, offsets::Array, method::Function = lbp_original) where T<:Gray
    uniform_params = PatternCache(points)
    lbp_image = zeros(UInt, size(img))
    R = CartesianIndices(size(img))
    bit_pattern = falses(length(offsets))
    for I in R
        for (i, o) in enumerate(offsets) bit_pattern[i] = img[I] >= bilinear_interpolation(img, I[1] + o[1], I[2] + o[2]) end
        lbp_image[I], uniform_params = method(bit_pattern, uniform_params)
    end
    lbp_image
end

const original_offsets = [[- 1, - 1], [- 1, 0], [- 1, 1], [0, 1], [1, 1], [1, 0], [1, - 1], [0, - 1]]

function circular_offsets(points::Integer, radius::Number)

    return [(round(- radius * sin(2 * pi * i / points), digits=5), round(radius * cos(2 * pi * i / points), digits=5)) for i = 0:points - 1]
end

lbp(img::AbstractArray{T, 2}, method::Function = lbp_original) where {T<:Gray} = _lbp(img, 8, original_offsets, method)

lbp(img::AbstractArray{T, 2}, points::Integer, radius::Number, method::Function = lbp_original) where {T<:Gray} = _lbp(img, points, circular_offsets(points, radius), method)

function _modified_lbp(img::AbstractArray{T, 2}, points::Integer, offsets::Array, method::Function = lbp_original) where T<:Gray
    uniform_params = PatternCache(points)
    lbp_image = zeros(UInt, size(img))
    R = CartesianIndices(size(img))
    bit_pattern = falses(length(offsets))
    for I in R
        avg = (sum(bilinear_interpolation(img, I[1] + o[1], I[2] + o[2]) for o in offsets) + img[I]) / (points + 1)
        for (i, o) in enumerate(offsets) bit_pattern[i] = avg >= bilinear_interpolation(img, I[1] + o[1], I[2] + o[2]) end
        lbp_image[I], uniform_params = method(bit_pattern, uniform_params)
    end
    lbp_image
end

modified_lbp(img::AbstractArray{T, 2}, method::Function = lbp_original) where {T<:Gray} = _modified_lbp(img, 8, original_offsets, method)

modified_lbp(img::AbstractArray{T, 2}, points::Integer, radius::Number, method::Function = lbp_original) where {T<:Gray} = _modified_lbp(img, points, circular_offsets(points, radius), method)

function _direction_coded_lbp(img::AbstractArray{T, 2}, offsets::Array) where T
    lbp_image = zeros(UInt, size(img))
    R = CartesianIndices(size(img))
    p = Int(length(offsets) / 2)
    raw_img = convert(Array{Int}, rawview(channelview(img)))
    neighbours = zeros(Int, length(offsets))
    for I in R
        for (i, o) in enumerate(offsets)
            neighbours[i] = Int(bilinear_interpolation(img, I[1] + o[1], I[2] + o[2]).val.i)
        end
        lbp_image[I] = sum(((neighbours[j] - raw_img[I]) * (neighbours[j + p] - raw_img[I]) >= 0) * (2 ^ (2 * p - 2 * j + 1)) +
                            (abs(neighbours[j] - raw_img[I]) >= abs(neighbours[j + p] - raw_img[I])) * (2 ^ (2 * p - 2 * j)) for j in 1:p)
    end
    lbp_image
end

direction_coded_lbp(img::AbstractArray{T, 2}, method::Function = lbp_original) where {T<:Gray} = _direction_coded_lbp(img, original_offsets)

function direction_coded_lbp(img::AbstractArray{T, 2}, points::Integer, radius::Number, method::Function = lbp_original) where T<:Gray
    @assert points % 2 == 0 "For Direction Coded LBP, the number of points must be an even number."
    _direction_coded_lbp(img, circular_offsets(points, radius))
end

function multi_block_lbp(img::AbstractArray{T, 2}, tl_y::Integer, tl_x::Integer, height::Integer, width::Integer) where T<:Gray
    int_img = integral_image(img)
    h, w = size(img)

    @assert (tl_y + 3 * height - 1 <= h) && (tl_x + 3 * width -1 <= w) "Rectangle Grid exceeds image dimensions."

    center = [tl_y + height, tl_x + width]
    central_sum = boxdiff(int_img, tl_y + height : tl_y + 2 * height - 1, tl_x + width : tl_x + 2 * width - 1)
    lbp_code = 0

    for (i, o) in enumerate(original_offsets)
        cur_tl_y = center[1] + o[1] * height
        cur_tl_x = center[2] + o[2] * width
        cur_window_sum = boxdiff(int_img, cur_tl_y : cur_tl_y + height - 1, cur_tl_x : cur_tl_x + height - 1)
        lbp_code += (cur_window_sum > central_sum ? 1 : 0) * 2 ^ (8 - i)
    end
    lbp_code
end

function _create_descriptor(img::AbstractArray{Gray{T}, 2}, yblocks::Integer = 4, xblocks = 4, lbp_type::Function = lbp, args...) where T<:Normed
    h, w = size(img)
    blockh = ceil(Int, h / (yblocks))
    blockw = ceil(Int, w / (xblocks))
    el_max = typemax(FixedPointNumbers.rawtype(eltype(img[1])))
    edges = 0:Int((el_max+1)^0.5):el_max+1
    descriptor = Int[]
    for i in 1:xblocks
        for j in 1:yblocks
            lbp_image = lbp_type(img[(j-1)*blockh+1 : j*blockh, (i-1)*blockw+1 : i*blockw], args...)
            lbp_norm = lbp_image
            _, hist = imhist(lbp_image, edges)
            append!(descriptor, hist[2 : end - 1])
        end
    end
    descriptor
end

function create_descriptor(img::AbstractArray{Gray{T}, 2}, yblocks::Integer = 4, xblocks = 4; lbp_type::Function = lbp, args...) where T<:Normed
    h, w = size(img)
    y_padded = ceil(Int, h / (yblocks)) * yblocks
    x_padded = ceil(Int, w / (xblocks)) * xblocks

    img_padded = Images.imresize(img, (y_padded, x_padded))
    _create_descriptor(img_padded, yblocks, xblocks, lbp_type, args...)
end
