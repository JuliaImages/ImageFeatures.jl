type FREAK{S, T, O, N} <: DescriptorParams
    pattern_scale::Float64
    pattern_table::Array{S, N}
    smoothing_table::Array{T, N}
    orientation_weights::Array{O}
end

typealias OrientationPair Vector{Int}
typealias SamplePair Vector{Int}

function FREAK(; pattern_scale::Float64 = 22.0)
    pattern_table, smoothing_table = _freak_tables(pattern_scale)
    orientation_weights = OrientationPair[]
    for o in freak_orientation_sampling_pattern
        offset_1 = pattern_table[1][o[1]]
        offset_2 = pattern_table[1][o[2]]
        dy, dx = offset_1 - offset_2
        norm = (dx ^ 2 + dy ^ 2)
        push!(orientation_weights, OrientationPair(round(Int, dy * 4096 / norm), round(Int, dx * 4096 / norm)))
    end
    FREAK(pattern_scale, pattern_table, smoothing_table, orientation_weights)
end

function _freak_orientation{T<:Gray}(img::AbstractArray{T, 2}, int_img::AbstractArray{T, 2}, keypoint::Keypoint, pattern::Array{SamplePair}, 
                                        orientation_weights::Array{OrientationPair})
    direction_sum_y = 0.0
    direction_sum_x = 0.0
    for (i, o) in enumerate(freak_orientation_sampling_pattern)
        offset_1 = pattern[o[1]]
        offset_2 = pattern[o[2]]
        point_1 = keypoint + CartesianIndex(offset_1[1], offset_1[2])
        point_2 = keypoint + CartesianIndex(offset_2[1], offset_2[2])
        intensity_diff = img[point_1] - img[point_2]
        direction_sum_y += orientation_weights[i] * intensity_diff / 4096
        direction_sum_x += orientation_weights[i] * intensity_diff / 4096
    end
    angle = atan2(direction_sum_y, direction_sum_x)
    scaled_angle = round(Int, (angle + pi) * freak_orientation_steps / (2 * pi))
    scaled_angle
end

function _freak_mean_intensity{T<:Gray}(int_img::AbstractArray{T, 2}, )
end

function _freak_tables(pattern_scale::Float64)
    pattern_table = Array{SamplePair}[]
    smoothing_table = Array{Float64}[]
    for ori in 0:freak_orientation_steps - 1
        theta = ori * 2 * pi / freak_orientation_steps 
        pattern = SamplePair[]
        sigmas = Float64[]
        for (i, n) in enumerate(freak_num_circular_pattern)
            for circle_number in 0:n - 1
                alt_offset = (pi / n) * ((i - 1) % 2)
                angle = (circle_number * 2 * pi / n) + alt_offset

                push!(pattern, SamplePair([round(Int, freak_radii[i] * sin(angle) * pattern_scale), 
                                            round(Int, freak_radii[i] * cos(angle) * pattern_scale)]))
                push!(sigmas, freak_sigma[i] * pattern_scale)
            end
        end
        push!(pattern_table, pattern)
        push!(smoothing_table, sigmas)
    end
    pattern_table, smoothing_table
end

function create_descriptor{T<:Gray}(img::AbstractArray{T, 2}, keypoints::Keypoints, params::FREAK)
    int_img = integral_image(img)
    descriptors = BitArray[]
    for k in keypoints
        orientation = _freak_orientation(img, int_img, k, pattern_table[1], params.orientation_weights)

        sampled_intensities = T[]

        descriptor = falses(512)
        for (i, f) in enumerate(freak_sampling_pattern)
            point_1 = sampled_intensities[f[1]]
            point_2 = sampled_intensities[f[2]]
            descriptor[i] = point_1 < point_2
        end
        push!(descriptors, descriptor)
    end
    descriptors
end