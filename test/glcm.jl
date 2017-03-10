using FactCheck, Base.Test, Images, ImageFeatures

facts("Gray Level Co Occurence Matrix") do 

    context("GLCM") do
        img = [ 0 0 1 1
                0 0 1 1
                0 2 2 2
                2 2 3 3 ]
        img_gray = convert(Array{Gray}, img / 3)

        glcm_mat = glcm(img, 1, 0, 4)
        expected_1 = [ 2 2 1 0
                    0 2 0 0
                    0 0 3 1
                    0 0 0 1 ]
        @fact all(expected_1 .== glcm_mat) --> true
        glcm_mat = glcm(img_gray, 1, 0, 4)
        @fact all(expected_1 .== glcm_mat) --> true
        glcm_mat = glcm_norm(img, 1, 0, 4)
        @fact all(expected_1 / sum(expected_1) .== glcm_mat) --> true
        glcm_mat = glcm_symmetric(img, 1, 0, 4)
        @fact all(expected_1 + expected_1' .== glcm_mat) --> true

        glcm_mat = glcm(img, 1, pi/2, 4)
        expected_2 = [ 3 0 2 0
                        0 2 2 0
                        0 0 1 2
                        0 0 0 0 ]
        @fact all(expected_2 .== glcm_mat) --> true

        glcm_mats = glcm(img, [1, 1], [0, pi/2], 4)     
        @fact all(glcm_mats[1, 1] .== expected_1) --> true
        @fact all(glcm_mats[1, 2] .== expected_2) --> true 
        @fact all(glcm_mats[2, 1] .== expected_1) --> true
        @fact all(glcm_mats[2, 2] .== expected_2) --> true

        glcm_mats = glcm(img_gray, [1, 1], [0, pi/2], 4)     
        @fact all(glcm_mats[1, 1] .== expected_1) --> true
        @fact all(glcm_mats[1, 2] .== expected_2) --> true 
        @fact all(glcm_mats[2, 1] .== expected_1) --> true
        @fact all(glcm_mats[2, 2] .== expected_2) --> true

        glcm_mats = glcm_symmetric(img, [1, 1], [0, pi/2], 4)     
        @fact all(glcm_mats[1, 1] .== expected_1 + expected_1') --> true
        @fact all(glcm_mats[1, 2] .== expected_2 + expected_2') --> true 
        @fact all(glcm_mats[2, 1] .== expected_1 + expected_1') --> true
        @fact all(glcm_mats[2, 2] .== expected_2 + expected_2') --> true

        glcm_mats = glcm_norm(img, [1, 1], [0, pi/2], 4)     
        @fact all(glcm_mats[1, 1] .== expected_1 / sum(expected_1)) --> true
        @fact all(glcm_mats[1, 2] .== expected_2 / sum(expected_2)) --> true 
        @fact all(glcm_mats[2, 1] .== expected_1 / sum(expected_1)) --> true
        @fact all(glcm_mats[2, 2] .== expected_2 / sum(expected_2)) --> true

        glcm_mat = glcm(img, 2, 0, 4)
        expected_3 = [ 0 4 1 0
                        0 0 0 0
                        0 0 1 2
                        0 0 0 0 ]
        @fact all(expected_3 .== glcm_mat) --> true

        glcm_mat = glcm(img, 1, 0, 2)
        expected_4 = [ 6 1
                        0 5 ]
        @fact all(expected_4 .== glcm_mat) --> true

        expected_5 = [ 1 0 3 0
                        0 0 2 2
                        0 0 0 0
                        0 0 0 0 ]
        glcm_mats = glcm(img, 2, [0, pi/2], 4)     
        @fact all(glcm_mats[1] .== expected_3) --> true
        @fact all(glcm_mats[2] .== expected_5) --> true 

        glcm_mats = glcm_symmetric(img, 2, [0, pi/2], 4)     
        @fact all(glcm_mats[1] .== expected_3 + expected_3') --> true
        @fact all(glcm_mats[2] .== expected_5 + expected_5') --> true

        glcm_mats = glcm_norm(img, 2, [0, pi/2], 4)     
        @fact all(glcm_mats[1] .== expected_3 / sum(expected_3)) --> true
        @fact all(glcm_mats[2] .== expected_5 / sum(expected_5)) --> true

        glcm_mats = glcm(img, [1, 2], 0, 4)     
        @fact all(glcm_mats[1] .== expected_1) --> true
        @fact all(glcm_mats[2] .== expected_3) --> true

        glcm_mats = glcm_symmetric(img, [1, 2], 0, 4)     
        @fact all(glcm_mats[1] .== expected_1 + expected_1') --> true
        @fact all(glcm_mats[2] .== expected_3 + expected_3') --> true 

        glcm_mats = glcm_norm(img, [1, 2], 0, 4)     
        @fact all(glcm_mats[1] .== expected_1 / sum(expected_1)) --> true
        @fact all(glcm_mats[2] .== expected_3 / sum(expected_3)) --> true 
    end
    
    context("Properties") do

        img = convert(Array{Int}, reshape(1:1:30, 5, 6))
        @fact glcm_prop(img, max_prob) --> maxfinite(img)
        @fact glcm_prop(img, contrast) --> 2780
        @fact glcm_prop(img, dissimilarity) --> 930
        @fact glcm_prop(img, ASM) --> 9455
        @fact isapprox(glcm_prop(img, energy), 97.2368, rtol = 0.001) --> true
        @fact isapprox(glcm_prop(img, glcm_entropy), -1357.0889, rtol = 0.001) --> true
        @fact glcm_prop(img, glcm_mean_ref) --> 1455
        @fact isapprox(glcm_prop(img, glcm_var_ref), 31307.95505, rtol = 0.001) --> true
        @fact glcm_prop(img, glcm_mean_neighbour) --> 2065
        @fact isapprox(glcm_prop(img, glcm_var_neighbour), 44433.61666, rtol = 0.001) --> true
        @fact isapprox(glcm_prop(img, correlation), 0.99999, rtol = 0.001) --> true
        @fact isapprox(glcm_prop(img, IDM), 165.5176, rtol = 0.001) --> true

        glcm_props = glcm_prop(img, 3, max_prob)
        expected = [  7.0  12.0  17.0  22.0  27.0  27.0
                      8.0  13.0  18.0  23.0  28.0  28.0
                      9.0  14.0  19.0  24.0  29.0  29.0
                     10.0  15.0  20.0  25.0  30.0  30.0
                     10.0  15.0  20.0  25.0  30.0  30.0 ]
        @fact all(glcm_props .== expected) --> true
        glcm_props = glcm_prop(img, 4, 3, max_prob)
        expected = [  8.0  13.0  18.0  23.0  28.0  28.0
                      9.0  14.0  19.0  24.0  29.0  29.0
                     10.0  15.0  20.0  25.0  30.0  30.0
                     10.0  15.0  20.0  25.0  30.0  30.0
                     10.0  15.0  20.0  25.0  30.0  30.0 ]
        @fact all(glcm_props .== expected) --> true

        # Test Correlation when Variance is Zero

        glcm_mat = [ 1 0 0 0
                     0 0 0 0
                     0 0 0 0
                     0 0 0 0 ]
        @fact glcm_prop(glcm_mat, correlation) --> 1

    end

end