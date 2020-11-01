#__precompile__()
module SeuratRDS

using Pkg
using Conda
using Dates
using RCall
using DelimitedFiles
using DataFrames

export initR,loadSeur,closeR

# install r to a temp path and return the path
# install r to a temp path and return the path
function initR()
    # make a new temporary conda environment for r
    ts = Dates.time()
    tdir = "/tmp/r$ts"
    mkpath(tdir)
    run(`conda create -p $tdir -y`)

    # install r in the temp environment
    Conda.add_channel("r",tdir)
    Conda.add("r-base>=3.4.0,<4",tdir) # greater than or equal to 3.4.0 AND strictly less than 4.0
    Conda.add("r-matrix",tdir) # greater than or equal to 3.4.0 AND strictly less than 4.0

    # ENV["R_HOME"] = tdir
    # Pkg.build("RCall")
    return(tdir)
end

# return features x barcodes data as tuple with data matrix, metadata, colnames, rownames, dataframe representation
function loadSeur(rdsPath::String,envPath::String,
              modality::String,assay::String,metadata::String)
    R"""
      rdsPath = $rdsPath;
      seur = readRDS(rdsPath);"""; # read in annotations

    # export counts and embedded labels
    R"""
      modality = $modality;
      assay = $assay;
      metadata = $metadata;
      modl = get($modality,slot(seur,"assays"));
      dat = slot(modl,$assay);
      met = get(metadata,slot(seur,"meta.data"));
      cnm = colnames(dat);
      rnm = rownames(dat);"""

    dat = rcopy(R"as.matrix(dat)")
    met = rcopy(R"as.matrix(met)")
    cnm = rcopy(R"as.matrix(cnm)")
    rnm = rcopy(R"as.matrix(rnm)")

    df = DataFrame(dat)
    rename!(df,Symbol.(reduce(vcat,cnm)))
    insertcols!(df,1,(:gene=>reduce(vcat,rnm)))

    (dat=dat,met=met,col=cnm,row=rnm,df=df)
end

# convert to loadSeur output to barcodes x features dataframe and add labels column
function bcFeatLabels(seurData::NamedTuple,labels::Vector)
  df = DataFrame(seurData.dat')
  rename!(df,Symbol.(reduce(vcat,seurData.row)))
  insertcols!(df,1,(:barcode=>reduce(vcat,seurData.col)))
  insertcols!(df,1,(:label=>reduce(vcat,labels)))
  df
end

# remove the repository
function closeR(envPath::String)
  run(`conda env remove -p $envPath`)
end

# return barcodes x features data where the metadata::Dict includes extra features like:
# :featurename => metadata, where metadata corresponds to get(metadata,slot(seur,"meta.data"))
function loadSeur(rdsPath::String,envPath::String,
                  modality::String,assay::String,
                  metadata::Dict)
    R"""
      rdsPath = $rdsPath;
      seur = readRDS(rdsPath);
      modality = $modality;
      assay = $assay;
      modl = get($modality,slot(seur,"assays"));
      dat = slot(modl,$assay);
      cnm = colnames(dat);
      rnm = rownames(dat);"""; # read in annotations

    dat = rcopy(R"as.matrix(dat)")
    cnm = rcopy(R"as.matrix(cnm)")
    rnm = rcopy(R"as.matrix(rnm)")

    df = DataFrame(dat')
    rename!(df,Symbol.(reduce(vcat,rnm)))
    insertcols!(df,1,(:barcode=>reduce(vcat,cnm)))

    # export counts and embedded labels
    for k in keys(metadata)
      seurkey = get(metadata,k,"")
      R"""
        met = get($seurkey,slot(seur,"meta.data"));"""
      met = rcopy(R"as.matrix(met)")
      insertcols!(df,1,(k=>reduce(vcat,met)))
    end
    df
end

end
