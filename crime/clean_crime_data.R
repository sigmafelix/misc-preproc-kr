library(dplyr)
library(tidyr)
library(tidytable)
library(readr)
library(stringi)

# data from
# https://www.data.go.kr/data/3074462/fileData.do#layer_data_infomation

# read
tdir <- "__base_dir__"
tdird <- file.path(tdir, "data")
flist <- list.files(path = tdird, pattern = "*.csv$", full.names = TRUE)
years <- stringi::stri_extract_first_regex(flist, pattern = "20[1-2][0-9]")

protoclean <- function(path) {
  csv <- read.csv(path, fileEncoding = "CP949")
  year_int <-
    stringi::stri_extract_first_regex(path, pattern = "20[1-2][0-9]") |>
    as.integer()
  csv_l <- csv |>
    tidyr::pivot_longer(cols = seq(3, ncol(csv))) |>
    dplyr::mutate(year = year_int)
  csv_l
}

fdf <- lapply(flist, protoclean)
fdfl <- collapse::rowbind(fdf, fill = TRUE)


fdfl <-
  fdfl |>
  dplyr::mutate(name = gsub("\\.", "", name)) |>
  dplyr::mutate(name = gsub("도", "", name)) |>
  dplyr::mutate(name = gsub("군", "", name)) |>
  dplyr::mutate(name = gsub("경북위", "경북군위", name)) |>
  dplyr::mutate(name = gsub("대구위", "대구군위", name)) |>
  dplyr::mutate(name = gsub("^산$", "군산", name)) |>
  dplyr::mutate(name = gsub("^포$", "군포", name))
