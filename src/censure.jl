abstract BiFilter

type BoxFilter <: BiFilter

    scale :: Int
    in_length :: Int
    out_length :: Int
    in_area :: Float64
    out_area :: Float64
    in_weight :: Float64
    out_weight :: Float64

end

type OctagonFilter <: BiFilter
    
    m_out :: Int
    m_in :: Int
    n_out :: Int
    n_in :: Int
    in_area :: Float64
    out_area :: Float64
    in_weight :: Float64
    out_weight :: Float64

end

type CENSURE{F} <: Detector

    smallest :: Int
    largest :: Int
    filter_type :: Type{F}
    filter_stack :: Array{F}
    response_threshold :: Float64
    line_threshold :: Float64

end

function OctagonFilter(mo, mi, no, ni)
    OF = OctagonFilter(mo, mi, no, ni, 0.0, 0.0, 0.0, 0.0)
    OF.out_area = OF.m_out ^ 2 + 2 * OF.n_out ^ 2 + 4 * OF.m_out * OF.n_out
    OF.in_area = OF.m_in ^ 2 + 2 * OF.n_in ^ 2 + 4 * OF.m_in * OF.n_in
    OF.out_weight = 1.0 / (OF.out_area - OF.in_area)
    OF.in_weight = 1.0 / OF.in_area
    OF
end

function BoxFilter(s)
    BF = BoxFilter(s, 2 * s + 1, 4 * s + 1, (2 * s + 1) ^ 2, (4 * s + 1) ^ 2, 0.0, 0.0)
    BF.in_weight = 1.0 / BF.in_area
    BF.out_weight = 1.0 / (BF.out_area - BF.in_area)
    BF
end

const octagon_filter_kernels = [[5, 3, 2, 0],
                                [5, 3, 3, 1],
                                [7, 3, 3, 2],
                                [9, 5, 4, 2],
                                [9, 5, 7, 3],
                                [13, 5, 7, 4],
                                [15, 5, 10, 5]]

const box_filter_kernels = [1, 2, 3, 4, 5, 6, 7]

_getkernel(::Type{BoxFilter}) = box_filter_kernels
_getkernel(::Type{OctagonFilter}) = octagon_filter_kernels

function _get_filter_stack(filter_type::Type, smallest::Integer, largest::Integer)
    k = _getkernel(filter_type)
    filter_stack = map(f -> filter_type(f...), k[smallest : largest])
end

_get_integral_image(img, filter_type::BoxFilter) = integral_image(img)

function _get_integral_image(img, filter_type::OctagonFilter)
    img_shape = size(img)
    int_img = zeros(img_shape)
    right_slant_img = zeros(img_shape)
    left_slant_img = zeros(img_shape)

    int_img[1, :] = cumsum(img[1, :])
    right_slant_img[1, :] = int_img[1, :]
    left_slant_img[1, :] = int_img[1, :]

    for i in 2:img_shape[1]
        sum = 0.0
        for j in 1:img_shape[2]
            sum += img[i, j]
            int_img[i, j] = sum + int_img[i - 1, j]
            left_slant_img[i, j] = sum
            right_slant_img[i, j] = sum

            if j > 1 left_slant_img[i, j] += left_slant_img[i - 1, j - 1] end
            right_slant_img[i, j] += j < img_shape[2] ? right_slant_img[i - 1, j + 1] : right_slant_img[i - 1, j]
        end
    end
    int_img, right_slant_img, left_slant_img
end

function _filter_response{T}(int_img::AbstractArray{T, 2}, BF::BoxFilter)
    margin = BF.scale * 2
    n = BF.scale
    img_shape = size(int_img)
    response = zeros(T, img_shape)
    R = CartesianRange(CartesianIndex((margin + 2, margin + 2)), CartesianIndex((img_shape[1] - margin, img_shape[2] - margin))) 
    
    for I in R
        topleft = I + CartesianIndex(- n - 1, - n - 1)
        topright = I + CartesianIndex(- n - 1, n)
        bottomleft = I + CartesianIndex(n, - n - 1)
        bottomright = I + CartesianIndex(n, n)
        A = checkbounds(Bool, int_img, topleft) ? int_img[topleft] : zero(T)
        B = checkbounds(Bool, int_img, topright) ? int_img[topright] : zero(T)
        C = checkbounds(Bool, int_img, bottomleft) ? int_img[bottomleft] : zero(T)
        D = checkbounds(Bool, int_img, bottomright) ? int_img[bottomright] : zero(T)
        in_sum = A + D - B - C
        
        topleft = I + CartesianIndex(- 2 * n - 1, - 2 * n - 1)
        topright = I + CartesianIndex(- 2 * n - 1, 2 * n)
        bottomleft = I + CartesianIndex(2 * n, - 2 * n - 1)
        bottomright = I + CartesianIndex(2 * n, 2 * n)
        A = checkbounds(Bool, int_img, topleft) ? int_img[topleft] : zero(T)
        B = checkbounds(Bool, int_img, topright) ? int_img[topright] : zero(T)
        C = checkbounds(Bool, int_img, bottomleft) ? int_img[bottomleft] : zero(T)
        D = checkbounds(Bool, int_img, bottomright) ? int_img[bottomright] : zero(T)
        out_sum = A + D - B - C - in_sum
        response[I] = out_sum * BF.out_weight - BF.in_weight * in_sum
    end

    response
