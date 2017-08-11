using Base.Test, ImageFeatures, Images

@testset "HOG Feature" begin
    img = rand(128, 64)
    @test length(create_descriptor(img, HOG())) == 3780

    img = rand(RGB, 128, 64)
    @test length(create_descriptor(img, HOG())) == 3780
end
