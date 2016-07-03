abstract BiFilter

type BoxFilter <: BiFilter

	scale :: Integer
	in_length :: Integer
	out_length :: Integer
	in_area :: Float64
	out_area :: Float64
	in_weight :: Float64
	out_weight :: Float64

end

type OctagonFilter <: BiFilter
	
	filter :: Array{Float64, 2}
	m_out :: UInt8
	m_in :: UInt8
	n_out :: UInt8
	n_in :: UInt8

end

type CENSURE <: Detector

	smallest :: Integer
	largest :: Integer
	filter_type :: Type
	filter_stack :: Array
	responseThreshold :: Number
	lineThreshold :: Number

end

function createFilter(OF::OctagonFilter)
	area_out = (OF.m_out + 2 * OF.n_out) ^ 2 - 2 * OF.n_out ^ 2
	area_in = (OF.m_in + 2 * OF.n_in) ^ 2 - 2 * OF.n_in ^ 2
	weight_out = 1.0/(area_out - area_in)
	weight_in = 1.0/area_in
	OF.filter[:, :] = weight_out
	inner_start = Int(0.5 * ((OF.m_out + 2 * OF.n_out) - (OF.m_in + 2 * OF.n_in)))
	OF.filter[inner_start + 1 : end - inner_start, inner_start + 1 : end - inner_start] = weight_in

	for i in 1:OF.n_in
		OF.filter[inner_start + i, inner_start + 1 : inner_start + OF.n_in - i + 1] = weight_out
		OF.filter[inner_start + i, inner_start + OF.n_in + OF.m_in + i : inner_start + OF.m_in + 2 * OF.n_in] = weight_out
		OF.filter[inner_start + OF.m_in + 2 * OF.n_in - i + 1, inner_start + 1 : inner_start + OF.n_in - i + 1] = weight_out
		OF.filter[inner_start + OF.m_in + 2 * OF.n_in - i + 1, inner_start + OF.n_in + OF.m_in + i : inner_start + OF.m_in + 2 * OF.n_in] = weight_out
	end

	for i in 1:OF.n_out
		OF.filter[i, 1 : OF.n_out - i + 1] = 0
		OF.filter[i, OF.n_out + OF.m_out + i : OF.m_out + 2 * OF.n_out] = 0
		OF.filter[OF.m_out + 2 * OF.n_out - i + 1, 1 : OF.n_out - i + 1] = 0
		OF.filter[OF.m_out + 2 * OF.n_out - i + 1, OF.n_out + OF.m_out + i : OF.m_out + 2 * OF.n_out] = 0
	end

end

OctagonFilter(mo, mi, no, ni) = (OF = OctagonFilter(ones(Float64, mo + 2 * no, mo + 2 * no), mo, mi, no, ni); createFilter(OF); OF)
BoxFilter(s) = (BF = BoxFilter(s, 2 * s + 1, 4 * s + 1, (2 * s + 1) ^ 2, (4 * s + 1) ^ 2, 0.0, 0.0); BF.in_weight = 1.0 / BF.in_area; BF.out_weight = 1.0 / (BF.out_area - BF.in_area); BF; )

OctagonFilter_Kernels = [
						[5, 3, 2, 0],
						[5, 3, 3, 1],
						[7, 3, 3, 2],
						[9, 5, 4, 2],
						[9, 5, 7, 3],
						[13, 5, 7, 4],
						[15, 5, 10, 5]
						]

BoxFilter_Kernels = [1, 2, 3, 4, 5, 6, 7]

Kernels = Dict(BoxFilter => BoxFilter_Kernels, OctagonFilter => OctagonFilter_Kernels)

function getFilterStack(filter_type::Type, smallest::Integer, largest::Integer)
	k = Kernels[filter_type]
	filter_stack = map(f -> filter_type(f...), k[smallest : largest])
end

function filterResponse{T}(int_img::AbstractArray{T, 2}, filter::BoxFilter)
	margin = filter.scale * 2
	n = filter.scale
	img_shape = size(int_img)
	response = zeros(img_shape)
	R = CartesianRange(CartesianIndex((margin + 1, margin + 1)), CartesianIndex((img_shape[1] - margin, img_shape[2] - margin))) 
    in_sum = 0.0
    out_sum = 0.0
    for I in R
    	topleft = I + CartesianIndex(- n - 1, - n - 1)
    	topright = I + CartesianIndex(n, - n - 1)
    	bottomleft = I + CartesianIndex(- n - 1, n)
    	bottomright = I + CartesianIndex(n, n)
    	A = topleft >= CartesianIndex(1, 1) ? int_img[topleft] : 0.0
    	B = topright >= CartesianIndex(1, 1) ? int_img[topright] : 0.0
    	C = bottomleft >= CartesianIndex(1, 1) ? int_img[bottomleft] : 0.0
    	D = bottomright >= CartesianIndex(1, 1) ? int_img[bottomright] : 0.0
    	in_sum = A + D - B - C

    	topleft = I + CartesianIndex(- 2 * n - 1, - 2 * n - 1)
    	topright = I + CartesianIndex(2 * n, - 2 * n - 1)
    	bottomleft = I + CartesianIndex(- 2 * n - 1, 2 * n)
    	bottomright = I + CartesianIndex(2 * n, 2 * n)
    	A = topleft >= CartesianIndex(1, 1) ? int_img[topleft] : 0.0
    	B = topright >= CartesianIndex(1, 1) ? int_img[topright] : 0.0
    	C = bottomleft >= CartesianIndex(1, 1) ? int_img[bottomleft] : 0.0
    	D = bottomright >= CartesianIndex(1, 1) ? int_img[bottomright] : 0.0
    	out_sum = A + D - B - C - in_sum

    	response[I] = in_sum * filter.in_weight - out_sum * filer.out_weight
    end

    response
end

function filterResponse(int_imgs::Tuple, filter::OctagonFilter)
	int_img = int_imgs[1]
	rs_img = int_imgs[2]
	ls_img = int_imgs[3]
end

getIntegralImage(img, filter_type::BoxFilter) = integral_image(img)

function getIntegralImage(img, filter_type::OctagonFilter)
	img_shape = size(img)
	int_img = zeros(img_shape)
	right_slant_img = zeros(img_shape)
	left_slant_img = zeros(img_shape)

	int_img[1, :] = cumsum(img[1, :])
	right_slant_img[1, :] = int_img[1, :]
	left_slant_img[1, :] = int_img[1, :]

	for i in 2:img_shape[1]
		sum = 0.0
		for j in 1:img_shape[2]
			sum += img[i, j]
			int_img[i, j] = sum + int_img[i - 1, j]
			left_slant_img[i, j] = sum
			right_slant_img[i, j] = sum

			if j > 1 left_slant_img[i, j] += left_slant_img[i - 1, j - 1] end
			right_slant_img[i, j] += j < img_shape[2] ? right_slant_img[i - 1, j + 1] : right_slant_img[i - 1, j]
		end
	end
	int_img, right_slant_img, left_slant_img
end

CENSURE(; smallest::Integer = 1, largest::Integer = 7, filter::Type = BoxFilter, responseThreshold::Number = 0.15, lineThreshold::Number = 10) = CENSURE(smallest, largest, filter, getFilterStack(filter, smallest, largest), responseThreshold, lineThreshold)

function censure{T}(img::AbstractArray{T, 2}, params::CENSURE)
	int_img = getIntegralImage(img, params.filter_stack[1])
	responses = map(f -> filterResponse(int_img, f), params.filter_stack)
	responses
end