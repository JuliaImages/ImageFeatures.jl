abstract Detector

typealias Keypoint CartesianIndex{2}

function createDetector(method::Type = CENSURE; args...)
	method(; args...)
end

function detect{T}(img::AbstractArray{T, 2}, method::Function, params::Detector)
	img_gray = convert(Image{Images.Gray{U8}}, img)
	method(img_gray, params)
end

function getDescriptor()
end