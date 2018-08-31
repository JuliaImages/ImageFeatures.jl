using Test, ImageFeatures, Images, ColorTypes

@testset "Orientations" begin
    img = zeros(20, 20)
    img[6:14, 6:14] .= 1
    orientations = corner_orientations(img)
    orientations_deg = map(rad2deg, orientations)
    expected = [45.0, -45.0, 135.0, -135.0]
    @test all(isapprox(orientations_deg[i], e, atol = 0.0001) for (i, e) in enumerate(expected))
    orientations = corner_orientations(img, Keypoints(imcorner(img)))
    orientations_deg = map(rad2deg, orientations)
    @test all(isapprox(orientations_deg[i], e, atol = 0.0001) for (i, e) in enumerate(expected))
    kernel = ones(5, 5)
    orientations = corner_orientations(img, kernel)
    orientations_deg = map(rad2deg, orientations)
    @test all(isapprox(orientations_deg[i], e, atol = 0.0001) for (i, e) in enumerate(expected))
    orientations = corner_orientations(img, Keypoints(imcorner(img)), kernel)
    orientations_deg = map(rad2deg, orientations)
    @test all(isapprox(orientations_deg[i], e, atol = 0.0001) for (i, e) in enumerate(expected))
    img = zeros(RGB{Float64}, 20, 20)
    img[6:14, 6:14] .= RGB{Float64}(1.0, 1.0, 1.0)
    orientations = corner_orientations(img, Keypoints(imcorner(img)), kernel)
    orientations_deg = map(rad2deg, orientations)
    @test all(isapprox(orientations_deg[i], e) for (i, e) in enumerate(expected))

    img = zeros(20, 20)
    diamond = [ 0.0  0.0  0.0  1.0  0.0  0.0  0.0
                0.0  0.0  1.0  1.0  1.0  0.0  0.0
                0.0  1.0  1.0  1.0  1.0  1.0  0.0
                1.0  1.0  1.0  1.0  1.0  1.0  1.0
                0.0  1.0  1.0  1.0  1.0  1.0  0.0
                0.0  0.0  1.0  1.0  1.0  0.0  0.0
                0.0  0.0  0.0  1.0  0.0  0.0  0.0 ]
    img[8:14, 8:14] = diamond
    orientations = corner_orientations(img)
    orientations_deg = map(rad2deg, orientations)
    expected = [0.0, 90.0, -90.0, -180.0]
    @test all(isapprox(orientations_deg[i], e, atol = 0.0001) for (i, e) in enumerate(expected))
end
