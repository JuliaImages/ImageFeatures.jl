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

function integral_window_sum{T}(int_img::AbstractArray{T}, tl_y::Integer, tl_x::Integer, br_y::Integer, br_x::Integer)
    sum = int_img[br_y, br_x]
    sum -= tl_x > 1 ? int_img[br_y, tl_x - 1] : zero(T)
    sum -= tl_y > 1 ? int_img[tl_y - 1, br_x] : zero(T)
    sum += tl_y > 1 && tl_x > 1 ? int_img[tl_y - 1, tl_x - 1] : zero(T)
    sum
end