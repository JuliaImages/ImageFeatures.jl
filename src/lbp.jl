function lbp{T<:Gray}(img::AbstractArray{T, 2})
	
	lbp_image = zeros(UInt8, size(img)[1] - 1, size(img)[2] - 1)
	R = CartesianRange(CartesianIndex(2, 2), CartesianIndex(size(img)[1] - 1, size(img)[2] - 1))
	Istart, Iend = first(R), last(R)
	bit_pattern = zeros(UInt8, 8)
	for I in R
		bit_pattern[1] = img[I] < img[I + CartesianIndex(- 1, - 1)] ? 0 : 1
		bit_pattern[2] = img[I] < img[I + CartesianIndex(- 1, 0)] ? 0 : 1
		bit_pattern[3] = img[I] < img[I + CartesianIndex(- 1, 1)] ? 0 : 1
		bit_pattern[4] = img[I] < img[I + CartesianIndex(0, 1)] ? 0 : 1
		bit_pattern[5] = img[I] < img[I + CartesianIndex(1, 1)] ? 0 : 1
		bit_pattern[6] = img[I] < img[I + CartesianIndex(1, 0)] ? 0 : 1
		bit_pattern[7] = img[I] < img[I + CartesianIndex(1, - 1)] ? 0 : 1
		bit_pattern[8] = img[I] < img[I + CartesianIndex(0, - 1)] ? 0 : 1

		lbp_image[I] = sum([b * 2 ^ (i - 1) for (i, b) in enumerate(bit_pattern)])
	end
	lbp_image
end

function lbp{T<:Gray}(img::AbstractArray{T, 2}, points::Integer, radius::Number)
	
	lbp_image = zeros(UInt, size(img))
	offset = [(round(- radius * sin(2 * pi * i / points), 5), round(radius * cos(2 * pi * i / points), 5)) for i = 0:points - 1]
	R = CartesianRange(size(img))

	for I in R
		bit_pattern = [img[I] < bilinear_interpolation(img, I[1] + o[1], I[2] + o[2]) ? 0 : 1 for o in offset]
		lbp_image[I] = sum([b * 2 ^ (i - 1) for (i, b) in enumerate(bit_pattern)])
	end
	lbp_image
end



