using Test, ImageFeatures, Images, Colors, FixedPointNumbers

@testset "circular_offsets" begin
    img = [  0x4c  0x19  0xac  0x2e  0x8c  0xcc  0x96  0x4c  0xdb  0x4f
             0x01  0x75  0x65  0x57  0x59  0x24  0xe9  0x8e  0x1f  0xd3
             0xb3  0x92  0xdd  0xdb  0x2e  0xf2  0xcc  0xc1  0xac  0x97
             0xc8  0x75  0xa8  0x38  0x6d  0x77  0xc3  0xf4  0x63  0x15
             0x7c  0xdf  0x54  0x11  0x0f  0x03  0xea  0x01  0x5e  0xe6
             0xa5  0x87  0x40  0x22  0xeb  0x71  0xf7  0xba  0xb2  0x6f
             0x9d  0xa7  0x58  0x7e  0xf8  0x0f  0x91  0xd0  0x8e  0x04
             0x58  0xd3  0x8b  0x5d  0x6f  0x8b  0xaa  0x77  0x53  0x46
             0x9a  0x74  0xd8  0x2f  0x38  0x4e  0x4b  0x18  0x4a  0xc7
             0x1a  0xe0  0x52  0x5a  0x6a  0x03  0xe8  0xcb  0x95  0xfc
          ]
    
    global img_gray = map(i -> Images.Gray(reinterpret(N0f8, i)), img)
end
 
@test ImageFeatures.circular_offsets(8, 1) == [ (-0.0,1.0), (-0.70711,0.70711), (-1.0,0.0), (-0.70711,-0.70711), (-0.0,-1.0), (0.70711,-0.70711), (1.0,-0.0), (0.70711,0.70711)]

@testset "Original" begin
    uniform_params = ImageFeatures.PatternCache(1)
    @test lbp_original(BitArray([false]), uniform_params)[1] == 0
    @test lbp_original(BitArray([false, true]), uniform_params)[1] == 1
    @test lbp_original(BitArray([true, false, true]), uniform_params)[1] == 5
    @test lbp_original(BitArray([true, false, true, true, false]), uniform_params)[1] == 22

    img = zeros(Gray{N0f8}, 10, 10)

    lbp_image = lbp(img)
    @test all(lbp_image .== 255)

    lbp_image = lbp(img, 10, 2)
    @test all(lbp_image .== 1023)

    lbp_image = lbp(img_gray)
    expected_lbp = [ 247  226  255  224  239  247  250  232  255  250
                     131  209  176   72  149    0  253   80    0  127
                     251  228  255  254   32  255  182  120  220  190
                     247    8  157   44   79  135   43  255   22   56
                     163  255   60   16   16    0  219    0   33  255
                     215  184   48   96  251  196  255  122  220  188
                     167  251   96  205  255    0  139  127   62   56
                     131  247  122  140   47   79  223   30   54  120
                     215  138  253    0    9   21   18    0   33  251
                     143  255   46  111  255   14  255  254  206  255
                    ]
    @test all(lbp_image .== expected_lbp)

    lbp_image = lbp(img_gray, 8, 1)
    expected_lbp = [ 255   48  255  112  127  255  245  112  255  241
                       8  184  208   32  154    0  255  160    0  255
                     253  114  255  247    0  255  214  225  243  215
                     255    0  159    3   47   30   13  255  134  128
                      28  255  195  128  128    0  253    0   72  255
                     191  193  192   32  253   50  255  245  243  195
                      94  253   96   62  255    0   28  239  199  128
                      28  255  225    3   79  111  191  135  198  225
                     190    4  255    0    9  142  132    0    8  253
                      14  255    7  111  255    2  255  247   55  255
                    ]
    @test all(lbp_image .== expected_lbp)
end

