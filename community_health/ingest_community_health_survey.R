## Date: 2025-11-02
## Title: Ingest Community Health Survey Data
## Availability: subjective health

source("load_packages.R")

# load data
selfreported <-
  readxl::read_excel(
    path = "community_health/177_DT_HEALTH_RECOG_20251031232136.xlsx",
    skip = 1
  )

# definition: "very good" or "good" subjective health status
names(selfreported) <-
  c("sggcd", "sggnm", "year", "n_respondents",
    "r_crude_subjective_good", "se_crude_subjective_good",
    "r_std_subjective_good", "se_std_subjective_good")

selfreported_df <-
  selfreported |>
  dplyr::mutate(
    year = as.integer(stringi::stri_extract_first_regex(year, pattern = "\\d{4,4}"))
  ) |>
  collapse::pivot(
    id = c("year", "sggcd", "sggnm"),
    values = c("r_crude_subjective_good", "se_crude_subjective_good",
               "r_std_subjective_good", "se_std_subjective_good"),
    how = "longer"
  ) |>
  dplyr::filter(
    !grepl("se_", variable)
  ) |>
  dplyr::mutate(
    type = "community_health",
    class1 = "selfreported_health",
    class2 = ifelse(grepl("std_", variable), "age_standardized", "crude"),
    unit = "percent"
  )
