using ImageFeatures

@testset "Hough_Transform" begin
    @testset "Hough Line Transform" begin

    #For images containing a straight line parallel to axes
        img = zeros(Bool,10,10)
        for i in 1:size(img)[1]
            for j in 1:size(img)[2]
                img[i,j] = true
            end
            h = hough_transform_standard(img,1,linspace(0,π/2,100),9,2)
            @test length(h) == 1
            @test h[1][1] == i
            for j in 1:size(img)[2]
                img[i,j] = false
            end
        end

    #For images with diagonal line
        img = diagm([true, true ,true])
        h = hough_transform_standard(img,1,linspace(0,π,100),2,3)
        @test length(h) == 1
        @test h[1][1] == 0

    #For a square image
        img = zeros(Bool,10,10)
        for i in 1:10
            img[2,i] = img[i,2] = img[7,i] = img[i,9] = true
        end
        h = hough_transform_standard(img,1,linspace(0,π/2,100),9,10)
        @test length(h) == 4
        r = [h[i][1] for i in CartesianRange(size(h))]
        @test all(r .== [2,2,7,9])
        theta = [h[i][2] for i in CartesianRange(size(h))]
        er = sum(map((t1,t2) -> abs(t1-t2), theta, [0, π/2, π/2, 0]))
        @test er <= 0.1
    end

    @testset "Hough Line Probabilistic" begin
        #one horizontal line segment with few scattered points 
        img = zeros(Bool,20,20)
        for j in 5:15
            img[15,j] = true
        end

        srand(1234)
        for k in 1:5
            img[rand(1:13),rand(6:14)] = true
        end
        lines = hough_line_probabilistic(img, 1, linspace(0,π,180),7,5,10,4)
        @test length(lines) == 1
        @test lines[1] == (15,5,15,15)

        #for a square image
        img = zeros(Bool, 20, 20)

        for i in (3,14)
            for j in 3:14
                img[i,j] = true
            end
        end     

        for i in (3,14)
            for j in 3:14
                img[j,i] = true
            end
        end
        srand(1234)
        for k in 1:4
            img[rand(6:10),rand(6:10)] = true
        end
        lines = hough_line_probabilistic(img, 1, linspace(0,π,180),9,7,15,4)
        lines_ = [line for line in lines]
        @test length(lines) == 4
        @test all(lines_ == [(3, 3, 3, 14), (14, 3, 14, 14), (13, 14, 4, 14), (13, 3, 4, 3)])
        
    end

    @testset "Hough Circle Gradient" begin

    dist(a, b) = sqrt(sum(abs2, (a-b).I))

    img=zeros(Int, 300, 300)
    for i in CartesianRange(size(img))
        if dist(i, CartesianIndex(100, 100))<25 || dist(i, CartesianIndex(200, 200))<50
            img[i]=1
        else
            img[i]=0
        end
    end

    img_edges = canny(img, (0.2, 0.1) ,1)
    dx, dy=imgradients(img, KernelFactors.ando3)
    img_phase = phase(dx, dy)

    centers, radii=hough_circle_gradient(img_edges, img_phase, 1, 40, 40, 5:75)

    @test dist(centers[1], CartesianIndex(200,200))<5
    @test dist(centers[2], CartesianIndex(100,100))<5
    @test abs(radii[1]-50)<5
    @test abs(radii[2]-25)<5

    end
end
