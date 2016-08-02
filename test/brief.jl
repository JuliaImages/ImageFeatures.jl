using FactCheck, Images, ImageFeatures, TestImages, Distributions, ColorTypes

facts("BRIEF") do 

    function check_samples(sample_one, sample_two, size::Int, window::Int)
        check_bool = true
        check_bool = check_bool && length(sample_one) == size
        check_bool = check_bool && length(sample_two) == size
        for s1 in sample_one, s2 in sample_two
            check_bool = check_bool && (s1[1] >= ceil(-window / 2) && s1[1] <= floor((window - 1) / 2)) && (s1[2] >= ceil(-window / 2) && s1[2] <= floor((window - 1) / 2))
            check_bool = check_bool && (s2[1] >= ceil(-window / 2) && s2[1] <= floor((window - 1) / 2)) && (s2[2] >= ceil(-window / 2) && s2[2] <= floor((window - 1) / 2))
        end
        return check_bool 
    end
    
    brief_params = BRIEF(size = 8, window = 3, seed = 123)
    @fact brief_params.size --> 8
    @fact brief_params.window --> 3
    @fact brief_params.seed --> 123
    @fact brief_params.sampling_type == gaussian --> true
    @fact brief_params.sigma --> 2 ^ 0.5

    context("Sampling Patterns") do
        # Check Bounds
        for si in [32, 128, 256], wi in [5, 15, 25, 49], se in [123, 546, 178]
            s1, s2 = centered(si, wi, se)
            @fact check_samples(s1, s2, si, wi) --> true
            @fact s1 == zeros(CartesianIndex{2}, si) --> true
            s1, s2 = random_coarse(si, wi, se)
            @fact check_samples(s1, s2, si, wi) --> true
            s1, s2 = random_uniform(si, wi, se)
            @fact check_samples(s1, s2, si, wi) --> true
            s1, s2 = gaussian(si, wi, se)
            @fact check_samples(s1, s2, si, wi) --> true
            s1, s2 = gaussian_local(si, wi, se)
            @fact check_samples(s1, s2, si, wi) --> true
        end
    end

    context("Descriptor Calculation") do
        img_1 = Gray{Float64}[ 0 0 0 0 0 0 
                  0 0 1 1 0 0 
                  0 0 1 1 0 0 
                  0 0 1 1 0 0 
                  0 0 1 1 0 0 
                  0 0 0 0 0 0 ]
        keypoints_1 = Keypoints(imcorner(img_1))

        img_2 = Gray{Float64}[ 0 0 0 0 0 0  
                  0 0 1 1 0 0  
                  0 0 1 1 0 0  
                  0 0 1 1 0 0  
                  0 0 1 1 0 0  
                  0 0 1 1 0 0  
                  0 0 1 1 0 0  
                  0 0 0 0 0 0  ]
        keypoints_2 = Keypoints(imcorner(img_2))

        brief_params = BRIEF(size = 8, window = 3, seed = 123)

        desc_1 = create_descriptor(img_1, keypoints_1, brief_params)
        desc_2 = create_descriptor(img_2, keypoints_2, brief_params)
        matches = match_keypoints(keypoints_1, keypoints_2, desc_1, desc_2)
        expected_matches = [[CartesianIndex((2,3)),CartesianIndex((2,3))],
                            [CartesianIndex((5,3)),CartesianIndex((7,3))]]
        @fact all(matches .== expected_matches) --> true

        img_1 = Gray{Float64}[ 0 0 0 0 0 0 0 0 0 
                  0 0 1 1 1 1 0 0 0 
                  0 0 1 1 1 1 0 0 0 
                  0 0 1 1 1 1 0 0 0 
                  0 0 1 1 1 1 0 0 0 
                  0 0 0 0 0 0 0 0 0 
                  0 0 0 0 0 0 0 0 0 
                  0 0 0 0 0 0 0 0 0 ]
        keypoints_1 = Keypoints(imcorner(img_1))

        img_2 = Gray{Float64}[ 0 0 0 0 0 0 0 0 0 
                  0 0 1 1 1 1 1 1 0 
                  0 0 1 1 1 1 1 1 0 
                  0 0 1 1 1 1 1 1 0 
                  0 0 1 1 1 1 1 1 0 
                  0 0 1 1 1 1 1 1 0 
                  0 0 1 1 1 1 1 1 0 
                  0 0 0 0 0 0 0 0 0 ]
        keypoints_2 = Keypoints(imcorner(img_2))

        brief_params = BRIEF(size = 8, window = 3, seed = 123)

        desc_1 = create_descriptor(img_1, keypoints_1, brief_params)
        desc_2 = create_descriptor(img_2, keypoints_2, brief_params)
        matches = match_keypoints(keypoints_1, keypoints_2, desc_1, desc_2)
        expected_matches = [[CartesianIndex((2,3)),CartesianIndex((2,3))],
                            [CartesianIndex((5,3)),CartesianIndex((7,3))],
                            [CartesianIndex((2,6)),CartesianIndex((2,8))],
                            [CartesianIndex((5,6)),CartesianIndex((7,8))]]
        @fact all(matches .== expected_matches) --> true

        img_1 = Gray{Float64}[ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                               0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
                               0 0 1 1 1 1 1 0 0 0 0 0 0 0 0 0 
                               0 0 1 1 1 1 1 0 0 0 0 0 0 0 0 0 
                               0 0 1 1 1 1 1 0 0 0 0 0 0 0 0 0 
                               0 0 1 1 1 1 1 0 0 0 0 0 0 0 0 0 
                               0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 
                               0 0 0 0 0 0 0 0 0 0 0 1 1 1 0 0 
                               0 0 0 0 0 0 0 0 0 0 0 1 1 1 0 0 
                               0 0 0 0 0 0 0 0 0 0 0 1 1 1 0 0
                               0 0 0 0 0 0 0 0 0 0 0 1 1 1 0 0
                               0 0 0 0 0 0 0 0 0 0 0 1 1 1 0 0
                               0 0 0 0 0 0 0 0 0 0 0 1 1 1 0 0
                               0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                               0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
        keypoints_1 = Keypoints(imcorner(img_1))

        img_2 = Gray{Float64}[ 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                               0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                               0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 
                               0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 
                               0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 
                               0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 
                               0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 
                               0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0    
                               0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 
                               0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0 
                               0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0
                               0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0
                               0 0 0 0 0 0 0 0 0 1 1 1 1 1 1 0 0
                               0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
                               0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
        keypoints_2 = Keypoints(imcorner(img_2))

        brief_params = BRIEF(size = 128, window = 5, seed = 123)

        desc_1 = create_descriptor(img_1, keypoints_1, brief_params)
        desc_2 = create_descriptor(img_2, keypoints_2, brief_params)
        matches = match_keypoints(keypoints_1, keypoints_2, desc_1, desc_2, 0.2)
        expected_matches = [[CartesianIndex{2}((3,3)),CartesianIndex{2}((9,10))],
                            [CartesianIndex{2}((6,3)),CartesianIndex{2}((13,10))],
                            [CartesianIndex{2}((3,7)),CartesianIndex{2}((9,15))],
                            [CartesianIndex{2}((6,7)),CartesianIndex{2}((13,15))],
                            [CartesianIndex{2}((8,13)),CartesianIndex{2}((3,4))],
                            [CartesianIndex{2}((13,13)),CartesianIndex{2}((7,4))]]
        @fact all(matches .== expected_matches) --> true

    end

end