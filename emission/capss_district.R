## Date: 2025-07-06
## Description: CAPSS district emission data processing
## Outline: load excel files, clean data, and export a wide data frame to csv/parquet

source("load_packages.R")

targ_dir <- "/mnt/s/Korea/emission/data"
xls <- list.files(
  path = targ_dir,
  pattern = "*.xlsx$",
  full.names = TRUE
)

# the ending year is subject to change
year_idx <- seq(2010, 2022)
xlss <- Map(readxl::read_excel, xls, skip = 3)
names(xlss) <- year_idx

# Bind all data frames into one
df <- collapse::rowbind(xlss, fill = TRUE, idcol = TRUE)

# 시도	시군구	배출원대분류	배출원중분류	배출원소분류	연료대분류	연료소분류
# Fill missing column names
cn_add <- c(
  "sido", "sigungu",
  "emission_class1", "emission_class2", "emission_class3",
  "fuel_class1", "fuel_class2"
)
names(df)[2:8] <- cn_add

# unit is kg
df <-
  df |>
  dplyr::mutate(
    PM2.5 = ifelse(is.na(PM2.5), `PM-2.5`, PM2.5),
    PM10 = ifelse(is.na(PM10), `PM-10`, PM10)
  ) |>
  dplyr::select(
    -dplyr::all_of(c("PM-2.5", "PM-10"))
  )
