# ==============================================================================
# ETL PROCESS - DATA TRANSFORMATION
# ==============================================================================
# File: 02_etl_process.R
# Purpose: Extract raw data from database, transform, save to data/processed
# Author: Kelompok 3 - Pemrosesan Data Besar
# Input: Database table `Dataset Retail Raw`
# Output: CSV files in data/processed/ folder
# ==============================================================================

# Load required libraries
library(tidyverse)
library(lubridate)
library(stringr)
library(DBI)
library(RMariaDB)

# ==============================================================================
# SET WORKING DIRECTORY
# ==============================================================================

# PATH 
setwd("C:/Users/Ni Made Ray Diantari/KELOMPOK")

cat("Working directory:", getwd(), "\n\n")

# ==============================================================================
# CONFIGURATION
# ==============================================================================

OUTPUT_DIR <- "data/processed"
RAW_TABLE_NAME <- "Dataset Retail Raw"

# Create output directory if not exists
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
  cat(paste0("✓ Created directory: ", OUTPUT_DIR, "\n\n"))
}

# ==============================================================================
# STEP 1: EXTRACT RAW DATA FROM DATABASE
# ==============================================================================

cat("=== STEP 1: EXTRACTING RAW DATA FROM DATABASE ===\n\n")

source("con/connection.R")

raw_df <- dbGetQuery(con, paste0("SELECT * FROM `", RAW_TABLE_NAME, "`"))

cat(paste0("✓ Data extracted: ", nrow(raw_df), " rows, ", ncol(raw_df), " columns\n\n"))

# Close connection (tidak perlu lagi setelah extract)
dbDisconnect(con)
cat("✓ Connection closed (data extracted)\n\n")

# ==============================================================================
# STEP 2: STANDARDIZATION
# ==============================================================================

cat("=== STEP 2: STANDARDIZATION ===\n\n")

# Column name standardization
colnames(raw_df) <- raw_df %>%
  colnames() %>%
  str_to_lower() %>%
  str_replace_all(" ", "_") %>%
  str_replace_all("[^a-z0-9_]", "")

# Data type conversion
raw_df <- raw_df %>%
  mutate(
    invoice_datetime = ymd_hms(invoice_datetime),
    store_open_date  = ymd(store_open_date),
    birth_date       = ymd(birth_date),
    quantity = as.numeric(quantity),
    product_price = as.numeric(product_price),
    across(where(is.character), ~str_trim(.x))
  )

# Convert empty strings to NA
raw_df <- raw_df %>%
  mutate(
    brand = if_else(brand == "", NA_character_, brand),
    product_description = if_else(product_description == "", NA_character_, product_description)
  )

cat("✓ Standardization completed\n\n")

# ==============================================================================
# STEP 3: DATA CLEANING
# ==============================================================================

cat("=== STEP 3: DATA CLEANING ===\n\n")

# Handle duplicate line items
invoice_clean <- raw_df %>%
  group_by(invoice_id, product_name) %>%
  summarise(
    quantity = sum(quantity, na.rm = TRUE),
    product_price = mean(product_price, na.rm = TRUE),
    invoice_datetime = first(invoice_datetime),
    customer_name = first(customer_name),
    gender = first(gender),
    birth_date = first(birth_date),
    customer_city = first(customer_city),
    store_name = first(store_name),
    store_city = first(store_city),
    store_type = first(store_type),
    store_province = first(store_province),
    store_open_date = first(store_open_date),
    payment_method = first(payment_method),
    brand = first(brand),
    category_lvl1 = first(category_lvl1),
    category_lvl2 = first(category_lvl2),
    product_description = first(product_description),
    .groups = "drop"
  )

cat(paste0("Duplicate items merged: ", nrow(raw_df) - nrow(invoice_clean), " rows\n"))

# Standardize & clean data
invoice_clean <- invoice_clean %>%
  mutate(
    customer_name = str_to_upper(str_trim(customer_name)),
    customer_city = str_to_title(str_trim(customer_city)),
    gender = str_to_upper(str_trim(gender)),
    
    # Age validation (set invalid birth_date to NULL)
    age = interval(birth_date, Sys.Date()) %/% years(1),
    birth_date = if_else(
      !is.na(age) & (age < 5 | age > 100), 
      NA_Date_, 
      birth_date
    ),
    
    store_name = str_to_upper(str_trim(store_name)),
    store_city = str_to_title(str_trim(store_city)),
    store_province = str_to_title(str_trim(store_province)),
    store_type = str_to_title(str_trim(store_type)),
    payment_method = str_to_lower(str_trim(payment_method)),
    product_name = str_to_upper(str_trim(product_name)),
    brand = str_to_title(str_trim(brand)),
    category_lvl1 = str_to_title(str_trim(category_lvl1)),
    category_lvl2 = str_to_title(str_trim(category_lvl2)),
    
    # Business validation
    quantity = if_else(quantity <= 0, NA_real_, quantity),
    product_price = if_else(product_price <= 0, NA_real_, product_price)
  ) %>%
  select(-age)

