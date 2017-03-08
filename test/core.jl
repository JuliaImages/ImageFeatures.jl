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

    context("Grade Matches") do
        k1 = map(CartesianIndex{2}, [(1,1),(2,1)])
        k2 = map(CartesianIndex{2}, [(1,1),(2,1)])
        @fact grade_matches(k1, k2) == 0 --> true
        @fact grade_matches(k1, k2, (i,j)->(abs(i[1]-j[1]) + abs(i[2]-j[2]))) == 0 --> true
        @fact grade_matches(k1, k2, 1) == 1 --> true
        @fact grade_matches(k1, k2, 1, (i,j)->(abs(i[1]-j[1]) + abs(i[2]-j[2]))) == 1 --> true
        k2 = map(CartesianIndex{2}, [(1,0),(0,1)])
        @fact grade_matches(k1, k2) == 1.5 --> true
        @fact grade_matches(k1, k2, 1) == 0 --> true
        @fact grade_matches(k1, k2, 2) == 0.5 --> true
        k2 = map(CartesianIndex{2}, [(0,0),(1,2)])
        @fact grade_matches(k1, k2) == sqrt(2) --> true
        @fact grade_matches(k1, k2, (i,j)->(abs(i[1]-j[1]) + abs(i[2]-j[2]))) == 2 --> true
        k2 = map(CartesianIndex{2}, [(0,0),(2,1)])
        @fact grade_matches(k1, k2) == sqrt(2) / 2 --> true
        @fact grade_matches(k1, k2, 1.2) == 0.5 --> true
    end
end