end

function _filter_response(int_imgs::Tuple, OF::OctagonFilter)
    int_img = int_imgs[1]
    rs_img = int_imgs[2]
    ls_img = int_imgs[3]

    T = eltype(int_img)

    margin = Int(floor(OF.m_out / 2 + OF.n_out))
    m_in2 = Int(floor(OF.m_in / 2))
    m_out2 = Int(floor(OF.m_out / 2))

    img_shape = size(int_img)
    response = zeros(T, img_shape)
    R = CartesianRange(CartesianIndex((margin + 2, margin + 2)), CartesianIndex((img_shape[1] - margin, img_shape[2] - margin))) 
    
    for I in R
        topleft = I + CartesianIndex(- m_in2 - 1, - m_in2 - OF.n_in - 1)
        topright = I + CartesianIndex(m_in2, - m_in2 - OF.n_in - 1)
        bottomleft = I + CartesianIndex(- m_in2 - 1, m_in2 + OF.n_in)
        bottomright = I + CartesianIndex(m_in2, m_in2 + OF.n_in)
        A = checkbounds(Bool, int_img, topleft) ? int_img[topleft] : zero(T)
        B = checkbounds(Bool, int_img, topright) ? int_img[topright] : zero(T)
        C = checkbounds(Bool, int_img, bottomleft) ? int_img[bottomleft] : zero(T)
        D = checkbounds(Bool, int_img, bottomright) ? int_img[bottomright] : zero(T)
        in_sum = A + D - B - C

        trap_top_right = bottomright
        trap_bot_right = I + CartesianIndex(m_in2 + OF.n_in, m_in2)
        trap_top_left = I + CartesianIndex(m_in2, - m_in2 - OF.n_in)
        trap_bot_left = I + CartesianIndex(m_in2 + OF.n_in, - m_in2 - 1)
        A = checkbounds(Bool, ls_img, trap_top_left) ? ls_img[trap_top_left] : zero(T)
        B = checkbounds(Bool, rs_img, trap_top_right) ? rs_img[trap_top_right] : zero(T)
        C = checkbounds(Bool, ls_img, trap_bot_left) ? ls_img[trap_bot_left] : zero(T)
        D = checkbounds(Bool, rs_img, trap_bot_right) ? rs_img[trap_bot_right] : zero(T)
        in_sum += A + D - B - C

        trap_top_right = I + CartesianIndex(- m_in2 - OF.n_in - 1, m_in2 - 1)
        trap_top_left = I + CartesianIndex(- m_in2 - OF.n_in - 1, - m_in2)
        trap_bot_right = I + CartesianIndex(- m_in2 - 1, m_in2 + OF.n_in - 1)
        trap_bot_left = I + CartesianIndex(- m_in2 - 1, - m_in2 - OF.n_in)
        A = checkbounds(Bool, rs_img, trap_top_left) ? rs_img[trap_top_left] : zero(T)
        B = checkbounds(Bool, ls_img, trap_top_right) ? ls_img[trap_top_right] : zero(T)
        C = checkbounds(Bool, rs_img, trap_bot_left) ? rs_img[trap_bot_left] : zero(T)
        D = checkbounds(Bool, ls_img, trap_bot_right) ? ls_img[trap_bot_right] : zero(T)
        in_sum += A + D - B - C

        topleft = I + CartesianIndex(- m_out2 - 1, - m_out2 - OF.n_out - 1)
        topright = I + CartesianIndex(m_out2, - m_out2 - OF.n_out - 1)
        bottomleft = I + CartesianIndex(- m_out2 - 1, m_out2 + OF.n_out)
        bottomright = I + CartesianIndex(m_out2, m_out2 + OF.n_out)
        A = checkbounds(Bool, int_img, topleft) ? int_img[topleft] : zero(T)
        B = checkbounds(Bool, int_img, topright) ? int_img[topright] : zero(T)
        C = checkbounds(Bool, int_img, bottomleft) ? int_img[bottomleft] : zero(T)
        D = checkbounds(Bool, int_img, bottomright) ? int_img[bottomright] : zero(T)
        out_sum = A + D - B - C

        trap_top_right = bottomright
        trap_bot_right = I + CartesianIndex(m_out2 + OF.n_out, m_out2)
        trap_top_left = I + CartesianIndex(m_out2, - m_out2 - OF.n_out)
        trap_bot_left = I + CartesianIndex(m_out2 + OF.n_out, - m_out2 - 1)
        A = checkbounds(Bool, ls_img, trap_top_left) ? ls_img[trap_top_left] : zero(T)
        B = checkbounds(Bool, rs_img, trap_top_right) ? rs_img[trap_top_right] : zero(T)
        C = checkbounds(Bool, ls_img, trap_bot_left) ? ls_img[trap_bot_left] : zero(T)
        D = checkbounds(Bool, rs_img, trap_bot_right) ? rs_img[trap_bot_right] : zero(T)
        out_sum += A + D - B - C

        trap_top_right = I + CartesianIndex(- m_out2 - OF.n_out - 1, m_out2 - 1)
        trap_top_left = I + CartesianIndex(- m_out2 - OF.n_out - 1, - m_out2)
        trap_bot_right = I + CartesianIndex(- m_out2 - 1, m_out2 + OF.n_out - 1)
        trap_bot_left = I + CartesianIndex(- m_out2 - 1, - m_out2 - OF.n_out)
        A = checkbounds(Bool, rs_img, trap_top_left) ? rs_img[trap_top_left] : zero(T)
        B = checkbounds(Bool, ls_img, trap_top_right) ? ls_img[trap_top_right] : zero(T)
        C = checkbounds(Bool, rs_img, trap_bot_left) ? rs_img[trap_bot_left] : zero(T)
        D = checkbounds(Bool, ls_img, trap_bot_right) ? ls_img[trap_bot_right] : zero(T)
        out_sum += A + D - B - C
        out_sum = out_sum - in_sum

        response[I] = in_sum * OF.in_weight - out_sum * OF.out_weight
    end
    response
    
