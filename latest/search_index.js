var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#ImageFeatures.jl-1",
    "page": "Home",
    "title": "ImageFeatures.jl",
    "category": "section",
    "text": ""
},

{
    "location": "index.html#Introduction-1",
    "page": "Home",
    "title": "Introduction",
    "category": "section",
    "text": "ImageFeatures is a package for identifying and characterizing \"keypoints\" (salient features) in images. Collections of keypoints can be matched between two images. Consequently, keypoints can be useful in many applications, such as object localization and image registration.The ideal keypoint detector finds salient image regions such that they are repeatably detected despite change of viewpoint and more generally it is robust to all possible image transformations. Similarly, the ideal keypoint descriptor captures the most important and distinctive information content enclosed in the detected salient regions, such that the same structure can be recognized if encountered."
},

{
    "location": "index.html#Installation-1",
    "page": "Home",
    "title": "Installation",
    "category": "section",
    "text": "Installing the package is extremely easy with julia's package manager -Pkg.add(\"ImageFeatures.jl\")ImageFeatures.jl requires Images.jl."
},

{
    "location": "tutorials/brief.html#",
    "page": "BRIEF",
    "title": "BRIEF",
    "category": "page",
    "text": "BRIEF (Binary Robust Independent Elementary Features) is an efficient feature point descriptor. It is highly discriminative even when using relatively few bits and is computed using simple intensity difference tests. BRIEF does not have a sampling pattern thus pairs can be chosen at any point on the SxS patch.To build a BRIEF descriptor of length n, we need to determine n pairs (Xi,Yi). Denote by X and Y the vectors of point Xi and Yi, respectively.In ImageFeatures.jl we have five methods to determine the vectors X and Y :random_uniform : X and Y are randomly uniformly sampled\ngaussian : X and Y are randomly sampled using a Gaussian distribution, meaning that locations that are closer to the center of the patch are preferred\ngaussian_local : X and Y are randomly sampled using a Gaussian distribution where first X is sampled with a standard deviation of 0.04*S^2 and then the Yi’s are sampled using a Gaussian distribution – Each Yi is sampled with mean Xi and standard deviation of 0.01 * S^2\nrandom_coarse : X and Y are randomly sampled from discrete location of a coarse polar grid\ncenter_sample : For each i, Xi is (0, 0) and Yi takes all possible values on a coarse polar gridAs with all the binary descriptors, BRIEF’s distance measure is the number of different bits between two binary strings which can also be computed as the sum of the XOR operation between the strings.BRIEF is a very simple feature descriptor and does not provide scale or rotation invariance (only translation invariance). To achieve those, see ORB, BRISK and FREAK."
},

{
    "location": "tutorials/brief.html#Example-1",
    "page": "BRIEF",
    "title": "Example",
    "category": "section",
    "text": "Let us take a look at a simple example where the BRIEF descriptor is used to match two images where one has been translated by (100, 200) pixels. We will use the lena_gray image from the TestImages package for this example.Now, let us create the two images we will match using BRIEF.using ImageFeatures, TestImages, Images, ImageDraw, CoordinateTransformations\n\nimg = testimage(\"lena_gray_512\");\nimg1 = Gray.(img);\ntrans = Translation(-100, -200)\nimg2 = warp(img1, trans, indices(img1));\nnothing # hideTo calculate the descriptors, we first need to get the keypoints. For this tutorial, we will use the FAST corners to generate keypoints (see fastcorners.keypoints_1 = Keypoints(fastcorners(img1, 12, 0.4))\nkeypoints_2 = Keypoints(fastcorners(img2, 12, 0.4))\nnothing # hideTo create the BRIEF descriptor, we first need to define the parameters by calling the BRIEF constructor.brief_params = BRIEF(size = 256, window = 10, seed = 123)\nnothing # hideNow pass the image with the keypoints and the parameters to the create_descriptor function.desc_1, ret_keypoints_1 = create_descriptor(img1, keypoints_1, brief_params);\ndesc_2, ret_keypoints_2 = create_descriptor(img2, keypoints_2, brief_params);\nnothing # hideThe obtained descriptors can be used to find the matches between the two images using the match_keypoints function.matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.1)\nnothing # hideWe can use the ImageDraw.jl package to view the results.\ngrid = hcat(img1, img2)\noffset = CartesianIndex(0, size(img1, 2))\nmap(m -> draw!(grid, LineSegment(m[1], m[2] + offset)), matches)\nsave(\"brief_example.jpg\", grid) # hide\nnothing # hide(Image: )"
},

