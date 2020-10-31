using Revise, Test
using CSV
using SeuratRDS

dn = joinpath(@__DIR__,"data")
testfn = joinpath(dn,"testSeur.rds")
checkfn = joinpath(dn,"dataSeur.csv")
@testset "SeuratRDS.jl" begin
    modality = "RNA"
    assay = "data"
    metadata = "nCount_RNA"

    env = initR()

    @test Conda.channels(env) == ["r","defaults"]

    dat = loadSeur(testfn,env,modality,assay,metadata)
    check = CSV.read(checkfn)

    @test Matrix(check) == dat.dat

    closeR(env)
    @test !isdir(env)
end
