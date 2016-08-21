*BRIEF* (Binary Robust Independent Elementary Features) is an efficient feature point descriptor. It is highly discriminative even when using relatively few bits and is computed using simple intensity difference tests. BRIEF does not have a sampling pattern thus pairs can be chosen at any point on the `SxS` patch.

To build a BRIEF descriptor of length `n`, we need to determine `n` pairs `(Xi,Yi)`. Denote by `X` and `Y` the vectors of point `Xi` and `Yi`, respectively.

In ImageFeatures.jl we have five methods to determine the vectors `X` and `Y` :
- [`random_uniform`] : `X` and `Y` are randomly uniformly sampled
- [`gaussian`] : `X` and `Y` are randomly sampled using a Gaussian distribution, meaning that locations that are closer to the center of the patch are preferred
- [`gaussian_local`] : `X` and `Y` are randomly sampled using a Gaussian distribution where first `X` is sampled with a standard deviation of `0.04*S^2` and then the `Yi’s` are sampled using a Gaussian distribution – Each `Yi` is sampled with mean `Xi` and standard deviation of `0.01 * S^2`
- [`random_coarse`] : `X and `Y` are randomly sampled from discrete location of a coarse polar grid
- [`centered`] : For each `i`, `Xi` is `(0, 0)` and `Yi` takes all possible values on a coarse polar grid

As with all the binary descriptors, BRIEF’s distance measure is the number of different bits between two binary strings which can also be computed as the sum of the XOR operation between the strings.

BRIEF is a very simple feature descriptor and does not provide scale, translation or rotation invariance. To achieve those, see [ORB](orb), [BRISK](brisk) and [FREAK](freak).