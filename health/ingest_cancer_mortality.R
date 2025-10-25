library(nanoparquet)
library(dplyr)

cancerfiles <- list.files(
  path = "~/Documents/nhis/cancer",
  pattern = "101_DT_1B34E13_Y_\\d{4,4}\\.csv$",
  full.names = TRUE
)

cancermort <-
  lapply(cancerfiles, read.csv, fileEncoding = "CP949", skip = 2) |>
  dplyr::bind_rows()
names(cancermort) <-
  c("causecd", "cause", "sggcd", "sgg", "sexcd",
    "sex", "year", "count", "crude",
    "age-standardized")

cancermort <-
  cancermort |>
  dplyr::mutate(
    sexcd = gsub("\\'", "", sexcd),
    sggcd = gsub("\\'", "", sggcd),
    causecd = gsub("\\'", "", causecd)
  ) |>
  dplyr::as_tibble() |>
  dplyr::filter(nchar(sggcd) == 5) |>
  dplyr::mutate(sgg = trimws(sgg), cause = trimws(cause)) |>
  dplyr::mutate(
    sex = dplyr::case_when(
      sex == "계" ~ "total",
      sex == "남자" ~ "male",
      sex == "여자" ~ "female"
    )
  ) |>
#   [1] "계"
#  [2] "특정 감염성 및 기생충성 질환 (A00-B99, U07.1, U07.2, U10)"
#  [3] "호흡기 결핵 (A15-A16)"
#  [4] "패혈증 (A40-A41)"
#  [5] "신생물 (C00-D48)"
#  [6] "악성신생물(암) (C00-C97)"
#  [7] "식도의 악성신생물 (C15)"
#  [8] "위의 악성신생물 (C16)"
#  [9] "결장, 직장 및 항문의 악성신생물 (C18-C21)"
# [10] "간 및 간내 담관의 악성신생물 (C22)"
# [11] "췌장의 악성신생물 (C25)"
# [12] "기관, 기관지 및 폐의 악성신생물 (C33-C34)"
# [13] "유방의 악성신생물 (C50)"
# [14] "자궁의 악성신생물 (C53-C55)"
# [15] "전립선의 악성신생물 (C61)"
# [16] "수막, 뇌 및 기타 중추신경계통의 악성신생물 (C70-C72)"
# [17] "백혈병 (C91-C95)"
# [18] "혈액 및 조혈기관질환과 면역메커니즘을 침범하는 특정장애 (D50-D89)"
# [19] "내분비, 영양 및 대사 질환 (E00-E88)"
# [20] "당뇨병 (E10-E14)"
# [21] "정신 및 행동장애 (F01-F99)"
# [22] "신경계통의 질환 (G00-G98)"
# [23] "알츠하이머병 (G30)"
# [24] "눈 및 눈부속기의 질환 (H00-H57)"
# [25] "귀 및 유돌의 질환 (H60-H93)"
# [26] "순환계통 질환 (I00-I99)"
# [27] "고혈압성 질환 (I10-I13)"
# [28] "심장 질환 (I20-I51)"
# [29] "허혈성 심장 질환 (I20-I25)"
# [30] "기타 심장 질환 (I26-I51)"
# [31] "뇌혈관 질환 (I60-I69)"
# [32] "호흡계통의 질환 (J00-J98,U04)"
# [33] "폐렴 (J12-J18)"
# [34] "만성 하기도 질환 (J40-J47)"
# [35] "소화계통의 질환 (K00-K92)"
# [36] "간 질환 (K70-K76)"
# [37] "피부 및 피하조직의 질환 (L00-L98)"
# [38] "근골격계통 및 결합 조직의 질환 (M00-M99)"
# [39] "비뇨생식계통의 질환 (N00-N98)"
# [40] "임신, 출산 및 산후기 (O00-O99)"
# [41] "출생전후기에 기원한 특정병태 (P00-P96)"
# [42] "선천 기형, 변형 및 염색체 이상 (Q00-Q99)"
# [43] "달리 분류되지 않은 증상, 징후 (R00-R99)"
# [44] "노쇠(R54)"
# [45] "질병이환 및 사망의 외인 (V01-Y89, U12)"
# [46] "운수사고 (V01-V99)"
# [47] "낙상(추락) (W00-W19)"
# [48] "불의의 익사 및 익수 (W65-W74)"
# [49] "연기, 불 및 불꽃에 노출 (X00-X09)"
# [50] "유독성 물질에 의한 불의의 중독 및 노출 (X40-X49)"
# [51] "고의적 자해(자살) (X60-X84)"
# [52] "가해(타살) (X85-Y09)"
  dplyr::mutate(
    cause = dplyr::case_when(
      cause == "계" ~ "total",
      cause == "특정 감염성 및 기생충성 질환 (A00-B99, U07.1, U07.2, U10)" ~ "infectiousparasitic",
      cause == "호흡기 결핵 (A15-A16)" ~ "tuberculosis",
      cause == "패혈증 (A40-A41)" ~ "sepsis",
      cause == "신생물 (C00-D48)" ~ "neoplasms",
      cause == "악성신생물(암) (C00-C97)" ~ "cancerall",
      cause == "식도의 악성신생물 (C15)" ~ "canceresophagus",
      cause == "위의 악성신생물 (C16)" ~ "cancerstomach",
      cause == "결장, 직장 및 항문의 악성신생물 (C18-C21)" ~ "cancercolorectum",
      cause == "간 및 간내 담관의 악성신생물 (C22)" ~ "cancerliver",
      cause == "췌장의 악성신생물 (C25)" ~ "cancerpancreas",
      cause == "기관, 기관지 및 폐의 악성신생물 (C33-C34)" ~ "cancerlung",
      cause == "유방의 악성신생물 (C50)" ~ "cancerbreast",
      cause == "자궁의 악성신생물 (C53-C55)" ~ "canceruterus",
      cause == "전립선의 악성신생물 (C61)" ~ "cancerprostate",
      cause == "수막, 뇌 및 기타 중추신경계통의 악성신생물 (C70-C72)" ~ "cancerbrain",
      cause == "백혈병 (C91-C95)" ~ "leukemia",
      cause == "혈액 및 조혈기관질환과 면역메커니즘을 침범하는 특정장애 (D50-D89)" ~ "immuneblood",
      cause == "내분비, 영양 및 대사 질환 (E00-E88)" ~ "endocricmetabolic",
      cause == "당뇨병 (E10-E14)" ~ "diabetesmellitus",
      cause == "정신 및 행동장애 (F01-F99)" ~ "behavioraldisorders",
      cause == "신경계통의 질환 (G00-G98)" ~ "nervoussystem",
      cause == "알츠하이머병 (G30)" ~ "alzheimer",
      cause == "눈 및 눈부속기의 질환 (H00-H57)" ~ "eyes",
      cause == "귀 및 유돌의 질환 (H60-H93)" ~ "earmastoid",
      cause == "순환계통 질환 (I00-I99)" ~ "circulation",
      cause == "고혈압성 질환 (I10-I13)" ~ "hypertension",
      cause == "심장 질환 (I20-I51)" ~ "heart",
      cause == "허혈성 심장 질환 (I20-I25)" ~ "heartischemic",
      cause == "기타 심장 질환 (I26-I51)" ~ "heartother",
      cause == "뇌혈관 질환 (I60-I69)" ~ "cerebrovascular",
      cause == "호흡계통의 질환 (J00-J98,U04)" ~ "respiratory",
      cause == "폐렴 (J12-J18)" ~ "pneumonia",
      cause == "만성 하기도 질환 (J40-J47)" ~ "lowerresp",
      cause == "소화계통의 질환 (K00-K92)" ~ "digestive",
      cause == "간 질환 (K70-K76)" ~ "liver",
      cause == "피부 및 피하조직의 질환 (L00-L98)" ~ "skin",
      cause == "근골격계통 및 결합 조직의 질환 (M00-M99)" ~ "musculoskeletal",
      cause == "비뇨생식계통의 질환 (N00-N98)" ~ "urinary",
      cause == "임신, 출산 및 산후기 (O00-O99)" ~ "pregnancy",
      cause == "출생전후기에 기원한 특정병태 (P00-P96)" ~ "perinatal",
      cause == "선천 기형, 변형 및 염색체 이상 (Q00-Q99)" ~ "congenital",
      cause == "달리 분류되지 않은 증상, 징후 (R00-R99)" ~ "nonclassified",
      cause == "노쇠(R54)" ~ "frailty",
      cause == "질병이환 및 사망의 외인 (V01-Y89, U12)" ~ "morbidity",
      cause == "운수사고 (V01-V99)" ~ "traffic",
      cause == "낙상(추락) (W00-W19)" ~ "falls",
      cause == "불의의 익사 및 익수 (W65-W74)" ~ "drowning",
      cause == "연기, 불 및 불꽃에 노출 (X00-X09)" ~ "smokeflame",
      cause == "유독성 물질에 의한 불의의 중독 및 노출 (X40-X49)" ~ "poisoning",
      cause == "고의적 자해(자살) (X60-X84)" ~ "suicide",
      cause == "가해(타살) (X85-Y09)" ~ "homicide"
    )
  ) |>
  dplyr::mutate(
    year = as.integer(year),
    count = as.integer(count),
    rel = as.numeric(rel),
    crude = as.numeric(crude),
    `age-standardized` = as.numeric(`age-standardized`),
    type = "cancer mortality"
  )