@testset "Uniform" begin
    uniform_params = ImageFeatures.PatternCache(4)
    @test uniform_params.table[BitArray([true, false, true, false])] == 14
    ret, uniform_params = lbp_uniform(BitArray([false, false, false, false]), uniform_params)
    @test ret == 1
    ret, uniform_params = lbp_uniform(BitArray([false, true, false, false]), uniform_params)
    @test ret == 2
    ret, uniform_params = lbp_uniform(BitArray([false, false, true, false]), uniform_params)
    @test ret == 3

    uniform_params = ImageFeatures.PatternCache(8)
    @test uniform_params.table[[true, false, true, false, true, false, true, false]] == 58

    lbp_image = lbp(img_gray, lbp_uniform)
    expected_lbp = [  1  58   6  11  15   1  58  58   6  58
                      2  58  58  58  58  14  10  58  14  21
                      3  58   6  12  16   6  58  20  58  58
                      1   5  58  58  58  17  58   6  58  24
                     58   6   7  13  13  14  58  14  58   6
                     58  58   8   9   3  58   6  58  58  58
                     58   3   9  58   6  14  58  21  23  24
                      2   1  58  58  58  58  19  22  58  20
                     58  58  10  14  58  58  58  14  58   3
                      4   6  58  58   6  18   6  12  58   6
                    ]
    @test all(lbp_image .== expected_lbp)

    lbp_image = lbp(img_gray, 8, 1, lbp_uniform)
    expected_lbp = [    1   7   1  17  23   1  58  17   1  30
                        2  58  58  18  58   8   1  58   8   1
                        3  58   1  19   8   1  58  15  28  58
                        1   8  11  20  58  24  58   1  58  21
                        4   1  12  21  21   8   3   8  58   1
                        5   9  13  18   3  58   1  58  28  12
                       58   3  14  22   1   8   4  26  29  21
                        4   1  15  20  58  58   5  27  58  15
                       58  10   1   8  58  58  58   8   2   3
                        6   1  16  58   1  25   1  19  58   1
                    ]
    @test all(lbp_image .== expected_lbp)
end

@testset "Modified" begin
    img = zeros(Gray{N0f8}, 10, 10)

    lbp_image = modified_lbp(img)
    @test all(lbp_image .== 255)

    lbp_image = modified_lbp(img, 10, 2)
    @test all(lbp_image .== 1023)

    lbp_image = modified_lbp(img_gray)
    expected_lbp = [ 231  226  241  224  233  230  242  232  245  250
                     163  209  177   89  149  131  113  208  160  121
                     195  228  234  252  230  199  162  104   76  188
                     131   74   29   46   79  135   11   28   22   56
                     131   93   60   87  147  197  147   48  105  120
                     131  184  116  227  233  196  163  106  216   60
                     135   50  104  205  182   86  139   29   62   56
                     131   53  122  156   47   79  142   30   54  120
                     199  170   61   86   25   23   19  113  225  249
                     143   31   46  110   30  142   47  238  206  190
                    ]
    @test all(lbp_image .== expected_lbp)

    lbp_image = modified_lbp(img_gray, 8, 1)
    expected_lbp = [  126  116  248  112  120  118  240  113  250  241
                       92   56  216  233  154   28  232  225   88  233
                       60  114  125  227  118   62  214  225   51  195
                       28   37  139  199   47   30   13  131  198  193
                       28  171  195  166  156   58  156  193  104  225
                       28  193  226  124  121   50   94   96  177  195
                       30  228   97   62  223  167   29  143  195  193
                       28  206  225  147   79   39   23  135  198  225
                       30   29  203  227  137  142  204  200  120  249
                       31  143  199   39  135   23   63  103   55  199
                    ]
    @test all(lbp_image .== expected_lbp)
end

@testset "Rotation Invariant" begin
    uniform_params = ImageFeatures.PatternCache(1)
    @test lbp_rotation_invariant(BitArray([false]), uniform_params)[1] == 0
    @test lbp_rotation_invariant(BitArray([false, true]), uniform_params)[1] == 1
    @test lbp_rotation_invariant(BitArray([true, false, true]), uniform_params)[1] == 3
    @test lbp_rotation_invariant(BitArray([true, false, true, true, false]), uniform_params)[1] == 11
    @test lbp_rotation_invariant(BitArray([false, true, true, true, false, true, true, false]), uniform_params)[1] == 59

    img = zeros(Gray{N0f8}, 10, 10)
    lbp_image = lbp(img)
    @test all(lbp_image .== 255)

    lbp_image = lbp(img, 10, 2)
    @test all(lbp_image .== 1023)

    lbp_image = lbp(img_gray, lbp_rotation_invariant)
    expected_lbp = [ 127   23  255    7  127  127   95   29  255   95
                       7   29   11    9   43    0  127    5    0  127
                     127   39  255  127    1  255   91   15   55   95
                     127    1   59   11   61   15   43  255   11    7
                      29  255   15    1    1    0  111    0    9  255
                      95   23    3    3  127   19  255   61   55   47
                      61  127    3   55  255    0   23  127   31    7
                       7  127   61   25   47   61  127   15   27   15
                      95   21  127    0    9   21    9    0    9  127
                      31  255   23  111  255    7  255  127   59  255
                    ]
    @test all(lbp_image .== expected_lbp)

    lbp_image = lbp(img_gray, 8, 1, lbp_rotation_invariant)
    expected_lbp = [ 255    3  255    7  127  255   95    7  255   31
                       1   23   13    1   53    0  255    5    0  255
                     127   39  255  127    0  255   91   15   63   95
                     255    0   63    3   47   15   13  255   13    1
                       7  255   15    1    1    0  127    0    9  255
                     127    7    3    1  127   25  255   95   63   15
                      47  127    3   31  255    0    7  127   31    1
                       7  255   15    3   61  111  127   15   27   15
                      95    1  255    0    9   29    9    0    1  127
                       7  255    7  111  255    1  255  127   55  255
                    ]
    @test all(lbp_image .== expected_lbp)
