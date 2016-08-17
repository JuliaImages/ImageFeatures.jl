type BRISK <: Params
	threshold::Float64
	octaves::Int
end

function BRISK(; threshold::Float64 = 0.25, octaves::Int = 4)
	BRISK(threshold, octaves)
end

function extract_features{T<:Gray}(img::AbstractArray{T, 2}, params::BRISK)

end

function create_descriptor{T<:Gray}(img::AbstractArray{T, 2}, params::BRISK)
	features = extract_features(img, params)
end

function create_descriptor{T<:Gray}(img::AbstractArray{T, 2}, features::Array{Feature}, params::BRISK)

end