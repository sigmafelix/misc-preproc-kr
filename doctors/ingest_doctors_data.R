## Date: 2025-11-02
## Title: Clean doctors data by specialties

source("load_packages.R")


doctor_files <- list.files(
  path = "doctors",
  pattern = ".xlsx$",
  full.names = TRUE
)

doctor_data <-
  lapply(doctor_files, readxl::read_excel) |>
  dplyr::bind_rows()

names(doctor_data) <-
  c("sggcd", "sggnm", "specialty_code", "specialty_name",
    "item_code", "item", "unit",
    "value_2010", "value_2015", "value_2020")

doctor_df <-
  doctor_data |>
  dplyr::mutate(
    sggcd = stringi::stri_extract_last_regex(sggcd, pattern = "\\d{6,6}"),
    class2 = dplyr::case_when(
      specialty_code == "A001" ~ "total",
      specialty_code == "A002" ~ "internal medicine",
      specialty_code == "A003" ~ "neurology",
      specialty_code == "A004" ~ "psychiatry",
      specialty_code == "A005" ~ "surgery",
      specialty_code == "A006" ~ "orthopedics",
      specialty_code == "A007" ~ "neurosurgery",
      specialty_code == "A008" ~ "thoracic and cardiovascular surgery",
      specialty_code == "A009" ~ "plastic surgery",
      specialty_code == "A010" ~ "anesthesiology and pain medicine",
      specialty_code == "A011" ~ "obstetrics and gynecology",
      specialty_code == "A012" ~ "pediatrics",
      specialty_code == "A013" ~ "ophthalmology",
      specialty_code == "A014" ~ "otorhinolaryngology",
      specialty_code == "A015" ~ "dermatology",
      specialty_code == "A016" ~ "urology",
      specialty_code == "A017" ~ "radiology",
      specialty_code == "A018" ~ "radiation oncology",
      specialty_code == "A019" ~ "pathology",
      specialty_code == "A020" ~ "clinical laboratory medicine",
      specialty_code == "A021" ~ "tuberculosis",
      specialty_code == "A022" ~ "rehabilitation medicine",
      specialty_code == "A023" ~ "nuclear medicine",
      specialty_code == "A024" ~ "family medicine",
      specialty_code == "A025" ~ "emergency medicine",
      specialty_code == "A026" ~ "occupational and environmental medicine",
      specialty_code == "A027" ~ "preventive medicine",
      TRUE ~ specialty_name
    ),
    class1 = "doctors",
    type = "medicine",
    unit = "persons"
  ) |>
  dplyr::select(
    sggcd, type, class1, class2, unit,
    value_2010, value_2015, value_2020
  ) |>
  collapse::pivot(
    ids = c("sggcd", "type", "class1", "class2", "unit"),
    values = c("value_2010", "value_2015", "value_2020"),
    how = "longer"
  ) |>
  dplyr::mutate(
    year = as.integer(stringi::stri_extract_first_regex(variable, pattern = "\\d{4,4}$"))
  ) |>
  dplyr::select(
    -variable
  )
