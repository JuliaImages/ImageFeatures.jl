type ORB <: DescriptorParams
    num_keypoints::Int
    n_fast::Int
    threshold::Float64
    harris_factor::Float64
    downsample::Float64
    levels::Int
    sigma::Float64
end

function ORB(; num_keypoints::Int = 500, n_fast::Int = 12, threshold::Float64 = 0.25, harris_factor::Float64 = 0.04, downsample::Real = 1.3, levels::Int = 8, sigma::Float64 = 1.2)
    ORB(num_keypoints, n_fast, threshold, harris_factor, downsample, levels, sigma)
end

function create_descriptor{T<:Gray}(img::AbstractArray{T, 2}, params::ORB)
    pyramid = gaussian_pyramid(img, params.levels, params.downsample, params.sigma)
    keypoints_stack = map(image -> Keypoints(fastcorners(image, params.n_fast, params.threshold)), pyramid)
    patch = ones(31, 31)
    orientations_stack = map((image, keypoints) -> corner_orientations(image, keypoints, patch), pyramid, keypoints_stack)
    harris_response_stack = map(image -> harris(image, k = params.harris_factor), pyramid)
    descriptors = BitArray[]
    ret_keypoints = Keypoint[]
    harris_responses = Float64[]
    scales = Float64[]

    for i in 1:params.levels + 1
        desc, ret_key = create_descriptor(pyramid[i], keypoints_stack[i], orientations_stack[i], params)
        ret_key_scaled = [Keypoint(floor(Int, rk[1] * (params.downsample ^ (i - 1))), floor(Int, rk[2] * (params.downsample ^ (i - 1)))) for rk in ret_key]
        append!(descriptors, desc)
        append!(ret_keypoints, ret_key_scaled)
        append!(harris_responses, harris_response_stack[i][ret_key])
        append!(scales, ones(length(ret_key)) * floor(Int, (params.downsample ^ (i - 1))))
    end
    
    if params.num_keypoints < length(descriptors)
        first_n_indices = selectperm(harris_responses, 1:params.num_keypoints, rev = true)
        return descriptors[first_n_indices], ret_keypoints[first_n_indices], scales[first_n_indices]
    end

    descriptors, ret_keypoints, scales
end

function create_descriptor{T<:Gray}(img::AbstractArray{T, 2}, keypoints::Keypoints, orientations::Array{Float64}, params::ORB)
    descriptors = BitArray[]
    ret_keypoints = Keypoint[]
    for (i, k) in enumerate(keypoints)
        orientation = orientations[i]
        sin_angle = sin(orientation)
        cos_angle = cos(orientation)
        descriptor = BitArray([])
        for (y0, x0, y1, x1) in sampling_pattern
            pixel0 = CartesianIndex(floor(Int, sin_angle * y0 + cos_angle * x0), floor(Int, cos_angle * y0 - sin_angle * x0))
            pixel1 = CartesianIndex(floor(Int, sin_angle * y1 + cos_angle * x1), floor(Int, cos_angle * y1 - sin_angle * x1))
            checkbounds(Bool, img, k + pixel0) && checkbounds(Bool, img, k + pixel1) || @goto endofloop
            push!(descriptor, img[k + pixel0] < img[k + pixel1])
        end
        push!(ret_keypoints, k)
        push!(descriptors, descriptor)
        @label endofloop
    end
    descriptors, ret_keypoints
end

