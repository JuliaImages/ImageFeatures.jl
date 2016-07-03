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
	
	m_out :: Integer
	m_in :: Integer
	n_out :: Integer
	n_in :: Integer
	in_area :: Float64
	out_area :: Float64
	in_weight :: Float64
	out_weight :: Float64

end

type CENSURE <: Detector

	smallest :: Integer
	largest :: Integer
	filter_type :: Type
	filter_stack :: Array
	responseThreshold :: Number
	lineThreshold :: Number

end

function OctagonFilter(mo, mi, no, ni)
	OF = OctagonFilter(mo, mi, no, ni, 0.0, 0.0, 0.0, 0.0)
	OF.out_area = OF.m_out ^ 2 + 2 * OF.n_out ^ 2 + 4 * OF.m_out * OF.n_out
	OF.in_area = OF.m_in ^ 2 + 2 * OF.n_in ^ 2 + 4 * OF.m_in * OF.n_in
	OF.out_weight = 1.0 / (OF.out_area - OF.in_area)
	OF.in_weight = 1.0 / OF.in_area
	OF
end

function BoxFilter(s)
	BF = BoxFilter(s, 2 * s + 1, 4 * s + 1, (2 * s + 1) ^ 2, (4 * s + 1) ^ 2, 0.0, 0.0)
	BF.in_weight = 1.0 / BF.in_area
	BF.out_weight = 1.0 / (BF.out_area - BF.in_area)
	BF
end

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

function filterResponse{T}(int_img::AbstractArray{T, 2}, BF::BoxFilter)
	margin = BF.scale * 2
	n = BF.scale
	img_shape = size(int_img)
	response = zeros(img_shape)
	R = CartesianRange(CartesianIndex((margin + 1, margin + 1)), CartesianIndex((img_shape[1] - margin, img_shape[2] - margin))) 
    in_sum = 0.0
    out_sum = 0.0
    for I in R
    	topleft = I + CartesianIndex(- n - 1, - n - 1)
    	topright = I + CartesianIndex(- n - 1, n)
    	bottomleft = I + CartesianIndex(n, - n - 1)
    	bottomright = I + CartesianIndex(n, n)
    	A = topleft >= CartesianIndex(1, 1) ? int_img[topleft] : 0.0
    	B = topright >= CartesianIndex(1, 1) ? int_img[topright] : 0.0
    	C = bottomleft >= CartesianIndex(1, 1) ? int_img[bottomleft] : 0.0
    	D = bottomright >= CartesianIndex(1, 1) ? int_img[bottomright] : 0.0
    	in_sum = A + D - B - C

    	topleft = I + CartesianIndex(- 2 * n - 1, - 2 * n - 1)
    	topright = I + CartesianIndex(- 2 * n - 1, 2 * n)
    	bottomleft = I + CartesianIndex(2 * n, - 2 * n - 1)
    	bottomright = I + CartesianIndex(2 * n, 2 * n)
    	A = topleft >= CartesianIndex(1, 1) ? int_img[topleft] : 0.0
    	B = topright >= CartesianIndex(1, 1) ? int_img[topright] : 0.0
    	C = bottomleft >= CartesianIndex(1, 1) ? int_img[bottomleft] : 0.0
    	D = bottomright >= CartesianIndex(1, 1) ? int_img[bottomright] : 0.0
    	out_sum = A + D - B - C - in_sum

    	response[I] = in_sum * BF.in_weight - out_sum * BF.out_weight
    end

    response
end

