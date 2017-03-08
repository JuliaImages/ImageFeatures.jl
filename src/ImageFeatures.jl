module ImageFeatures

# package code goes here
using Images, ColorTypes, FixedPointNumbers, Distributions

include("core.jl")
include("const.jl")
include("corner.jl")
include("lbp.jl")
include("glcm.jl")
include("brief.jl")
include("orb.jl")
include("freak.jl")
include("brisk.jl")

export Keypoint, Keypoints, Feature, Features, Params, BRIEF, ORB, FREAK, BRISK

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

    #Gray Level Co Occurence Matrix
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
	centre_sample
end
