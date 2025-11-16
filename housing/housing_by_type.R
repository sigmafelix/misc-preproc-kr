## Date: 2025-11-16
## Title: Housing Data by Type Processing

library(dplyr)
library(nanoparquet)

# Read the vacant housing data from a Parquet file
housing_type <- read_parquet("housing/housing_by_type_2015_2024.parquet")
names(housing_type) <-
  c("sggcd", "sggnm", "housingcd", "housingnm", "year1", "n_housing",
    "n_2024", "n_2023", "n_2022", "n_2021", "n_2020", "n_2019",
    "n_2018", "n_2017", "n_2016", "n_2015", "n_2014", "n_2013", "n_2012",
    "n_2011", "n_2010",
    "n_2005_2009", "n_2000_2004", "n_1990_1999",
    "n_1980_1989", "n_before_1979", "year"
  )

housing_type_long <-
  housing_type |>
  dplyr::mutate(
    dplyr::across(
        c(sggcd, housingcd),
        ~ gsub("\\'", "", .x)
    )
  ) |>
  dplyr::filter(nchar(sggcd) != 2) |>
  tidyr::pivot_longer(
    cols = dplyr::starts_with("n_"),
    names_to = "year_housing",
    values_to = "n_housing"
  ) |>
  dplyr::mutate(
    housing_type = dplyr::case_when(
      housingcd == "00" ~ "total housing",
      housingcd == "20" ~ "apartments",
      housingcd == "10" ~ "detached houses",
      housingcd == "30" ~ "row houses",
      housingcd == "40" ~ "multi-family houses",
      housingcd == "50" ~ "in nonresidential buildings",
      TRUE ~ NA_character_
    ),
  ) |>
  dplyr::mutate(
    year_built = as.integer(stringi::stri_extract_last_regex(year_housing, pattern = "\\d{4}")),
    n_housing = ifelse(n_housing == "X", -999, as.numeric(n_housing))
  ) |>
  dplyr::filter(
    !is.na(n_housing)
  ) |>
  dplyr::mutate(
    build_age = year - year_built,
    build_age_group = ifelse(build_age >= 40, "40 years or older", build_age)
  )


sgg_lookup <-
  read.csv("https://github.com/sigmafelix/tidycensuskr/raw/refs/heads/main/inst/extdata/lookup_district_code.csv",
    fileEncoding = "UTF-8")

joinby <- dplyr::join_by(
  sggcd == adm2_code, year <= base_year
)

housing_type_tdc <-
  housing_type_long |>
  dplyr::select(-sggnm, -housingcd, -housingnm, -year1, -year_housing) |>
  dplyr::mutate(
    type = "housing",
    class1 = housing_type,
    class2 = build_age_group,
    unit = "count",
    sggcd = as.integer(sggcd)
  ) |>
  dplyr::rename(
    value = n_housing,
  ) |>
  dplyr::left_join(
    sgg_lookup %>%
      dplyr::select(adm2_code, base_year, sido_en, sigungu_2_en),
    by = joinby
  ) |>
  dplyr::select(-base_year) |>
  dplyr::rename(
    adm2_code = sggcd,
    value = value,
    adm1 = sido_en,
    adm2 = sigungu_2_en
  ) |>
  dplyr::mutate(
    adm1_code = as.integer(substr(adm2_code, 1, 2)),
    class2 = ifelse(is.na(class2), "total", class2),
    class2 = ifelse(is.na(as.integer(class2)), class2, paste0(class2, " years"))
  ) |>
  dplyr::relocate(
    adm1, adm1_code, adm2, adm2_code, year, type, class1, class2, unit, value
  ) |>
  dplyr::filter(year %in% c(2015, 2020))
