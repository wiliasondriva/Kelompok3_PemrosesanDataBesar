#==============================================================================
library(shiny)
library(bs4Dash)
library(DBI)
library(RMySQL)
library(plotly)
library(dplyr)
library(scales)
library(fresh)
library(ggplot2)
library(gridExtra)
library(DT)
# ── DB Connection ────────────────────────────────────────────────────────────

con <- dbConnect(
  RMySQL::MySQL(),
  dbname = "retaildatabase",
  host = "127.0.0.1",
  port = 3306,
  user = "root",
  password = ""
)

# ── Helper Functions ─────────────────────────────────────────────────────────
build_where <- function(date_start, date_end, province = "all", store_type = "all") {
  clauses <- c(sprintf("DATE(ft.invoice_datetime) BETWEEN '%s' AND '%s'", date_start, date_end))
  if (!is.null(province)   && province   != "all") clauses <- c(clauses, sprintf("ds.store_province = '%s'", province))
  if (!is.null(store_type) && store_type != "all") clauses <- c(clauses, sprintf("ds.store_type = '%s'", store_type))
  paste("WHERE", paste(clauses, collapse = " AND "))
}

build_where_cust <- function(date_start, date_end, province = "all",
                             store_type = "all", city = "all") {
  clauses <- c(sprintf("DATE(ft.invoice_datetime) BETWEEN '%s' AND '%s'", date_start, date_end))
  if (!is.null(province)   && province   != "all") clauses <- c(clauses, sprintf("ds.store_province = '%s'", province))
  if (!is.null(store_type) && store_type != "all") clauses <- c(clauses, sprintf("ds.store_type = '%s'", store_type))
  if (!is.null(city)       && city       != "all") clauses <- c(clauses, sprintf("dc.customer_city = '%s'", city))
  paste("WHERE", paste(clauses, collapse = " AND "))
}

fmt_rupiah <- function(x) {
  if (is.na(x) || is.null(x)) return("Rp 0")
  x <- as.numeric(x)
  if (x >= 1e9) return(paste0("Rp ", round(x/1e9,2), "B"))
  if (x >= 1e6) return(paste0("Rp ", round(x/1e6,2), "M"))
  if (x >= 1e3) return(paste0("Rp ", round(x/1e3,1), "K"))
  paste0("Rp ", scales::comma(x))
}

fmt_num <- function(x) {
  if (is.na(x) || is.null(x)) return("0")
  x <- as.numeric(x)
  if (x >= 1e6) return(paste0(round(x/1e6,2), "M"))
  if (x >= 1e3) return(paste0(round(x/1e3,1), "K"))
  scales::comma(x)
}

prev_period <- function(date_start, date_end) {
  start <- as.Date(date_start); end <- as.Date(date_end)
  dur   <- as.numeric(end - start)
  list(start = as.character(start - dur - 1), end = as.character(end - dur - 1))
}

pct_badge <- function(current, previous) {
  current <- as.numeric(current); previous <- as.numeric(previous)
  if (is.na(previous) || is.null(previous) || previous == 0)
    return(list(text = "N/A", color = "#94A3B8", arrow = "\u2022"))
  pct <- (current - previous) / abs(previous) * 100
  list(text  = sprintf("%.1f%%", abs(pct)),
       color = if (pct >= 0) "#10B981" else "#EF4444",
       arrow = if (pct >= 0) "\u25b2" else "\u25bc",
       pct   = pct)
}

query_kpi_val <- function(where_clause, kpi) {
  need_detail <- kpi %in% c("revenue", "items_sold", "basket", "aov")
  join_detail <- if (need_detail) "JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id" else ""
  select_col  <- switch(kpi,
                        "revenue"      = "SUM(ftd.product_price * ftd.quantity)",
                        "transaction"  = "COUNT(DISTINCT ft.invoice_id)",
                        "items_sold"   = "SUM(ftd.quantity)",
                        "basket"       = "ROUND(SUM(ftd.quantity) / COUNT(DISTINCT ft.invoice_id), 2)",
                        "aov"          = "ROUND(SUM(ftd.product_price * ftd.quantity) / COUNT(DISTINCT ft.invoice_id), 0)",
                        "active_store" = "COUNT(DISTINCT ft.store_id)"
  )
  sql <- sprintf("SELECT %s AS val FROM fact_transaction ft %s JOIN dim_store ds ON ft.store_id = ds.store_id %s",
                 select_col, join_detail, where_clause)
  as.numeric(dbGetQuery(con, sql)$val[1])
}

make_subtitle <- function(label, badge) {
  tagList(
    tags$div(style = "font-size:13px; opacity:0.9;", label),
    tags$div(
      style = paste0("display:inline-flex; align-items:center; gap:3px; margin-top:4px; ",
                     "font-size:16px; font-weight:700; background:rgba(0,0,0,0.25)",
                     "color:white", badge$color, "; padding:2px 8px; border-radius:20px;"),
      badge$arrow, " ", badge$text,
      tags$span(style = "font-weight:400; font-size:16px; opacity:0.8; margin-left:2px;", "vs prev period")
    )
  )
}