end

@testset "Direction Coded" begin
    img = zeros(Gray{N0f8}, 10, 10)

    lbp_image = direction_coded_lbp(img)
    @test all(lbp_image .== 255)

    lbp_image = direction_coded_lbp(img, 10, 2)
    @test all(lbp_image .== 1023)

    lbp_image = direction_coded_lbp(img_gray)
    expected_lbp = [ 126   15  254   82  252  126  221  211  254  204
                      37   26   36   74   27  175  182  157  187   63
                     218  115  190  237  167  250   88   21  185  141
                     106  110  139   82  100   17   40  175  144   96
                     120  187   16  188  173  187  211  250  225  191
                     114  181  224  131  158  123  238   92  253  149
                      72  143  194  253  235  238  244   43   13  112
                     113  110    8  142   29  113  227    0  220   69
                      98  163  167  254   61  142  161  234  161  159
                     213  170   26  105  171   87  170  169  163  175
                    ]
    @test all(lbp_image .== expected_lbp)

    lbp_image = direction_coded_lbp(img_gray, 8, 1)
    expected_lbp = [ 175  224  191  132   63  191  119  197  191   18
                     122  165    8  163  244  250  191  103  238  254
                     167  205  190  122  234  175   37   84   78  114
                     171  187  242  181    8   84    8  250   23   43
                      13  254    5   62  122  254  231  175   75  254
                     143   76   11  226  183  237  171   54   78   84
                      33  242  131   93  235  187   29  232  112   47
                      92  187   16  176  101  108  202    0   55   81
                     137  218  250  175  125  146   90  170  106  246
                      86  170  133  104  234  247  170  106  202  234
                    ]
    @test all(lbp_image .== expected_lbp)
end

@testset "Multi Block" begin
    img = zeros(Gray{Float64}, 12, 12)
    img[1:4, 1:4] .= Gray(6.0)
    img[9:12, 1:4] .= Gray(3.0)
    img[5:8, 5:8] .= Gray(1.0)

    @test multi_block_lbp(img, 1, 1, 4, 4) == 130

    img = zeros(Gray{Float64}, 12, 12)
    img[9:12, 1:4] .= Gray(6.0)
    img[5:8, 9:12] .= Gray(3.0)
    img[5:8, 5:8] .= Gray(1.0)

    @test multi_block_lbp(img, 1, 1, 4, 4) == 18
end

@testset "Descriptor" begin
    img = Gray{N0f8}[   0 1 1 0 1 1 0 1 1 0
                        0 1 1 0 1 1 0 1 1 0
                        0 1 1 0 1 1 0 1 1 0
                        0 1 1 0 1 1 0 1 1 0
                        0 1 1 0 1 1 0 1 1 0
                        0 1 1 0 1 1 0 1 1 0
                        0 1 1 0 1 1 0 1 1 0
                        0 1 1 0 1 1 0 1 1 0
                        0 1 1 0 1 1 0 1 1 0
                        0 1 1 0 1 1 0 1 1 0 ]

    descriptor = create_descriptor(img, 1, 1)
    expected = [0,0,0,0,18,0,0,9,0,0,0,0,9,0,3,61]
    @test all(descriptor .== expected)

    img = Gray{N0f8}[   0 1 1 0 1 1 0 1 1 0 1 1
                        1 1 1 1 1 1 1 1 1 1 1 1
                        1 1 1 1 1 1 1 1 1 1 1 1
                        0 1 1 0 1 1 0 1 1 0 1 1
                        1 1 1 1 1 1 1 1 1 1 1 1
                        1 1 1 1 1 1 1 1 1 1 1 1
                        0 1 1 0 1 1 0 1 1 0 1 1
                        1 1 1 1 1 1 1 1 1 1 1 1
                        1 1 1 1 1 1 1 1 1 1 1 1
                        0 1 1 0 1 1 0 1 1 0 1 1
                        1 1 1 1 1 1 1 1 1 1 1 1
                        1 1 1 1 1 1 1 1 1 1 1 1 ]

    descriptor = create_descriptor(img, 2, 2)
    expected = [1,0,0,0,0,0,0,0,1,0,0,0,0,0,2,32,1,0,0,0,0,0,0,0,1,0,0,0,0,0,2,32,1,0,0,0,0,0,0,0,1,0,0,0,0,0,2,32,1,0,0,0,0,0,0,0,1,0,0,0,0,0,2,32]
    @test all(descriptor .== expected)
end
