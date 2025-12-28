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
  c("total", "urban_natural", "urban_national", "small", "children",
    "neighborhood", "historic", "cultural", "waterfront", "cemetery",
    "sports", "ordinance_province", "urban_agricultural", "hazard_prevention",
    "ordinance_city")
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
    sido_kr, sigungu_1_kr, base_year, adm2_code
  ) %>%
  dplyr::mutate(
    sido_kr = ifelse(sido_kr == "전라북도", "전북특별자치도", sido_kr)
  ) %>%
  dplyr::distinct()
joinby <-
  dplyr::join_by(
    sido_kr == sido_kr,
    sigungu_1_kr == sigungu_1_kr,
    year >= base_year
  )


parks_data <-
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
  dplyr::group_by(sggcd11) %>%
  dplyr::mutate(
    sido_kr = dplyr::first(sggnm),
    sigungu_1_kr = ifelse(sggnm == "세종특별자치시", "세종시", sggnm)
  ) %>%
  dplyr::ungroup() %>%
  dplyr::left_join(
    sgg_lookup_11,
    by = joinby
  )

## pivotting ...
  dplyr::mutate(
    unit = "square meters",
    value = AREA_SQM
  ) %>%
  dplyr::select(
    adm2_code = ADM2_CODE,
    year = DATA_YEAR,
    type,
    class1,
    class2,
    unit,
    value
  )

# check
pkd_t <-
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
  dplyr::group_by(sggcd11) %>%
  dplyr::mutate(
    sido_kr = dplyr::first(sggnm),
    sigungu_1_kr = sggnm
  )
