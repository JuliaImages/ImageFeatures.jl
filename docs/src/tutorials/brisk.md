The *BRISK* descriptor has a predefined sampling pattern as compared to [BRIEF](brief) or [ORB](orb). Pixels are sampled over concentric rings. For each sampling point, a small patch is considered around it. Before starting the algorithm, the patch is smoothed using gaussian smoothing.

![BRISK Sampling Pattern](/img/brisk_pattern.png = 50x50)

Two types of pairs are used for sampling, short and long pairs. Short pairs are those where the distance is below a set threshold distmax while the long pairs have distance above distmin. Long pairs are used for orientation and short pairs are used for calculating the descriptor by comparing intensities.

BRISK achieves rotation invariance by trying the measure orientation of the keypoint and rotating the sampling pattern by that orientation. This is done by first calculating the local gradient `g(pi,pj)` between sampling pair `(pi,pj)` where `I(pj, pj)` is the smoothed intensity after applying gaussian smoothing.

`g(pi, pj) = (pi - pj) . I(pj, j) -I(pj, j)pj - pi2`

All local gradients between long pairs and then summed and the `arctangent(gy/gx)` between `y` and `x` components of the sum is taken as the angle of the keypoint. Now, we only need to rotate the short pairs by that angle to help the descriptor become more invariant to rotation. 
The descriptor is built using intensity comparisons. For each short pair if the first point has greater intensity than the second, then 1 is written else 0 is written to the corresponding bit of the descriptor.