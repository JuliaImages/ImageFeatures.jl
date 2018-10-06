using ImageFeatures

function random_circle_example()
    dims = rand(100:200,2)
    img = zeros(dims...)
    r = rand(10:20)
    x,y = rand(20:80,2)
    for i in axes(img)[1]
        for j in axes(img)[2]
            if (x-i)^2 + (y-j)^2 <= r^2
                img[i,j] = 1
            end
        end
    end
    img, [x,y], r
end

@testset "Hough_Transform" begin
    @testset "Hough Line Transform" begin

    #For images containing a straight line parallel to axes
        for i in 1:9
            img = zeros(Bool,9,9)
            img[i,:] .= true
            h = hough_transform_standard(img)
            @test length(h) == 1
            line = first(h)
            @test line == (i, pi/2)
        end

    #For images with diagonal line
        img = Matrix(Diagonal([true, true ,true]))
        h = hough_transform_standard(img, angles=range(0,stop=pi,length=100))
        @test length(h) == 1
        @test h[1][1] == 0

    #For a square image
        img = zeros(Bool,10,10)
        for i in 1:10
            img[2,i] = img[i,2] = img[7,i] = img[i,9] = true
        end
        # h = hough_transform_standard(img,1,
        h = hough_transform_standard(img, angles=range(0,stop=π/2,length=100))
        @test length(h) == 4
        r = [h[i][1] for i in CartesianIndices(size(h))]
        @test all(r .== [2,2,7,9])
        theta = [h[i][2] for i in CartesianIndices(size(h))]
        er = sum(map((t1,t2) -> abs(t1-t2), theta, [0, π/2, π/2, 0]))
        @test er <= 0.1
    end

    @testset "Hough Circle Gradient" begin
        for _ in 1:10
            img, c_truth, r_truth = random_circle_example()
            img_edges = canny(img, (Percentile(80), Percentile(20)))
            dx, dy=imgradients(img, KernelFactors.ando5)
            img_phase = phase(dx, dy)
            radii = 10:20
            centers, rs = hough_circle_gradient(img_edges, img_phase, radii)
            @test length(centers) == length(rs) == 1
            c_hough = [Tuple(first(centers))...]
            r_hough = first(rs)
            @test r_hough ≈ r_truth atol=4
            @test c_hough ≈ c_truth atol=4
        end
    end
end
