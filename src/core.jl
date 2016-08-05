abstract Detector
  
typealias Keypoint CartesianIndex{2}
typealias Keypoints Array{CartesianIndex{2}}
  
function Keypoints(img::AbstractArray)
    r, c, _ = findnz(img)
    map((ri, ci) -> Keypoint(ri, ci), r, c)
end