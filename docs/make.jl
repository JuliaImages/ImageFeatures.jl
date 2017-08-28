using Documenter, ImageFeatures

makedocs(format   = :html,
         sitename = "ImageFeatures",
         pages    = ["Home" => "index.md",
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
         )

deploydocs(repo   = "github.com/JuliaImages/ImageFeatures.jl.git",
           julia  = "0.6",
           target = "build",
           deps   = nothing,
           make   = nothing,
           )
