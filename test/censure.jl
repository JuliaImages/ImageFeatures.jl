using FactCheck, Base.Test, Images, Colors, FixedPointNumbers, ImageFeatures

facts("CENSURE") do

	context("Filters") do

		bf = BoxFilter(1)
		@fact bf.scale --> 1
		@fact bf.in_length --> 3
		@fact bf.out_length --> 5
		@fact bf.in_area --> 9.0
		@fact bf.out_area --> 25.0
		@fact isapprox(bf.in_weight, 1 / 9) --> true
		@fact isapprox(bf.out_weight, 1 / 16) --> true
		bf = BoxFilter(5)
		@fact bf.scale --> 5
		@fact bf.in_length --> 11
		@fact bf.out_length --> 21
		@fact bf.in_area --> 121.0
		@fact bf.out_area --> 441.0
		@fact isapprox(bf.in_weight, 1 / 121) --> true
		@fact isapprox(bf.out_weight, 1 / 320) --> true

		of = OctagonFilter(5, 3, 2, 0)
		@fact of.m_out --> 5
		@fact of.m_in --> 3
		@fact of.n_out --> 2
		@fact of.n_in --> 0
		@fact of.in_area --> 9.0
		@fact of.out_area --> 73.0
		@fact isapprox(of.in_weight, 1 / 9) --> true
		@fact isapprox(of.out_weight, 1 / 64) --> true

		of = OctagonFilter(13, 5, 7, 4)
		@fact of.m_out --> 13
		@fact of.m_in --> 5
		@fact of.n_out --> 7
		@fact of.n_in --> 4
		@fact of.in_area --> 137.0
		@fact of.out_area --> 631.0
		@fact isapprox(of.in_weight, 1 / 137) --> true
		@fact isapprox(of.out_weight, 1 / 494) --> true

	end

	context("Integral Image") do

		img = ones(5, 5)
		bf = BoxFilter(1)
		@fact all(integral_image(img) .== ImageFeatures._get_integral_image(img, bf)) --> true

		of = OctagonFilter(5, 3, 2, 0)
		i, rs, ls = ImageFeatures._get_integral_image(img, of)
		@fact all(i .== integral_image(img)) --> true
		r_check =  [ 1.0   2.0   3.0   4.0   5.0
					  3.0   5.0   7.0   9.0  10.0
					  6.0   9.0  12.0  14.0  15.0
					 10.0  14.0  17.0  19.0  20.0
					 15.0  19.0  22.0  24.0  25.0 ]
		@fact all(rs .== r_check) --> true
		l_check = [ 1.0  2.0  3.0   4.0   5.0
					 1.0  3.0  5.0   7.0   9.0
					 1.0  3.0  6.0   9.0  12.0
					 1.0  3.0  6.0  10.0  14.0
					 1.0  3.0  6.0  10.0  15.0 ]
		@fact all(ls .== l_check) --> true

	end

	context("Filter Response") do

		img = [4.0 2.0 6.0 1.0 1.0 8.0 2.0; 
			9.0 3.0 8.0 3.0 5.0 8.0 4.0; 
			4.0 10.0 6.0 2.0 5.0 1.0 5.0; 
			10.0 5.0 8.0 6.0 6.0 3.0 3.0; 
			5.0 6.0 4.0 8.0 3.0 3.0 9.0; 
			3.0 1.0 5.0 6.0 2.0 2.0 2.0; 
			9.0 3.0 4.0 1.0 10.0 8.0 6.0]
		bf = BoxFilter(1)
		response = ImageFeatures._filter_response(ImageFeatures._get_integral_image(img, bf), bf)
		@fact isapprox(response[4, 4], -0.895833, rtol = 0.001) --> true
		@fact isapprox(response[4, 5], 0.888889, rtol = 0.001) --> true
		@fact isapprox(response[5, 4], -0.958333, rtol = 0.001) --> true
		@fact isapprox(response[5, 5], 0.604167, rtol = 0.001) --> true
		@fact all(response[:, 1:3] .== 0) --> true 
		@fact all(response[1:3, :] .== 0) --> true
		@fact all(response[:, 6:6] .== 0) --> true 
		@fact all(response[6:7, :] .== 0) --> true 

		img = [  3.0   5.0  8.0   8.0   5.0  4.0   1.0
			  3.0   8.0  6.0  10.0   1.0  5.0   4.0
			 10.0   1.0  6.0   4.0  10.0  4.0   5.0
			  2.0  10.0  9.0   4.0   5.0  3.0   7.0
			  1.0   7.0  5.0   9.0   7.0  6.0   3.0
			  5.0   6.0  9.0   9.0   1.0  4.0   8.0
			  2.0   4.0  6.0   9.0   8.0  4.0  10.0]
		response = ImageFeatures._filter_response(ImageFeatures._get_integral_image(img, bf), bf)
		@fact isapprox(response[4, 4], -0.93056, rtol = 0.001) --> true
		@fact isapprox(response[4, 5], -0.02777, rtol = 0.001) --> true
		@fact isapprox(response[5, 4], -0.69444, rtol = 0.001) --> true
		@fact isapprox(response[5, 5], 1.35417, rtol = 0.001) --> true
		@fact all(response[:, 1:3] .== 0) --> true 
		@fact all(response[1:3, :] .== 0) --> true
		@fact all(response[:, 6:6] .== 0) --> true 
		@fact all(response[6:7, :] .== 0) --> true 

	end

end