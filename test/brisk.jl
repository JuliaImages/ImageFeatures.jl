using Test, ImageFeatures, Images, TestImages, Distributions, ColorTypes

@testset "Testing brisk params" begin
    brisk_params = BRISK(pattern_scale = 2.0)
    @test brisk_params.pattern_scale == 2.0
    pt, st = ImageFeatures._brisk_tables(2.0)
    @test brisk_params.pattern_table == pt
    @test brisk_params.smoothing_table == st
end
    
@testset "Testing with Standard Images - Lighthouse (Rotation 45)" begin
    img = testimage("lighthouse")
    img_array_1 = convert(Array{Gray}, img)
    img_array_2 = _warp(img_array_1, pi / 4)

    features_1 = Features(fastcorners(img_array_1, 12, 0.35))
    features_2 = Features(fastcorners(img_array_2, 12, 0.35))
    brisk_params = BRISK()

    desc_1, ret_features_1 = create_descriptor(img_array_1, features_1, brisk_params)
    desc_2, ret_features_2 = create_descriptor(img_array_2, features_2, brisk_params)

    matches = match_keypoints(Keypoints(ret_features_1), Keypoints(ret_features_2), desc_1, desc_2, 0.1)
    reverse_keypoints_1 = [_reverserotate(m[1], pi / 4, (256, 384)) for m in matches]
    @test all(isapprox(rk[1], m[2][1], atol = 4) && isapprox(rk[2], m[2][2], atol = 4) for (rk, m) in zip(reverse_keypoints_1, matches))
end

@testset "Testing with Standard Images - Lighthouse (Rotation 45, Translation (50, 40))" begin
    img = testimage("lighthouse")
    img_array_1 = convert(Array{Gray}, img)
    img_temp_2 = _warp(img_array_1, pi / 4)
    img_array_2 = _warp(img_temp_2, 50, 40)

    features_1 = Features(fastcorners(img_array_1, 12, 0.35))
    features_2 = Features(fastcorners(img_array_2, 12, 0.35))
    brisk_params = BRISK()

    desc_1, ret_features_1 = create_descriptor(img_array_1, features_1, brisk_params)
    desc_2, ret_features_2 = create_descriptor(img_array_2, features_2, brisk_params)
    matches = match_keypoints(Keypoints(ret_features_1), Keypoints(ret_features_2), desc_1, desc_2, 0.1)
    reverse_keypoints_1 = [_reverserotate(m[1], pi / 4, (256, 384)) + CartesianIndex(50, 40) for m in matches]
    @test all(isapprox(rk[1], m[2][1], atol = 3) && isapprox(rk[2], m[2][2], atol = 3) for (rk, m) in zip(reverse_keypoints_1, matches))
end

@testset "Testing with Standard Images - Lighthouse (Rotation 75, Translation (50, 40))" begin
    img = testimage("lighthouse")
    img_array_1 = convert(Array{Gray}, img)
    img_temp_2 = _warp(img_array_1, 5 * pi / 6)
    img_array_2 = _warp(img_temp_2, 50, 40)

    features_1 = Features(fastcorners(img_array_1, 12, 0.35))
    features_2 = Features(fastcorners(img_array_2, 12, 0.35))
    brisk_params = BRISK()

    desc_1, ret_features_1 = create_descriptor(img_array_1, features_1, brisk_params)
    desc_2, ret_features_2 = create_descriptor(img_array_2, features_2, brisk_params)
    matches = match_keypoints(Keypoints(ret_features_1), Keypoints(ret_features_2), desc_1, desc_2, 0.1)
    reverse_keypoints_1 = [_reverserotate(m[1], 5 * pi / 6, (256, 384)) + CartesianIndex(50, 40) for m in matches]
    @test all(isapprox(rk[1], m[2][1], atol = 4) && isapprox(rk[2], m[2][2], atol = 4) for (rk, m) in zip(reverse_keypoints_1, matches))
end

@testset "Testing with Standard Images - Lena (Rotation 45, Translation (10, 20))" begin
    img = testimage("lena_gray_512")
    img_array_1 = convert(Array{Gray}, img)
    img_temp_2 = _warp(img_array_1, pi / 4)
    img_array_2 = _warp(img_temp_2, 10, 20)

    features_1 = Features(fastcorners(img_array_1, 12, 0.2))
    features_2 = Features(fastcorners(img_array_2, 12, 0.2))
    brisk_params = BRISK()

    desc_1, ret_features_1 = create_descriptor(img_array_1, features_1, brisk_params)
    desc_2, ret_features_2 = create_descriptor(img_array_2, features_2, brisk_params)
    matches = match_keypoints(Keypoints(ret_features_1), Keypoints(ret_features_2), desc_1, desc_2, 0.1)
    reverse_keypoints_1 = [_reverserotate(m[1], pi / 4, (256, 256)) + CartesianIndex(10, 20) for m in matches]
    @test all(isapprox(rk[1], m[2][1], atol = 4) && isapprox(rk[2], m[2][2], atol = 4) for (rk, m) in zip(reverse_keypoints_1, matches))
end
