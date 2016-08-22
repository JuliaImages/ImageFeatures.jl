*FREAK* has a defined sampling pattern like [BRISK](brisk). It uses a retinal sampling grid with more density of points near the centre 
with the density decreasing exponentially with distance from the centre.

![FREAK Sampling Pattern](/img/freak_pattern.png = 50x50)

FREAK’s measure of orientation is similar to [BRISK](brisk) but instead of using long pairs, it uses a set of predefined 45 symmetric sampling pairs. The set of sampling pairs is determined using a method similar to [ORB](orb), by finding sampling pairs over keypoints in standard datasets and then extracting the most discriminative pairs. The orientation weights over these pairs are summed and the sampling window is rotated by this orientation to some canonical orientation to achieve rotation invariance.

The descriptor is built using intensity comparisons of a predetermined set of 512 sampling pairs. This set is also obtained using a method similar to the one described above. For each pair if the first point has greater intensity than the second, then 1 is written else 0 is written to the corresponding bit of the descriptor.

## Example 

Let us take a look at a simple example where the FREAK descriptor is used to match two images where one has been translated by `(50, 40)` pixels and then rotated by an angle of 75 degrees. We will use the `lighthouse` image from the [TestImages](https://github.com/timholy/TestImages.jl) package for this example.

First, lets define warping functions to transform and rotate the image.

```@example 1
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

Now, let us create the two images we will match using FREAK.

```@example 1

using ImageFeatures, TestImages, Images, ImageDraw

img = testimage("lighthouse")
img_array_1 = convert(Array{Gray}, img)
img_temp_2 = _warp(img_array_1, 5 * pi / 6)
img_array_2 = _warp(img_temp_2, 50, 40)
nothing # hide
```

To calculate the descriptors, we first need to get the keypoints. For this tutorial, we will use the FAST corners to generate keypoints (see [`fastcorners`](@ref).

```@example 1
keypoints_1 = Keypoints(fastcorners(img_array_1, 12, 0.35))
keypoints_2 = Keypoints(fastcorners(img_array_2, 12, 0.35))
nothing # hide
```

To create the BRIEF descriptor, we first need to define the parameters by calling the [`BRIEF`](@ref) constructor.

```@example 1
freak_params = FREAK()
nothing # hide
```

Now pass the image with the keypoints and the parameters to the [`create_descriptor`](@ref) function.

```@example 1
desc_1, ret_keypoints_1 = create_descriptor(img_array_1, keypoints_1, freak_params)
desc_2, ret_keypoints_2 = create_descriptor(img_array_2, keypoints_2, freak_params)
nothing # hide
```

The obtained descriptors can be used to find the matches between the two images using the [`match_keypoints`](@ref) function.

```@example 1
matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.1)
nothing # hide
```

We can use the [ImageDraw.jl](https://github.com/JuliaImages/ImageDraw.jl) package to view the results.

```@example 1

grid = hcat(img_array_1, img_array_2)
offset = CartesianIndex(0, 768)
map(m_i -> line!(grid, m_i[1], m_i[2] + offset), matches)
save("brief_example.jpg", grid); nothing # hide

```

![](brief_example.jpg)
