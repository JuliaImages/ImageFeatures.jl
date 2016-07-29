module ImageFeatureTests

using FactCheck, ImageFeatures, Base.Test

include("glcm.jl")
include("lbp.jl")

isinteractive() || FactCheck.exitstatus()

end
