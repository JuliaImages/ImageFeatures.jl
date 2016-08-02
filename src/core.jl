abstract Detector
abstract DescriptorParams
typealias Keypoint CartesianIndex{2}
typealias Keypoints Array{CartesianIndex{2}}

function Keypoints(img::AbstractArray)
	r, c, _ = findnz(img)
	map((ri, ci) -> Keypoint(ri, ci), r, c)
end

hamming_distance(desc_1, desc_2) = mean(desc_1 .!= desc_2)

function match_keypoints(keypoints_1::Keypoints, keypoints_2::Keypoints, desc_1, desc_2, threshold::Float64 = 0.1)
	smaller = desc_1
	larger = desc_2
	s_key = keypoints_1
	l_key = keypoints_2
	order = false
	if length(desc_1) > length(desc_2) 
		smaller = desc_2
		larger = desc_1
		s_key = keypoints_2
		l_key = keypoints_1
		order = true
	end
	hamming_distances = [hamming_distance(s, l) for s in smaller, l in larger]
	matches = Keypoints[]
	for i in 1:length(smaller)
		if any(hamming_distances[i, :] .< threshold)
			push!(matches, order ? [l_key[indmin(hamming_distances[i, :])], s_key[i]] : [s_key[i], l_key[indmin(hamming_distances[i, :])]])
			hamming_distances[:, indmin(hamming_distances[i, :])] = 1.0
		end
	end
	matches
end