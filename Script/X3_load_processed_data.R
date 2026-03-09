# ==============================================================================
# LOAD PROCESSED DATA TO DATABASE
# ==============================================================================
# File: 03_load_processed_data.R
# Purpose: Load processed CSV files from data/processed to database
# Author: Kelompok 3 - Pemrosesan Data Besar
# Input: CSV files from data/processed/ folder
# Output: Database tables (dim_* and fact_*)
# ==============================================================================

# Load required libraries
library(tidyverse)
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

INPUT_DIR <- "data/processed"

# Table names and their corresponding CSV files
TABLES <- list(
  dim_customer = "dim_customer.csv",
  dim_store = "dim_store.csv",
  dim_category = "dim_category.csv",
  dim_product = "dim_product.csv",
  fact_transaction = "fact_transaction.csv",
  fact_transaction_detail = "fact_transaction_detail.csv"
)

# ==============================================================================
# STEP 1: VERIFY CSV FILES EXIST
# ==============================================================================

cat("=== STEP 1: VERIFYING CSV FILES ===\n\n")

missing_files <- c()

for (table_name in names(TABLES)) {
  csv_file <- TABLES[[table_name]]
  file_path <- file.path(INPUT_DIR, csv_file)
  
  if (file.exists(file_path)) {
    cat(paste0("✓ Found: ", csv_file, "\n"))
  } else {
    cat(paste0("✗ Missing: ", csv_file, "\n"))
    missing_files <- c(missing_files, csv_file)
  }
}

if (length(missing_files) > 0) {
  cat("\n✗ Error: Missing CSV files!\n")
  cat("Please run 02_etl_process.R first to generate CSV files.\n")
  stop("Missing required CSV files")
}

cat("\n✓ All CSV files found\n\n")

# ==============================================================================
# STEP 2: CONNECT TO DATABASE
# ==============================================================================

cat("=== STEP 2: CONNECTING TO DATABASE ===\n\n")

source("con/connection.R")

# ==============================================================================
# STEP 3: LOAD DIMENSION TABLES
# ==============================================================================

cat("=== STEP 3: LOADING DIMENSION TABLES ===\n\n")

# Order: Load dimensions first (no FK dependencies)
dim_tables <- c("dim_customer", "dim_store", "dim_category", "dim_product")

for (table_name in dim_tables) {
  csv_file <- TABLES[[table_name]]
  file_path <- file.path(INPUT_DIR, csv_file)
  
  cat(paste0("Loading ", table_name, "...\n"))
  
  # Read CSV
  data <- read_csv(file_path, show_col_types = FALSE)
  cat(paste0("  Read: ", nrow(data), " rows from ", csv_file, "\n"))
  
  # Check if table exists
  if (dbExistsTable(con, table_name)) {
    cat(paste0("  ⚠ Table '", table_name, "' exists. Dropping...\n"))
    dbRemoveTable(con, table_name)
  }
  
  # Write to database
  tryCatch({
    dbWriteTable(
      conn = con,
      name = table_name,
      value = data,
      overwrite = FALSE,
      row.names = FALSE
    )
    
    # Verify
    row_count <- dbGetQuery(con, paste0("SELECT COUNT(*) as count FROM ", table_name))
    cat(paste0("  ✓ Loaded: ", row_count$count, " rows to ", table_name, "\n\n"))
    
  }, error = function(e) {
    cat(paste0("  ✗ Error loading ", table_name, ": ", e$message, "\n\n"))
    dbDisconnect(con)
    stop(paste0("Failed to load ", table_name))
  })
}

# ==============================================================================
# STEP 4: LOAD FACT TABLES
# ==============================================================================

cat("=== STEP 4: LOADING FACT TABLES ===\n\n")

# Order: Load facts after dimensions (FK dependencies)
fact_tables <- c("fact_transaction", "fact_transaction_detail")

for (table_name in fact_tables) {
  csv_file <- TABLES[[table_name]]
  file_path <- file.path(INPUT_DIR, csv_file)
  
  cat(paste0("Loading ", table_name, "...\n"))
  
  # Read CSV
  data <- read_csv(file_path, show_col_types = FALSE)
  cat(paste0("  Read: ", nrow(data), " rows from ", csv_file, "\n"))
  
  # Check if table exists
  if (dbExistsTable(con, table_name)) {
    cat(paste0("  ⚠ Table '", table_name, "' exists. Dropping...\n"))
    dbRemoveTable(con, table_name)
  }
  
  # Write to database
  tryCatch({
    dbWriteTable(
      conn = con,
      name = table_name,
      value = data,
      overwrite = FALSE,
      row.names = FALSE
    )
    
    # Verify
    row_count <- dbGetQuery(con, paste0("SELECT COUNT(*) as count FROM ", table_name))
    cat(paste0("  ✓ Loaded: ", row_count$count, " rows to ", table_name, "\n\n"))
    
  }, error = function(e) {
    cat(paste0("  ✗ Error loading ", table_name, ": ", e$message, "\n\n"))
    dbDisconnect(con)
    stop(paste0("Failed to load ", table_name))
  })
}

