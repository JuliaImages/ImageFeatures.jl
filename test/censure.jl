using Images, Base.Test, ImageFeatures

@testset "CENSURE" begin

	@testset "Filters" begin

		bf = BoxFilter(1)
		@test bf.scale == 1
		@test bf.in_length == 3
		@test bf.out_length == 5
		@test bf.in_area == 9.0
		@test bf.out_area == 25.0
		@test isapprox(bf.in_weight, 1 / 9) == true
		@test isapprox(bf.out_weight, 1 / 16) == true
		bf = BoxFilter(5)
		@test bf.scale == 5
		@test bf.in_length == 11
		@test bf.out_length == 21
		@test bf.in_area == 121.0
		@test bf.out_area == 441.0
		@test isapprox(bf.in_weight, 1 / 121) == true
		@test isapprox(bf.out_weight, 1 / 320) == true

		of = OctagonFilter(5, 3, 2, 0)
		@test of.m_out == 5
		@test of.m_in == 3
		@test of.n_out == 2
		@test of.n_in == 0
		@test of.in_area == 9.0
		@test of.out_area == 73.0
		@test isapprox(of.in_weight, 1 / 9) == true
		@test isapprox(of.out_weight, 1 / 64) == true

		of = OctagonFilter(13, 5, 7, 4)
		@test of.m_out == 13
		@test of.m_in == 5
		@test of.n_out == 7
		@test of.n_in == 4
		@test of.in_area == 137.0
		@test of.out_area == 631.0
		@test isapprox(of.in_weight, 1 / 137) == true
		@test isapprox(of.out_weight, 1 / 494) == true

	end

	@testset "Integral Image" begin

		img = ones(5, 5)
		bf = BoxFilter(1)
		@test all(integral_image(img) .== ImageFeatures._get_integral_image(img, bf)) == true

		of = OctagonFilter(5, 3, 2, 0)
		i, rs, ls = ImageFeatures._get_integral_image(img, of)
		@test all(i .== integral_image(img)) == true
		r_check =  [ 1.0   2.0   3.0   4.0   5.0
					  3.0   5.0   7.0   9.0  10.0
					  6.0   9.0  12.0  14.0  15.0
					 10.0  14.0  17.0  19.0  20.0
					 15.0  19.0  22.0  24.0  25.0 ]
		@test all(rs .== r_check) == true
		l_check = [ 1.0  2.0  3.0   4.0   5.0
					 1.0  3.0  5.0   7.0   9.0
					 1.0  3.0  6.0   9.0  12.0
					 1.0  3.0  6.0  10.0  14.0
					 1.0  3.0  6.0  10.0  15.0 ]
		@test all(ls .== l_check) == true

	end

	@testset "Filter Response" begin

		img = [4.0 2.0 6.0 1.0 1.0 8.0 2.0; 
			9.0 3.0 8.0 3.0 5.0 8.0 4.0; 
			4.0 10.0 6.0 2.0 5.0 1.0 5.0; 
			10.0 5.0 8.0 6.0 6.0 3.0 3.0; 
			5.0 6.0 4.0 8.0 3.0 3.0 9.0; 
			3.0 1.0 5.0 6.0 2.0 2.0 2.0; 
			9.0 3.0 4.0 1.0 10.0 8.0 6.0]
		bf = BoxFilter(1)
		response = ImageFeatures._filter_response(ImageFeatures._get_integral_image(img, bf), bf)
		@test isapprox(response[4, 4], -0.895833, rtol = 0.001) == true
		@test isapprox(response[4, 5], 0.888889, rtol = 0.001) == true
		@test isapprox(response[5, 4], -0.958333, rtol = 0.001) == true
		@test isapprox(response[5, 5], 0.604167, rtol = 0.001) == true
		@test all(response[:, 1:3] .== 0) == true 
		@test all(response[1:3, :] .== 0) == true
		@test all(response[:, 6:6] .== 0) == true 
		@test all(response[6:7, :] .== 0) == true 

		img = [  3.0   5.0  8.0   8.0   5.0  4.0   1.0
			  3.0   8.0  6.0  10.0   1.0  5.0   4.0
			 10.0   1.0  6.0   4.0  10.0  4.0   5.0
			  2.0  10.0  9.0   4.0   5.0  3.0   7.0
			  1.0   7.0  5.0   9.0   7.0  6.0   3.0
			  5.0   6.0  9.0   9.0   1.0  4.0   8.0
			  2.0   4.0  6.0   9.0   8.0  4.0  10.0]
		response = ImageFeatures._filter_response(ImageFeatures._get_integral_image(img, bf), bf)
		@test isapprox(response[4, 4], -0.93056, rtol = 0.001) == true
		@test isapprox(response[4, 5], -0.02777, rtol = 0.001) == true
		@test isapprox(response[5, 4], -0.69444, rtol = 0.001) == true
		@test isapprox(response[5, 5], 1.35417, rtol = 0.001) == true
		@test all(response[:, 1:3] .== 0) == true 
		@test all(response[1:3, :] .== 0) == true
		@test all(response[:, 6:6] .== 0) == true 
		@test all(response[6:7, :] .== 0) == true 


	end

end