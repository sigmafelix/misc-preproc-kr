## Date: 2025-12-28
## Title: road area data processing
## Notes: import pre-packaged parquet file for Git upload

source("load_packages.R")

# Load data
road_data <-
  nanoparquet::read_parquet("landuse/460_TX_315_2009_H1022.parquet")
road_data <-
  setNames(
    road_data,
    c(
      "sggcd", "sggnm", "roadtypecd", "roadtypenm",
      "year", "n_road", "length_m", "area_sqm", "blank"
    )
  )

unique(road_data$roadtypenm)

roadtypenm_map <-
  c(
    "total", "regular", "automobile-only", "pedestrian-only",
    "pedestrian-priority", "bicycle-only", "overpass",
    "underpass"
  )
roadtypenm_koen <-
  data.frame(
    class2 = roadtypenm_map,
    roadtypenm = unique(road_data$roadtypenm)
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

# extract sido info
road_data_sd <-
  road_data %>%
  dplyr::transmute(
    sggnm = sggnm,
    sdcd = substr(sggcd, 9, 11)
  ) %>%
  dplyr::distinct() %>%
  dplyr::group_by(sdcd) %>%
  dplyr::summarize(
    sido_kr = dplyr::first(sggnm)
  ) %>%
  dplyr::ungroup()

road_data_sd <-
  tibble::tribble(
    ~sdcd, ~sido_kr,
    "001", "서울특별시",
    "002", "부산광역시",
    "003", "인천광역시",
    "004", "대구광역시",
    "005", "광주광역시",
    "006", "대전광역시",
    "007", "울산광역시",
    "017", "세종특별자치시",
    "008", "경기도",
    "009", "강원특별자치도",
    "010", "충청북도",
    "011", "충청남도",
    "012", "전북특별자치도",
    "013", "전라남도",
    "014", "경상북도",
    "015", "경상남도",
    "016", "제주특별자치도"
  )


road_data_cl <-
  road_data %>%
  dplyr::select(-blank) %>%
  dplyr::mutate(
    type = "landuse",
    class1 = "road"
  ) %>%
  dplyr::left_join(
    roadtypenm_koen,
    by = "roadtypenm"
  ) %>%
  dplyr::mutate(
    sggcd11 = substr(sggcd, 9, 11),
    year = as.integer(substr(year, 1, 4))
  ) %>%
  dplyr::left_join(
    road_data_sd,
    by = c("sggcd11" = "sdcd")
  ) %>%
  dplyr::rename(
    roads = n_road,
    road_length = length_m,
    road_area = area_sqm
  ) %>%
  dplyr::mutate(
    sigungu_1_kr = ifelse(sggnm == "세종특별자치시", "세종시", sggnm)
  ) %>%
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
    type, class1, class2, roads, road_length, road_area
  ) %>%
  dplyr::rename(
    adm1 = sido_en,
    adm2 = sigungu_1_en
  ) %>%
  tidyr::pivot_longer(
    cols = c(roads, road_length, road_area),
    names_to = "variable",
    values_to = "value"
  ) %>%
  dplyr::mutate(
    adm1_code = as.integer(substr(adm2_code, 1, 2)),
    adm2_code = as.integer(adm2_code),
    class2 = paste0(class2, "_", variable),
    unit = dplyr::case_when(
      variable == "roads" ~ "count",
      variable == "road_length" ~ "meters",
      variable == "road_area" ~ "square meters",
      TRUE ~ "unknown"
    )
  ) %>%
  dplyr::relocate(
    adm1, adm1_code,
    adm2, adm2_code,
    year,
    type, class1, class2,
    unit,
    value
  ) %>%
  dplyr::filter(unit != "count")
