## Date: 2025-12-28
## Title: greenspace data processing
## Notes: import pre-packaged parquet file for Git upload

source("load_packages.R")

# Load data
greenspace_data <-
  nanoparquet::read_parquet("landuse/460_TX_315_2009_H1037.parquet")
greenspace_data <-
  setNames(
    greenspace_data,
    c(
      "sggcd", "sggnm", "greenspacecd", "greenspacenm",
      "year", "n_greenspace", "area_sqm", "blank"
    )
  )


unique(greenspace_data$greenspacenm)

# English terms are from National Forest Service
greenspacenm_map <-
  c(
    "total", "buffer_green", "scenery_green", "connection_green"
  )
greenspacenm_koen <-
  data.frame(
    class2 = greenspacenm_map,
    greenspacenm = unique(greenspace_data$greenspacenm)
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
greenspace_data_sd <-
  greenspace_data %>%
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


greenspace_data_cl <-
  greenspace_data %>%
  dplyr::select(-blank) %>%
  dplyr::mutate(
    type = "landuse",
    class1 = "greenspace"
  ) %>%
  dplyr::left_join(
    greenspacenm_koen,
    by = "greenspacenm"
  ) %>%
  dplyr::mutate(
    sggcd11 = substr(sggcd, 9, 11),
    year = as.integer(substr(year, 1, 4))
  ) %>%
  dplyr::left_join(
    greenspace_data_sd,
    by = c("sggcd11" = "sdcd")
  ) %>%
  dplyr::rename(
    greenspaces = n_greenspace,
    greenspace_area = area_sqm
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
    type, class1, class2, greenspaces, greenspace_area
  ) %>%
  dplyr::rename(
    adm1 = sido_en,
    adm2 = sigungu_1_en
  ) %>%
  tidyr::pivot_longer(
    cols = c(greenspaces, greenspace_area),
    names_to = "variable",
    values_to = "value"
  ) %>%
  dplyr::mutate(
    adm1_code = as.integer(substr(adm2_code, 1, 2)),
    adm2_code = as.integer(adm2_code),
    class2 = paste0(class2, "_", variable),
    unit = ifelse(variable == "greenspaces", "count", "square meters")
  ) %>%
  dplyr::relocate(
    adm1, adm1_code,
    adm2, adm2_code,
    year,
    type, class1, class2,
    unit,
    value
  )
