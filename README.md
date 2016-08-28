# ImageFeatures

[![Build Status](https://travis-ci.org/JuliaImages/ImageFeatures.jl.svg?branch=master)](https://travis-ci.org/JuliaImages/ImageFeatures.jl) [![Coverage Status](https://coveralls.io/repos/github/JuliaImages/ImageFeatures.jl/badge.svg?branch=master)](https://coveralls.io/github/JuliaImages/ImageFeatures.jl?branch=master) [![](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaImages.github.io/ImageFeatures.jl/stable) [![](https://img.shields.io/badge/docs-latest-blue.svg)](https://JuliaImages.github.io/ImageFeatures.jl/latest)

The ideal keypoint detector finds salient image regions such that they are repeatably detected despite change of viewpoint and more generally it is robust to all possible image transformations. Similarly, the ideal keypoint descriptor captures the most important and distinctive information content enclosed in the detected salient regions, such that the same structure can be recognized if encountered. ImageFeatures.jl is a collection of such feature extraction and detection algorithms in the Julia language.

### Installation 

Installing the package is extremely easy with julia's package manager -
```julia
Pkg.clone("https://github.com/JuliaImages/ImageFeatures.jl")
```
ImageFeatures.jl requires Images.jl.

### Functions

The following functionality is currently available in ImageFeatures.jl. See the [docs](https://JuliaImages.github.io/ImageFeatures.jl/latest) for more information.

- GLCM (Grey Level Co-occurence Matrices)
- LBP (Local Binary Patterns)
- BRIEF (Binary Robust Independent Elementary Features)
- ORB (Oriented Fast and Rotated Brief)
- BRISK (Binary Robust Invariant Scalable Keypoints)
- FREAK (Fast REtinA Keypoint)

### Tutorials

Tutorials on using the package are avaiable in the [docs](https://JuliaImages.github.io/ImageFeatures.jl/latest).

### Contributing

A guide on contributing to ImageFeatures.jl is available [here](http://juliaimages.github.io/ImageFeatures.jl/latest/CONTRIBUTING/).