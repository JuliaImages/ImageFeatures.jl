using Test, ImageFeatures, Images
import ImageFeatures.trilinear_interpolate!

@testset "HOG Feature" begin
    img = rand(128, 64)
    @test length(create_descriptor(img, HOG())) == 3780

    img = rand(RGB, 128, 64)
    @test length(create_descriptor(img, HOG())) == 3780

    img = zeros(128, 64)
    img[64, :] .= 1
    @test length(create_descriptor(img, HOG())) == 3780

    #tests for function trilinear_interpolate!
    rows = 12
    cols = 12
    cell_size = 4
    cell_rows::Int = rows/cell_size
    cell_cols::Int = cols/cell_size
    orientations = 9

    hist = zeros(9, 3, 3)
    trilinear_interpolate!(hist, 1, 170, orientations, CartesianIndex(1, 1), cell_size, cell_rows, cell_cols, rows, cols)
    @test hist[1, 1, 1] == hist[9, 1, 1] == 0.5

    hist = zeros(9, 3, 3)
    trilinear_interpolate!(hist, 1, 150, orientations, CartesianIndex(1, 4), cell_size, cell_rows, cell_cols, rows, cols)
    @test hist[8, 1, 1] == hist[9, 1, 1] == hist[8, 1, 2] == hist[9, 1, 2] == 0.25

    hist = zeros(9, 3, 3)
    trilinear_interpolate!(hist, 1, 145, orientations, CartesianIndex(4, 4), cell_size, cell_rows, cell_cols, rows, cols)
    @test hist[8, 1, 1] == hist[8, 1, 2] == hist[8, 2, 1] == hist[8, 2, 2] == 0.1875
    @test hist[9, 1, 1] == hist[9, 1, 2] == hist[9, 2, 1] == hist[9, 2, 2] == 0.0625
end
