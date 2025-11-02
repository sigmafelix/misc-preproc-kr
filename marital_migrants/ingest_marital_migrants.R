## Date: 2025-11-02
## Title: Ingest Marital Migrants Data
## Notes: DOJ codes following the MOIS classification

source("load_packages.R")

marital_migrant_files <- list.files(
  path = "marital_migrants",
  pattern = ".xlsx$",
  full.names = TRUE
)

marital_migrant_data <-
  lapply(marital_migrant_files, readxl::read_excel) |>
  dplyr::bind_rows()

names(marital_migrant_data) <-
  c("year", "sdcd", "sggcd", "total",
    "male", "female")

marital_migrant_df <-
  marital_migrant_data |>
  dplyr::mutate(
    year = as.integer(stringi::stri_extract_first_regex(year, pattern = "\\d{4,4}$")),
    sggcd = stringi::stri_extract_first_regex(sggcd, pattern = "BVXX\\d{3,5}(|[AB])")
  ) |>
  dplyr::select(
    year, sggcd, total, male, female
  ) |>
  dplyr::filter(!is.na(sggcd)) |>
  collapse::pivot(
    ids = c("year", "sggcd"),
    values = c("total", "male", "female"),
    how = "longer"
  ) |>
  dplyr::mutate(
    type = "migration",
    class1 = "marital",
    class2 = dplyr::case_when(
      variable == "total" ~ "total",
      variable == "male" ~ "male",
      variable == "female" ~ "female"
    ),
    unit = "count"
  )

marital_migrant_df_tdc <-
  marital_migrant_df |>
  dplyr::filter(year %in% c(2010, 2015, 2020)) |>
  dplyr::select(
    year, sggcd,
    type, class1, class2, unit,
    value
  )
