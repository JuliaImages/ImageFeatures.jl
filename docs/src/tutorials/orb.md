The *ORB* (Oriented Fast and Rotated Brief) descriptor is a somewhat similar to [BRIEF](brief). It doesn’t have an elaborate sampling pattern as [BRISK](brisk) or [FREAK](freak). 

However, there are two main differences between ORB and BRIEF:

- ORB uses an orientation compensation mechanism, making it rotation invariant.
- ORB learns the optimal sampling pairs, whereas BRIEF uses randomly chosen sampling pairs.

The ORB descriptor uses the intensity centroid as a measure of orientation. To calculate the centroid, we first need to find the moment of a patch, which is given by `Mpq = x,yxpyqI(x,y)`. The centroid, or ‘centre of mass' is then given by `C=(M10M00, M01M00)`.

The vector from the corner’s center to the centroid gives the orientation of the patch. Now, the patch can be rotated to some predefined canonical orientation before calculating the descriptor, thus achieving rotation invariance.

ORB tries to take sampling pairs which are uncorrelated so that each new pair will bring new information to the descriptor, thus maximizing the amount of information the descriptor carries. We also want high variance among the pairs making a feature more discriminative, since it responds differently to inputs. To do this, we consider the sampling pairs over keypoints in standard datasets and then do a greedy evaluation of all the pairs in order of distance from mean till the number of desired pairs are obtained i.e. the size of the descriptor.

The descriptor is built using intensity comparisons of the pairs. For each pair if the first point has greater intensity than the second, then 1 is written else 0 is written to the corresponding bit of the descriptor.

## Example 

Let us take a look at a simple example where the ORB descriptor is used to match two images where one has been translated by `(50, 40)` pixels and then rotated by an angle of 75 degrees. We will use the `lighthouse` image from the [TestImages](https://github.com/timholy/TestImages.jl) package for this example.

First, lets define warping functions to transform and rotate the image.

```@example 2
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

Now, let us create the two images we will match using ORB. 

```@example 2

using ImageFeatures, TestImages, Images, ImageDraw

img = testimage("lighthouse")
img_array_1 = convert(Array{Images.Gray}, img)
img_temp_2 = _warp(img_array_1, 5 * pi / 6)
img_array_2 = _warp(img_temp_2, 50, 40)
        
nothing # hide
```

The ORB descriptor calculates the keypoints as well as the descriptor, unlike [BRIEF](brief). To create the ORB descriptor, we first need to define the parameters by calling the [`ORB`](@ref) constructor.

```@example 2
orb_params = ORB(num_keypoints = 1000)
nothing # hide
```

Now pass the image with the parameters to the [`create_descriptor`](@ref) function.

```@example 2
desc_1, ret_keypoints_1 = create_descriptor(img_array_1, orb_params)
desc_2, ret_keypoints_2 = create_descriptor(img_array_2, orb_params)
nothing # hide
```

The obtained descriptors can be used to find the matches between the two images using the [`match_keypoints`](@ref) function.

```@example 2
matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.2)
nothing # hide
```

We can use the [ImageDraw.jl](https://github.com/JuliaImages/ImageDraw.jl) package to view the results.

```@example 2

grid = hcat(img_array_1, img_array_2)
offset = CartesianIndex(0, 768)
map(m_i -> line!(grid, m_i[1], m_i[2] + offset), matches)
save("orb_example.jpg", grid); nothing # hide

```

![](orb_example.jpg)
