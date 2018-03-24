using Images

"""
```
lines = hough_transform_standard(image, ρ, θ, threshold, linesMax)
```

Returns a vector of tuples corresponding to the tuples of (r,t)
where r and t are parameters for normal form of line:
    `x \* cos(t) + y \* sin(t) = r`

-   `r` = length of perpendicular from (1,1) to the line
-   `t` = angle between perpendicular from (1,1) to the line and x-axis

The lines are generated by applying hough transform on the image.

Parameters:
-    `image`       = Image to be transformed (eltype should be `Bool`)
-    `ρ`           = Discrete step size for perpendicular length of line
-    `θ`           = List of angles for which the transform is computed
-    `threshold`   = Accumulator threshold for line detection
-    `linesMax`    = Maximum no of lines to return

# Example
```julia
julia> img = load("line.jpg");

julia> img_edges = canny(img, (Percentile(0.99), Percentile(0.97)), 1);

julia> lines = hough_transform_standard(img_edges, 1, linspace(0,π,30), 40, 5)
5-element Array{Tuple{Float64,Float64},1}:
 (45.0,1.73329)  
 (1.0,1.73329)   
 (32.0,1.73329)  
 (209.0,0.649985)
 (-9.0,2.49161) 
```
"""

function hough_transform_standard(
img::AbstractArray{T,2},
ρ::Real, θ::Range,
threshold::Integer, linesMax::Integer) where T<:Union{Bool,Gray{Bool}}


    #function to compute local maximum lines with values > threshold and return a vector containing them
    function findlocalmaxima!(validLines::AbstractVector{CartesianIndex{2}}, accumulator_matrix::Array{Int,2}, threshold::T) where T<:Integer
        for val in CartesianRange(size(accumulator_matrix))
            if  accumulator_matrix[val] >  threshold                             &&
                accumulator_matrix[val] >  accumulator_matrix[val[1],val[2] - 1] &&
                accumulator_matrix[val] >= accumulator_matrix[val[1],val[2] + 1] &&
                accumulator_matrix[val] >  accumulator_matrix[val[1] - 1,val[2]] &&
                accumulator_matrix[val] >= accumulator_matrix[val[1] + 1,val[2]]
                push!(validLines,val)
            end
        end
    end

    ρ > 0 || error("Discrete step size must be positive")

    indsy, indsx = indices(img)
    ρinv = 1 / ρ
    numangle = length(θ)
    numrho = round(Int,(2(length(indsx) + length(indsy)) + 1)*ρinv)

    accumulator_matrix = zeros(Int, numangle + 2, numrho + 2)

    #Pre-Computed sines and cosines in tables
    sinθ, cosθ = sin.(θ).*ρinv, cos.(θ).*ρinv

    #Hough Transform implementation
    constadd = round(Int,(numrho -1)/2)
    for pix in CartesianRange(size(img))
        if img[pix]
            for i in 1:numangle
                dist = round(Int, pix[1] * sinθ[i] + pix[2] * cosθ[i])
                dist += constadd
                accumulator_matrix[i + 1, dist + 1] += 1
            end
        end
    end

    #Finding local maximum lines
    validLines = Vector{CartesianIndex{2}}(0)
    findlocalmaxima!(validLines, accumulator_matrix, threshold)

    #Sorting by value in accumulator_matrix
    @noinline sort_by_votes(validLines, accumulator_matrix) = sort!(validLines, lt = (a,b)-> accumulator_matrix[a]>accumulator_matrix[b])
    sort_by_votes(validLines, accumulator_matrix)

    linesMax = min(linesMax, length(validLines))

    lines = Vector{Tuple{Float64,Float64}}(0)

    #Getting lines with Maximum value in accumulator_matrix && size(lines) < linesMax
    for l in 1:linesMax
        lrho = ((validLines[l][2]-1) - (numrho-1)*0.5)*ρ
        langle = θ[validLines[l][1]-1]
        push!(lines,(lrho,langle))
    end

    lines

end

