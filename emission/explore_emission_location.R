## Date: 2025-07-06
## Description: Emission location data exploration
## Outline: load excel files, clean data, and export a wide data frame to csv/parquet

source("load_packages.R")

library(nanoparquet)

csv <- file.path("/mnt/c", "Users/user", "Downloads", "fulldata_09_30_08_P_대기오염물질배출시설설치사업장.csv")
loc <- readr::locale(encoding = "CP949")
csv1 <-
  readr::read_csv(
    csv,
    locale = loc
  )

csv11 <- csv1 |>
  dplyr::select(
    6, 7, 8, 9, 10, 11, 12, 13,
    14, 15, 17, 18, 19, 20, 21,
    22, 25, 26, 27, 28, 30, 31,
    32, 33, 34, 35, 36
  )

csv11sf <-
  csv11 |>
  dplyr::filter(
    !is.na(`좌표정보x(epsg5174)`) & !is.na(`좌표정보y(epsg5174)`)
  ) |>
  dplyr::mutate(
    X = as.numeric(`좌표정보x(epsg5174)`),
    Y = as.numeric(`좌표정보y(epsg5174)`)
  ) |>
  tidyr::separate(
    col = "도로명전체주소",
    into = sprintf("%s%02d", "addr", 1:12),
    sep = " ") |>
  sf::st_as_sf(
    coords = c("X", "Y"),
    crs = 5174
  )

# dim(csv11sf)
# dim(csv11)

# addr02 stores district name in each row
table(csv11sf$addr02)

# location
library(terra)
csv11v <- csv11sf |>
  sf::st_transform(4326) |>
  dplyr::filter(
    addr02 == "연천군"
  ) |>
  terra::vect()
terra::plot(csv11v)
