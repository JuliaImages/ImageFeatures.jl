using Documenter, ImageFeatures

makedocs()

deploydocs(deps=Deps.pip("mkdocs", "mkdocs-material"),
           repo="github.com/JuliaImages/ImageFeatures.jl.git",
           osname="linux"
           )