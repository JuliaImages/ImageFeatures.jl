type FREAK <: DescriptorParams
    pattern_scale::Float64
    octaves::Int
end

typealias SamplePair Vector{Float64}

function FREAK(; pattern_scale::Float64 = 22.0, octaves::Int = 4)
    FREAK(pattern_scale, octaves)
end

function _freak_orientation()
end

function _freak_mean_intensity()
end

function _freak_tables(pattern_scale::Float64, scale_step::Float64)
    pattern_table = Array{SamplePair}[]
    smoothing_table = Array{Float64}[]
    window_sizes = Int[]
    for i in 0:freak_num_scales-1
        scale_factor = scale_step ^ i
        pattern = SamplePair[]
        sigmas = Float64[]
        largest_window = 0
        for (i, n) in enumerate(freak_num_circular_pattern)
            for circle_number in 0:n - 1
                alt_offset = (pi / n) * ((i - 1) % 2)
                angle = (circle_number * 2 * pi / n) + alt_offset

                push!(pattern, SamplePair([freak_radii[i] * cos(angle) * scale_factor * pattern_scale, 
                                            freak_radii[i] * sin(angle) * scale_factor * pattern_scale]))
                push!(sigmas, freak_sigma[i] * scale_factor * pattern_scale)

                largest_window = max(ceil(Int, (freak_radii[i] + freak_sigma[i]) * scale_factor * pattern_scale) + 1, largest_window)
            end
        end
        push!(pattern_table, pattern)
        push!(smoothing_table, sigmas)
        push!(window_sizes, largest_window)
    end
    pattern_table, smoothing_table, window_sizes
end

function create_descriptor{T<:Gray}(img::AbstractArray{T, 2}, keypoints::Keypoints, params::FREAK)
    scale_step = 2 ^ (params.octaves / freak_num_scales)
    pattern_table, smoothing_table, window_sizes = _freak_tables(params.pattern_scale, scale_step)
end