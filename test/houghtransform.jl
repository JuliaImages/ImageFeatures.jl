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

    @testset "Hough Circle Gradient" begin

    dist(a, b) = sqrt(sum(abs2, (a-b).I))

    img=zeros(Integer, 300, 300)
    for i in CartesianRange(size(img))
        if dist(i, CartesianIndex(100, 100))<25 || dist(i, CartesianIndex(200, 200))<50
            img[i]=255
        else
            img[i]=0
        end
    end

    centers, radii=hough_circle_gradient(img, 1, 40, 0.8, 40, 5, 75)

    @test dist(centers[1], CartesianIndex(200,200))<5
    @test dist(centers[2], CartesianIndex(100,100))<5
    @test abs(radii[1]-50)<5
    @test abs(radii[2]-25)<5

    end
end
