"""
```
orb_params = ORB([num_keypoints = 500], [n_fast = 12], [threshold = 0.25], [harris_factor = 0.04], [downsample = 1.3], [levels = 8], [sigma = 1.2])
```

| Argument | Type | Description |
|----------|------|-------------|
| **num_keypoints** | Int | Number of keypoints to extract and size of the descriptor calculated |
| **n_fast** | Int | Number of consecutive pixels used for finding corners with FAST. See [`fastcorners`] |
| **threshold** | Float64 | Threshold used to find corners in FAST. See [`fastcorners`] |
| **harris_factor** | Float64 | Harris factor `k` used to rank keypoints by harris responses and extract the best ones |
| **downsample** | Float64 | Downsampling parameter used while building the gaussian pyramid. See [`gaussian_pyramid`] in Images.jl |
| **levels** | Int | Number of levels in the gaussian pyramid.  See [`gaussian_pyramid`] in Images.jl |
| **sigma** | Float64 | Used for gaussian smoothing in each level of the gaussian pyramid.  See [`gaussian_pyramid`] in Images.jl |
"""
mutable struct ORB <: Params
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

function create_descriptor(img::AbstractArray{T, 2}, params::ORB) where T<:Gray
    pyramid = gaussian_pyramid(img, params.levels, params.downsample, params.sigma)
    keypoints_stack = map(image -> Keypoints(fastcorners(image, params.n_fast, params.threshold)), pyramid)
    patch = ones(31, 31)
    orientations_stack = map((image, keypoints) -> corner_orientations(image, keypoints, patch), pyramid, keypoints_stack)
    harris_response_stack = map(image -> harris(image, k = params.harris_factor), pyramid)
    descriptors = BitVector[]
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
        first_n_indices = partialsortperm(harris_responses, 1:params.num_keypoints, rev = true)
        return descriptors[first_n_indices], ret_keypoints[first_n_indices], scales[first_n_indices]
    end

    descriptors, ret_keypoints, scales
end

function create_descriptor(img::AbstractArray{T, 2}, keypoints::Keypoints, orientations::Array{Float64}, params::ORB) where T<:Gray
    descriptors = BitVector[]
    ret_keypoints = Keypoint[]
    for (i, k) in enumerate(keypoints)
        orientation = orientations[i]
        sin_angle = sin(orientation)
        cos_angle = cos(orientation)
        descriptor = BitVector([])
        for (y0, x0, y1, x1) in orb_sampling_pattern
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
