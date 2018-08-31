"""
```
brisk_params = BRISK([pattern_scale = 1.0])
```

| Argument | Type | Description |
|----------|------|-------------|
| `pattern_scale` | `Float64` | Scaling factor for the sampling window |
"""
mutable struct BRISK <: Params
    threshold::Float64
    octaves::Int
    pattern_scale::Float64
    pattern_table::Vector{Vector{SamplePair}}
    smoothing_table::Vector{Vector{Float16}}
    orientation_weights::Vector{OrientationWeights}
    short_pairs::Vector{OrientationPair}
    long_pairs::Vector{OrientationPair}
end

function BRISK(; threshold::Float64 = 0.25, octaves::Int = 4, pattern_scale = 1.0)
    pattern_table, smoothing_table = _brisk_tables(pattern_scale)
    orientation_weights = OrientationWeights[]
    short_pairs = OrientationPair[]
    long_pairs = OrientationPair[]
    dminsq = (brisk_dmin * pattern_scale) ^ 2
    dmaxsq = (brisk_dmax * pattern_scale) ^ 2
    for i in 2:brisk_points
        for j in 1:i - 1
            dy = pattern_table[1][j][1] - pattern_table[1][i][1]
            dx = pattern_table[1][j][2] - pattern_table[1][i][2]
            norm = dy ^ 2 + dx ^ 2
            if norm > dminsq
                push!(long_pairs, OrientationPair((j, i)))
                push!(orientation_weights, OrientationWeights((dy / norm, dx / norm)))
            elseif norm < dmaxsq
                push!(short_pairs, OrientationPair((j, i)))
            end
        end
    end
    BRISK(threshold, octaves, pattern_scale, pattern_table, smoothing_table, orientation_weights, short_pairs, long_pairs)
end

function _brisk_orientation(int_img::AbstractArray{T, 2}, keypoint::Keypoint, pattern::Array{SamplePair},
                               orientation_weights::Array{OrientationWeights}, sigmas::Array{Float16}, long_pairs::Array{OrientationPair}) where T<:Gray
    direction_sum_y = 0.0
    direction_sum_x = 0.0
    for (i, o) in enumerate(long_pairs)
        offset_1 = pattern[o[1]]
        offset_2 = pattern[o[2]]
        intensity_diff = ImageFeatures._freak_mean_intensity(int_img, keypoint, offset_1, sigmas[o[1]]) - ImageFeatures._freak_mean_intensity(int_img, keypoint, offset_2, sigmas[o[2]])
        direction_sum_y += orientation_weights[i][1] * intensity_diff
        direction_sum_x += orientation_weights[i][2] * intensity_diff
    end
    angle = atan(direction_sum_y, direction_sum_x)
    scaled_angle = ceil(Int, (angle + pi) * brisk_orientation_steps / (2 * pi))
    scaled_angle
end

function _brisk_tables(pattern_scale::Float64)
    pattern_table = Vector{SamplePair}[]
    smoothing_table = Vector{Float16}[]
    for ori in 0:brisk_orientation_steps - 1
        theta = ori * 2 * pi / brisk_orientation_steps
        pattern = SamplePair[]
        sigmas = Float16[]
        for (i, n) in enumerate(brisk_num_circular_pattern)
            for circle_number in 0:n - 1
                angle = (circle_number * 2 * pi / n) + theta

                push!(pattern, SamplePair((brisk_radii[i] * sin(angle) * pattern_scale * 0.85,
                                            brisk_radii[i] * cos(angle) * pattern_scale * 0.85)))
                push!(sigmas, brisk_sigma[i] * pattern_scale * 0.85)
            end
        end
        push!(pattern_table, pattern)
        push!(smoothing_table, sigmas)
    end
    pattern_table, smoothing_table
end

function create_descriptor(img::AbstractArray{T, 2}, features::Features, params::BRISK) where T<:Gray
    int_img = integral_image(img)
    descriptors = BitArray{1}[]
    ret_features = Feature[]
    window_size = ceil(Int, (brisk_radii[end] + brisk_sigma[end]) * params.pattern_scale * 0.85) + 1
    lim = CartesianIndex(window_size, window_size)
    for feature in features
        keypoint = Keypoint(feature)
        checkbounds(Bool, img, keypoint - lim) && checkbounds(Bool, img, keypoint + lim) || continue
        orientation = _brisk_orientation(int_img, keypoint, params.pattern_table[1], params.orientation_weights, params.smoothing_table[1], params.long_pairs)
        sampled_intensities = T[]
        for (i, p) in enumerate(params.pattern_table[orientation])
            push!(sampled_intensities, ImageFeatures._freak_mean_intensity(int_img, keypoint, p, params.smoothing_table[orientation][i]))
        end
        descriptor = falses(size(params.short_pairs, 1))
        for (i, f) in enumerate(params.short_pairs)
            point_1 = sampled_intensities[f[1]]
            point_2 = sampled_intensities[f[2]]
            descriptor[i] = point_1 < point_2
        end
        push!(descriptors, descriptor)
        push!(ret_features, Feature(keypoint, orientation))
    end
    descriptors, ret_features
end
