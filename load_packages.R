
if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
}

pacman::p_load(dplyr, janitor, tidyr, lubridate, sf, stringi, readxl, collapse, yaml, readr, nanoparquet)
set_collapse(mask = "manip")
options(sf_use_s2 = FALSE)

## base directory
base_dir <- unlist(yaml::read_yaml("config.yaml"))

