## Date: 2025-12-28
## Title: road area data processing
## Notes: import pre-packaged parquet file for Git upload

source("load_packages.R")

# Load data
road_data <-
  nanoparquet::read_parquet("landuse/460_TX_315_2009_H1022.parquet")
road_data <-
  setNames(
    road_data,
    c("sggcd", "sggnm", "roadtypecd", "roadtypenm",
      "year", "n_road", "area_sqm", "blank")
  )
