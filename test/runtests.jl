module ImageFeatureTests

using FactCheck, ImageFeatures, Base.Test, TestImages, Distributions, ColorTypes, Images

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
    res = shareproperties(img, res)
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
    res = shareproperties(img, res)
	res
end	

include("core.jl")
include("brief.jl")
include("glcm.jl")
include("lbp.jl")
include("corner.jl")
include("orb.jl")

isinteractive() || FactCheck.exitstatus()

end