"""
```
lines = hough_line_probabilistic(image, ρ, θ, threshold, lineLength, lineGap, linesMax)
```

Returns lines :
      vector of lines identified, lines in format ((r0, c0), (r1, c1))
      indicating line start and end.

The lines are generated by applying hough transform on the image.

Parameters:
-    `image`       = Image to be transformed (eltype should be `Bool`)
-    `ρ`           = Discrete step size for perpendicular length of line
-    `θ`           = List of angles for which the transform is computed
-    `threshold`   = Accumulator threshold for line detection
-    'lineLength'  = minimum length of a good_line
-    'lineGap'     = minimum gap between two different lines.
-    `linesMax`    = Maximum no of lines to return

# Example
```julia
julia> img = load("line.jpg");

julia> img_edges = canny(img, (Percentile(0.99), Percentile(0.97)), 1);

julia> lines = hough_line_probabilistic(img_edges, 1, linspace(0,π,180),30,30,10,10)
10-element Array{NTuple{4,Int64},1}:
 (186, 283, 20, 283) 
 (186, 20, 20, 20)   
 (200, 218, 200, 291)
 (20, 68, 20, 180)   
 (186, 85, 186, 197) 
 (48, 59, 69, 199)   
 (50, 58, 65, 160)   
 (200, 35, 200, 147) 
 (20, 186, 20, 282)  
 (155, 138, 75, 198)  
```
May use LineSegment of ImageDraw to draw lines.

References
    ----------
    .. [1] C. Galamhos, J. Matas and J. Kittler, "Progressive probabilistic
           Hough transform for line detection", in IEEE Computer Society
           Conference on Computer Vision and Pattern Recognition, 1999.
"""
type Param
       numangle::Int64
       constadd::Float64
       accumulator_matrix::AbstractArray{Int64, 2}
       mask::AbstractArray{Bool, 2}
       nzloc::Vector{Tuple{Int64,Int64}}
       lines::Vector{Tuple{Int64, Int64, Int64, Int64}}
       shift::Int64
       threshold::Int64
       lineLength::Int64
       lineGap::Int64
end

type Sample
    x0::Int64
    y0::Int64
    dx0::Int64
    dy0::Int64
end    

#function to mark and collect all non zero points
function collect_points(params, img)
    for pix in CartesianRange(size(img))
        pix1 = (pix[1], pix[2])
        if(img[pix])
            push!(params.nzloc, pix1)
            params.mask[pix] = true
        else
            params.mask[pix] = false
        end
    end
end    

#function to update the accumulator matrix for every point selected
function update_accumulator(params, point, sinθ, cosθ)
    max_n = 1
    max_val = params.threshold-1
    for n in 0:params.numangle-1
            dist = point[2]*cosθ[n+1] + point[1]*sinθ[n+1]
            dist += params.constadd
            dist = Int64(floor(dist))
            params.accumulator_matrix[n+1 , dist + 1] += 1
            val = params.accumulator_matrix[n+1 , dist + 1]
            if(max_val < val)
                max_val = val
                max_n = n+1
            end    
    end
    return max_n, max_val
end    

#function to detect the line segment after merging lines within lineGap
function pass_1(img, params, sample, xflag)
    line_end = [[0,0],[0,0]]
    h, w = size(img)
    for k = 1:2
        gap = 0
        x = sample.x0
        y = sample.y0
        dx = sample.dx0
        dy = sample.dy0

        if k>1
            dx = -dx
            dy = -dy
        end
        
        while(true)
            i1 = 0
            j1 = 0
            if(xflag==1)
                j1 = x
                i1 = y>>params.shift
            else
                j1 = x>>params.shift
                i1 = y
            end

            # check when line exits image boundary
            if( j1 < 0 || j1 >= w || i1 < 0 || i1 >= h )
                break;
            end
            gap+=1

            # if non-zero point found, continue the line
            if(params.mask[i1+1, j1+1])
                gap = 0
                line_end[k][1] = i1+1
                line_end[k][2] = j1+1
             # if gap to this point was too large, end the line    
            elseif(gap > params.lineGap)
                break
            end
            x = Int64(x+dx)
            y = Int64(y+dy)
        end
    end
    return line_end
end

