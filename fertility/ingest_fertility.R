## Date: 2025-11-02
## Title: Clean fertility data

source("load_packages.R")

fertility_files <- list.files(
  path = "fertility",
  pattern = ".xlsx$",
  full.names = TRUE
)

fertility_data <-
  lapply(fertility_files, readxl::read_excel, skip = 1) |>
  dplyr::bind_rows()

fertility_cns <-
  c("sggcd", "sggnm", "year", "fertility_rate_total",
    "fertility_rate|1519|sim", "fertility_rate|2024",
    "fertility_rate|2529", "fertility_rate|3034",
    "fertility_rate|3539", "fertility_rate|4044",
    "fertility_rate|4549")
names(fertility_data) <- fertility_cns

fertility_df <-
  fertility_data |>
  dplyr::mutate(
    sggcd = stringi::stri_extract_last_regex(sggcd, pattern = "\\d{5,5}"),
    year = as.integer(stringi::stri_extract_first_regex(year, pattern = "\\d{4,4}")),
    type = "population",
    class1 = "fertility"
  ) |>
  collapse::pivot(
    ids = c("sggcd", "sggnm", "year", "type", "class1"),
    values = fertility_cns[-1:-3]
  ) |>
  dplyr::select(-sggnm) |>
  dplyr::mutate(
    variable = plyr::mapvalues(
      variable,
      from = c(
        "fertility_rate_total",
        "fertility_rate|1519|sim",
        "fertility_rate|2024",
        "fertility_rate|2529",
        "fertility_rate|3034",
        "fertility_rate|3539",
        "fertility_rate|4044",
        "fertility_rate|4549"
      ),
      to = c(
        "total",
        "15-19 (simulated)",
        "20-24",
        "25-29",
        "30-34",
        "35-39",
        "40-44",
        "45-49"
      )
    ),
  ) |>
  dplyr::mutate(
    unit = dplyr::case_when(
      variable == "total" ~ "births",
      variable == "15-19 (simulated)" ~ "births per 1000",
      variable == "20-24" ~ "births per 1000",
      variable == "25-29" ~ "births per 1000",
      variable == "30-34" ~ "births per 1000",
      variable == "35-39" ~ "births per 1000",
      variable == "40-44" ~ "births per 1000",
      variable == "45-49" ~ "births per 1000",
      TRUE ~ NA_character_)
  ) |>
  dplyr::rename(
    class2 = variable
  ) |>
  dplyr::relocate(
    sggcd, year, type, class1, class2, unit, value
  )

fertility_df_tdc <-
  fertility_df |>
  dplyr::filter(
    year %in% c(2010, 2015, 2020)
  )
