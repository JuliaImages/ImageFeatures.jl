abstract Params

"""
```
feature = Feature(keypoint, orientation = 0.0, scale = 0.0)
```

The `Feature` type has the keypoint, its orientation and its scale.
"""
immutable Feature
    keypoint::Keypoint
    orientation::Float64
    scale::Float64
end

Feature(k::Keypoint) = Feature(k, 0.0, 0.0)

Feature(k::Keypoint, ori::Float64) = Feature(k, ori, 0.0)

"""
```
features = Features(boolean_img)
features = Features(keypoints)
```

Returns a `Vector{Feature}` of features generated from the `true` values in a boolean image or from a 
list of keypoints.
"""
typealias Features Vector{Feature}

Features(keypoints::Keypoints) = map(k -> Feature(k), keypoints)

Features(img::AbstractArray) = Features(Keypoints(img))

"""
```
keypoint = Keypoint(y, x)
keypoint = Keypoint(feature)
```

A `Keypoint` may be created by passing the coordinates of the point or from a feature.
"""
typealias Keypoint CartesianIndex{2}

"""
```
keypoints = Keypoints(boolean_img)
keypoints = Keypoints(features)
```

Creates a `Vector{Keypoint}` of the `true` values in a boolean image or from a list of features.
"""
typealias Keypoints Vector{CartesianIndex{2}}

function Keypoints(img::AbstractArray)
    r, c, _ = findnz(img)
    map((ri, ci) -> Keypoint(ri, ci), r, c)
end

Keypoints(features::Features) = map(f -> f.keypoint, features)        

Keypoint(feature::Feature) = feature.keypoint

"""
```
distance = hamming_distance(desc_1, desc_2)
```

Calculates the hamming distance between two descriptors.
"""
hamming_distance(desc_1, desc_2) = mean(desc_1 $ desc_2)

"""
```
matches = match_keypoints(keypoints_1, keypoints_2, desc_1, desc_2, threshold = 0.1)
```

Finds matched keypoints using the [`hamming_distance`](@ref) function having distance value less than `threshold`.
"""
function match_keypoints(keypoints_1::Keypoints, keypoints_2::Keypoints, desc_1, desc_2, threshold::Float64 = 0.1)
    smaller = desc_1
    larger = desc_2
    s_key = keypoints_1
    l_key = keypoints_2
    order = false
    if length(desc_1) > length(desc_2) 
        smaller = desc_2
        larger = desc_1
        s_key = keypoints_2
        l_key = keypoints_1
        order = true
    end
    hamming_distances = [hamming_distance(s, l) for s in smaller, l in larger]
    matches = Keypoints[]
    for i in 1:length(smaller)
        if any(hamming_distances[i, :] .< threshold)
            id_min = indmin(hamming_distances[i, :])
            push!(matches, order ? [l_key[id_min], s_key[i]] : [s_key[i], l_key[id_min]])
            hamming_distances[:, id_min] = 1.0
        end
    end
    matches
end