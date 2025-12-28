## Date: 2025-12-28
## Title: Urban and national parks data processing
## Notes: import pre-packaged parquet file for Git upload

source("load_packages.R")

# Load data
parks_data <-
  nanoparquet::read_parquet("landuse/460_TX_315_2009_H1126_20251228123408.parquet")
parks_data <-
  setNames(
    parks_data,
    c("sggcd", "sggnm", "parktypecd", "parktypenm", "year", "n_parks", "area_sqm", "blank")
  )

unique(parks_data$parktypenm)
parktypenm_map <-
  c(
    "total", "urban_natural", "urban_national", "small", "children",
    "neighborhood", "historic", "cultural", "waterfront", "cemetery",
    "sports", "ordinance_province", "urban_agricultural", "hazard_prevention",
    "ordinance_city"
  )
parktypenm_koen <-
  data.frame(
    class2 = parktypenm_map,
    parktypenm = unique(parks_data$parktypenm)
  )

# lookup
sgg_lookup <-
  read.csv(
    "../tidycensuskr/inst/extdata/lookup_district_code.csv"
  )
sgg_lookup_11 <-
  sgg_lookup %>%
  dplyr::select(
    sido_kr, sido_en, sigungu_1_kr, sigungu_1_en, base_year, adm2_code
  ) %>%
  dplyr::mutate(
    sido_kr = ifelse(sido_kr == "전라북도", "전북특별자치도", sido_kr)
  ) %>%
  dplyr::distinct()
joinby <-
  dplyr::join_by(
    sido_kr == sido_kr,
    sigungu_1_kr == sigungu_1_kr,
    year <= base_year
  )


parks_data_cl <-
  parks_data %>%
  dplyr::select(-blank) %>%
  dplyr::mutate(
    type = "landuse",
    class1 = "park"
  ) %>%
  dplyr::left_join(
    parktypenm_koen,
    by = "parktypenm"
  ) %>%
  dplyr::mutate(
    sggcd11 = substr(sggcd, 1, 11),
    year = as.integer(substr(year, 1, 4))
  ) %>%
  dplyr::rename(
    parks = n_parks,
    park_area = area_sqm
  ) %>%
  dplyr::group_by(sggcd11) %>%
  dplyr::mutate(
    sido_kr = dplyr::first(sggnm),
    sigungu_1_kr = ifelse(sggnm == "세종특별자치시", "세종시", sggnm)
  ) %>%
  dplyr::ungroup() %>%
  dplyr::left_join(
    sgg_lookup_11,
    by = joinby
  ) %>%
  dplyr::filter(year %in% c(2010, 2015, 2020)) %>%
  dplyr::filter(!is.na(adm2_code)) %>%
  dplyr::select(
    year,
    sido_en,
    sigungu_1_en,
    adm2_code,
    type, class1, class2, parks, park_area
  ) %>%
  dplyr::rename(
    adm1 = sido_en,
    adm2 = sigungu_1_en
  ) %>%
  tidyr::pivot_longer(
    cols = c(parks, park_area),
    names_to = "variable",
    values_to = "value"
  ) %>%
  dplyr::mutate(
    adm1_code = as.integer(substr(adm2_code, 1, 2)),
    adm2_code = as.integer(adm2_code),
    class2 = paste0(class2, "_", variable),
    unit = ifelse(variable == "parks", "count", "square meters")
  ) %>%
  dplyr::relocate(
    adm1, adm1_code,
    adm2, adm2_code,
    year,
    type, class1, class2,
    unit,
    value
  )

## TODO: processing logic after 2020 until 2025 census data release
