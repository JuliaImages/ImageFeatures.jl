type BRISK{S, T, O} <: Params
	threshold::Float64
	octaves::Int
	pattern_scale::Float64
    pattern_table::Array{Array{S}, 1}
    smoothing_table::Array{T, 1}
    orientation_weights::Array{O, 1}
    short_pairs::Array{O}
    long_pairs::Array{O}
end

typealias OrientationPair Vector{Int}
typealias SamplePair Vector{Float64}

function BRISK(; threshold::Float64 = 0.25, octaves::Int = 4, pattern_scale = 1.0)
    pattern_table, smoothing_table = _brisk_tables(pattern_scale)
    orientation_weights = OrientationPair[]
    short_pairs = SamplePair[]
    long_pairs = SamplePair[]
    dminsq = (brisk_dmin ^ 2) * pattern_scale
    dmaxsq = (brisk_dmax ^ 2) * pattern_scale
    for i in 2:brisk_points
        for j in 1:i - 1
            dy, dx = pattern_table[1][j] - pattern_table[1][i]
            norm = dy ^ 2 + dx ^ 2
            if norm > dminsq
                push!(long_pairs, OrientationPair(j, i))
                push!(orientation_weights, OrientationPair([round(Int, dy * 4096 / norm), round(Int, dx * 4096 / norm)]))
            elseif norm < dmaxsq
                push!(short_pairs, OrientationPair(j, i))
            end
        end
    end
    BRISK(threshold, octaves, pattern_scale, pattern_table, smoothing_table, orientation_weights, short_pairs, long_pairs)
end

function _brisk_mean_intensity{T<:Gray}(int_img::AbstractArray{T, 2}, keypoint::Keypoint, offset::SamplePair, sigma::Float64)
    y = k[1] + offset[1]
    x = k[2] + offset[2]
    if sigma < 0.5
        tl = bilinear_interpolation(int_img, y - sigma, x - sigma)
        tr = bilinear_interpolation(int_img, y - sigma, x + sigma)
        bl = bilinear_interpolation(int_img, y + sigma, x)
        br = bilinear_interpolation(int_img, y + sigma, x + sigma)
        return (br + tl - tr - bl) / (4 * (sigma ^ 2))
    end
    xs = round(Int, x - sigma)
    ys = round(Int, y - sigma)
    xst = round(Int, x + sigma)
    yst = round(Int, y + sigma)
    intensity = boxdiff(int_img, ys:yst, xs:xst)
    intensity / ((xst - xs) * (yst - ys))
end

function _brisk_orientation{T<:Gray}(int_img::AbstractArray{T, 2}, keypoint::Keypoint, pattern::Array{SamplePair}, 
                                        orientation_weights::Array{OrientationPair}, sigmas::Array{Float64}, long_pairs::Array{OrientationPair})
    direction_sum_y = 0.0
    direction_sum_x = 0.0
    for (i, o) in enumerate(long_pairs)
        offset_1 = pattern[o[1]]
        offset_2 = pattern[o[2]]
        intensity_diff = _freak_mean_intensity(int_img, k, offset_1, sigmas[o[1]]) - _freak_mean_intensity(int_img, k, offset_2, sigmas[o[2]])
        direction_sum_y += orientation_weights[i] * intensity_diff / 4096
        direction_sum_x += orientation_weights[i] * intensity_diff / 4096
    end
    angle = atan2(direction_sum_y, direction_sum_x)
    scaled_angle = round(Int, (angle + pi) * brisk_orientation_steps / (2 * pi))
    scaled_angle
end

function _brisk_tables(pattern_scale::Float64)
    pattern_table = Array{SamplePair}[]
    smoothing_table = Array{Float64}[]
    for ori in 0:brisk_orientation_steps - 1
        theta = ori * 2 * pi / brisk_orientation_steps 
        pattern = SamplePair[]
        sigmas = Float64[]
        for (i, n) in enumerate(brisk_num_circular_pattern)
            for circle_number in 0:n - 1
                angle = (circle_number * 2 * pi / n) + theta

                push!(pattern, SamplePair([brisk_radii[i] * sin(angle) * pattern_scale, 
                                            brisk_radii[i] * cos(angle) * pattern_scale]))
                push!(sigmas, brisk_sigma[i] * pattern_scale)
            end
        end
        push!(pattern_table, pattern)
        push!(smoothing_table, sigmas)
    end
    pattern_table, smoothing_table
end

function extract_features{T<:Gray}(img::AbstractArray{T, 2}, params::BRISK)
	
end

function create_descriptor{T<:Gray}(img::AbstractArray{T, 2}, params::BRISK)
	features = extract_features(img, params)
	create_descriptor(img, features, params)
end

function create_descriptor{T<:Gray}(img::AbstractArray{T, 2}, features::Array{Feature}, params::BRISK)
    int_img = integral_image(img)
    descriptors = BitArray[]
    ret_keypoints = Keypoint[]
    window_size = ceil(Int, (brisk_radii[1] + brisk_sigma[1]) * params.patternScale) + 1
    tl_lim = CartesianIndex(-window_size, -window_size)
    br_lim = CartesianIndex(window_size, window_size)
    for k in keypoints
        checkbounds(Bool, img, k + tl_lim) && checkbounds(Bool, img, k + br_lim) || continue
        orientation = _brisk_orientation(int_img, k, pattern_table[1], params.orientation_weights, smoothing_table[1], params.long_pairs)
        sampled_intensities = T[]
        for (i, p) in enumerate(pattern_table[orientation])
            push!(sampled_intensities, _brisk_mean_intensity(int_img, k, p[i], smoothing_table[orientation][i]))
        end
        descriptor = falses(size(params.short_pairs, 1))
        for (i, f) in enumerate(params.short_pairs)
            point_1 = sampled_intensities[f[1]]
            point_2 = sampled_intensities[f[2]]
            descriptor[i] = point_1 < point_2
        end
        push!(descriptors, descriptor)
        push!(ret_keypoints, k)
    end
    descriptors, ret_keypoints	
end