{
    "location": "tutorials/orb.html#",
    "page": "ORB",
    "title": "ORB",
    "category": "page",
    "text": "The ORB descriptor is a somewhat similar to BRIEF. It doesn’t have an elaborate sampling pattern as BRISK or FREAK.However, there are two main differences between ORB and BRIEF:ORB uses an orientation compensation mechanism, making it rotation invariant.\nORB learns the optimal sampling pairs, whereas BRIEF uses randomly chosen sampling pairs.The ORB descriptor uses the intensity centroid as a measure of orientation. To calculate the centroid, we first need to find the moment of a patch, which is given by Mpq = x,yxpyqI(x,y). The centroid, or ‘centre of mass' is then given by C=(M10M00, M01M00).The vector from the corner’s center to the centroid gives the orientation of the patch. Now, the patch can be rotated to some predefined canonical orientation before calculating the descriptor, thus achieving rotation invariance.ORB tries to take sampling pairs which are uncorrelated so that each new pair will bring new information to the descriptor, thus maximizing the amount of information the descriptor carries. We also want high variance among the pairs making a feature more discriminative, since it responds differently to inputs. To do this, we consider the sampling pairs over keypoints in standard datasets and then do a greedy evaluation of all the pairs in order of distance from mean till the number of desired pairs are obtained i.e. the size of the descriptor.The descriptor is built using intensity comparisons of the pairs. For each pair if the first point has greater intensity than the second, then 1 is written else 0 is written to the corresponding bit of the descriptor."
},

{
    "location": "tutorials/orb.html#Example-1",
    "page": "ORB",
    "title": "Example",
    "category": "section",
    "text": "Let us take a look at a simple example where the ORB descriptor is used to match two images where one has been translated by (50, 40) pixels and then rotated by an angle of 75 degrees. We will use the lighthouse image from the TestImages package for this example.First, let us create the two images we will match using ORB.using ImageFeatures, TestImages, Images, ImageDraw, CoordinateTransformations\n\nimg = testimage(\"lighthouse\")\nimg1 = Gray.(img)\nrot = recenter(RotMatrix(5pi/6), [size(img1)...] .÷ 2)  # a rotation around the center\ntform = rot ∘ Translation(-50, -40)\nimg2 = warp(img1, tform, indices(img1))\nnothing # hideThe ORB descriptor calculates the keypoints as well as the descriptor, unlike BRIEF. To create the ORB descriptor, we first need to define the parameters by calling the ORB constructor.orb_params = ORB(num_keypoints = 1000)\nnothing # hideNow pass the image with the parameters to the create_descriptor function.desc_1, ret_keypoints_1 = create_descriptor(img1, orb_params)\ndesc_2, ret_keypoints_2 = create_descriptor(img2, orb_params)\nnothing # hideThe obtained descriptors can be used to find the matches between the two images using the match_keypoints function.matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.2)\nnothing # hideWe can use the ImageDraw.jl package to view the results.\ngrid = hcat(img1, img2)\noffset = CartesianIndex(0, size(img1, 2))\nmap(m -> draw!(grid, LineSegment(m[1], m[2] + offset)), matches)\nsave(\"orb_example.jpg\", grid); nothing # hide\n(Image: )"
},

{
    "location": "tutorials/brisk.html#",
    "page": "BRISK",
    "title": "BRISK",
    "category": "page",
    "text": "The BRISK descriptor has a predefined sampling pattern as compared to BRIEF or ORB. Pixels are sampled over concentric rings. For each sampling point, a small patch is considered around it. Before starting the algorithm, the patch is smoothed using gaussian smoothing.(Image: BRISK Sampling Pattern)Two types of pairs are used for sampling, short and long pairs. Short pairs are those where the distance is below a set threshold distmax while the long pairs have distance above distmin. Long pairs are used for orientation and short pairs are used for calculating the descriptor by comparing intensities.BRISK achieves rotation invariance by trying the measure orientation of the keypoint and rotating the sampling pattern by that orientation. This is done by first calculating the local gradient g(pi,pj) between sampling pair (pi,pj) where I(pj, pj) is the smoothed intensity after applying gaussian smoothing.g(pi, pj) = (pi - pj) . I(pj, j) -I(pj, j)pj - pi2All local gradients between long pairs and then summed and the arctangent(gy/gx) between y and x components of the sum is taken as the angle of the keypoint. Now, we only need to rotate the short pairs by that angle to help the descriptor become more invariant to rotation. The descriptor is built using intensity comparisons. For each short pair if the first point has greater intensity than the second, then 1 is written else 0 is written to the corresponding bit of the descriptor."
},

