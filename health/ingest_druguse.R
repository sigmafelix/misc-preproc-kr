## Date: 2025-07-15
## Description: Drug use statistics data processing
## Outline: load Excel files, clean data, and export a cleaned data frame

if (!requireNamespace("pacman", quietly = TRUE)) {
  install.packages("pacman")
  requireNamespace("pacman")
}
pacman::p_load(
  readxl, dplyr, tidyr, stringr, purrr, yaml
)

# Function to process a single Excel file
process_single_file <-
  function(file_path, atc_code = "N06A") {
    # Extract metadata from filename
    filename <- basename(file_path)
    # Updated pattern to match your actual filename format
    pattern <-
      sprintf(
        "^%s_(.+)_(\\d{6})_(\\d{6})_202[1-9][0-1][1-9][0-3][0-9]\\((처방|조제)\\)\\.xlsx$",
        atc_code
      )

    if (!stringr::str_detect(filename, pattern)) {
      warning(paste("Filename does not match expected pattern:", filename))
      return(NULL)
    }

    # Extract components
    matches <- stringr::str_match(filename, pattern)
    region_name <- matches[2]
    begin_date <- matches[3]
    end_date <- matches[4]
    file_type <- matches[5] # 처방 or 조제

    message("Processing file: ", filename)
    message("Region: ", region_name, " Type: ", file_type)

    # Read the Excel file
    nc_detected <- ifelse(begin_date == "201801", 72, 100)
    ctyp <- c(rep("text", 5), rep("numeric", nc_detected))
    sheet_header <- readxl::read_excel(
      file_path,
      col_names = FALSE,
      n_max = 3
    )[3, ] %>% unlist()
    sheet_header <-
      c(
        rep(NA, 5),
        rep(na.omit(sheet_header[6:(length(sheet_header))]))
      )

    sheet_data <-
      readxl::read_excel(
        file_path,
        na = "-",
        skip = 3,
        col_names = TRUE
      )
    sheet_data <-
      sheet_data %>%
      dplyr::select(dplyr::where(~ !all(is.na(.)))) # Remove empty columns

    # Extract time periods from row 1 (which is now index 1 after skipping)
    time_periods <- as.character(sheet_data[1, ])
    time_periods <- time_periods[!is.na(time_periods) & time_periods != "기간"]

    # Create proper column names
    # First 5 columns are: ATC코드, ATC코드명, 시도명칭, 시군구명칭, 요양기관종별
    base_cols <- c("ATC코드", "ATC코드명", "시도명칭", "시군구명칭", "요양기관종별")
    time_periods <- stringr::str_replace_all(na.omit(sheet_header), "(년 |월)", "")

    # sheet_header <- c(base_cols, na.omit(sheet_header))
    # For the time series data, we have alternating 수량/금액 columns
    data_cols <- c()
    for (i in seq_along(time_periods)) {
      data_cols <- c(
        data_cols,
        paste0(time_periods[i], "_수량"),
        paste0(time_periods[i], "_금액")
      )
    }
    # return(data_cols)

    all_col_names <- c(base_cols, data_cols)

    # Read the actual data starting from row 3 (index 3 after skipping 2)
    data_start_row <- 3
    actual_data <-
      readxl::read_excel(
        file_path,
        skip = data_start_row + 1,
        col_names = FALSE,
        na = "-"
      )

    # Set column names (truncate if there are more columns than expected)
    ncol_data <- ncol(actual_data)
    ncol_expected <- length(all_col_names)

    # if (ncol_data > ncol_expected) {
    #   actual_data <- actual_data[, 1:ncol_expected]
    # } else if (ncol_data < ncol_expected) {
    #   all_col_names <- all_col_names[1:ncol_data]
    # }

    # Ensure all column names are valid and not empty
    all_col_names[is.na(all_col_names) | all_col_names == ""] <- paste0("col_", seq_along(all_col_names))[is.na(all_col_names) | all_col_names == ""]

    names(actual_data) <- all_col_names

    # Filter out summary rows (첫 번째 row가 "계"인 경우 등)
    actual_data <-
      actual_data[!is.na(actual_data[[1]]) & actual_data[[1]] != "계", ]

    # Add metadata columns
    actual_data$region_name <- region_name
    actual_data$file_type <- file_type
    actual_data$begin_date <- begin_date
    actual_data$end_date <- end_date
    actual_data$source_file <- filename

    # Convert to long format - FIXED VERSION
    # Identify quantity and amount columns
    qty_cols <-
      names(actual_data)[stringr::str_detect(names(actual_data), "_수량$")]
    amt_cols <-
      names(actual_data)[stringr::str_detect(names(actual_data), "_금액$")]

    # Create separate dataframes for quantities and amounts
    id_vars <- c(base_cols, "region_name", "file_type", "begin_date", "end_date", "source_file")

    # Quantity data
    qty_data <- actual_data %>%
      dplyr::select(dplyr::all_of(c(id_vars, qty_cols))) %>%
      dplyr::mutate(row_id = dplyr::row_number())

    # Rename quantity columns (remove _수량 suffix)
    qty_col_names <- names(qty_data)
    qty_col_names[qty_col_names %in% qty_cols] <- stringr::str_remove(qty_col_names[qty_col_names %in% qty_cols], "_수량$")
    names(qty_data) <- qty_col_names

    # Amount data
    amt_data <- actual_data %>%
      dplyr::select(dplyr::all_of(c(id_vars, amt_cols))) %>%
      dplyr::mutate(row_id = dplyr::row_number())

    # Rename amount columns (remove _금액 suffix)
    amt_col_names <- names(amt_data)
    amt_col_names[amt_col_names %in% amt_cols] <- stringr::str_remove(amt_col_names[amt_col_names %in% amt_cols], "_금액$")
    names(amt_data) <- amt_col_names

    # Pivot to long format
    qty_long <- qty_data %>%
      tidyr::pivot_longer(
        cols = -c(dplyr::all_of(id_vars), row_id),
        names_to = "year_month",
        values_to = "quantity"
      )

    amt_long <- amt_data %>%
      tidyr::pivot_longer(
        cols = -c(dplyr::all_of(id_vars), row_id),
        names_to = "year_month",
        values_to = "total_price"
      )

    # Merge quantity and amount data
    long_data <- qty_long %>%
      dplyr::left_join(
        amt_long,
        by = c(id_vars, "row_id", "year_month")
      ) %>%
      # Clean up the data
      dplyr::filter(!is.na(quantity) | !is.na(total_price)) %>%
      # Convert quantities and prices
      dplyr::mutate(
        # Convert "-" or empty strings to NA for numeric columns
        quantity = dplyr::case_when(
          quantity == "-" | quantity == "" | is.na(quantity) ~ NA_real_,
          TRUE ~ as.numeric(quantity)
        ),
        total_price = dplyr::case_when(
          total_price == "-" | total_price == "" | is.na(total_price) ~ NA_real_,
          TRUE ~ as.numeric(total_price)
        ),
        # Clean year_month format (remove "년", "월" and convert to YYYY-MM)
        year_month = stringr::str_replace_all(
          year_month, c("년 " = "-", "월" = "")
        )
      ) %>%
      # Fix year_month format more carefully
      dplyr::mutate(
        year_month = dplyr::case_when(
          stringr::str_detect(year_month, "^\\d{4}-\\d{1,2}$") ~ {
            parts <- stringr::str_split_fixed(year_month, "-", 2)
            paste0(parts[, 1], "-", stringr::str_pad(parts[, 2], 2, "left", "0"))
          },
          stringr::str_detect(year_month, "^\\d{4}년\\s*\\d{1,2}월$") ~ {
            year <- stringr::str_extract(year_month, "^\\d{4}")
            month <- stringr::str_extract(year_month, "\\d{1,2}(?=월)")
            paste0(year, "-", stringr::str_pad(month, 2, "left", "0"))
          },
          TRUE ~ year_month
        )
      ) %>%
      dplyr::select(-row_id)

    return(long_data)
  }

