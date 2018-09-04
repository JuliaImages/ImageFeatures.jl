using Test, ImageFeatures, Images, TestImages, Distributions

@testset "Testing ORB params" begin
    orb_params = ORB(num_keypoints = 1000, threshold = 0.2)
    @test orb_params.num_keypoints == 1000
    @test orb_params.n_fast == 12
    @test orb_params.threshold == 0.2
    @test orb_params.harris_factor == 0.04
    @test orb_params.downsample == 1.3
    @test orb_params.levels == 8
    @test orb_params.sigma == 1.2
end

@testset "Testing with Standard Images - Lighthouse (Rotation 45)" begin
    img = testimage("lighthouse")
    img_array_1 = convert(Array{Gray}, img)
    img_array_2 = _warp(img_array_1, pi / 4)

    #Test Number of Keypoints returned
    orb_params = ORB(num_keypoints = 1000, threshold = 0.1)
    desc_1, ret_keypoints_1 = create_descriptor(img_array_1, orb_params)
    @test length(desc_1) == 1000
    orb_params = ORB(num_keypoints = 500, threshold = 0.1)
    desc_1, ret_keypoints_1 = create_descriptor(img_array_1, orb_params)
    @test length(desc_1) == 500
    orb_params = ORB(num_keypoints = 300, threshold = 0.1)
    desc_1, ret_keypoints_1 = create_descriptor(img_array_1, orb_params)
    @test length(desc_1) == 300

    orb_params = ORB(num_keypoints = 1000)

    desc_1, ret_keypoints_1 = create_descriptor(img_array_1, orb_params)
    desc_2, ret_keypoints_2 = create_descriptor(img_array_2, orb_params)
    matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.2)
    reverse_keypoints_1 = [_reverserotate(m[1], pi / 4, (256, 384)) for m in matches]
    @test (grade_matches(reverse_keypoints_1, [match[2] for match in matches], 10, (i,j)->(abs(i[1]-j[1]) + abs(i[2]-j[2]))) > 0.95 )
end

@testset "Testing with Standard Images - Lighthouse (Rotation 45, Translation (50, 40))" begin
    img = testimage("lighthouse")
    img_array_1 = convert(Array{Gray}, img)
    img_temp_2 = _warp(img_array_1, pi / 4)
    img_array_2 = _warp(img_temp_2, 50, 40)

    orb_params = ORB(num_keypoints = 1000)

    desc_1, ret_keypoints_1 = create_descriptor(img_array_1, orb_params)
    desc_2, ret_keypoints_2 = create_descriptor(img_array_2, orb_params)
    matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.2)
    reverse_keypoints_1 = [_reverserotate(m[1], pi / 4, (256, 384)) + CartesianIndex(50, 40) for m in matches]
    @test (grade_matches(reverse_keypoints_1, [match[2] for match in matches], 10, (i,j)->(abs(i[1]-j[1]) + abs(i[2]-j[2]))) > 0.95 )
end

@testset "Testing with Standard Images - Lighthouse (Rotation 75, Translation (50, 40))" begin
    img = testimage("lighthouse")
    img_array_1 = convert(Array{Gray}, img)
    img_temp_2 = _warp(img_array_1, 5 * pi / 6)
    img_array_2 = _warp(img_temp_2, 50, 40)

    orb_params = ORB(num_keypoints = 1000)

    desc_1, ret_keypoints_1 = create_descriptor(img_array_1, orb_params)
    desc_2, ret_keypoints_2 = create_descriptor(img_array_2, orb_params)
    matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.2)
    reverse_keypoints_1 = [_reverserotate(m[1], 5 * pi / 6, (256, 384)) + CartesianIndex(50, 40) for m in matches]
    @test (grade_matches(reverse_keypoints_1, [match[2] for match in matches], 10, (i,j)->(abs(i[1]-j[1]) + abs(i[2]-j[2]))) > 0.95 )
end

@testset "Testing with Standard Images - Lena (Rotation 45, Translation (10, 20))" begin
    img = testimage("lena_gray_512")
    img_array_1 = convert(Array{Gray}, img)
    img_temp_2 = _warp(img_array_1, pi / 4)
    img_array_2 = _warp(img_temp_2, 10, 20)

    orb_params = ORB(num_keypoints = 1000, threshold = 0.18)

    desc_1, ret_keypoints_1 = create_descriptor(img_array_1, orb_params)
    desc_2, ret_keypoints_2 = create_descriptor(img_array_2, orb_params)
    matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.2)
    reverse_keypoints_1 = [_reverserotate(m[1], pi / 4, (256, 256)) + CartesianIndex(10, 20) for m in matches]
    @test (grade_matches(reverse_keypoints_1, [match[2] for match in matches], 10, (i,j)->(abs(i[1]-j[1]) + abs(i[2]-j[2]))) > 0.95 )
end
