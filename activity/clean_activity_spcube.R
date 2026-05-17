library(duckplyr)
library(collapse)
library(readr)
library(sf)

BASE_DIR <- "~/Documents"

# load data
filename <- "LOCAL_PEOPLE_20250515.csv"
filename <- file.path(BASE_DIR, filename)

readr::read_csv(filename, locale = locale(encoding = "EUC-KR"))

# column names to eng
coln_first <- c(
  "date", "hour", "emd_code", "coa_code", "total"
)
coln <-
  expand.grid(
    c2 = c("00_09", "10_14", "15_19", "20_24", "25_29", "30_34", "35_39", "40_44", "45_49", "50_54", "55_59", "60_64", "65_69", "70_plus"),
    c1 = c("m", "f")
  )
coln <- paste0(coln$c1, "_", coln$c2)


coa_poly <- read_sf("coa.shp") |>
  filter(grepl("^11210", TOT_REG_CD)) |>
  rename(coa_code = TOT_REG_CD) |>
  st_set_crs(5179) |>
  st_transform(4326)

write_sf(coa_poly, file.path("target_dir", "gwanak_coa_poly.sqlite"), delete_dsn = TRUE)

coa_data <- read_csv(filename) |>
  setNames(c(coln_first, coln)) |>
  filter(grepl("^11210", coa_code)) |>
  mutate(date = as.Date(date, format = "%Y%m%d"))
nanoparquet::write_parquet(coa_data, file.path("target_dir", "cleaned_coa_data.parquet"))