function filterResponse(int_imgs::Tuple, OF::OctagonFilter)
	int_img = int_imgs[1]
	rs_img = int_imgs[2]
	ls_img = int_imgs[3]

	margin = Int(floor(OF.m_out / 2 + OF.n_out))
	m_in2 = Int(floor(OF.m_in / 2))
	m_out2 = Int(floor(OF.m_out / 2))

	img_shape = size(int_img)
	response = zeros(img_shape)
	R = CartesianRange(CartesianIndex((margin + 1, margin + 1)), CartesianIndex((img_shape[1] - margin, img_shape[2] - margin))) 
    
    for I in R
    	topleft = I + CartesianIndex(- m_in2 - 1, - m_in2 - OF.n_in - 1)
    	topright = I + CartesianIndex(m_in2, - m_in2 - OF.n_in - 1)
    	bottomleft = I + CartesianIndex(- m_in2 - 1, m_in2 + OF.n_in)
    	bottomright = I + CartesianIndex(m_in2, m_in2 + OF.n_in)
    	A = topleft >= CartesianIndex(1, 1) ? int_img[topleft] : 0.0
    	B = topright >= CartesianIndex(1, 1) ? int_img[topright] : 0.0
    	C = bottomleft >= CartesianIndex(1, 1) ? int_img[bottomleft] : 0.0
    	D = bottomright >= CartesianIndex(1, 1) ? int_img[bottomright] : 0.0
    	in_sum = A + D - B - C

    	trap_top_right = bottomright
    	trap_bot_right = I + CartesianIndex(m_in2 + OF.n_in, m_in2)
    	trap_top_left = I + CartesianIndex(m_in2, - m_in2 - OF.n_in)
    	trap_bot_left = I + CartesianIndex(m_in2 + OF.n_in, - m_in2 - 1)
    	A = trap_top_left >= CartesianIndex(1, 1) ? ls_img[trap_top_left] : 0.0
    	B = trap_top_right >= CartesianIndex(1, 1) ? rs_img[trap_top_right] : 0.0
    	C = trap_bot_left >= CartesianIndex(1, 1) ? ls_img[trap_bot_left] : 0.0
    	D = trap_bot_right >= CartesianIndex(1, 1) ? rs_img[trap_bot_right] : 0.0
    	in_sum += A + D - B - C

    	trap_top_right = I + CartesianIndex(- m_in2 - OF.n_in - 1, m_in2 - 1)
    	trap_top_left = I + CartesianIndex(- m_in2 - OF.n_in - 1, - m_in2)
    	trap_bot_right = I + CartesianIndex(- m_in2 - 1, m_in2 + OF.n_in - 1)
    	trap_bot_left = I + CartesianIndex(- m_in2 - 1, - m_in2 - OF.n_in)
    	A = trap_top_left >= CartesianIndex(1, 1) ? rs_img[trap_top_left] : 0.0
    	B = trap_top_right >= CartesianIndex(1, 1) ? ls_img[trap_top_right] : 0.0
    	C = trap_bot_left >= CartesianIndex(1, 1) ? rs_img[trap_bot_left] : 0.0
    	D = trap_bot_right >= CartesianIndex(1, 1) ? ls_img[trap_bot_right] : 0.0
    	in_sum += A + D - B - C

    	topleft = I + CartesianIndex(- m_out2 - 1, - m_out2 - OF.n_out - 1)
    	topright = I + CartesianIndex(m_out2, - m_out2 - OF.n_out - 1)
    	bottomleft = I + CartesianIndex(- m_out2 - 1, m_out2 + OF.n_out)
    	bottomright = I + CartesianIndex(m_out2, m_out2 + OF.n_out)
    	A = topleft >= CartesianIndex(1, 1) ? int_img[topleft] : 0.0
    	B = topright >= CartesianIndex(1, 1) ? int_img[topright] : 0.0
    	C = bottomleft >= CartesianIndex(1, 1) ? int_img[bottomleft] : 0.0
    	D = bottomright >= CartesianIndex(1, 1) ? int_img[bottomright] : 0.0
    	out_sum = A + D - B - C

    	trap_top_right = bottomright
    	trap_bot_right = I + CartesianIndex(m_out2 + OF.n_out, m_out2)
    	trap_top_left = I + CartesianIndex(m_out2, - m_out2 - OF.n_out)
    	trap_bot_left = I + CartesianIndex(m_out2 + OF.n_out, - m_out2 - 1)
    	A = trap_top_left >= CartesianIndex(1, 1) ? ls_img[trap_top_left] : 0.0
    	B = trap_top_right >= CartesianIndex(1, 1) ? rs_img[trap_top_right] : 0.0
    	C = trap_bot_left >= CartesianIndex(1, 1) ? ls_img[trap_bot_left] : 0.0
    	D = trap_bot_right >= CartesianIndex(1, 1) ? rs_img[trap_bot_right] : 0.0
    	out_sum += A + D - B - C

    	trap_top_right = I + CartesianIndex(- m_out2 - OF.n_out - 1, m_out2 - 1)
    	trap_top_left = I + CartesianIndex(- m_out2 - OF.n_out - 1, - m_out2)
    	trap_bot_right = I + CartesianIndex(- m_out2 - 1, m_out2 + OF.n_out - 1)
    	trap_bot_left = I + CartesianIndex(- m_out2 - 1, - m_out2 - OF.n_out)
    	A = trap_top_left >= CartesianIndex(1, 1) ? rs_img[trap_top_left] : 0.0
    	B = trap_top_right >= CartesianIndex(1, 1) ? ls_img[trap_top_right] : 0.0
    	C = trap_bot_left >= CartesianIndex(1, 1) ? rs_img[trap_bot_left] : 0.0
    	D = trap_bot_right >= CartesianIndex(1, 1) ? ls_img[trap_bot_right] : 0.0
    	out_sum += A + D - B - C
    	out_sum = out_sum - in_sum

    	response[I] = in_sum * filter.in_weight - out_sum * filer.out_weight
    end
	response
	
end

CENSURE(; smallest::Integer = 1, largest::Integer = 7, filter::Type = BoxFilter, responseThreshold::Number = 0.15, lineThreshold::Number = 10) = CENSURE(smallest, largest, filter, getFilterStack(filter, smallest, largest), responseThreshold, lineThreshold)

function censure{T}(img::AbstractArray{T, 2}, params::CENSURE)
	int_img = getIntegralImage(img, params.filter_stack[1])
	responses = map(f -> filterResponse(int_img, f), params.filter_stack)
	responses
end