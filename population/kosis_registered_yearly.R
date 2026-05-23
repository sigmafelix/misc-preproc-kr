library(kosis)
library(readxl)

KOSIS_KEY <- readLines("~/.kosiskey")[1]

base_url <- sprintf("https://kosis.kr/openapi/Param/statisticsParameterData.do?method=getList&apiKey=%s&itmId=T20+T21+T22+&objL1=00+11+26+27+28+29+30+31+36+41+51+43+44+52+46+47+48+50+&objL2=&objL3=&objL4=&objL5=&objL6=&objL7=&objL8=&format=json&jsonVD=Y&prdSe=Y&startPrdDe=2010&endPrdDe=2025&outputFields=TBL_ID+OBJ_ID+OBJ_NM+OBJ_NM_ENG+NM+NM_ENG+ITM_ID+ITM_NM+ITM_NM_ENG+&orgId=101&tblId=DT_1YL20651E", KOSIS_KEY)

kosis::kosis.setKey(KOSIS_KEY)

# population 2015-2025
pop1525 <-
  kosis::getStatDataFromURL(
    url = base_url
  )

conv_table <- read.csv("population/sgg_code_conversion_202507.csv")
conv_table <- conv_table[, c("code_mods", "code_juris")]
conv_table <- conv_table[!duplicated(conv_table), ]
conv_table <- conv_table[!is.na(conv_table$code_mods), ]
conv_table <- conv_table[nchar(conv_table$code_mods) == 5L, ]

# population
sgg_pop <- readxl::read_excel("population/주민등록인구_시도_시_군_구.xlsx")
names(sgg_pop) <- c("year", "element", "sgg_juris", "population")

# fill in the first row's year value until the next non-NA year value
sgg_pop$year <- as.integer(stringi::stri_extract_first_regex(sgg_pop$year, pattern = "[0-9]{4}"))
sgg_pop$year <- zoo::na.locf(sgg_pop$year)



sgg_pop[["code_juris"]] <- stringi::stri_extract_first_regex(sgg_pop[["sgg_juris"]], pattern = "[0-9]{5}")

sgg_pop_ex <- merge(sgg_pop, conv_table, by = "code_juris", all.x = TRUE)

sgg_pop_ex
summary(sgg_pop_ex)
sgg_pop_ex[is.na(sgg_pop_ex$code_mods), ]

# 인천 남구 (-2018) 23030
# 여주군 (-2012) 31320
# 청원군 (-2014) 33310
# 연기군 (-2010) 34320
# 당진군 (-2013) 34390
# 경북 군위군 (-2023): 37310
# 세종특별자치시 (2010-): 29010
# split rows by NA in code_modes into separate rows
sgg_pop_ex_missing <- sgg_pop_ex[is.na(sgg_pop_ex$code_mods), ]
sgg_pop_ex_missing <- sgg_pop_ex_missing |>
  dplyr::mutate(
    sgg_nm = stringi::stri_extract_first_regex(sgg_juris, pattern = "[가-힣]+")
  ) |>
  dplyr::mutate(
    code_mods = dplyr::case_when(
      sgg_nm == "남구" ~ 23030,
      sgg_nm == "여주군" ~ 31320,
      sgg_nm == "청원군" ~ 33310,
      sgg_nm == "연기군" ~ 34320,
      sgg_nm == "당진군" ~ 34390,
      sgg_nm == "군위군" ~ 37310,
      sgg_nm == "세종특별자치시" ~ 29010,
      TRUE ~ NA_integer_
    )
  )

sgg_pop_ex_nonmissing <- sgg_pop_ex[!is.na(sgg_pop_ex$code_mods), ]

sgg_pop_ex_filled <- dplyr::bind_rows(sgg_pop_ex_nonmissing, sgg_pop_ex_missing)

nanoparquet::write_parquet(
  sgg_pop_ex_filled,
  "population/sgg_population.parquet"
)