{
    "location": "tutorials/brisk.html#Example-1",
    "page": "BRISK",
    "title": "Example",
    "category": "section",
    "text": "Let us take a look at a simple example where the BRISK descriptor is used to match two images where one has been translated by (50, 40) pixels and then rotated by an angle of 75 degrees. We will use the lighthouse image from the TestImages package for this example.First, let us create the two images we will match using BRISK.\nusing ImageFeatures, TestImages, Images, ImageDraw, CoordinateTransformations\n\nimg = testimage(\"lighthouse\")\nimg1 = Gray.(img)\nrot = recenter(RotMatrix(5pi/6), [size(img1)...] .÷ 2)  # a rotation around the center\ntform = rot ∘ Translation(-50, -40)\nimg2 = warp(img1, tform, indices(img1))\nnothing # hideTo calculate the descriptors, we first need to get the keypoints. For this tutorial, we will use the FAST corners to generate keypoints (see fastcorners.features_1 = Features(fastcorners(img1, 12, 0.35))\nfeatures_2 = Features(fastcorners(img2, 12, 0.35))\nnothing # hideTo create the BRISK descriptor, we first need to define the parameters by calling the BRISK constructor.brisk_params = BRISK()\nnothing # hideNow pass the image with the keypoints and the parameters to the create_descriptor function.desc_1, ret_features_1 = create_descriptor(img1, features_1, brisk_params)\ndesc_2, ret_features_2 = create_descriptor(img2, features_2, brisk_params)\nnothing # hideThe obtained descriptors can be used to find the matches between the two images using the match_keypoints function.matches = match_keypoints(Keypoints(ret_features_1), Keypoints(ret_features_2), desc_1, desc_2, 0.1)\nnothing # hideWe can use the ImageDraw.jl package to view the results.\ngrid = hcat(img1, img2)\noffset = CartesianIndex(0, size(img1, 2))\nmap(m -> draw!(grid, LineSegment(m[1], m[2] + offset)), matches)\nsave(\"brisk_example.jpg\", grid); nothing # hide\n(Image: )"
},

{
    "location": "tutorials/freak.html#",
    "page": "FREAK",
    "title": "FREAK",
    "category": "page",
    "text": "FREAK has a defined sampling pattern like BRISK. It uses a retinal sampling grid with more density of points near the centre with the density decreasing exponentially with distance from the centre.(Image: FREAK Sampling Pattern)FREAK’s measure of orientation is similar to BRISK but instead of using long pairs, it uses a set of predefined 45 symmetric sampling pairs. The set of sampling pairs is determined using a method similar to ORB, by finding sampling pairs over keypoints in standard datasets and then extracting the most discriminative pairs. The orientation weights over these pairs are summed and the sampling window is rotated by this orientation to some canonical orientation to achieve rotation invariance.The descriptor is built using intensity comparisons of a predetermined set of 512 sampling pairs. This set is also obtained using a method similar to the one described above. For each pair if the first point has greater intensity than the second, then 1 is written else 0 is written to the corresponding bit of the descriptor."
},

{
    "location": "tutorials/freak.html#Example-1",
    "page": "FREAK",
    "title": "Example",
    "category": "section",
    "text": "Let us take a look at a simple example where the FREAK descriptor is used to match two images where one has been translated by (50, 40) pixels and then rotated by an angle of 75 degrees. We will use the lighthouse image from the TestImages package for this example.First, let us create the two images we will match using FREAK.\nusing ImageFeatures, TestImages, Images, ImageDraw, CoordinateTransformations\n\nimg = testimage(\"lighthouse\")\nimg1 = Gray.(img)\nrot = recenter(RotMatrix(5pi/6), [size(img1)...] .÷ 2)  # a rotation around the center\ntform = rot ∘ Translation(-50, -40)\nimg2 = warp(img1, tform, indices(img1))\nnothing # hideTo calculate the descriptors, we first need to get the keypoints. For this tutorial, we will use the FAST corners to generate keypoints (see fastcorners.keypoints_1 = Keypoints(fastcorners(img1, 12, 0.35))\nkeypoints_2 = Keypoints(fastcorners(img2, 12, 0.35))\nnothing # hideTo create the FREAK descriptor, we first need to define the parameters by calling the FREAK constructor.freak_params = FREAK()\nnothing # hideNow pass the image with the keypoints and the parameters to the create_descriptor function.desc_1, ret_keypoints_1 = create_descriptor(img1, keypoints_1, freak_params)\ndesc_2, ret_keypoints_2 = create_descriptor(img2, keypoints_2, freak_params)\nnothing # hideThe obtained descriptors can be used to find the matches between the two images using the match_keypoints function.matches = match_keypoints(ret_keypoints_1, ret_keypoints_2, desc_1, desc_2, 0.1)\nnothing # hideWe can use the ImageDraw.jl package to view the results.\ngrid = hcat(img1, img2)\noffset = CartesianIndex(0, size(img1, 2))\nmap(m -> draw!(grid, LineSegment(m[1], m[2] + offset)), matches)\nsave(\"freak_example.jpg\", grid); nothing # hide\n(Image: )"
},

