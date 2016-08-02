facts("Core") do
	
	img = zeros(10, 10)
	ids = map(CartesianIndex{2}, [(1, 1), (3, 4), (4, 6), (7, 5), (5, 3)])

	img[ids] = 1

	keypoints = Keypoints(img)
	@fact sort(keypoints) == sort(ids) --> true
	@fact Keypoint(1, 2) --> CartesianIndex{2}(1, 2)

end