## Date: 2025-11-25
## Title: National Health Insurance Income Data Processing

library(dplyr)
library(nanoparquet)

# national health insurance income data
nhis_income <-
  read.csv("income/국민연금공단_자격 시군구 평균소득월액_20241231.csv",
    fileEncoding = "UTF-8"
  )
names(nhis_income) <-
  c("year_month", "sgg_name", "avg_income_monthly")
nhis_income <- nhis_income %>%
  dplyr::rowwise() %>%
  dplyr::transmute(
    year = as.integer(stringi::stri_extract_first_regex(year_month, pattern = "20[1-2][0-9]")),
    month = as.integer(stringi::stri_extract_last_regex(year_month, pattern = "[0-1][0-9]")),
    adm1 = stringi::stri_split_fixed(sgg_name, pattern = " ", n = 2)[[1]][1],
    adm2 = stringi::stri_split_fixed(sgg_name, pattern = " ", n = 2)[[1]][2],
    avg_income_monthly = as.integer(avg_income_monthly)
  ) %>%
  dplyr::ungroup() %>%
  dplyr::select(-month)

sgg_lookup <-
  read.csv("../tidycensuskr/inst/extdata/lookup_district_code.csv",
    fileEncoding = "UTF-8"
  ) %>%
  dplyr::select(adm2_code, sido_kr, sigungu_1_kr, base_year)
nhis_income_j <-
  nhis_income %>%
  dplyr::left_join(
    sgg_lookup,
    by = dplyr::join_by(adm1 == sido_kr, adm2 == sigungu_1_kr, year <= base_year),
    multiple = "first"
  ) %>%
  # dplyr::select(-sgg_name) %>%
  dplyr::rename(
    adm2_code = adm2_code,
    value = avg_income_monthly
  ) %>%
  dplyr::mutate(
    type = "income",
    class1 = "national health insurance",
    class2 = "average monthly income",
    unit = "KRW"
  ) %>%
  dplyr::select(
    adm2_code, year, type, class1, class2, unit, value
  )