{
    "location": "tutorials/glcm.html#",
    "page": "Gray level co-occurence matrix",
    "title": "Gray level co-occurence matrix",
    "category": "page",
    "text": "Gray Level Co-occurrence Matrix (GLCM) is used for texture analysis. We consider two pixels at a time, called the reference and the neighbour pixel. We define a particular spatial relationship between the reference and neighbour pixel before calculating the GLCM. For eg, we may define the neighbour to be 1 pixel to the right of the current pixel, or it can be 3 pixels above, or 2 pixels diagonally (one of NE, NW, SE, SW) from the reference.Once a spatial relationship is defined, we create a GLCM of size (Range of Intensities x Range of Intensities) all initialised to 0. For eg, a 8 bit single channel Image will have a 256x256 GLCM. We then traverse through the image and for every pair of intensities we find for the defined spatial relationship, we increment that cell of the matrix.(Image: Gray Level Co-occurence Matrix)Each entry of the GLCM[i,j] holds the count of the number of times that pair of intensities appears in the image with the defined spatial relationship.The matrix may be made symmetrical by adding it to its transpose and normalised to that each cell expresses the probability of that pair of intensities occurring in the image.Once the GLCM is calculated, we can find texture properties from the matrix to represent the textures in the image."
},

{
    "location": "tutorials/glcm.html#GLCM-Properties-1",
    "page": "Gray level co-occurence matrix",
    "title": "GLCM Properties",
    "category": "section",
    "text": "The properties can be calculated over the entire matrix or by considering a window which is moved along the matrix."
},

{
    "location": "tutorials/glcm.html#Mean-1",
    "page": "Gray level co-occurence matrix",
    "title": "Mean",
    "category": "section",
    "text": ""
},

{
    "location": "tutorials/glcm.html#Variance-1",
    "page": "Gray level co-occurence matrix",
    "title": "Variance",
    "category": "section",
    "text": ""
},

{
    "location": "tutorials/glcm.html#Correlation-1",
    "page": "Gray level co-occurence matrix",
    "title": "Correlation",
    "category": "section",
    "text": ""
},

{
    "location": "tutorials/glcm.html#Contrast-1",
    "page": "Gray level co-occurence matrix",
    "title": "Contrast",
    "category": "section",
    "text": ""
},

{
    "location": "tutorials/glcm.html#IDM-(Inverse-Difference-Moment)-1",
    "page": "Gray level co-occurence matrix",
    "title": "IDM (Inverse Difference Moment)",
    "category": "section",
    "text": ""
},

{
    "location": "tutorials/glcm.html#ASM-(Angular-Second-Moment)-1",
    "page": "Gray level co-occurence matrix",
    "title": "ASM (Angular Second Moment)",
    "category": "section",
    "text": ""
},

{
    "location": "tutorials/glcm.html#Entropy-1",
    "page": "Gray level co-occurence matrix",
    "title": "Entropy",
    "category": "section",
    "text": ""
},

{
    "location": "tutorials/glcm.html#Max-Probability-1",
    "page": "Gray level co-occurence matrix",
    "title": "Max Probability",
    "category": "section",
    "text": ""
},

{
    "location": "tutorials/glcm.html#Energy-1",
    "page": "Gray level co-occurence matrix",
    "title": "Energy",
    "category": "section",
    "text": ""
},

{
    "location": "tutorials/glcm.html#Dissimilarity-1",
    "page": "Gray level co-occurence matrix",
    "title": "Dissimilarity",
    "category": "section",
    "text": ""
},

