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
end
