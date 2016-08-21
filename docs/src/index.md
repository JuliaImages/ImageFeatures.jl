# ImageFeatures.jl

## Introduction

The ideal keypoint detector finds salient image regions such that they are repeatably detected despite change of viewpoint and more generally it is robust to all possible image transformations. Similarly, the ideal keypoint descriptor captures the most important and distinctive information content enclosed in the detected salient regions, such that the same structure can be recognized if encountered. 

## Installation

Installing the package is extremely easy with julia's package manager - 

```julia
Pkg.clone("https://github.com/JuliaImages/ImageFeatures.jl")
```

ImageFeatures.jl requires [Images.jl](https://github.com/timholy/Images.jl).

