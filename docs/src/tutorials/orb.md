The *ORB* descriptor is a somewhat similar to [BRIEF](brief). It doesn’t have an elaborate sampling pattern as [BRISK](brisk) or [FREAK](freak). 

However, there are two main differences between ORB and BRIEF:
- ORB uses an orientation compensation mechanism, making it rotation invariant.
- ORB learns the optimal sampling pairs, whereas BRIEF uses randomly chosen sampling pairs.

The ORB descriptor uses the intensity centroid as a measure of orientation. To calculate the centroid, we first need to find the moment of a patch, which is given by `Mpq = x,yxpyqI(x,y)`. The centroid, or ‘centre of mass' is then given by `C=(M10M00, M01M00)`.

The vector from the corner’s center to the centroid gives the orientation of the patch. Now, the patch can be rotated to some predefined canonical orientation before calculating the descriptor, thus achieving rotation invariance.

ORB tries to take sampling pairs which are uncorrelated so that each new pair will bring new information to the descriptor, thus maximizing the amount of information the descriptor carries. We also want high variance among the pairs making a feature more discriminative, since it responds differently to inputs. To do this, we consider the sampling pairs over keypoints in standard datasets and then do a greedy evaluation of all the pairs in order of distance from mean till the number of desired pairs are obtained i.e. the size of the descriptor.

The descriptor is built using intensity comparisons of the pairs. For each pair if the first point has greater intensity than the second, then 1 is written else 0 is written to the corresponding bit of the descriptor.