# Main function to process multiple files
process_multiple_files <-
  function(
      file_directory,
      file_pattern = "xlsx$",
      atc_code = "N06A") {
    # Get list of files matching the pattern
    all_files <- list.files(file_directory, pattern = file_pattern, full.names = TRUE)

    if (length(all_files) == 0) {
      stop("No files found matching the pattern in the specified directory")
    }

    message("Found ", length(all_files), " files to process.")

    # Process all files and combine
    all_data <- purrr::map_dfr(all_files, process_single_file, atc_code = atc_code)
    nalld <- nrow(all_data)
    message("Processed ", nalld, " rows from all files.")

    # Final data cleaning and standardization
    final_data <- all_data %>%
      # Remove rows where both quantity and price are NA
      dplyr::filter(!(is.na(quantity) & is.na(total_price))) %>%
      # Arrange data
      dplyr::arrange(region_name, file_type, ATC코드, 시군구명칭, 요양기관종별, year_month)

    return(final_data)
  }



tdir <- unlist(yaml::yaml.load(
  readLines("config.yaml")[1]
))
file_directory <- file.path(tdir, "drug", "data", "N06A")

sng <- process_single_file(
  file_path = file.path(
    file_directory,
    "N06A_광주_201801_202012_20250712(처방).xlsx"
  ),
  atc_code = "N06A"
)


# Process all files
combined_data <- process_multiple_files(file_directory, atc_code = "N06A")

# lookup table
lookup <- readxl::read_excel(file.path("health", "sigungu_nhis.xlsx"))

# convert
combined_data_sgg <-
  combined_data |>
  dplyr::left_join(
    lookup[, c(1, 6, 7)],
    by = c("시도명칭" = "sdnhis", "시군구명칭" = "sggnhis"),
    relationship = "many-to-many"
  ) |>
  dplyr::select(
    sggcd, region_name, 시군구명칭,
    ATC코드, ATC코드명, 요양기관종별,
    year_month,
    file_type, begin_date, end_date,
    quantity, total_price
  ) |>
  dplyr::arrange(region_name, 시군구명칭, 요양기관종별, year_month)

# export
nanoparquet::write_parquet(
  combined_data_sgg,
  file.path(tdir, "drug", "data", "druguse_N06A.parquet")
)
