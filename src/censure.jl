abstract BiFilter

type BoxFilter <: BiFilter
	
	filter :: Array{Float64, 2}
	scale :: UInt8

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
	filter_stack :: Array{BiFilter}
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

function createFilter(BF::BoxFilter)
	
end

OctagonFilter(mo, mi, no, ni) = (OF = OctagonFilter(ones(Float64, mo + 2 * no, mo + 2 * no), mo, mi, no, ni); createFilter(OF); OF)
BoxFilter(s) = (BF = BoxFilter(ones(Float64, 4 * s + 1, 4 * s + 1), s); createFilter(BF); BF)

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

CENSURE(; smallest::Integer = 1, largest::Integer = 7, filter::Type = OctagonFilter, responseThreshold::Number = 0.15, lineThreshold::Number = 10) = CENSURE(smallest, largest, filter, getFilterStack(filter, smallest, largest), responseThreshold, lineThreshold)

function censure{T}(img::AbstractArray{T, 2}, params::CENSURE)
	
end