{
    "location": "tutorials/lbp.html#",
    "page": "Local binary patterns",
    "title": "Local binary patterns",
    "category": "page",
    "text": "Local Binary Pattern (LBP) is a very efficient texture operator which labels the pixels of an image by thresholding the neighborhood of each pixel and considers the result as a binary number. The LBP feature vector, in its simplest form, is created in the following manner :(Image: Local Binary Pattern)Divide the examined window into cells (e.g. 16x16 pixels for each cell).\nFor each pixel in a cell, compare the pixel to each of its 8 neighbors (on its left-top, left-middle, left-bottom, right-top, etc.). Follow the pixels along a circle, i.e. clockwise or counterclockwise.\nIn the above step, the neighbours considered can be changed by varying the radius of the circle around the pixel, R and the quantisation of the angular space P.\nWhere the center pixel's value is greater than the neighbor's value, write \"0\". Otherwise, write \"1\". This gives an 8-digit binary number (which is usually converted to decimal for convenience).\nCompute the histogram, over the cell, of the frequency of each \"number\" occurring (i.e., each combination of which pixels are smaller and which are greater than the center). This histogram can be seen as a 256-dimensional feature vector.\nOptionally normalize the histogram.\nConcatenate (normalized) histograms of all cells. This gives a feature vector for the entire window.The feature vector can now then be processed using some machine-learning algorithm to classify images. Such classifiers are often used for face recognition or texture analysis."
},

{
    "location": "tutorials/lbp.html#Types-of-Local-Binary-Patterns-in-ImageFeatures.jl-1",
    "page": "Local binary patterns",
    "title": "Types of Local Binary Patterns in ImageFeatures.jl",
    "category": "section",
    "text": "ImageFeatures.jl provides the following types of local binary patterns :"
},

{
    "location": "tutorials/lbp.html#[lbp](@ref)-1",
    "page": "Local binary patterns",
    "title": "lbp",
    "category": "section",
    "text": "The original local binary patterns"
},

{
    "location": "tutorials/lbp.html#[modified_lbp](@ref)-1",
    "page": "Local binary patterns",
    "title": "modified_lbp",
    "category": "section",
    "text": ""
},

{
    "location": "tutorials/lbp.html#[direction_coded_lbp](@ref)-1",
    "page": "Local binary patterns",
    "title": "direction_coded_lbp",
    "category": "section",
    "text": ""
},

{
    "location": "tutorials/lbp.html#[multi_block_lbp](@ref)-1",
    "page": "Local binary patterns",
    "title": "multi_block_lbp",
    "category": "section",
    "text": ""
},

{
    "location": "tutorials/object_detection.html#",
    "page": "Object Detection using HOG",
    "title": "Object Detection using HOG",
    "category": "page",
    "text": ""
},