# ── Helper: pairs query ───────────────────────────────────────────────────
get_pairs <- function(where_clause, is_member, type = "product", limit = 10) {
  cond      <- if (is_member) "ft.customer_id > 0" else "ft.customer_id = 0"
  total_sub <- if (is_member) "customer_id > 0"    else "customer_id = 0"
  if (type == "product") {
    col_a <- "CASE WHEN p1.product_name < p2.product_name THEN p1.product_name ELSE p2.product_name END"
    col_b <- "CASE WHEN p1.product_name < p2.product_name THEN p2.product_name ELSE p1.product_name END"
    extra_join <- ""
    extra_filter <- ""
    label_a <- "Product A"; label_b <- "Product B"
  } else {
    col_a <- "CASE WHEN c1.category_lvl2 < c2.category_lvl2 THEN c1.category_lvl2 ELSE c2.category_lvl2 END"
    col_b <- "CASE WHEN c1.category_lvl2 < c2.category_lvl2 THEN c2.category_lvl2 ELSE c1.category_lvl2 END"
    extra_join <- "JOIN dim_category c1 ON p1.category_id = c1.category_id
      JOIN dim_category c2 ON p2.category_id = c2.category_id"
    extra_filter <- "AND c1.category_lvl2 != c2.category_lvl2
        AND c1.category_lvl2 IS NOT NULL AND c2.category_lvl2 IS NOT NULL"
    label_a <- "Subcategory A"; label_b <- "Subcategory B"
  }
  sql <- sprintf("
      SELECT %s AS col_a, %s AS col_b,
             COUNT(DISTINCT ftd1.invoice_id) AS freq,
             ROUND(COUNT(DISTINCT ftd1.invoice_id) * 100.0 /
               (SELECT COUNT(DISTINCT invoice_id) FROM fact_transaction WHERE %s), 2) AS support_pct
      FROM fact_transaction_detail ftd1
      JOIN fact_transaction_detail ftd2
        ON ftd1.invoice_id = ftd2.invoice_id AND ftd1.product_id < ftd2.product_id
      JOIN fact_transaction ft ON ftd1.invoice_id = ft.invoice_id
      JOIN dim_store ds ON ft.store_id = ds.store_id
      JOIN dim_product p1 ON ftd1.product_id = p1.product_id
      JOIN dim_product p2 ON ftd2.product_id = p2.product_id
      %s
      %s AND %s %s
      GROUP BY %s, %s
      HAVING freq >= 1
      ORDER BY freq DESC LIMIT %d",
                 col_a, col_b, total_sub, extra_join,
                 where_clause, cond, extra_filter,
                 col_a, col_b, limit)
  data <- dbGetQuery(con, sql)
  if (nrow(data) == 0) return(data.frame())
  out <- data.frame(
    Rank = paste0("#", seq_len(nrow(data))),
    A    = data$col_a,
    B    = data$col_b,
    Freq = sapply(data$freq, fmt_num),
    Supp = paste0(data$support_pct, "%"),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  names(out) <- c("Rank", label_a, label_b, "Frequency", "Support %")
  out
}

# ── Helper: render heatmap from affinity data ─────────────────────────────
render_affinity_heatmap <- function(data, colorscale) {
  if (nrow(data) == 0) return(plotly_empty())
  cats  <- sort(unique(c(data$cat_a, data$cat_b)))
  n     <- length(cats)
  mat   <- matrix(NA_real_, nrow=n, ncol=n, dimnames=list(cats, cats))
  for (i in seq_len(nrow(data))) {
    mat[data$cat_a[i], data$cat_b[i]] <- data$freq[i]
    mat[data$cat_b[i], data$cat_a[i]] <- data$freq[i]
  }
  plot_ly(x=cats, y=cats, z=mat, type="heatmap",
          colorscale=colorscale,
          hovertemplate="<b>%{x} + %{y}</b><br>Frequency: %{z:,}<extra></extra>",
          showscale=TRUE) |>
    layout(
      xaxis=list(title="", tickangle=-40, showgrid=FALSE),
      yaxis=list(title="", showgrid=FALSE, autorange="reversed"),
      paper_bgcolor="transparent", plot_bgcolor="transparent",
      margin=list(t=10, b=130, l=150, r=20)
    )
}


# ── Helper: fetch category affinity data ──────────────────────────────────
affinity_data <- function(where_clause, is_member) {
  cond      <- if (is_member) "ft.customer_id > 0" else "ft.customer_id = 0"
  total_sub <- if (is_member) "customer_id > 0" else "customer_id = 0"
  sql <- sprintf("
      SELECT
        CASE WHEN c1.category_lvl1 < c2.category_lvl1 THEN c1.category_lvl1 ELSE c2.category_lvl1 END AS cat_a,
        CASE WHEN c1.category_lvl1 < c2.category_lvl1 THEN c2.category_lvl1 ELSE c1.category_lvl1 END AS cat_b,
        COUNT(DISTINCT ftd1.invoice_id) AS freq
      FROM fact_transaction_detail ftd1
      JOIN fact_transaction_detail ftd2
        ON ftd1.invoice_id = ftd2.invoice_id AND ftd1.product_id < ftd2.product_id
      JOIN fact_transaction ft ON ftd1.invoice_id = ft.invoice_id
      JOIN dim_store ds ON ft.store_id = ds.store_id
      JOIN dim_product p1 ON ftd1.product_id = p1.product_id
      JOIN dim_product p2 ON ftd2.product_id = p2.product_id
      JOIN dim_category c1 ON p1.category_id = c1.category_id
      JOIN dim_category c2 ON p2.category_id = c2.category_id
      %s AND %s AND c1.category_lvl1 != c2.category_lvl1
      GROUP BY
        CASE WHEN c1.category_lvl1 < c2.category_lvl1 THEN c1.category_lvl1 ELSE c2.category_lvl1 END,
        CASE WHEN c1.category_lvl1 < c2.category_lvl1 THEN c2.category_lvl1 ELSE c1.category_lvl1 END",
                 where_clause, cond)
  dbGetQuery(con, sql)
}