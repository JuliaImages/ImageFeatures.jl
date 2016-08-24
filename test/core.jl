facts("Core") do
    
    context("Types") do
        img = zeros(10, 10)
        ids = map(CartesianIndex{2}, [(1, 1), (3, 4), (4, 6), (7, 5), (5, 3)])

        img[ids] = 1

        keypoints = Keypoints(img)
        @fact sort(keypoints) == sort(ids) --> true
        @fact Keypoint(1, 2) --> CartesianIndex{2}(1, 2)
        
        features = Features(img)
        keypoints = Keypoints(features)
        @fact sort(keypoints) == sort(ids) --> true

    end

    context("Keypoint Matching") do
        @fact hamming_distance([false], [false]) == 0 --> true
        @fact hamming_distance([false, true], [false, false]) == 0.5 --> true
        @fact hamming_distance([false, false, true], [false, false, true]) == 0 --> true
        @fact hamming_distance([false, false, true], [false, true, false]) == 2 / 3 --> true
        @fact hamming_distance([false], [true]) == 1.0 --> true

        k1 = map(CartesianIndex{2}, [(1, 1), (2, 2), (3, 3), (4, 4)])
        k2 = map(CartesianIndex{2}, [(5, 5)])
        d1 = [[false, false, false],
              [false, false, true],
              [false, true, false],
              [true, true, true]]
        d2 = [[false, true, false]]
        matches = match_keypoints(k1, k2, d1, d2)
        expected_matches = [[CartesianIndex(3, 3), CartesianIndex(5, 5)]]
        @fact all(expected_matches .== matches) --> true

        k2 = map(CartesianIndex{2}, [(5, 5), (6, 6)])
        d2 = [[false, true, false],
              [false, false, false]]
        matches = match_keypoints(k1, k2, d1, d2)
        expected_matches = [[CartesianIndex(3, 3), CartesianIndex(5, 5)],
                            [CartesianIndex(1, 1), CartesianIndex(6, 6)]]
        @fact all(expected_matches .== matches) --> true
    end

end