{
    "location": "tutorials/object_detection.html#Object-Detection-using-HOG-1",
    "page": "Object Detection using HOG",
    "title": "Object Detection using HOG",
    "category": "section",
    "text": "In this tutorial, we will use Histogram of Oriented Gradient (HOG) feature descriptor based linear SVM to create a person detector. We will first create a person classifier and then use this classifier with a sliding window to identify and localize people in an image.The key challenge in creating a classifier is that it needs to work with variations in illumination, pose and occlusions in the image. To achieve this, we will train the classifier on an intermediate representation of the image instead of the pixel-based representation. Our ideal representation (commonly called feature vector) captures information which is useful for classification but is invariant to small changes in illumination and occlusions. HOG descriptor is a gradient-based representation which is invariant to local geometric and photometric changes (i.e. shape and illumination changes) and so is a good choice for our problem. In fact HOG descriptors are widely used for object detection.Download the script to get the training data here. Download tutorial.zip, decompress it and run get_data.bash. (Change the variable path_to_tutorial in preprocess.jl and path to julia executable in get_data.bash). This script will download the required datasets. We will start by loading the data and computing HOG features of all the images.using Images, ImageFeatures\n\npath_to_tutorial = \"\"\npos_examples = \"path_to_tutorial/tutorial/humans/\"\nneg_examples = \"path_to_tutorial/tutorial/not_humans/\"\n\nn_pos = length(readdir(pos_examples))   # number of positive training examples\nn_neg = length(readdir(neg_examples))   # number of negative training examples\nn = n_pos + n_neg                       # number of training examples \ndata = Array{Float64}(3780, n)          # Array to store HOG descriptor of each image. Each image in our training data has size 128x64 and so has a 3780 length \nlabels = Vector{Int}(n)                 # Vector to store label (1=human, 0=not human) of each image.\n\nfor (i, file) in enumerate([readdir(pos_examples); readdir(neg_examples)])\n    filename = \"$(i <= n_pos ? pos_examples : neg_examples )/$file\"\n    img = load(filename)\n    data[:, i] = create_descriptor(img, HOG())\n    labels[i] = (i <= n_pos ? 1 : 0)\nendBasically we now have an encoded version of images in our training data. This encoding captures useful information but discards extraneous information  (illumination changes, pose variations etc). We will train a linear SVM on this data.using LIBSVM\n\n#Split the dataset into train and test set. Train set = 2500 images, Test set = 294 images.\nrandom_perm = randperm(n)\ntrain_ind = random_perm[1:2500]\ntest_ind = random_perm[2501:end]\n\nmodel = svmtrain(data[:, train_ind], labels[train_ind]);Now let's test this classifier on some images.img = load(\"$pos_examples/per00003.ppm\")\ndescriptor = Array{Float64}(3780, 1)\ndescriptor[:, 1] = create_descriptor(img, HOG())\n\npredicted_label, _ = svmpredict(model, descriptor);\nprint(predicted_label)                          # 1=human, 0=not human\n\n# Get test accuracy of our model\npredicted_labels, decision_values = svmpredict(model, data[:, test_ind]);\n@printf \"Accuracy: %.2f%%\\n\" mean((predicted_labels .== labels[test_ind]))*100 # test accuracy should be > 98%Try testing our trained model on more images. You can see that it performs quite well.(Image: Original) (Image: Original)\npredicted_label = 1 predicted_label = 1(Image: Original) (Image: Original)\npredicted_label = 1 predicted_label = 0Next we will use our trained classifier with a sliding window to localize persons in an image.(Image: Original)img = load(\"path_to_tutorial/tutorial/humans.jpg\")\nrows, cols = size(img)\n\nscores = Array{Float64}(22, 45)\ndescriptor = Array{Float64}(3780, 1)\n\n#Apply classifier using a sliding window approach and store classification score for not-human at every location in score array\nfor j in 32:10:cols-32\n    for i in 64:10:rows-64\n        box = img[i-63:i+64, j-31:j+32]\n        descriptor[:, 1] = create_descriptor(box, HOG())\n        predicted_label, s = svmpredict(model, descriptor);\n        scores[Int((i-64)/10)+1, Int((j-32)/10)+1] = s[1]\n    end\nend(Image: Original)You can see that classifier gave low score to not-human class (i.e. high score to human class) at positions corresponding to humans in the original image.  Below we threshold the image and supress non-minimal values to get the human locations. We then plot the bounding boxes using ImageDraw.using ImageDraw, ImageView\n\nscores[scores.>0] = 0\nobject_locations = findlocalminima(scores)\n\nrectangles = [[((i[2]-1)*10+1, (i[1]-1)*10+1), ((i[2]-1)*10+64, (i[1]-1)*10+1), ((i[2]-1)*10+64, (i[1]-1)*10+128), ((i[2]-1)*10+1, (i[1]-1)*10+128)] for i in object_locations];\n\nfor rec in rectangles\n    draw!(img, Polygon(rec), RGB{N0f8}(0, 0, 1.0))\nend\nimshow(img)(Image: Original)In our example we were lucky that the persons in our image had roughly the same size (128x64) as examples in our train set. We will generally need to take bounding boxes across multiple scales (and multiple aspect ratios for some object classes)."
},

{
    "location": "function_reference.html#",
    "page": "Function reference",
    "title": "Function reference",
    "category": "page",
    "text": ""
},

{
    "location": "function_reference.html#Feature-Extraction-and-Descriptors-1",
    "page": "Function reference",
    "title": "Feature Extraction and Descriptors",
    "category": "section",
    "text": "Below [] in an argument list means an optional argument."
},

{
    "location": "function_reference.html#ImageFeatures.Feature",
    "page": "Function reference",
    "title": "ImageFeatures.Feature",
    "category": "Type",
    "text": "feature = Feature(keypoint, orientation = 0.0, scale = 0.0)\n\nThe Feature type has the keypoint, its orientation and its scale.\n\n\n\n"
},

{
    "location": "function_reference.html#ImageFeatures.Features",
    "page": "Function reference",
    "title": "ImageFeatures.Features",
    "category": "Type",
    "text": "features = Features(boolean_img)\nfeatures = Features(keypoints)\n\nReturns a Vector{Feature} of features generated from the true values in a boolean image or from a list of keypoints.\n\n\n\n"
},

{
    "location": "function_reference.html#ImageFeatures.Keypoint",
    "page": "Function reference",
    "title": "ImageFeatures.Keypoint",
    "category": "Type",
    "text": "keypoint = Keypoint(y, x)\nkeypoint = Keypoint(feature)\n\nA Keypoint may be created by passing the coordinates of the point or from a feature.\n\n\n\n"
},

{
    "location": "function_reference.html#ImageFeatures.Keypoints",
    "page": "Function reference",
    "title": "ImageFeatures.Keypoints",
    "category": "Type",
    "text": "keypoints = Keypoints(boolean_img)\nkeypoints = Keypoints(features)\n\nCreates a Vector{Keypoint} of the true values in a boolean image or from a list of features.\n\n\n\n"
},

