type ORB <: DescriptorParams
	num_keypoints::Int
	n::Int
	threshold::Float64
	line_threshold::Float64
end

function ORB(; num_keypoints::Int = )
    ORB(num_keypoints, n, threshold, line_threshold, )
end

function create_descriptor{T<:Gray}(img::AbstractArray{T, 2}, keypoints::Keypoints, params::ORB)

end