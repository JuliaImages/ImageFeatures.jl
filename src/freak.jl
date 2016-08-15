type FREAK <: DescriptorParams
	patternScale::Float64

end

function FREAK(; patternScale = 22)
	FREAK(patternScale, )
end

function _freak_orientation()
end

function _freak_mean_intensity()
end

function _freak_pattern(patternScale<:Float64)
	for (i, n) in enumerate(freak_num_circular_pattern)
		for circle_number in 0:n - 1
			alt_offset = (pi / n) * ((i - 1) % 2)

		end
	end
end

function create_descriptor{T<:Gray}(img::AbstractArray{T, 2}, keypoints::Keypoints, params::FREAK)
	
end