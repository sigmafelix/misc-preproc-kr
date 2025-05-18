## Date: 2025-05-18
## Description: Clean electricity usage data from KEPCO
## Outline: load excel files, clean data, and export a wide data frame to csv/parquet

source("load_packages.R")

##
dir_work <- file.path(base_dir, "energy", "electricity")

l_files <-
  list.files(
    path = dir_work,
    pattern = "20[0-2][0-9]",
    full.names = TRUE
  )
ln_files <- stringi::stri_extract_all_regex(
  l_files,
  pattern = "20[0-2][0-9]",
  simplify = TRUE
) %>%
  as.vector()

# Adjust depending on the focal years
not2025 <- which(ln_files != "2025")
l_files <- l_files[not2025]
ln_files <- ln_files[not2025]


# Function to read and clean the data
fast_ingest <- function(file, sheet = 1, wider_from = "계약종별") {
  if (length(file) > 1) {
    file <- unlist(grep("12", file, value = TRUE))
  }
  sheet_list <- readxl::excel_sheets(file)
  sheet_data <- tryCatch(
    readxl::read_excel(file, sheet = sheet, skip = 2),
    error = function(e) {
      message("Sheet not found: ", sheet)
      readxl::read_excel(file, sheet = "산업분류별", skip = 2)
    }
  )

  sheet_data %>%
    dplyr::mutate(
      dplyr::across(dplyr::ends_with("월"), ~ifelse(.=="-", NA, .))
    ) %>%
    #.[, -sapply(., function(x) all(!is.na(x)))] %>%
    tidyr::pivot_longer(
      cols = -c(1:4),
      names_to = "month",
      values_to = "usage"
    ) %>%
    dplyr::mutate(
      !!rlang::sym(wider_from) := sub(" ", "", !!rlang::sym(wider_from)),
      연도 = as.integer(sub("년", "", 연도))
    ) %>%
    tidyr::pivot_wider(
      names_from = wider_from,
      values_from = "usage"
    )
}

l_files <- split(l_files, ln_files)

# rowbind all data
electricity_raw <-
  lapply(l_files, fast_ingest, sheet = "계약종별") %>%
  collapse::rowbind(fill = TRUE)

electricity_seg <- lapply(l_files, fast_ingest, sheet = "용도업종별", wider_from = "업종별") %>%
  collapse::rowbind(fill = TRUE)

# rename fields
electricity_raw <-
  electricity_raw %>%
  dplyr::rename(
    year = 연도,
    sido = 시도,
    sgg = 시군구
  )
electricity_seg <-
  electricity_seg %>%
  dplyr::rename(
    year = 연도,
    sido = 시도,
    sgg = 시군구
  )


# Export to parquet
nanoparquet::write_parquet(
  electricity_raw,
  file.path(dir_work, "electricity_purpose.parquet"),
  compression = "zstd"
)
nanoparquet::write_parquet(
  electricity_seg,
  file.path(dir_work, "electricity_industry.parquet"),
  compression = "zstd"
)
