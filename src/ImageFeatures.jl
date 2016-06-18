module ImageFeatures

# package code goes here
using Images, ColorTypes, FixedPointNumbers

include("core.jl")
include("lbp.jl")
include("glcm.jl")
include("corner.jl")
include("brief.jl")

export Keypoint, Keypoints

export 
	#Local Binary Patterns
	lbp,
	modified_lbp,
	direction_coded_lbp,
	lbp_original,
	lbp_uniform,
	lbp_rotation_invariant,
	multi_block_lbp,

	#GLCM
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
	contrast,
	dissimilarity,
	correlation,
	glcm_mean_ref,
	glcm_mean_neighbour,
	glcm_var_ref,
	glcm_var_neighbour,

	#Corners
	corner_orientations,

	#Core
	create_descriptor

end # module
