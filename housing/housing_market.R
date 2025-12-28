## Date: 2025-12-28
## Title: Housing market data processing

source("load_packages.R")




# Load data
housing_data <-
  nanoparquet::read_parquet("housing/408_DT_408_2006_S0045.parquet")
housing_data <-
  setNames(
    housing_data,
    c("sggcd", "sggnm", "housingtypecd", "housingtypenm", "year", "n_housing", "area_ksqm", "blank")
  )

