# Feature Extraction and Descriptors

Below `[]` in an argument list means an optional argument.

## Types

```@docs
Feature
Features
Keypoint
Keypoints
BRIEF
ORB
FREAK
BRISK
```

## Corners

```@docs
corner_orientations
```

## BRIEF Sampling Patterns

```@docs
random_uniform
random_coarse
gaussian
gaussian_local
center_sample
```

## Feature Extraction

```@docs
```

## Feature Description

```@docs
create_descriptor
```

## Feature Matching

```@docs
hamming_distance
match_keypoints
```

# Texture Matching

## Gray Level Co-occurence Matrix

```@docs
glcm
glcm_symmetric
glcm_norm
glcm_prop
max_prob
contrast
ASM
IDM
glcm_entropy
energy
dissimilarity
correlation
glcm_mean_ref
glcm_mean_neighbour
glcm_var_ref
glcm_var_neighbour
```

## Local Binary Patterns

```@docs
lbp
modified_lbp
direction_coded_lbp
lbp_original
lbp_uniform
lbp_rotation_invariant
multi_block_lbp
```

# Misc

```@docs
hough_transform_standard
hough_circle_gradient
```