#function to reset the mask and accumulator_matrix 
function pass_2(params, sample, xflag, good_line, line_end, sinθ, cosθ)
    for k = 1:2
        x = sample.x0
        y = sample.y0
        dx = sample.dx0
        dy = sample.dy0

        if k>1
            dx = -dx
            dy = -dy
        end

        # walk along the line using fixed-point arithmetics,
        while(true)
            i1, j1 = 0,0

            if (xflag==1)
                j1 = x
                i1 = y >> params.shift
            else
                j1 = x >> params.shift
                i1 = y
            end

            # if non-zero point found, continue the line
            if(params.mask[i1+1, j1+1])
                if(good_line)
                    for n = 0:params.numangle-1
                        r = ((j1+1)*cosθ[n+1] + (i1+1)*sinθ[n+1])
                        r = Int64(floor(r+params.constadd))
                        params.accumulator_matrix[n+1, r+1]-=1
                        params.mask[i1+1, j1+1] = false
                    end
                end
            end
            # exit when the point is the line end                
            if((i1+1) == line_end[k][1] && (j1+1) == line_end[k][2])
                break
            end
            x = Int64(x+dx)
            y = Int64(y+dy)              
        end
    end
end    

function hough_line_probabilistic(
img::AbstractArray{T,2},
ρ::Real, θ::Range,
threshold::Integer, lineLength::Integer, lineGap::Integer, linesMax::Integer) where T<:Union{Bool,Gray{Bool}}
  
    ρ > 0 || throw(ArgumentError("Discrete step size must be positive"))
    indsy, indsx = indices(img)
    ρinv = 1 / ρ
    numangle = length(θ)
    numrho = round(Int,(2(length(indsx) + length(indsy)) + 1)*ρinv) 
    constadd = (numrho-1)/2
    accumulator_matrix = zeros(Int, numangle + 2, numrho + 2)
    h, w = size(img)
    mask = zeros(Bool, h, w)
    #Pre-Computed sines and cosines in tables
    sinθ, cosθ = sin.(θ).*ρinv, cos.(θ).*ρinv
    nzloc = Vector{Tuple{Int64,Int64}}(0)
    lines = Vector{Tuple{Int64, Int64, Int64, Int64}}(0)
    params = Param(numangle, constadd, accumulator_matrix, mask, nzloc, lines, 16, threshold, lineLength, lineGap)
    sample = Sample(0,0,0,0)

    #collect non-zero image points
    collect_points(params, img)

    count_ = size(nzloc)[1]+1

    # stage 2. process all the points in random order
    while(count_>1)
        count_-=1
        good_line = false
        # choose random point out of the remaining ones
        idx = rand(1:count_)
        max_n = 1
        point = nzloc[idx]
        i, j = point[1]-1, point[2]-1    
        sample.x0, sample.y0, sample.dx0, sample.dy0, xflag = 0, 0, 0, 0, 0
        max_n = 1

        # "remove" it by overriding it with the last element
        params.nzloc[idx] = params.nzloc[count_]

        if(!(params.mask[point[1], point[2]]))
            continue
        end
        
        # update accumulator, find the most probable line
        max_n, max_val = update_accumulator(params, point, sinθ, cosθ)

        # if it is too "weak" candidate, continue with another point
        if(max_val < params.threshold)
            continue
        end
        
        # from the current point walk in each direction along the found line
        a = -sinθ[max_n]
        b = cosθ[max_n]
        sample.x0 = j
        sample.y0 = i
        good_line = false

        if(abs(a) > abs(b))
            xflag = 1
            sample.dx0 = a > 0 ? 1 : -1
            sample.dy0 = round(b*(1 << params.shift)/abs(a))
            sample.y0 = (sample.y0 << params.shift) + (1 << (params.shift-1))
        else
            xflag = 0
            sample.dy0 = b > 0 ? 1 : -1
            sample.dx0 = round( a*(1 << params.shift)/abs(b) );
            sample.x0 = (sample.x0 << params.shift) + (1 << (params.shift-1));    
        end   

        # pass 1: walk the line, merging lines less than specified gap length
        line_end = pass_1(img, params, sample, xflag)

        # confirm line length is sufficient
        good_line = abs(line_end[2][1] - line_end[1][1]) >= lineLength || abs(line_end[2][2] - line_end[1][2]) >= lineLength              

        # pass 2: walk the line again and reset accumulator and mask
        pass_2(params, sample, xflag, good_line, line_end, sinθ, cosθ) 

        # add line to the result
        if(good_line)
            push!(lines, (line_end[1][1], line_end[1][2], line_end[2][1], line_end[2][2]))

            if(size(lines)[1] >= linesMax)
                return lines
            end
        end         
    end
    return lines        
