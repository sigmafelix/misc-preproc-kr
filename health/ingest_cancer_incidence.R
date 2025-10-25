library(nanoparquet)
library(dplyr)

cancerinc <-
  read.csv("~/Downloads/117_DT_117N_A11109_F_2018.csv", fileEncoding = "CP949", skip = 2)
names(cancerinc) <-
  c("sexcd", "sex", "sggcd", "sgg", "cancertypecd",
    "cancertype", "timecd", "time", "datayear",
    "count", "rel", "crude", "age-standardized")

cancerinc <-
  cancerinc |>
  dplyr::mutate(
    sexcd = gsub("\\'", "", sexcd),
    sggcd = gsub("\\'", "", sggcd),
    cancertypecd = gsub("\\'", "", cancertypecd),
    timecd = gsub("\\'", "", timecd)
  ) |>
  dplyr::as_tibble() |>
  dplyr::filter(nchar(sggcd) == 5) |>
  dplyr::mutate(sgg = trimws(sgg)) |>
  dplyr::mutate(
    sex = dplyr::case_when(
      sex == "계" ~ "total",
      sex == "남자" ~ "male",
      sex == "여자" ~ "female"
    )
  ) |>
  dplyr::mutate(
    cancertype = dplyr::case_when(
      cancertype == "모든 암(C00-C96)" ~ "all",
      cancertype == "입술, 구강 및 인두(C00-C14)" ~ "oral_pharynx",
      cancertype == "위(C16)" ~ "stomach",
      cancertype == "대장(C18-C20)" ~ "colorectal",
      cancertype == "간(C22)" ~ "liver",
      cancertype == "폐(C33-C34)" ~ "lung",
      cancertype == "유방(C50)" ~ "breast",
      cancertype == "자궁경부(C53)" ~ "cervix",
      cancertype == "자궁체부(C54)" ~ "corpus",
      cancertype == "담낭 및 기타 담도(C23-C24)" ~ "gallbladder_bileduct",
      cancertype == "췌장(C25)" ~ "pancreas",
      cancertype == "갑상선(C73)" ~ "thyroid",
      cancertype == "전립선(C61)" ~ "prostate",
      cancertype == "신장(C64)" ~ "kidney",
      cancertype == "방광(C67)" ~ "bladder",
      cancertype == "뇌 및 중추신경계(C70-C72)" ~ "brain_cns",
      cancertype == "식도(C15)" ~ "esophagus",
      cancertype == "호지킨 림프종(C81)" ~ "hodgkin_lymphoma",
      cancertype == "비호지킨 림프종(C82-C86,C96)" ~ "non_hodgkin_lymphoma",
      cancertype == "백혈병(C91-C95)" ~ "leukemia",
      cancertype == "다발성 골수종(C90)" ~ "multiple_myeloma",
      cancertype == "기타 암(Re. C00-C96)" ~ "other"
    )
  ) |>
  dplyr::mutate(
    datayear = as.integer(datayear),
    count = as.integer(count),
    rel = as.numeric(rel),
    crude = as.numeric(crude),
    `age-standardized` = as.numeric(`age-standardized`),
    type = "cancer incidence"
  )


cancerinc_d <-
  cancerinc |>
  dplyr::filter(
  ) |>
  dplyr::select(
    sggcd,
    sgg,
    sex,
    type,
    time,
    cancertype,
    count,
    crude,
    `age-standardized`
  ) |>
  tidyr::pivot_longer(
    cols = c(count, crude, `age-standardized`),
    names_to = "class1"
  ) |>
  dplyr::mutate(
    unit = dplyr::case_when(
      class1 == "count" ~ "persons",
      class1 == "crude" ~ "per 100k population",
      class1 == "age-standardized" ~ "per 100k population"
    )
  ) |>
  dplyr::rename(
    adm2_code = sggcd,
    adm2 = sgg,
    class2 = sex
  ) |>
  dplyr::relocate(adm2_code, adm2, time, type, class1, class2, unit, value)
  # tidyr::pivot_wider(
  #   names_from = cancertype,
  #   values_from = c(n, crude, asmr),
  #   names_sep = "_",
  #   values_fill = 0,
  #   id_cols = c(sggcd, sgg),
  #   names_glue = ""
  # )

nanoparquet::write_parquet(
  cancerinc_d,
  "./health/cancer_incidence_2018_4periods.parquet"
)
