using ImageFeatures

@testset "Hough_Transform" begin
    @testset "Hough Line Transform" begin

    #For images containing a straight line parallel to axes
        img = zeros(Bool,10,10)
        for i in 1:size(img)[1]
            for j in 1:size(img)[2]
                img[i,j] = true
            end
            h = hough_transform_standard(img,1,0.1,0,3.14,9,2)
            @test length(h) == 1
            @test h[1][1] == i
            for j in 1:size(img)[2]
                img[i,j] = false
            end
        end
    #For images with diagonal line
        img = diagm([true, true ,true])
        h = hough_transform_standard(img,1,0.1,0,3.14,2,3)
        @test length(h) == 1
        @test h[1][1] == 0
    end
end