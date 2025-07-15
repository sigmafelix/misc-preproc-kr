## Date: 2025-07-15
## Description: Internal migration statistics data processing
## Outline: load Excel files, clean data, and export a cleaned data frame

if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
  requireNamespace("pacman")
}
pacman::p_load(
  readxl, dplyr, tidyr, stringr, purrr, yaml, janitor
)

# Read files
tdir <- unlist(yaml::yaml.load(
  readLines("config.yaml")[1]
))
file_directory <- file.path(tdir, "migration", "data")

csvs <- list.files(
  path = file_directory,
  pattern = "*.csv$",
  full.names = TRUE
)


# Load CSVs
df_list <- lapply(csvs, read.csv, fileEncoding = "CP949")
df_list <-
  df_list |>
  purrr::map(
    .f = function(x) x[, -ncol(x)]
  )

# Combine data frames
df_all <- Reduce(
  function(x, y) dplyr::full_join(x, y),
  df_list
)

# some cleaning
df_all_cn <- janitor::clean_names(df_all)
df_all_cn <-
  df_all_cn |>
  dplyr::mutate(
    x_item_hangmog = stringr::str_replace_all(
      x_item_hangmog,
      "\\[14STD03818\\]",
      ""
    )
  )
names(df_all_cn)[1:7] <- c(
  "sggcd_adm", "sggnm_adm", "persons_perinstance", "persons_perinstance_label",
  "type_cd", "type", "unit"
)

# Convert to long format
df_long <- df_all_cn |>
  tidyr::pivot_longer(
    cols = x2017_01_wol:x2024_12_wol,
    names_to = "year_month",
    values_to = "value"
  )
df_long <-
  df_long |>
  dplyr::mutate(
    year_month = stringr::str_replace_all(
      year_month, c("x" = "", "_wol" = "", "_" = "")
    ),
    year_month = lubridate::ym(year_month)
  )

nanoparquet::write_parquet(
  df_long,
  file.path(file_directory, "internal_migration_201701_202412.parquet")
)
