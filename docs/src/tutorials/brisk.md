The *BRISK* (Binary Robust Invariant Scalable Keypoints) descriptor has a predefined sampling pattern as compared to [BRIEF](brief) or [ORB](orb). Pixels are sampled over concentric rings. For each sampling point, a small patch is considered around it. Before starting the algorithm, the patch is smoothed using gaussian smoothing.

![BRISK Sampling Pattern](/img/brisk_pattern.png = 50x50)

Two types of pairs are used for sampling, short and long pairs. Short pairs are those where the distance is below a set threshold distmax while the long pairs have distance above distmin. Long pairs are used for orientation and short pairs are used for calculating the descriptor by comparing intensities.

BRISK achieves rotation invariance by trying the measure orientation of the keypoint and rotating the sampling pattern by that orientation. This is done by first calculating the local gradient `g(pi,pj)` between sampling pair `(pi,pj)` where `I(pj, pj)` is the smoothed intensity after applying gaussian smoothing.

`g(pi, pj) = (pi - pj) . I(pj, j) -I(pj, j)pj - pi2`

All local gradients between long pairs and then summed and the `arctangent(gy/gx)` between `y` and `x` components of the sum is taken as the angle of the keypoint. Now, we only need to rotate the short pairs by that angle to help the descriptor become more invariant to rotation. 
The descriptor is built using intensity comparisons. For each short pair if the first point has greater intensity than the second, then 1 is written else 0 is written to the corresponding bit of the descriptor.

## Example 

Let us take a look at a simple example where the BRISK descriptor is used to match two images where one has been translated by `(50, 40)` pixels and then rotated by an angle of 75 degrees. We will use the `lighthouse` image from the [TestImages](https://github.com/timholy/TestImages.jl) package for this example.

First, lets define warping functions to transform and rotate the image.

```@example 4
function _warp(img, transx, transy)
    res = zeros(eltype(img), size(img))
    for i in 1:size(img, 1) - transx
        for j in 1:size(img, 2) - transy
            res[i + transx, j + transy] = img[i, j]
        end
    end
    res = shareproperties(img, res)
    res
end

function _warp(img, angle)
	cos_angle = cos(angle)
	sin_angle = sin(angle)
    res = zeros(eltype(img), size(img))
    cx = size(img, 1) / 2
    cy = size(img, 2) / 2
	for i in 1:size(res, 1)
		for j in 1:size(res, 2)
			i_rot = ceil(Int, cos_angle * (i - cx) - sin_angle * (j - cy) + cx)
			j_rot = ceil(Int, sin_angle * (i - cx) + cos_angle * (j - cy) + cy)
			if checkbounds(Bool, img, i_rot, j_rot) res[i, j] = bilinear_interpolation(img, i_rot, j_rot) end
		end
	end
    res = shareproperties(img, res)
	res
end	
nothing # hide
```

Now, let us create the two images we will match using BRISK.

```@example 4

using ImageFeatures, TestImages, Images, ImageDraw

img = testimage("lighthouse")
img_array_1 = convert(Array{Images.Gray}, img)
img_temp_2 = _warp(img_array_1, 5 * pi / 6)
img_array_2 = _warp(img_temp_2, 50, 40)
nothing # hide
```

To calculate the descriptors, we first need to get the keypoints. For this tutorial, we will use the FAST corners to generate keypoints (see [`fastcorners`](@ref).

```@example 4
features_1 = Features(fastcorners(img_array_1, 12, 0.35))
features_2 = Features(fastcorners(img_array_2, 12, 0.35))
nothing # hide
```
 
To create the BRISK descriptor, we first need to define the parameters by calling the [`BRISK`](@ref) constructor.

```@example 4
brisk_params = BRISK()
nothing # hide
```

Now pass the image with the keypoints and the parameters to the [`create_descriptor`](@ref) function.

```@example 4
desc_1, ret_features_1 = create_descriptor(img_array_1, features_1, brisk_params)
desc_2, ret_features_2 = create_descriptor(img_array_2, features_2, brisk_params)
nothing # hide
```

The obtained descriptors can be used to find the matches between the two images using the [`match_keypoints`](@ref) function.

```@example 4
matches = match_keypoints(Keypoints(ret_features_1), Keypoints(ret_features_2), desc_1, desc_2, 0.1)
nothing # hide
```

We can use the [ImageDraw.jl](https://github.com/JuliaImages/ImageDraw.jl) package to view the results.

```@example 4

grid = hcat(img_array_1, img_array_2)
offset = CartesianIndex(0, 768)
map(m_i -> line!(grid, m_i[1], m_i[2] + offset), matches)
save("brisk_example.jpg", grid); nothing # hide

```

![](brisk_example.jpg)
