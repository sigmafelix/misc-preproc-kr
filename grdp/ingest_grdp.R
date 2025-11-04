## Date: 2025-11-02
## Notes: Original XLSX data were downloaded from KOSIS;
##      some provinces have different column layouts, so manual adjustments were made.
## Inflation-adjusted GRDP data are variably available across
## provinces. Thus we only ingest the nominal GRDP here.
# Some provinces required manual code adjustments;
# for example, Seoul, Daegu (before 2015), Busan, Ulsan
# did not report SGIS district codes
# Sejong should be collected at the province level only (2013-).


source("load_packages.R")

grdp_files <- list.files(
  path = "/mnt/s/Korea/census_data/sgg/grdp",
  pattern = ".xlsx$",
  full.names = TRUE
)

# check the column order
Map(read_excel, grdp_files) |>
  Map(f = names) |>
  Reduce(f = rbind)

grdp_data <-
  lapply(
    grdp_files,
    function(x) {
      xdf <-
        readxl::read_excel(
          x,
          col_types = c("text", "text", "text", "numeric", "numeric")
        )
      names(xdf) <-
        c("year", "sggcd", "name_sector", "grdp_nominal_milkrw",
          "grdp_real_milkrw")
      xdf
    }
  ) |>
  dplyr::bind_rows()

# deflators are not consistent; grdp_real_milkrw will be
# dropped
names(grdp_data) <-
  c("year", "sggcd", "name_sector", "grdp_nominal_milkrw",
    "grdp_real_milkrw")


grdp_data
grdp_data$name_sector |> unique()

# clean name_sector by extracting hangul characters
# with at least white spaces in between and comma
grdp_data_cl <-
  grdp_data |>
  dplyr::mutate(
    name_sector = stringr::str_trim(
      stringr::str_replace_all(
        name_sector,
        pattern = "[^가-힣\\s]",
        replacement = ""
      )
    )
  ) |>
  dplyr::mutate(
    name_sector = gsub(" ", "", name_sector)
  )
grdp_data_cl$name_sector |> unique() |> sort()


# convert the name_sector field values following this mapping table:
# | Korean Sector Name | KSIC Section | English Translation |
# |---|---|---|
# | 농림어업 | A | Agriculture, forestry and fishing |
# | 농업어업및임업 | A | Agriculture, forestry and fishing |
# | 농업임업및어업 | A | Agriculture, forestry and fishing |
# | 광업 | B | Mining and quarrying |
# | 제조업 | C | Manufacturing |
# | 전기가스증기및공기조절공급업 | D & E | Electricity, gas, steam and air conditioning supply; Water supply and waste management |
# | 전기가스증기및공기조절업 | D & E | Electricity, gas, steam and air conditioning supply; Water supply and waste management |
# | 전기가스증기및수도사업 | D & E | Electricity, gas, steam and air conditioning supply; Water supply and waste management |
# | 건설업 | F | Construction |
# | 도매및소매업 | G | Wholesale and retail trade |
# | 도소매업 | G | Wholesale and retail trade |
# | 숙박및음식점업 | I | Accommodation and food service activities |
# | 운수및창고업 | H | Transportation and storage |
# | 운수업 | H | Transportation and storage |
# | 정보및통신업 | J | Information and communication |
# | 정보통신업 | J | Information and communication |
# | 출판영상방송통신및정보서비스업 | J | Information and communication |
# | 금융및보험업 | K | Financial and insurance activities |
# | 금융보험업 | K | Financial and insurance activities |
# | 부동산업 | L & N | Real estate activities; Rental and leasing activities |
# | 부동산업및임대업 | L & N | Real estate activities; Rental and leasing activities |
# | 사업서비스업 | M & N | Professional, scientific and technical activities; Business support facilities |
# | 공공행정국방및사회보장 | O | Public administration and defence; compulsory social security |
# | 공공행정국방및사회보장행정 | O | Public administration and defence; compulsory social security |
# | 교육서비스업 | P | Education |
# | 교육서비스업정부 | P | Education |
# | 보건및사회복지서비스업 | Q | Human health and social work activities |
# | 보건업및사회복지서비스업 | Q | Human health and social work activities |
# | 예술스포츠및여가관련서비스업 | R | Arts, sports and recreation related activities |
# | 문화및기타서비스업 | R & S | Arts, sports and recreation; Membership organizations and personal services |
# | 기타서비스업 | R & S | Arts, sports and recreation; Membership organizations and personal services |
# | 순생산물세 | — | Net taxes on products |
# | 지역내총생산시장가격 | — | Gross Regional Domestic Product at market prices |
# | 총부가가치기초가격 | — | Total value added at basic prices |

