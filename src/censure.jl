abstract BiFilter

type BoxFilter <: BiFilter
	
	filter :: Array{Float64, 2}
	m_out :: UInt8
	m_in :: UInt8

	BoxFilter(mo, mi) = new(ones(Float64, mo, mo), mo, mi)

end

type OctagonFilter <: BiFilter
	
	filter :: Array{Float64, 2}
	m_out :: UInt8
	m_in :: UInt8
	n_out :: UInt8
	n_in :: UInt8

	OctagonFilter(mo, mi, no, ni) = new(ones(Float64, mo + 2 * no, mo + 2 * no), mo, mi, no, ni)

end

type CENSURE <: Detector

	smallest :: Integer
	largest :: Integer
	filter :: Type
	responseThreshold :: Number
	lineThreshold :: Number

end

function createFilter(OF::OctagonFilter)
	inner_start = Int(0.5 * ((OF.m_out + 2 * OF.n_out) - (OF.m_in + 2 * OF.n_in)))
	OF.filter[inner_start + 1 : end - inner_start, inner_start + 1 : end - inner_start] = -1

	for i in 1:OF.n_in
		OF.filter[inner_start + i, inner_start + 1 : inner_start + OF.n_in - i + 1] = 0
		OF.filter[inner_start + i, inner_start + OF.n_in + OF.m_in + i : inner_start + OF.m_in + 2 * OF.n_in] = 0
		OF.filter[inner_start + OF.m_in + 2 * OF.n_in - i + 1, inner_start + 1 : inner_start + OF.n_in - i + 1] = 0
		OF.filter[inner_start + OF.m_in + 2 * OF.n_in - i + 1, inner_start + OF.n_in + OF.m_in + i : inner_start + OF.m_in + 2 * OF.n_in] = 0
	end

	for i in 1:OF.n_out
		OF.filter[i, 1 : OF.n_out - i + 1] = 0
		OF.filter[i, OF.n_out + OF.m_out + i : OF.m_out + 2 * OF.n_out] = 0
		OF.filter[OF.m_out + 2 * OF.n_out - i + 1, 1 : OF.n_out - i + 1] = 0
		OF.filter[OF.m_out + 2 * OF.n_out - i + 1, OF.n_out + OF.m_out + i : OF.m_out + 2 * OF.n_out] = 0
	end

end

function createFilter(BF::BoxFilter)
	inner_start = Int(0.5 * (BF.m_out - BF.m_in))
	BF.filter[inner_start + 1 : end - inner_start, inner_start + 1 : end - inner_start] = -1
end

CENSURE(; smallest::Integer = 1, largest::Integer = 7, filter::Type = BoxFilter, responseThreshold::Number = 0.15, lineThreshold::Number = 10) = CENSURE(scale, filter, responseThreshold, lineThreshold)

function censure{T}(img::AbstractArray{T, 2}, params::CENSURE)


end