const sampling_pattern = [[8, -3, 9, 5], [4, 2, 7, -12], [-11, 9, -8, 2], [7, -12, 12, -13], [2, -13, 2, 12], [1, -7, 1, 6], 
                        [-2, -10, -2, -4], [-13, -13, -11, -8], [-13, -3, -12, -9], [10, 4, 11, 9], [-13, -8, -8, -9], [-11, 7, -9, 12], 
                        [7, 7, 12, 6], [-4, -5, -3, 0], [-13, 2, -12, -3], [-9, 0, -7, 5], [12, -6, 12, -1], [-3, 6, -2, 12], [-6, -13, -4, -8], 
                        [11, -13, 12, -8], [4, 7, 5, 1], [5, -3, 10, -3], [3, -7, 6, 12], [-8, -7, -6, -2], [-2, 11, -1, -10], [-13, 12, -8, 10], 
                        [-7, 3, -5, -3], [-4, 2, -3, 7], [-10, -12, -6, 11], [5, -12, 6, -7], [5, -6, 7, -1], [1, 0, 4, -5], [9, 11, 11, -13], 
                        [4, 7, 4, 12], [2, -1, 4, 4], [-4, -12, -2, 7], [-8, -5, -7, -10], [4, 11, 9, 12], [0, -8, 1, -13], [-13, -2, -8, 2], 
                        [-3, -2, -2, 3], [-6, 9, -4, -9], [8, 12, 10, 7], [0, 9, 1, 3], [7, -5, 11, -10], [-13, -6, -11, 0], [10, 7, 12, 1], 
                        [-6, -3, -6, 12], [10, -9, 12, -4], [-13, 8, -8, -12], [-13, 0, -8, -4], [3, 3, 7, 8], [5, 7, 10, -7], [-1, 7, 1, -12], 
                        [3, -10, 5, 6], [2, -4, 3, -10], [-13, 0, -13, 5], [-13, -7, -12, 12], [-13, 3, -11, 8], [-7, 12, -4, 7], [6, -10, 12, 8], 
                        [-9, -1, -7, -6], [-2, -5, 0, 12], [-12, 5, -7, 5], [3, -10, 8, -13], [-7, -7, -4, 5], [-3, -2, -1, -7], [2, 9, 5, -11], 
                        [-11, -13, -5, -13], [-1, 6, 0, -1], [5, -3, 5, 2], [-4, -13, -4, 12], [-9, -6, -9, 6], [-12, -10, -8, -4], [10, 2, 12, -3], 
                        [7, 12, 12, 12], [-7, -13, -6, 5], [-4, 9, -3, 4], [7, -1, 12, 2], [-7, 6, -5, 1], [-13, 11, -12, 5], [-3, 7, -2, -6], 
                        [7, -8, 12, -7], [-13, -7, -11, -12], [1, -3, 12, 12], [2, -6, 3, 0], [-4, 3, -2, -13], [-1, -13, 1, 9], [7, 1, 8, -6], 
                        [1, -1, 3, 12], [9, 1, 12, 6], [-1, -9, -1, 3], [-13, -13, -10, 5], [7, 7, 10, 12], [12, -5, 12, 9], [6, 3, 7, 11], 
                        [5, -13, 6, 10], [2, -12, 2, 3], [3, 8, 4, -6], [2, 6, 12, -13], [9, -12, 10, 3], [-8, 4, -7, 9], [-11, 12, -4, -6], 
                        [1, 12, 2, -8], [6, -9, 7, -4], [2, 3, 3, -2], [6, 3, 11, 0], [3, -3, 8, -8], [7, 8, 9, 3], [-11, -5, -6, -4], 
                        [-10, 11, -5, 10], [-5, -8, -3, 12], [-10, 5, -9, 0], [8, -1, 12, -6], [4, -6, 6, -11], [-10, 12, -8, 7], [4, -2, 6, 7], 
                        [-2, 0, -2, 12], [-5, -8, -5, 2], [7, -6, 10, 12], [-9, -13, -8, -8], [-5, -13, -5, -2], [8, -8, 9, -13], [-9, -11, -9, 0], 
                        [1, -8, 1, -2], [7, -4, 9, 1], [-2, 1, -1, -4], [11, -6, 12, -11], [-12, -9, -6, 4], [3, 7, 7, 12], [5, 5, 10, 8], 
                        [0, -4, 2, 8], [-9, 12, -5, -13], [0, 7, 2, 12], [-1, 2, 1, 7], [5, 11, 7, -9], [3, 5, 6, -8], [-13, -4, -8, 9], 
                        [-5, 9, -3, -3], [-4, -7, -3, -12], [6, 5, 8, 0], [-7, 6, -6, 12], [-13, 6, -5, -2], [1, -10, 3, 10], [4, 1, 8, -4], 
                        [-2, -2, 2, -13], [2, -12, 12, 12], [-2, -13, 0, -6], [4, 1, 9, 3], [-6, -10, -3, -5], [-3, -13, -1, 1], [7, 5, 12, -11], 
                        [4, -2, 5, -7], [-13, 9, -9, -5], [7, 1, 8, 6], [7, -8, 7, 6], [-7, -4, -7, 1], [-8, 11, -7, -8], [-13, 6, -12, -8], 
                        [2, 4, 3, 9], [10, -5, 12, 3], [-6, -5, -6, 7], [8, -3, 9, -8], [2, -12, 2, 8], [-11, -2, -10, 3], [-12, -13, -7, -9], 
                        [-11, 0, -10, -5], [5, -3, 11, 8], [-2, -13, -1, 12], [-1, -8, 0, 9], [-13, -11, -12, -5], [-10, -2, -10, 11], [-3, 9, -2, -13], 
                        [2, -3, 3, 2], [-9, -13, -4, 0], [-4, 6, -3, -10], [-4, 12, -2, -7], [-6, -11, -4, 9], [6, -3, 6, 11], [-13, 11, -5, 5], 
                        [11, 11, 12, 6], [7, -5, 12, -2], [-1, 12, 0, 7], [-4, -8, -3, -2], [-7, 1, -6, 7], [-13, -12, -8, -13], [-7, -2, -6, -8], 
                        [-8, 5, -6, -9], [-5, -1, -4, 5], [-13, 7, -8, 10], [1, 5, 5, -13], [1, 0, 10, -13], [9, 12, 10, -1], [5, -8, 10, -9], 
                        [-1, 11, 1, -13], [-9, -3, -6, 2], [-1, -10, 1, 12], [-13, 1, -8, -10], [8, -11, 10, -6], [2, -13, 3, -6], [7, -13, 12, -9], 
                        [-10, -10, -5, -7], [-10, -8, -8, -13], [4, -6, 8, 5], [3, 12, 8, -13], [-4, 2, -3, -3], [5, -13, 10, -12], [4, -13, 5, -1],  
                        [-9, 9, -4, 3], [0, 3, 3, -9], [-12, 1, -6, 1], [3, 2, 4, -8], [-10, -10, -10, 9], [8, -13, 12, 12], [-8, -12, -6, -5],  
                        [2, 2, 3, 7], [10, 6, 11, -8], [6, 8, 8, -12], [-7, 10, -6, 5], [-3, -9, -3, 9], [-1, -13, -1, 5], [-3, -7, -3, 4],  
                        [-8, -2, -8, 3], [4, 2, 12, 12], [2, -5, 3, 11], [6, -9, 11, -13], [3, -1, 7, 12], [11, -1, 12, 4], [-3, 0, -3, 6],  
                        [4, -11, 4, 12], [2, -4, 2, 1], [-10, -6, -8, 1], [-13, 7, -11, 1], [-13, 12, -11, -13], [6, 0, 11, -13], [0, -1, 1, 4],  
                        [-13, 3, -9, -2], [-9, 8, -6, -3], [-13, -6, -8, -2], [5, -9, 8, 10], [2, 7, 3, -9], [-1, -6, -1, -1], [9, 5, 11, -2],  
                        [11, -3, 12, -8], [3, 0, 3, 5], [-1, 4, 0, 10], [3, -6, 4, 5], [-13, 0, -10, 5], [5, 8, 12, 11], [8, 9, 9, -6], [7, -4, 8, -12],  
                        [-10, 4, -10, 9], [7, 3, 12, 4], [9, -7, 10, -2], [7, 0, 12, -2], [-1, -6, 0, -11]]
