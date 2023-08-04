module ImageFeatures

# package code goes here
using Images, Distributions
using SparseArrays
import Random.seed!
using Images.ImageTransformations.Interpolations

include("core.jl")
include("const.jl")
include("corner.jl")
include("lbp.jl")
include("glcm.jl")
include("brief.jl")
include("orb.jl")
include("freak.jl")
include("brisk.jl")
include("houghtransform.jl")
include("hog.jl")

export Keypoint, Keypoints, Feature, Features, Params, BRIEF, ORB, FREAK, BRISK, HOG

export
    #Core
    create_descriptor,
    hamming_distance,
    match_keypoints,
    grade_matches,

    #Local Binary Patterns
    lbp,
    modified_lbp,
    direction_coded_lbp,
    lbp_original,
    lbp_uniform,
    lbp_rotation_invariant,
    multi_block_lbp,

    #Gray Level Co-Occurrence Matrix
    glcm,
    glcm_symmetric,
    glcm_norm,
    glcm_prop,
    max_prob,
    contrast,
    ASM,
    IDM,
    glcm_entropy,
    energy,
    dissimilarity,
    correlation,
    glcm_mean_ref,
    glcm_mean_neighbour,
    glcm_var_ref,
    glcm_var_neighbour,

    #Corners
    corner_orientations,

    #BRIEF
    random_uniform,
    random_coarse,
    gaussian,
    gaussian_local,
    center_sample,

    #Lines
    hough_transform_standard,

    #Circles
    hough_circle_gradient

_oneunit(i::CartesianIndex) = VERSION >= v"1.1" ? oneunit(i) : one(i)

"""
    desc, keypoints = create_descriptor(img, keypoints, params)
    desc, keypoints = create_descriptor(img, params)

Create a descriptor for each entry in `keypoints` from the image `img`. `params` specifies the parameters for any of several descriptors:
 - [`BRIEF`](@ref)
 - [`ORB`](@ref)
 - [`BRISK`](@ref)
 - [`FREAK`](@ref)
 - [`HOG`](@ref)

Some descriptors support discovery of the `keypoints` from [`fastcorners`](@ref).
"""
create_descriptor

end
