"""
```
freak_params = FREAK([pattern_scale = 22.0])
```

| Argument | Type | Description |
|----------|------|-------------|
| **pattern_scale** | Float64 | Scaling factor for the sampling window |
"""
mutable struct FREAK <: Params
    pattern_scale::Float64
    pattern_table::Vector{Vector{SamplePair}}
    smoothing_table::Vector{Vector{Float16}}
    orientation_weights::Vector{OrientationWeights}
end

function FREAK(; pattern_scale::Float64 = 22.0)
    pattern_table, smoothing_table = _freak_tables(pattern_scale)
    orientation_weights = OrientationWeights[]
    for o in freak_orientation_sampling_pattern
        offset_1 = pattern_table[1][o[1]]
        offset_2 = pattern_table[1][o[2]]
        dy = offset_1[1] - offset_2[1]
        dx = offset_1[2] - offset_2[2]
        norm = (dx ^ 2 + dy ^ 2)
        push!(orientation_weights, OrientationWeights((dy / norm, dx / norm)))
    end
    FREAK(pattern_scale, pattern_table, smoothing_table, orientation_weights)
end

function _freak_mean_intensity(int_img::AbstractArray{T, 2}, keypoint::Keypoint, offset::SamplePair, sigma::Float16) where T<:Gray
    y = keypoint[1] + offset[1]
    x = keypoint[2] + offset[2]
    if sigma < 0.5
        sigma = 1.0
    end
    xs = round(Int, x - sigma)
    ys = round(Int, y - sigma)
    xst = round(Int, x + sigma)
    yst = round(Int, y + sigma)
    intensity = boxdiff(int_img, ys:yst, xs:xst)
    intensity / ((xst - xs + 1) * (yst - ys + 1))
end

function _freak_orientation(int_img::AbstractArray{T, 2}, keypoint::Keypoint, pattern::Array{SamplePair},
                               orientation_weights::Array{OrientationWeights}, sigmas::Array{Float16}) where T<:Gray
    direction_sum_y = 0.0
    direction_sum_x = 0.0
    for (i, o) in enumerate(freak_orientation_sampling_pattern)
        offset_1 = pattern[o[1]]
        offset_2 = pattern[o[2]]
        intensity_diff = _freak_mean_intensity(int_img, keypoint, offset_1, sigmas[o[1]]) - _freak_mean_intensity(int_img, keypoint, offset_2, sigmas[o[2]])
        direction_sum_y += orientation_weights[i][1] * intensity_diff
        direction_sum_x += orientation_weights[i][2] * intensity_diff
    end
    angle = atan(direction_sum_y, direction_sum_x)
    scaled_angle = ceil(Int, (angle + pi) * freak_orientation_steps / (2 * pi))
    scaled_angle
end

function _freak_tables(pattern_scale::Float64)
    pattern_table = Vector{SamplePair}[]
    smoothing_table = Vector{Float16}[]
    for ori in 0:freak_orientation_steps - 1
        theta = ori * 2 * pi / freak_orientation_steps
        pattern = SamplePair[]
        sigmas = Float16[]
        for (i, n) in enumerate(freak_num_circular_pattern)
            for circle_number in 0:n - 1
                alt_offset = (pi / n) * ((i - 1) % 2)
                angle = (circle_number * 2 * pi / n) + alt_offset + theta

                push!(pattern, SamplePair((freak_radii[i] * sin(angle) * pattern_scale,
                                            freak_radii[i] * cos(angle) * pattern_scale)))
                push!(sigmas, freak_sigma[i] * pattern_scale)
            end
        end
        push!(pattern_table, pattern)
        push!(smoothing_table, sigmas)
    end
    pattern_table, smoothing_table
end

function create_descriptor(img::AbstractArray{T, 2}, keypoints::Keypoints, params::FREAK) where T<:Gray
    int_img = integral_image(img)
    descriptors = BitArray{1}[]
    ret_keypoints = Keypoint[]
    window_size = ceil(Int, (freak_radii[1] + freak_sigma[1]) * params.pattern_scale) + 1
    lim = CartesianIndex(window_size, window_size)
    for k in keypoints
        checkbounds(Bool, img, k - lim) && checkbounds(Bool, img, k + lim) || continue
        orientation = _freak_orientation(int_img, k, params.pattern_table[1], params.orientation_weights, params.smoothing_table[1])
        sampled_intensities = T[]
        for (i, p) in enumerate(params.pattern_table[orientation])
            push!(sampled_intensities,  _freak_mean_intensity(int_img, k, p, params.smoothing_table[orientation][i]))
        end
        descriptor = falses(512)
        for (i, f) in enumerate(freak_sampling_pattern)
            point_1 = sampled_intensities[f[1]]
            point_2 = sampled_intensities[f[2]]
            descriptor[i] = point_1 < point_2
        end
        push!(descriptors, descriptor)
        push!(ret_keypoints, k)
    end
    descriptors, ret_keypoints
end
