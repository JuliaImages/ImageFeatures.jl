# High-level overview of the framework

The `Feature` and `Keypoint` types are the fundamental types in ImageFeatures.jl. `Feature` stores the `keypoint` and its `orientation` and `scale`. A vector of the `Feature` type is denoted by the `Features` type and similary a vector of `Keypoint` type is denoted by the `Keypoints` type. We provide multiple methods for easily transitioning between the two types. 

`Keypoints` or `Features` can be generate from an image of boolean values by `Keypoints(boolean_image)` or `Features(boolean_image)` where the boolean_image may be obtained from a feature detection algorithm for eg. the result of a corner detector. All feature detectors in ImageFeatures.jl directly return `Features`.

A keypoint may be converted to a feature or vice versa by directly passing it to the respective method eg. `Keypoint(feature_A)` or `Feature(keypoint_A)`.

```julia
descriptor, ret_keypoints = create_descriptor(img, dparams)
descriptor, ret_keypoints = create_descriptor(img, keypoints, dparams)
```

Depending on the algorithm , the `create_descriptor` API can be used to directly create a feature descriptor from the image (eg. ORB, BRISK) or from the keypoints (eg. BRIEF, FREAK). In case of the latter, the keypoints can be obtained using algorithms such as FAST. The `dparams` argument is dependent on the algorithm chosen and its type is the name of the algorithm.
