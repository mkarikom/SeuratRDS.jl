using Test
using DelimitedFiles
using SeuratRDS

dn = joinpath(@__DIR__,"data")
testfn = joinpath(dn,"testSeur.rds")
checkfn = joinpath(dn,"dataSeur.csv")
@testset "SeuratRDS.jl" begin
    modality = "RNA"
    assay = "data"
    metadata = "nCount_RNA"

    env = initR() # make the env

    dat = loadSeur(testfn,env,modality,assay,metadata)
    check,ccols = readdlm(checkfn,header=true)

    @test check == dat.dat

    closeR(env)
    @test !isdir(env)
end
