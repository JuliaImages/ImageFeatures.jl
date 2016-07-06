module ImageFeatures

# package code goes here

using Images, ColorTypes, FixedPointNumbers

include("glcm.jl")

import ColorTypes: U8, U16, Gray

export 
	glcm,
	glcm_symmetric,
	glcm_norm,
	glcm_prop,
	max_prob,
	contrast,
	ASM,
	IDM,
	entropy,
	energy,
	contrast,
	dissimilarity,
	correlation,
	glcm_mean_ref,
	glcm_mean_neighbour,
	glcm_var_ref,
	glcm_var_neighbour

end # module