# Remove rows with critical nulls
rows_before <- nrow(invoice_clean)

invoice_clean <- invoice_clean %>%
  filter(
    !is.na(invoice_id),
    !is.na(product_name),
    !is.na(quantity),
    !is.na(product_price),
    !is.na(store_name),
    !is.na(invoice_datetime)
  )

cat(paste0("Critical nulls removed: ", rows_before - nrow(invoice_clean), " rows\n"))

# Fix category hierarchy
category_mapping <- invoice_clean %>%
  group_by(category_lvl2, category_lvl1) %>%
  summarise(count = n(), .groups = "drop") %>%
  group_by(category_lvl2) %>%
  slice_max(count, n = 1, with_ties = FALSE) %>%
  select(category_lvl2, category_lvl1_correct = category_lvl1)

invoice_clean <- invoice_clean %>%
  select(-category_lvl1) %>%
  left_join(category_mapping, by = "category_lvl2") %>%
  rename(category_lvl1 = category_lvl1_correct)

cat("✓ Data cleaning completed\n")
cat(paste0("Final clean dataset: ", nrow(invoice_clean), " rows\n\n"))

# ==============================================================================
# STEP 4: CREATE DIMENSION TABLES
# ==============================================================================

cat("=== STEP 4: CREATING DIMENSION TABLES ===\n\n")

# dim_customer (registered customers only)
dim_customer_registered <- invoice_clean %>%
  filter(
    !is.na(customer_name), customer_name != "",
    !is.na(customer_city), customer_city != "",
    !is.na(gender), gender != "",
    !is.na(birth_date)
  ) %>%
  distinct(customer_name, customer_city, gender, birth_date) %>%
  mutate(customer_id = row_number()) %>%
  select(customer_id, customer_name, gender, birth_date, customer_city)

# Add unknown customer (customer_id = 0)
unknown_customer <- tibble(
  customer_id = 0L,
  customer_name = "UNKNOWN CUSTOMER",
  gender = NA_character_,
  birth_date = NA_Date_,
  customer_city = "UNKNOWN"
)

dim_customer <- bind_rows(unknown_customer, dim_customer_registered)

cat(paste0("1. dim_customer: ", nrow(dim_customer), " customers\n"))

# dim_store
dim_store <- invoice_clean %>%
  distinct(store_name, store_city, store_type, store_province, store_open_date) %>%
  filter(!is.na(store_name)) %>%
  mutate(store_id = row_number()) %>%
  select(store_id, store_name, store_city, store_type, store_province, store_open_date)

cat(paste0("2. dim_store: ", nrow(dim_store), " stores\n"))

# dim_category
dim_category <- invoice_clean %>%
  distinct(category_lvl1, category_lvl2) %>%
  filter(!is.na(category_lvl1), !is.na(category_lvl2)) %>%
  mutate(category_id = row_number()) %>%
  select(category_id, category_lvl1, category_lvl2)

cat(paste0("3. dim_category: ", nrow(dim_category), " categories\n"))

# dim_product
dim_product <- invoice_clean %>%
  distinct(product_name, brand, category_lvl1, category_lvl2) %>%
  filter(!is.na(product_name)) %>%
  left_join(
    dim_category %>% select(category_id, category_lvl1, category_lvl2),
    by = c("category_lvl1", "category_lvl2")
  ) %>%
  mutate(product_id = row_number()) %>%
  left_join(
    invoice_clean %>%
      group_by(product_name, brand) %>%
      summarise(product_description = first(product_description), .groups = "drop"),
    by = c("product_name", "brand")
  ) %>%
  mutate(
    brand = if_else(is.na(brand), "UNKNOWN", brand),
    product_description = if_else(is.na(product_description), 
                                   "No description available", 
                                   product_description)
  ) %>%
  select(product_id, product_name, brand, product_description, category_id)

cat(paste0("4. dim_product: ", nrow(dim_product), " products\n\n"))

# ==============================================================================
# STEP 5: CREATE FACT TABLES
# ==============================================================================

cat("=== STEP 5: CREATING FACT TABLES ===\n\n")

