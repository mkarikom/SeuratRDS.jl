__precompile__()
module SeuratRDS

using Pkg
using Conda
using Dates
using RCall

export initR,loadSeur,closeR

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
    return(tdir)
end

# get the data
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
      print(class(dat));"""

    dat = rcopy(R"as.matrix(dat)")
    met = rcopy(R"as.matrix(met)")
    (dat=dat,met=met)
end

# remove the repository
function closeR(envPath::String)
  run(`conda env remove -p $envPath`)
end

end