# ==============================================================================
# STEP 5: VERIFY DATA INTEGRITY
# ==============================================================================

cat("=== STEP 5: VERIFYING DATA INTEGRITY ===\n\n")

cat("Checking referential integrity...\n\n")

# Check orphan transactions
orphan_transactions <- dbGetQuery(con, "
  SELECT COUNT(*) as count
  FROM fact_transaction ft
  LEFT JOIN dim_customer dc ON ft.customer_id = dc.customer_id
  WHERE dc.customer_id IS NULL
")

if (orphan_transactions$count == 0) {
  cat("✓ No orphan transactions (all have valid customer_id)\n")
} else {
  cat(paste0("⚠ Found ", orphan_transactions$count, " orphan transactions\n"))
}

# Check orphan transaction details
orphan_details <- dbGetQuery(con, "
  SELECT COUNT(*) as count
  FROM fact_transaction_detail ftd
  LEFT JOIN fact_transaction ft ON ftd.invoice_id = ft.invoice_id
  WHERE ft.invoice_id IS NULL
")

if (orphan_details$count == 0) {
  cat("✓ No orphan transaction details (all have valid invoice_id)\n")
} else {
  cat(paste0("⚠ Found ", orphan_details$count, " orphan transaction details\n"))
}

# Check orphan products
orphan_products <- dbGetQuery(con, "
  SELECT COUNT(*) as count
  FROM fact_transaction_detail ftd
  LEFT JOIN dim_product dp ON ftd.product_id = dp.product_id
  WHERE dp.product_id IS NULL
")

if (orphan_products$count == 0) {
  cat("✓ No orphan transaction details (all have valid product_id)\n")
} else {
  cat(paste0("⚠ Found ", orphan_products$count, " transaction details with invalid product_id\n"))
}

cat("\n")

# ==============================================================================
# STEP 6: DISPLAY SUMMARY
# ==============================================================================

cat("=== STEP 6: DATA LOAD SUMMARY ===\n\n")

cat("Database Tables:\n")
cat("----------------\n\n")

cat("Dimension Tables:\n")
for (table_name in dim_tables) {
  row_count <- dbGetQuery(con, paste0("SELECT COUNT(*) as count FROM ", table_name))
  cat(paste0("  ", sprintf("%-25s", table_name), ": ", 
             format(row_count$count, big.mark = ","), " rows\n"))
}

cat("\nFact Tables:\n")
for (table_name in fact_tables) {
  row_count <- dbGetQuery(con, paste0("SELECT COUNT(*) as count FROM ", table_name))
  cat(paste0("  ", sprintf("%-25s", table_name), ": ", 
             format(row_count$count, big.mark = ","), " rows\n"))
}

cat("\n")

# Sample data
cat("Sample Data (first 3 rows):\n")
cat("---------------------------\n\n")

for (table_name in names(TABLES)) {
  cat(paste0(table_name, ":\n"))
  sample_data <- dbGetQuery(con, paste0("SELECT * FROM ", table_name, " LIMIT 3"))
  print(sample_data)
  cat("\n")
}

# ==============================================================================
# STEP 7: CLOSE CONNECTION
# ==============================================================================

cat("=== STEP 7: CLOSING CONNECTION ===\n\n")

dbDisconnect(con)
cat("✓ Connection closed\n\n")

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================

cat("=== PROCESS COMPLETED ===\n\n")
cat("✓ All processed CSV files successfully loaded to database\n")
cat("✓ Data integrity verified\n")
cat("✓ Database ready for analysis\n\n")

cat("Database Structure:\n")
cat("  - 4 Dimension Tables (Customer, Store, Category, Product)\n")
cat("  - 2 Fact Tables (Transaction, Transaction_Detail)\n")
cat("  - Pure 3NF implementation\n")
cat("  - Ready for analytical queries\n\n")

cat("Next steps:\n")
cat("  1. Run analytical queries\n")
cat("  2. Create views for convenience\n")
cat("  3. Generate reports\n")

# ==============================================================================
# END OF SCRIPT
# ==============================================================================