end

function CENSURE(; smallest::Integer = 1, largest::Integer = 7, filter::Type = BoxFilter, response_threshold::Number = 0.15, line_threshold::Number = 10)
    CENSURE{filter}(smallest, largest, filter, _get_filter_stack(filter, smallest, largest), response_threshold, line_threshold)
end

function censure{T, F}(img::AbstractArray{T, 2}, params::CENSURE{F})
    int_img = _get_integral_image(img, params.filter_stack[1])
    responses = map(f -> _filter_response(int_img, f), params.filter_stack)
    response_matrix = reshape(hcat(responses...), size(img)..., size(responses)...)
    minima, maxima = extrema_filter(convert(Array{Float64}, padarray(response_matrix, [1, 1, 1], [1, 1, 1], "replicate")), [3, 3, 3])
    features = map(i -> (minima[i] == response_matrix[i] || maxima[i] == response_matrix[i]) && ( response_matrix[i] > params.response_threshold ), CartesianRange(size(response_matrix)))
    (grad_x, grad_y) = imgradients(img, "sobel", "replicate")
    cov_xx = grad_x .* grad_x
    cov_xy = grad_x .* grad_y
    cov_yy = grad_y .* grad_y
    for i in 1:params.largest - params.smallest + 1
        gamma = (1 + (params.smallest + i - 1) / 3.0)
        filt_cov_xx = imfilter_gaussian(cov_xx, [gamma, gamma])
        filt_cov_xy = imfilter_gaussian(cov_xy, [gamma, gamma])
        filt_cov_yy = imfilter_gaussian(cov_yy, [gamma, gamma])

        features[:, :, i] = map((xx, yy, xy, f) -> (xx + yy) ^ 2 > params.line_threshold * (xx * yy - xy ^ 2) ? false : f, filt_cov_xx, filt_cov_yy, filt_cov_xy, features[:, :, i])
    end
    keypoints = Array{Keypoint}([])
    scales = Array{Integer}([])
    for scale in 1:(params.largest - params.smallest + 1)
        rows, cols, _ = findnz(features[:, :, scale])
        append!(keypoints, map((r, c) -> Keypoint(r, c), rows, cols))
        append!(scales, ones(length(rows)) * scale)
    end
    keypoints, scales
end