# fact_transaction
fact_transaction <- invoice_clean %>%
  left_join(
    dim_customer %>% 
      filter(customer_id > 0) %>%
      select(customer_id, customer_name, gender, birth_date, customer_city),
    by = c("customer_name", "gender", "birth_date", "customer_city")
  ) %>%
  mutate(
    customer_id = if_else(is.na(customer_id), 0L, customer_id)
  ) %>%
  left_join(
    dim_store %>% select(store_id, store_name, store_city, store_type, 
                         store_province, store_open_date),
    by = c("store_name", "store_city", "store_type", "store_province", "store_open_date")
  ) %>%
  distinct(invoice_id, .keep_all = TRUE) %>%
  filter(!is.na(store_id)) %>%
  select(
    invoice_id, 
    invoice_datetime,
    payment_method,
    customer_id,
    store_id
  )

cat(paste0("1. fact_transaction: ", nrow(fact_transaction), " transactions\n"))
cat(paste0("   - Unknown customers: ", sum(fact_transaction$customer_id == 0), "\n"))
cat(paste0("   - Registered customers: ", sum(fact_transaction$customer_id > 0), "\n"))

# fact_transaction_detail (NO line_total - Pure 3NF)
fact_transaction_detail <- invoice_clean %>%
  left_join(
    dim_product %>% select(product_id, product_name, brand),
    by = c("product_name", "brand")
  ) %>%
  filter(!is.na(invoice_id), !is.na(product_id)) %>%
  select(
    invoice_id, 
    product_id, 
    quantity, 
    product_price
    # NOTE: line_total NOT stored (Pure 3NF)
  )

cat(paste0("2. fact_transaction_detail: ", nrow(fact_transaction_detail), " line items\n"))
cat("   Note: line_total NOT stored (Pure 3NF - calculate as qty × price)\n\n")

# ==============================================================================
# STEP 6: SAVE TO CSV FILES
# ==============================================================================

cat("=== STEP 6: SAVING TO CSV FILES ===\n\n")

# Save dimension tables
write_csv(dim_customer, file.path(OUTPUT_DIR, "dim_customer.csv"))
cat(paste0("✓ Saved: ", OUTPUT_DIR, "/dim_customer.csv (", nrow(dim_customer), " rows)\n"))

write_csv(dim_store, file.path(OUTPUT_DIR, "dim_store.csv"))
cat(paste0("✓ Saved: ", OUTPUT_DIR, "/dim_store.csv (", nrow(dim_store), " rows)\n"))

write_csv(dim_category, file.path(OUTPUT_DIR, "dim_category.csv"))
cat(paste0("✓ Saved: ", OUTPUT_DIR, "/dim_category.csv (", nrow(dim_category), " rows)\n"))

write_csv(dim_product, file.path(OUTPUT_DIR, "dim_product.csv"))
cat(paste0("✓ Saved: ", OUTPUT_DIR, "/dim_product.csv (", nrow(dim_product), " rows)\n"))

# Save fact tables
write_csv(fact_transaction, file.path(OUTPUT_DIR, "fact_transaction.csv"))
cat(paste0("✓ Saved: ", OUTPUT_DIR, "/fact_transaction.csv (", nrow(fact_transaction), " rows)\n"))

write_csv(fact_transaction_detail, file.path(OUTPUT_DIR, "fact_transaction_detail.csv"))
cat(paste0("✓ Saved: ", OUTPUT_DIR, "/fact_transaction_detail.csv (", nrow(fact_transaction_detail), " rows)\n\n"))

# ==============================================================================
# SUMMARY
# ==============================================================================

cat("=== ETL PROCESS COMPLETED ===\n\n")

cat("Summary:\n")
cat("--------\n")
cat(paste0("Input:  Database table '", RAW_TABLE_NAME, "' (", nrow(raw_df), " rows)\n"))
cat(paste0("Output: ", OUTPUT_DIR, "/ (6 CSV files)\n\n"))

cat("Dimension Tables:\n")
cat(paste0("  - dim_customer.csv: ", nrow(dim_customer), " customers\n"))
cat(paste0("  - dim_store.csv: ", nrow(dim_store), " stores\n"))
cat(paste0("  - dim_category.csv: ", nrow(dim_category), " categories\n"))
cat(paste0("  - dim_product.csv: ", nrow(dim_product), " products\n\n"))

cat("Fact Tables:\n")
cat(paste0("  - fact_transaction.csv: ", nrow(fact_transaction), " transactions\n"))
cat(paste0("  - fact_transaction_detail.csv: ", nrow(fact_transaction_detail), " line items\n\n"))

cat("Design Notes:\n")
cat("  - Pure 3NF implementation\n")
cat("  - age NOT stored (calculate from birth_date)\n")
cat("  - line_total NOT stored (calculate as qty × price)\n")
cat("  - customer_id = 0 for unknown/guest customers\n\n")

cat("Next step: Run 03_load_processed_data.R to load CSV files to database\n")

# ==============================================================================
# END OF SCRIPT
# ==============================================================================