end

"""
```
circle_centers, circle_radius = hough_circle_gradient(img_edges, img_phase, scale, min_dist, vote_thres, min_radius:max_radius)  
```
Returns two vectors, corresponding to circle centers and radius.  
  
The circles are generated using a hough transform variant in which a non-zero point only votes for circle  
centers perpendicular to the local gradient. In case of concentric circles, only the largest circle is detected.
  
Parameters:  
-   `img_edges`    = edges of the image  
-   `img_phase`    = phase of the gradient image   
-   `scale`        = relative accumulator resolution factor  
-   `min_dist`     = minimum distance between detected circle centers  
-   `vote_thres`   = accumulator threshold for circle detection  
-   `min_radius:max_radius`   = circle radius range

[`canny`](@ref) and [`phase`](@ref) can be used for obtaining img_edges and img_phase respectively.

# Example
```julia
img = load("circle.png")

img_edges = canny(img, 1, 0.99, 0.97)
dx, dy=imgradients(img, KernelFactors.ando5)
img_phase = phase(dx, dy)

centers, radii=hough_circle_gradient(img_edges, img_phase, 1, 60, 60, 3:50)
```
"""  

function hough_circle_gradient(
        img_edges::AbstractArray{Bool,2}, img_phase::AbstractArray{T,2},
        scale::Number, min_dist::Number,
        vote_thres::Number, radii::AbstractVector{Int}) where T<:Number

    rows,cols=size(img_edges)

    non_zeros=CartesianIndex{2}[]
    centers=CartesianIndex{2}[]
    circle_centers=CartesianIndex{2}[]
    circle_radius=Int[]
    accumulator_matrix=zeros(Int, Int(floor(rows/scale))+1, Int(floor(cols/scale))+1)

    function vote!(accumulator_matrix, x, y)
        fx = Int(floor(x))
        fy = Int(floor(y))

        for i in fx:fx+1
            for j in fy:fy+1
                if checkbounds(Bool, accumulator_matrix, i, j)
                    @inbounds accumulator_matrix[i, j] += 1
                end
            end
        end
    end

    for j in indices(img_edges, 2)
        for i in indices(img_edges, 1)
            if img_edges[i,j]
                sinθ = -cos(img_phase[i,j]);
                cosθ = sin(img_phase[i,j]);

                for r in radii
                    x=(i+r*sinθ)/scale
                    y=(j+r*cosθ)/scale
                    vote!(accumulator_matrix, x, y)

                    x=(i-r*sinθ)/scale
                    y=(j-r*cosθ)/scale
                    vote!(accumulator_matrix, x, y)
                end
                push!(non_zeros, CartesianIndex{2}(i,j));
            end
        end
    end

    for i in findlocalmaxima(accumulator_matrix)
        if accumulator_matrix[i]>vote_thres
            push!(centers, i);
        end
    end

    @noinline sort_by_votes(centers, accumulator_matrix) = sort!(centers, lt=(a, b) -> accumulator_matrix[a]>accumulator_matrix[b])

    sort_by_votes(centers, accumulator_matrix)

    dist(a, b) = sqrt(sum(abs2, (a-b).I))

    f = CartesianIndex(map(r->first(r), indices(accumulator_matrix)))
    l = CartesianIndex(map(r->last(r), indices(accumulator_matrix)))
    radius_accumulator=Vector{Int}(Int(floor(dist(f,l)/scale)+1))

    for center in centers
        center=(center-1)*scale
        fill!(radius_accumulator, 0)

        too_close=false
        for circle_center in circle_centers
            if dist(center, circle_center)< min_dist
                too_close=true
                break
            end
        end
        if too_close
            continue;
        end

        for point in non_zeros
            r=Int(floor(dist(center, point)/scale))
            if radii.start/scale<=r<=radii.stop/scale
                radius_accumulator[r+1]+=1
            end
        end

        voters, radius = findmax(radius_accumulator)
        radius=(radius-1)*scale;

        if voters>vote_thres
            push!(circle_centers, center)
            push!(circle_radius, radius)
        end
    end
    return circle_centers, circle_radius
end

