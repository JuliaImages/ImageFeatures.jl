*FREAK* has a defined sampling pattern like [BRISK](brisk). It uses a retinal sampling grid with more density of points near the centre 
with the density decreasing exponentially with distance from the centre.

![FREAK Sampling Pattern](/img/freak_pattern.png = 50x50)

FREAK’s measure of orientation is similar to [BRISK](brisk) but instead of using long pairs, it uses a set of predefined 45 symmetric sampling pairs. The set of sampling pairs is determined using a method similar to [ORB](orb), by finding sampling pairs over keypoints in standard datasets and then extracting the most discriminative pairs. The orientation weights over these pairs are summed and the sampling window is rotated by this orientation to some canonical orientation to achieve rotation invariance.

The descriptor is built using intensity comparisons of a predetermined set of 512 sampling pairs. This set is also obtained using a method similar to the one described above. For each pair if the first point has greater intensity than the second, then 1 is written else 0 is written to the corresponding bit of the descriptor.