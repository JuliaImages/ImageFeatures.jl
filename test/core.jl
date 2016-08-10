facts("Core") do
    
    context("Types") do
        img = zeros(10, 10)
        ids = map(CartesianIndex{2}, [(1, 1), (3, 4), (4, 6), (7, 5), (5, 3)])

        img[ids] = 1

        keypoints = Keypoints(img)
        @fact sort(keypoints) == sort(ids) --> true
        @fact Keypoint(1, 2) --> CartesianIndex{2}(1, 2)
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

    #TEMP

    context("Gaussian Pyramid") do
        img = zeros(40, 40)
        img[10:30, 10:30] = 1
        pyramid = gaussian_pyramid(img, 3, 2, 1.0)
        @fact size(pyramid[1]) == (40, 40) --> true
        @fact size(pyramid[2]) == (20, 20) --> true
        @fact size(pyramid[3]) == (10, 10) --> true
        @fact size(pyramid[4]) == (5, 5) --> true
        @fact isapprox(pyramid[1][20, 20], 1.0, atol = 0.01) --> true
        @fact isapprox(pyramid[2][10, 10], 1.0, atol = 0.01) --> true
        @fact isapprox(pyramid[3][5, 5], 1.0, atol = 0.05) --> true
        @fact isapprox(pyramid[4][3, 3], 0.9, atol = 0.025) --> true
        
        for p in pyramid
            h, w = size(p)
            @fact all([isapprox(v, 0, atol = 0.06) for v in p[1, :]]) --> true
            @fact all([isapprox(v, 0, atol = 0.06) for v in p[:, 1]]) --> true
            @fact all([isapprox(v, 0, atol = 0.06) for v in p[h, :]]) --> true
            @fact all([isapprox(v, 0, atol = 0.06) for v in p[:, w]]) --> true
        end 
    end

end