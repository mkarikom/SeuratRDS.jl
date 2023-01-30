#__precompile__()
module SeuratRDS

using Pkg
using Dates
using DelimitedFiles
using DataFrames

ENV["R_HOME"]="*";Pkg.build("RCall");using RCall # make sure we have a good r environment

# ensure that Matrix is installed for R

export loadSeur

# return features x barcodes data as tuple with data matrix, metadata, colnames, rownames, dataframe representation
function loadSeur(rdsPath::String,modality::String,assay::String,metadata::String)
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

# return barcodes x features data where the metadata::Dict includes extra features like:
# :featurename => metadata, where metadata corresponds to get(metadata,slot(seur,"meta.data"))
function loadSeur(rdsPath::String,
                  modality::String,assay::String,
                  metadata::Dict)
    R"""
      library(Matrix)
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
