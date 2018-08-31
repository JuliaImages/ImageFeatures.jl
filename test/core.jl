using Test, ImageFeatures, Images

@testset "Types" begin
    img = zeros(10, 10)
    ids = map(CartesianIndex{2}, [(1, 1), (3, 4), (4, 6), (7, 5), (5, 3)])

    img[ids] .= 1

    keypoints = Keypoints(img)
    @test sort(keypoints) == sort(ids)
    @test Keypoint(1, 2) == CartesianIndex{2}(1, 2)

    features = Features(img)
    keypoints = Keypoints(features)
    @test sort(keypoints) == sort(ids)
end

@testset "Keypoint Matching" begin
    @test hamming_distance([false], [false]) == 0
    @test hamming_distance([false, true], [false, false]) == 0.5
    @test hamming_distance([false, false, true], [false, false, true]) == 0
    @test hamming_distance([false, false, true], [false, true, false]) == 2 / 3
    @test hamming_distance([false], [true]) == 1.0

    k1 = map(CartesianIndex{2}, [(1, 1), (2, 2), (3, 3), (4, 4)])
    k2 = map(CartesianIndex{2}, [(5, 5)])
    d1 = [[false, false, false],
          [false, false, true],
          [false, true, false],
          [true, true, true]]
    d2 = [[false, true, false]]
    matches = match_keypoints(k1, k2, d1, d2)
    #expected_matches = [[CartesianIndex(3, 3), CartesianIndex(5, 5)]]
    #@test all(expected_matches .== matches)

    k2 = map(CartesianIndex{2}, [(5, 5), (6, 6)])
    d2 = [[false, true, false],
          [false, false, false]]
    #matches = match_keypoints(k1, k2, d1, d2)
    expected_matches = [[CartesianIndex(3, 3), CartesianIndex(5, 5)],
                        [CartesianIndex(1, 1), CartesianIndex(6, 6)]]
    #@test all(expected_matches .== matches)
end

@testset "Grade Matches" begin
    k1 = map(CartesianIndex{2}, [(1,1),(2,1)])
    k2 = map(CartesianIndex{2}, [(1,1),(2,1)])
    @test grade_matches(k1, k2, 1) == 1
    @test grade_matches(k1, k2, 1, (i,j)->(abs(i[1]-j[1]) + abs(i[2]-j[2]))) == 1
    k2 = map(CartesianIndex{2}, [(1,0),(0,1)])
    @test grade_matches(k1, k2, 1) == 0
    @test grade_matches(k1, k2, 2) == 0.5
    k2 = map(CartesianIndex{2}, [(0,0),(2,1)])
    @test grade_matches(k1, k2, 1.2) == 0.5
end