# Create the mapping
sector_mapping <- tibble(
  korean = c(
    "농림어업", "농업어업및임업", "농업임업및어업",
    "광업",
    "제조업",
    "전기가스증기및공기조절공급업", "전기가스증기및공기조절업", "전기가스증기및수도사업",
    "건설업",
    "도매및소매업", "도소매업",
    "숙박및음식점업",
    "운수및창고업", "운수업",
    "정보및통신업", "정보통신업", "출판영상방송통신및정보서비스업",
    "금융및보험업", "금융보험업",
    "부동산업", "부동산업및임대업",
    "사업서비스업",
    "공공행정국방및사회보장", "공공행정국방및사회보장행정",
    "교육서비스업", "교육서비스업정부",
    "보건및사회복지서비스업", "보건업및사회복지서비스업",
    "예술스포츠및여가관련서비스업",
    "문화및기타서비스업", "기타서비스업",
    "순생산물세",
    "지역내총생산시장가격",
    "총부가가치기초가격"
  ),
  english = c(
    "Agriculture, forestry and fishing", "Agriculture, forestry and fishing", "Agriculture, forestry and fishing",
    "Mining and quarrying",
    "Manufacturing",
    "Electricity, gas, steam and air conditioning supply; Water supply and waste management",
    "Electricity, gas, steam and air conditioning supply; Water supply and waste management",
    "Electricity, gas, steam and air conditioning supply; Water supply and waste management",
    "Construction",
    "Wholesale and retail trade", "Wholesale and retail trade",
    "Accommodation and food service activities",
    "Transportation and storage", "Transportation and storage",
    "Information and communication", "Information and communication", "Information and communication",
    "Financial and insurance activities", "Financial and insurance activities",
    "Real estate activities; Rental and leasing activities", "Real estate activities; Rental and leasing activities",
    "Professional, scientific and technical activities; Business support facilities",
    "Public administration and defence; compulsory social security", "Public administration and defence; compulsory social security",
    "Education", "Education",
    "Human health and social work activities", "Human health and social work activities",
    "Arts, sports and recreation related activities",
    "Arts, sports and recreation; Membership organizations and personal services", "Arts, sports and recreation; Membership organizations and personal services",
    "Net taxes on products",
    "Gross Regional Domestic Product at market prices",
    "Total value added at basic prices"
  )
)

# Convert using left_join
grdp_data_cl <- grdp_data_cl |>
  left_join(sector_mapping, by = c("name_sector" = "korean")) |>
  dplyr::select(-name_sector) |>
  rename(name_sector = english)




grdp_df <-
  grdp_data_cl |>
  dplyr::mutate(
    year = as.integer(stringi::stri_extract_first_regex(year, pattern = "\\d{4,4}$")),
    sggcd = stringi::stri_extract_last_regex(sggcd, pattern = "\\d{5,5}")
  ) |>
  dplyr::select(-grdp_real_milkrw) |>
  collapse::pivot(
    id = c("year", "sggcd", "name_sector"),
    values = c("grdp_nominal_milkrw"),
    how = "longer"
  ) |>
  dplyr::mutate(
    type = "economy",
    class1 = "grdp",
    class2 = tolower(name_sector),
    unit = "million KRW"
  )

grdp_df_tdc <-
  grdp_df |>
  dplyr::filter(!is.na(sggcd)) |>
  dplyr::filter(!is.na(class2)) |>
  # Some provinces use variable code starting with 15216
  # and it has no matching 5-digit district code
  dplyr::filter(sggcd != 15216) |>
  dplyr::filter(year %in% c(2010, 2015, 2020)) |>
  dplyr::select(-name_sector, -variable) |>
  dplyr::relocate(
    type, class1, class2, unit,
    .after = sggcd
  )
