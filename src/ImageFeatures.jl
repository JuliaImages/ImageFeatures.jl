module ImageFeatures

# package code goes here

using Images, ColorTypes, FixedPointNumbers

include("glcm.jl")

import ColorTypes: U8, U16, Gray

export 
	glcm

end # module