{
    "location": "function_reference.html#ImageFeatures.BRIEF",
    "page": "Function reference",
    "title": "ImageFeatures.BRIEF",
    "category": "Type",
    "text": "brief_params = BRIEF([size = 128], [window = 9], [sigma = 2 ^ 0.5], [sampling_type = gaussian], [seed = 123])\n\nArgument Type Description\nsize Int Size of the descriptor\nwindow Int Size of sampling window\nsigma Float64 Value of sigma used for inital gaussian smoothing of image\nsampling_type Function Type of sampling used for building the descriptor (See BRIEF Sampling Patterns)\nseed Int Random seed used for generating the sampling pairs. For matching two descriptors, the seed used to build both should be same.\n\n\n\n"
},

{
    "location": "function_reference.html#ImageFeatures.ORB",
    "page": "Function reference",
    "title": "ImageFeatures.ORB",
    "category": "Type",
    "text": "orb_params = ORB([num_keypoints = 500], [n_fast = 12], [threshold = 0.25], [harris_factor = 0.04], [downsample = 1.3], [levels = 8], [sigma = 1.2])\n\nArgument Type Description\nnum_keypoints Int Number of keypoints to extract and size of the descriptor calculated\nn_fast Int Number of consecutive pixels used for finding corners with FAST. See [fastcorners]\nthreshold Float64 Threshold used to find corners in FAST. See [fastcorners]\nharris_factor Float64 Harris factor k used to rank keypoints by harris responses and extract the best ones\ndownsample Float64 Downsampling parameter used while building the gaussian pyramid. See [gaussian_pyramid] in Images.jl\nlevels Int Number of levels in the gaussian pyramid.  See [gaussian_pyramid] in Images.jl\nsigma Float64 Used for gaussian smoothing in each level of the gaussian pyramid.  See [gaussian_pyramid] in Images.jl\n\n\n\n"
},

{
    "location": "function_reference.html#ImageFeatures.FREAK",
    "page": "Function reference",
    "title": "ImageFeatures.FREAK",
    "category": "Type",
    "text": "freak_params = FREAK([pattern_scale = 22.0])\n\nArgument Type Description\npattern_scale Float64 Scaling factor for the sampling window\n\n\n\n"
},

{
    "location": "function_reference.html#ImageFeatures.BRISK",
    "page": "Function reference",
    "title": "ImageFeatures.BRISK",
    "category": "Type",
    "text": "brisk_params = BRISK([pattern_scale = 1.0])\n\nArgument Type Description\npattern_scale Float64 Scaling factor for the sampling window\n\n\n\n"
},

{
    "location": "function_reference.html#Types-1",
    "page": "Function reference",
    "title": "Types",
    "category": "section",
    "text": "Feature\nFeatures\nKeypoint\nKeypoints\nBRIEF\nORB\nFREAK\nBRISK"
},

{
    "location": "function_reference.html#ImageFeatures.corner_orientations",
    "page": "Function reference",
    "title": "ImageFeatures.corner_orientations",
    "category": "Function",
    "text": "orientations = corner_orientations(img)\norientations = corner_orientations(img, corners)\norientations = corner_orientations(img, corners, kernel)\n\nReturns the orientations of corner patches in an image. The orientation of a corner patch is denoted by the orientation of the vector between intensity centroid and the corner. The intensity centroid can be calculated as C = (m01/m00, m10/m00) where mpq is defined as -\n\n`mpq = (x^p)(y^q)I(y, x) for each p, q in the corner patch`\n\nThe kernel used for the patch can be given through the kernel argument. The default kernel used is a gaussian kernel of size 5x5.\n\n\n\n"
},

{
    "location": "function_reference.html#Corners-1",
    "page": "Function reference",
    "title": "Corners",
    "category": "section",
    "text": "corner_orientations"
},

{
    "location": "function_reference.html#ImageFeatures.random_uniform",
    "page": "Function reference",
    "title": "ImageFeatures.random_uniform",
    "category": "Function",
    "text": "sample_one, sample_two = random_uniform(size, window, seed)\n\nBuilds sampling pairs using random uniform sampling.\n\n\n\n"
},

{
    "location": "function_reference.html#ImageFeatures.random_coarse",
    "page": "Function reference",
    "title": "ImageFeatures.random_coarse",
    "category": "Function",
    "text": "sample_one, sample_two = random_coarse(size, window, seed)\n\nBuilds sampling pairs using random sampling over a coarse grid.\n\n\n\n"
},

