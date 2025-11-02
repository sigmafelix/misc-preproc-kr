## Date: 2025-11-02

library(nanoparquet)
library(dplyr)
library(collapse)
library(readxl)


wastewater_files <- list.files(
  path = "wastewater",
  pattern = ".xlsx$",
  full.names = TRUE
)

wastewater_data <-
  lapply(wastewater_files, read_excel, skip = 1) |>
  dplyr::bind_rows()

names(wastewater_data) <-
  c("year", "sdcd", "sggcd", "n_emittors",
    "total_wastewater_gen_m3_day", "total_wastewater_discharge_m3_day",
    "total_organic_gen_kg_day", "total_organic_discharge_kg_day")

wastewater_df <-
  wastewater_data |>
  dplyr::mutate(
    year = as.integer(stringi::stri_extract_first_regex(year, pattern = "\\d{4,4}$")),
    sggcd = stringi::stri_extract_first_regex(sggcd, pattern = "420\\d{4,4}")
  ) |>
  dplyr::select(-sdcd) |>
  collapse::pivot(
    id = c("year", "sggcd"),
    values = c("n_emittors",
               "total_wastewater_gen_m3_day", "total_wastewater_discharge_m3_day",
               "total_organic_gen_kg_day", "total_organic_discharge_kg_day"),
    how = "longer"
  ) |>
  dplyr::mutate(
    type = "environment",
    class1 = ifelse(grepl("wastewater", variable), "wastewater", "organic_matter"),
    class2 = ifelse(grepl("gen", variable), "generation", "discharge"),
    unit = ifelse(grepl("m3", variable), "m3_day", "kg_day")
  )
