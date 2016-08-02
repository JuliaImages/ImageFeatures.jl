module ImageFeatureTests

using FactCheck, ImageFeatures, Base.Test, TestImages, Distributions, ColorTypes, Images

include("core.jl")
include("brief.jl")
include("glcm.jl")
include("lbp.jl")
include("corner.jl")

isinteractive() || FactCheck.exitstatus()

end
