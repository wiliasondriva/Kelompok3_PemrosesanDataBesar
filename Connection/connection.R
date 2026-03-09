# ==============================================================================
# DATABASE CONNECTION
# ==============================================================================
# File: connection.R
# Purpose: Database connection 
# Author: Kelompok 3 - Pemrosesan Data Besar
# ==============================================================================

# Load library
library(DBI)
library(RMariaDB)

# Database configuration
DB_NAME <- "retaildatabase2"
DB_USER <- "root"
DB_PASS <- ""
DB_HOST <- "127.0.0.1"
DB_PORT <- 3307

# Create connection
con <- dbConnect(
  RMariaDB::MariaDB(),
  dbname = DB_NAME,
  user = DB_USER,
  password = DB_PASS,
  host = DB_HOST,
  port = DB_PORT
)

cat("✓ Connected to database:", DB_NAME, "\n")

# ==============================================================================
# END OF CONNECTION FILE
# ==============================================================================
