module ImageFeatureTests

using ImageFeatures, Images, TestImages, Distributions, ColorTypes
using Test
using LinearAlgebra
import Random.seed!

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

function _warp(img, transx, transy)
    res = zeros(eltype(img), size(img))
    for i in 1:size(img, 1) - transx
        for j in 1:size(img, 2) - transy
            res[i + transx, j + transy] = img[i, j]
        end
    end
    res
end

function _warp(img, angle)
    cos_angle = cos(angle)
    sin_angle = sin(angle)
    res = zeros(eltype(img), size(img))
    cx = size(img, 1) / 2
    cy = size(img, 2) / 2
    for i in 1:size(res, 1)
        for j in 1:size(res, 2)
            i_rot = ceil(Int, cos_angle * (i - cx) - sin_angle * (j - cy) + cx)
            j_rot = ceil(Int, sin_angle * (i - cx) + cos_angle * (j - cy) + cy)
            if checkbounds(Bool, img, i_rot, j_rot) res[i, j] = bilinear_interpolation(img, i_rot, j_rot) end
        end
    end
    res
end

function _reverserotate(p, angle, center)
    cos_angle = cos(angle)
    sin_angle = sin(angle)
    return CartesianIndex(floor(Int, sin_angle * (p[2] - center[2]) + cos_angle * (p[1] - center[1]) + center[1]), floor(Int, cos_angle * (p[2] - center[2]) - sin_angle * (p[1] - center[1]) + center[2]))
end

tests = [
    "core.jl",
    "brief.jl",
    "glcm.jl",
    "lbp.jl",
    "corner.jl",
    "orb.jl",
    "freak.jl",
    "brisk.jl",
    "houghtransform.jl",
    "hog.jl"
]

for t in tests
    @testset "$t" begin
        include(t)
    end
end

end
