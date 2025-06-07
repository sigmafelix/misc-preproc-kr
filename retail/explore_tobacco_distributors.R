library(sf)
library(dplyr)
library(ggplot2)
library(collapse)
library(readxl)
library(nanoparquet)

# Load the tobacco distributors data
basedir <- "/home/felix/Documents"
filepath <- file.path(basedir, "tobacco.xlsx")

# define sheet indices
sheet_idx <- seq(1, 3)

# Read the data
tobacco_data <- lapply(sheet_idx, function(i) {
  readxl::read_excel(filepath, sheet = i, col_names = TRUE)
}) |>
  collapse::rowbind(fill = TRUE)

# 
tobacco_data_open <-
  tobacco_data |>
  dplyr::mutate(
    dplyr::across(
      dplyr::contains("영업상태"),
      ~as.factor(.)
    )
  )
summary(tobacco_data_open)

# 상세영업상태코드 0: 영업중
# no coordinates: 10682


tobacco_data_open <-
  tobacco_data_open |>
  dplyr::filter(
    상세영업상태코드 == "0"
  ) |>
  dplyr::mutate(
    X = as.numeric(`좌표정보X(EPSG5174)`),
    Y = as.numeric(`좌표정보Y(EPSG5174)`)
  )

# Explore NA coordinates
tobacco_data_open |>
  dplyr::filter(
    is.na(X)
  ) |>
  dplyr::select(사업장명)


# Subset not-NA coordinates
tobacco_sf <-
  tobacco_data_open |>
  dplyr::filter(
    !is.na(X) & !is.na(Y)
  ) |>
  sf::st_as_sf(
    coords = c("X", "Y"),
    crs = 5174
  ) |>
  sf::st_transform(4326) |>
  terra::vect()

# terra::plet(tobacco_sf)
terra::plot(tobacco_sf, col = "blue", pch = 19, cex = 0.1)
terra::writeVector(
  tobacco_sf,
  file.path(basedir, "tobacco_distributors.gpkg"),
  overwrite = TRUE
)

# Explore: point pattern
library(spatstat.explore)
library(geodata)
geodata::geodata_path("~/geodata")
kor_lv2 <- geodata::gadm(
  country = "KOR",
  level = 2,
  path = basedir,
  force = TRUE
)

kor_gw <- kor_lv2 |>
  sf::st_as_sf() |>
  sf::st_transform(5179) |>
  dplyr::filter(NAME_2 == "Gwanak") |>
  terra::vect()

tobacco_gwsf <- tobacco_sf |>
  terra::project("EPSG:5179") |>
  _[kor_gw, ]
tobacco_ppp <- as.ppp(st_as_sf(tobacco_gwsf))

tobacco_ppp_l <- Lest(tobacco_ppp, win = as.owin(kor_gw), nsim = 999, global = TRUE, correction = "bord.modif")
plot(tobacco_ppp_l, main = "Lest(tobacco_ppp)")

# TODO: identify duplicates
# TODO: rectify coordinates (i.e., one street address in a large area)