{
    "location": "function_reference.html#ImageFeatures.gaussian",
    "page": "Function reference",
    "title": "ImageFeatures.gaussian",
    "category": "Function",
    "text": "sample_one, sample_two = gaussian(size, window, seed)\n\nBuilds sampling pairs using gaussian sampling.\n\n\n\n"
},

{
    "location": "function_reference.html#ImageFeatures.gaussian_local",
    "page": "Function reference",
    "title": "ImageFeatures.gaussian_local",
    "category": "Function",
    "text": "sample_one, sample_two = gaussian_local(size, window, seed)\n\nPairs (Xi, Yi) are randomly sampled using a Gaussian distribution where first X is sampled with a standard deviation of 0.04*S^2 and then the Yi’s are sampled using a Gaussian distribution – Each Yi is sampled with mean Xi and standard deviation of 0.01 * S^2\n\n\n\n"
},

{
    "location": "function_reference.html#ImageFeatures.center_sample",
    "page": "Function reference",
    "title": "ImageFeatures.center_sample",
    "category": "Function",
    "text": "sample_one, sample_two = center_sample(size, window, seed)\n\nBuilds sampling pairs (Xi, Yi) where Xi is (0, 0) and Yi is sampled uniformly from the window.\n\n\n\n"
},

{
    "location": "function_reference.html#BRIEF-Sampling-Patterns-1",
    "page": "Function reference",
    "title": "BRIEF Sampling Patterns",
    "category": "section",
    "text": "random_uniform\nrandom_coarse\ngaussian\ngaussian_local\ncenter_sample"
},

{
    "location": "function_reference.html#Feature-Extraction-1",
    "page": "Function reference",
    "title": "Feature Extraction",
    "category": "section",
    "text": ""
},

{
    "location": "function_reference.html#ImageFeatures.create_descriptor",
    "page": "Function reference",
    "title": "ImageFeatures.create_descriptor",
    "category": "Function",
    "text": "desc, keypoints = create_descriptor(img, keypoints, params)\ndesc, keypoints = create_descriptor(img, params)\n\nCreate a descriptor for each entry in keypoints from the image img. params specifies the parameters for any of several descriptors:\n\nBRIEF\nORB\nBRISK\nFREAK\nHOG\n\nSome descriptors support discovery of the keypoints from fastcorners.\n\n\n\n"
},

{
    "location": "function_reference.html#Feature-Description-1",
    "page": "Function reference",
    "title": "Feature Description",
    "category": "section",
    "text": "create_descriptor"
},

{
    "location": "function_reference.html#ImageFeatures.hamming_distance",
    "page": "Function reference",
    "title": "ImageFeatures.hamming_distance",
    "category": "Function",
    "text": "distance = hamming_distance(desc_1, desc_2)\n\nCalculates the hamming distance between two descriptors.\n\n\n\n"
},

{
    "location": "function_reference.html#ImageFeatures.match_keypoints",
    "page": "Function reference",
    "title": "ImageFeatures.match_keypoints",
    "category": "Function",
    "text": "matches = match_keypoints(keypoints_1, keypoints_2, desc_1, desc_2, threshold = 0.1)\n\nFinds matched keypoints using the hamming_distance function having distance value less than threshold.\n\n\n\n"
},

{
    "location": "function_reference.html#Feature-Matching-1",
    "page": "Function reference",
    "title": "Feature Matching",
    "category": "section",
    "text": "hamming_distance\nmatch_keypoints"
},

{
    "location": "function_reference.html#Texture-Matching-1",
    "page": "Function reference",
    "title": "Texture Matching",
    "category": "section",
    "text": ""
},

{
    "location": "function_reference.html#Gray-Level-Co-occurence-Matrix-1",
    "page": "Function reference",
    "title": "Gray Level Co-occurence Matrix",
    "category": "section",
    "text": "glcm\nglcm_symmetric\nglcm_norm\nglcm_prop\nmax_prob\ncontrast\nASM\nIDM\nglcm_entropy\nenergy\ndissimilarity\ncorrelation\nglcm_mean_ref\nglcm_mean_neighbour\nglcm_var_ref\nglcm_var_neighbour"
},

{
    "location": "function_reference.html#Local-Binary-Patterns-1",
    "page": "Function reference",
    "title": "Local Binary Patterns",
    "category": "section",
    "text": "lbp\nmodified_lbp\ndirection_coded_lbp\nlbp_original\nlbp_uniform\nlbp_rotation_invariant\nmulti_block_lbp"
},

]}
