using SeuratRDS
using Documenter

makedocs(;
    modules=[SeuratRDS],
    authors="Matt Karikomi <mattkarikomi@gmail.com> and contributors",
    repo="https://github.com/mkarikom/SeuratRDS.jl/blob/{commit}{path}#L{line}",
    sitename="SeuratRDS.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://mkarikom.github.io/SeuratRDS.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/mkarikom/SeuratRDS.jl",
)
