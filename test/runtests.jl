module ImageFeatureTests

using ImageFeatures, Images, TestImages, Distributions
using Test
using LinearAlgebra
import Random.seed!
using Images.ImageTransformations: imrotate

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

_warp(img, angle) = imrotate(img, angle, axes(img))

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
