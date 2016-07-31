module ImageFeatureTests

using FactCheck, ImageFeatures, Base.Test, Images

include("corner.jl")
include("glcm.jl")
include("lbp.jl")
include("brief.jl")

isinteractive() || FactCheck.exitstatus()

end
