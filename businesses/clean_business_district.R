## business district data
## from: https://www.data.go.kr/data/15083033/fileData.do
library(yaml)
library(data.table)
basedir <- unlist(yaml::read_yaml("./config.yaml"))["basedir_ws2"]


# read
data_dir <- file.path(basedir, "business_district")
flist <- list.files(path = data_dir, pattern = "*.csv$", full.names = TRUE)
years <- stringi::stri_extract_first_regex(flist, pattern = "20[1-2][0-9]")

bdlist <- lapply(flist, function(path) {
  read.csv(path, fileEncoding = "UTF-8")
})


bdlistdf <- collapse::rowbind(bdlist, fill = TRUE)
dim(bdlistdf)

bdlistsf <- bdlistdf |>
  sf::st_as_sf(coords = c("경도", "위도"), crs = 4326)
sf::st_write(
  bdlistsf,
  file.path(data_dir, "business_district.gpkg")
)


# read the exported gpkg
bdlistsf <- sf::st_read(
  file.path(data_dir, "business_district.gpkg")
)

table(bdlistsf[["상권업종소분류명"]])
