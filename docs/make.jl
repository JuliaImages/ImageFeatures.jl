using Documenter, ImageFeatures, Images

makedocs(sitename = "ImageFeatures",
         format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
         pages    = ["Home" => "index.md",
                     "Framework" => "framework.md",
                     "Tutorials" => [
                         "BRIEF" => "tutorials/brief.md",
                         "ORB" => "tutorials/orb.md",
                         "BRISK" => "tutorials/brisk.md",
                         "FREAK" => "tutorials/freak.md",
                         "Gray level co-occurence matrix" => "tutorials/glcm.md",
                         "Local binary patterns" => "tutorials/lbp.md",
                         "Object Detection using HOG" => "tutorials/object_detection.md"
                     ],
                     "Function reference" => "function_reference.md",
                     ],
         warnonly = true,  # TODO: add docstrings and remove this line
         )

deploydocs(repo   = "github.com/JuliaImages/ImageFeatures.jl.git",
           push_preview = true
           )
