# ==============================================================================
# LOAD RAW DATA TO DATABASE
# ==============================================================================
# File: 01_load_raw_data.R
# Purpose: Load raw CSV data from data/raw folder to database
# Author: Kelompok 3 - Pemrosesan Data Besar
# Input: data/raw/Dataset_Retail.csv 
# Output: Database table `Dataset Retail Raw`
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

RAW_TABLE_NAME <- "Dataset Retail Raw"

# PATH 
RAW_DATA_PATH <- "data/raw/Dataset_Retail.csv"

# Check if file exists
if (!file.exists(RAW_DATA_PATH)) {
  cat("✗ File not found:", RAW_DATA_PATH, "\n")
  cat("\nPossible solutions:\n")
  cat("1. Edit RAW_DATA_PATH in this script to match your file location\n")
  cat("2. Create folder structure: data/raw/ and place CSV file there\n")
  cat("3. Uncomment line below to browse for file manually:\n")
  cat("   # RAW_DATA_PATH <- file.choose()\n\n")
  stop("CSV file not found. Please check path.")
}

cat("✓ Found CSV file at:", RAW_DATA_PATH, "\n\n")

# ==============================================================================
# STEP 1: READ RAW CSV DATA
# ==============================================================================

cat("=== STEP 1: READING RAW DATA ===\n\n")

# Read CSV file
raw_data <- read_csv(
  RAW_DATA_PATH,
  show_col_types = FALSE,
  locale = locale(encoding = "UTF-8")
)

cat(paste0("✓ Raw data loaded from: ", RAW_DATA_PATH, "\n"))
cat(paste0("  Rows: ", nrow(raw_data), "\n"))
cat(paste0("  Columns: ", ncol(raw_data), "\n\n"))

# ==============================================================================
# STEP 2: CONNECT TO DATABASE
# ==============================================================================

cat("=== STEP 2: CONNECTING TO DATABASE ===\n\n")

source("con/connection.R")

# ==============================================================================
# STEP 3: LOAD DATA TO DATABASE
# ==============================================================================

cat("=== STEP 3: LOADING DATA TO DATABASE ===\n\n")

# Check if table already exists
table_exists <- dbExistsTable(con, RAW_TABLE_NAME)

if (table_exists) {
  cat(paste0("⚠ Table '", RAW_TABLE_NAME, "' already exists!\n"))
  cat("Dropping old table and creating new one...\n")
  dbRemoveTable(con, RAW_TABLE_NAME)
}

# Write data to database
tryCatch({
  dbWriteTable(
    conn = con,
    name = RAW_TABLE_NAME,
    value = raw_data,
    overwrite = FALSE,
    row.names = FALSE
  )
  
  cat(paste0("✓ Data successfully loaded to table: '", RAW_TABLE_NAME, "'\n"))
  cat(paste0("  Rows inserted: ", nrow(raw_data), "\n\n"))
  
}, error = function(e) {
  cat("✗ Error loading data to database!\n")
  cat(paste0("  Error: ", e$message, "\n"))
  dbDisconnect(con)
  stop("Data load failed")
})

# ==============================================================================
# STEP 4: VERIFY DATA LOAD
# ==============================================================================

cat("=== STEP 4: VERIFYING DATA LOAD ===\n\n")

# Count rows in database
row_count <- dbGetQuery(con, paste0("SELECT COUNT(*) as count FROM `", RAW_TABLE_NAME, "`"))
cat(paste0("Rows in database: ", row_count$count, "\n"))

# Get first few rows
sample_data <- dbGetQuery(con, paste0("SELECT * FROM `", RAW_TABLE_NAME, "` LIMIT 3"))
cat("\nFirst 3 rows from database:\n")
print(sample_data)
cat("\n")

# Verify row counts match
if (row_count$count == nrow(raw_data)) {
  cat("✓ Data verification successful! Row counts match.\n\n")
} else {
  cat("⚠ Warning: Row count mismatch!\n")
  cat(paste0("  CSV rows: ", nrow(raw_data), "\n"))
  cat(paste0("  DB rows: ", row_count$count, "\n\n"))
}

# ==============================================================================
# STEP 5: CLOSE CONNECTION
# ==============================================================================

cat("=== STEP 5: CLOSING CONNECTION ===\n\n")

dbDisconnect(con)
cat("✓ Connection closed\n\n")

# ==============================================================================
# SUMMARY
# ==============================================================================

cat("=== PROCESS COMPLETED ===\n")
cat("✓ Raw data successfully loaded to database\n")
cat(paste0("  Table: '", RAW_TABLE_NAME, "'\n"))
cat(paste0("  Rows: ", nrow(raw_data), "\n"))
cat(paste0("  Columns: ", ncol(raw_data), "\n"))

# ==============================================================================
# END OF SCRIPT
# ==============================================================================
