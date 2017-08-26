# ImageFeatures.jl

## Introduction

[ImageFeatures](https://github.com/JuliaImages/ImageFeatures.jl) is a
package for identifying and characterizing "keypoints" (salient
features) in images. Collections of keypoints can be matched between
two images. Consequently, keypoints can be useful in many
applications, such as object localization and image registration.

The ideal keypoint detector finds salient image regions such that they
are repeatably detected despite change of viewpoint and more generally
it is robust to all possible image transformations. Similarly, the
ideal keypoint descriptor captures the most important and distinctive
information content enclosed in the detected salient regions, such
that the same structure can be recognized if encountered.

## Installation

Installing the package is extremely easy with julia's package manager -

```julia
Pkg.add("ImageFeatures.jl")
```

ImageFeatures.jl requires [Images.jl](https://github.com/JuliaImages/Images.jl).
