## Date: 2025-12-28
## Title: greenspace data processing
## Notes: import pre-packaged parquet file for Git upload

source("load_packages.R")

# Load data
greenspace_data <-
  nanoparquet::read_parquet("landuse/460_TX_315_2009_H1037.parquet")
greenspace_data <-
  setNames(
    greenspace_data,
    c("sggcd", "sggnm", "greenspacecd", "greenspacenm",
      "year", "n_greenspace", "area_sqm", "blank")
  )

