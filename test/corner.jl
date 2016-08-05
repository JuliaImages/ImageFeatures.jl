using FactCheck, Base.Test, Images, ImageFeatures, ColorTypes

facts("Corners") do 

    context("Orientations") do
        img = zeros(20, 20)
        img[6:14, 6:14] = 1
        orientations = corner_orientations(img)
        orientations_deg = map(rad2deg, orientations)
        expected = [45.0, -45.0, 135.0, -135.0]
        @fact all(isapprox(orientations_deg[i], e, atol = 0.0001) for (i, e) in enumerate(expected)) --> true
        orientations = corner_orientations(img, Keypoints(imcorner(img)))
        orientations_deg = map(rad2deg, orientations)
        @fact all(isapprox(orientations_deg[i], e, atol = 0.0001) for (i, e) in enumerate(expected)) --> true
        kernel = ones(5, 5)
        orientations = corner_orientations(img, kernel)
        orientations_deg = map(rad2deg, orientations)
        @fact all(isapprox(orientations_deg[i], e, atol = 0.0001) for (i, e) in enumerate(expected)) --> true
        orientations = corner_orientations(img, Keypoints(imcorner(img)), kernel)
        orientations_deg = map(rad2deg, orientations)
        @fact all(isapprox(orientations_deg[i], e, atol = 0.0001) for (i, e) in enumerate(expected)) --> true
        img = zeros(RGB{Float64}, 20, 20)
        img[6:14, 6:14] = one(RGB{Float64})
        orientations = corner_orientations(img, Keypoints(imcorner(img)), kernel)
        orientations_deg = map(rad2deg, orientations)
        @fact all(isapprox(orientations_deg[i], e) for (i, e) in enumerate(expected)) --> true

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
        @fact all(isapprox(orientations_deg[i], e, atol = 0.0001) for (i, e) in enumerate(expected)) --> true
    end

end