## Date: 2025-11-16
## Title: Vacant Housing Data Processing

library(dplyr)
library(nanoparquet)


# vacant housing
vacant_housing <-
  readxl::read_excel("housing/빈집비율_시도_시_군_구__20251108222214.xlsx")
names(vacant_housing) <-
  c("year", "sggcd", "p_vacant_housing", "n_vacant_housing", "n_total_housing")
vacant_housing <- vacant_housing %>%
  dplyr::transmute(
    year = as.integer(stringi::stri_extract_last_regex(year, pattern = "20[1-2][0-9]")),
    sggcd = as.integer(stringi::stri_extract_first_regex(sggcd, pattern = "\\d{5,5}")),
    p_vacant_housing = as.numeric(p_vacant_housing),
    n_vacant_housing = as.integer(n_vacant_housing),
    n_total_housing = as.integer(n_total_housing)
  )

sgg_lookup <-
  read.csv("../tidycensuskr/inst/extdata/lookup_district_code.csv",
    fileEncoding = "UTF-8")

joinby <- dplyr::join_by(
  sggcd == adm2_code, year <= base_year
)

vacant_housing_tdc <-
  vacant_housing |>
  dplyr::filter(year %in% c(2015, 2020)) |>
  tidyr::pivot_longer(
    cols = 3:5
  ) |>
  dplyr::mutate(
    type = "housing",
    class1 = "vacant housing",
    class2 = dplyr::case_when(
      name == "p_vacant_housing" ~ "fraction",
      name == "n_vacant_housing" ~ "number of vacant housing",
      name == "n_total_housing" ~ "total number of housing" ,
      TRUE ~ NA_character_
    ),
    unit = dplyr::case_when(
      name == "p_vacant_housing" ~ "percent",
      name %in% c("n_vacant_housing", "n_total_housing") ~ "count",
      TRUE ~ NA_character_
    )
  ) |>
  dplyr::left_join(
    sgg_lookup %>%
      dplyr::select(adm2_code, base_year, sido_en, sigungu_2_en),
    by = joinby
  ) |>
  dplyr::select(-base_year, -name) |>
  dplyr::rename(
    adm2_code = sggcd,
    value = value,
    adm1 = sido_en,
    adm2 = sigungu_2_en
  ) |>
  dplyr::mutate(
    adm1_code = as.integer(substr(adm2_code, 1, 2))
  ) |>
  dplyr::relocate(
    adm1, adm1_code, adm2, adm2_code, year, type, class1, class2, unit, value
  ) |>
  # fix sejong-si
  dplyr::mutate(
    adm1 = ifelse(is.na(adm1), "Sejong", adm1),
    adm2 = ifelse(is.na(adm2), "Sejong-si", adm2),
    adm1_code = ifelse(is.na(adm1_code), 29, adm1_code),
    adm2_code = ifelse(is.na(adm2_code), 29010, adm2_code)
  )
