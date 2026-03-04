build_where <- function(date_start, date_end, province = "all", store_type = "all") {
  clauses <- c(sprintf("DATE(ft.invoice_datetime) BETWEEN '%s' AND '%s'", date_start, date_end))
  if (!is.null(province)   && province   != "all") clauses <- c(clauses, sprintf("ds.store_province = '%s'", province))
  if (!is.null(store_type) && store_type != "all") clauses <- c(clauses, sprintf("ds.store_type = '%s'", store_type))
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
                     "font-size:12px; font-weight:700; background:rgba(255,255,255,0.2); ",
                     "color:", badge$color, "; padding:2px 8px; border-radius:20px;"),
      badge$arrow, " ", badge$text,
      tags$span(style = "font-weight:400; font-size:10px; opacity:0.8; margin-left:2px;", "vs prev period")
    )
  )
}

# ── Customer WHERE (tambah city filter) ──────────────────────────────────────
build_where_cust <- function(date_start, date_end, province = "all",
                             store_type = "all", city = "all") {
  clauses <- c(sprintf("DATE(ft.invoice_datetime) BETWEEN '%s' AND '%s'", date_start, date_end))
  if (!is.null(province)   && province   != "all") clauses <- c(clauses, sprintf("ds.store_province = '%s'", province))
  if (!is.null(store_type) && store_type != "all") clauses <- c(clauses, sprintf("ds.store_type = '%s'", store_type))
  if (!is.null(city)       && city       != "all") clauses <- c(clauses, sprintf("dc.customer_city = '%s'", city))
  paste("WHERE", paste(clauses, collapse = " AND "))
}

# =============================================================================
server <- function(input, output, session) {
  
  # ── Populate dropdowns ───────────────────────────────────────────────────
  observe({
    provinces   <- dbGetQuery(con, "SELECT DISTINCT store_province FROM dim_store ORDER BY store_province")
    store_types <- dbGetQuery(con, "SELECT DISTINCT store_type FROM dim_store ORDER BY store_type")
    cities      <- dbGetQuery(con, "SELECT DISTINCT customer_city FROM dim_customer WHERE customer_city IS NOT NULL ORDER BY customer_city")
    updateSelectInput(session, "province",
                      choices = c("All Province" = "all", setNames(provinces$store_province, provinces$store_province)))
    updateSelectInput(session, "store_type",
                      choices = c("All Store Type" = "all", setNames(store_types$store_type, store_types$store_type)))
    updateSelectInput(session, "customer_city",
                      choices = c("All Cities" = "all", setNames(cities$customer_city, cities$customer_city)))
  })
  
  # ── Auto granularity ─────────────────────────────────────────────────────
  observeEvent(input$date_range, {
    n_days <- as.numeric(as.Date(input$date_range[2]) - as.Date(input$date_range[1]))
    sel    <- if (n_days <= 31) "daily" else "monthly"
    updateRadioButtons(session, "trend_granularity", selected = sel)
    updateRadioButtons(session, "cust_granularity",  selected = sel)
  })
  
  # ── Reactives: Sales ─────────────────────────────────────────────────────
  flt <- reactive({
    list(start = format(input$date_range[1], "%Y-%m-%d"),
         end   = format(input$date_range[2], "%Y-%m-%d"),
         province   = input$province,
         store_type = input$store_type)
  })
  
  base_query <- reactive({
    f <- flt()
    list(where = build_where(f$start, f$end, f$province, f$store_type), f = f)
  })
  
  prev_where <- reactive({
    f    <- flt(); prev <- prev_period(f$start, f$end)
    build_where(prev$start, prev$end, f$province, f$store_type)
  })
  
  gran     <- reactive({ if (!is.null(input$trend_granularity)) input$trend_granularity else "monthly" })
  date_fmt <- reactive({ if (gran() == "daily") "%Y-%m-%d" else "%Y-%m" })
  
  # ── Reactives: Customer ──────────────────────────────────────────────────
  cust_flt <- reactive({
    f    <- flt()
    city <- if (!is.null(input$customer_city)) input$customer_city else "all"
    prev <- prev_period(f$start, f$end)
    list(
      where      = build_where_cust(f$start, f$end, f$province, f$store_type, city),
      where_prev = build_where_cust(prev$start, prev$end, f$province, f$store_type, city),
      start = f$start, end = f$end
    )
  })
  
  cust_gran     <- reactive({ if (!is.null(input$cust_granularity)) input$cust_granularity else "monthly" })
  cust_date_fmt <- reactive({ if (cust_gran() == "daily") "%Y-%m-%d" else "%Y-%m" })
  
  # ── CTE helper ───────────────────────────────────────────────────────────
  first_trans_cte <- function(where_clause) {
    sprintf("
      WITH first_trans AS (
        SELECT ft.customer_id,
               MIN(ft.invoice_datetime) AS first_dt,
               DATE_FORMAT(MIN(ft.invoice_datetime), '%%Y-%%m') AS first_month
        FROM fact_transaction ft
        JOIN dim_store ds ON ft.store_id = ds.store_id
        JOIN dim_customer dc ON ft.customer_id = dc.customer_id
        %s AND ft.customer_id > 0
        GROUP BY ft.customer_id
      )", where_clause)
  }
  
  # =========================================================================
  # SALES KPIs
  # =========================================================================
  output$total_revenue <- renderbs4ValueBox({
    cur <- query_kpi_val(base_query()$where, "revenue"); prev <- query_kpi_val(prev_where(), "revenue")
    bs4ValueBox(value = fmt_rupiah(cur), subtitle = make_subtitle("Total Revenue", pct_badge(cur, prev)),
                icon = icon("money-bill-wave"), color = "success", width = 12)
  })
  output$total_transaction <- renderbs4ValueBox({
    cur <- query_kpi_val(base_query()$where, "transaction"); prev <- query_kpi_val(prev_where(), "transaction")
    bs4ValueBox(value = fmt_num(cur), subtitle = make_subtitle("Total Transactions", pct_badge(cur, prev)),
                icon = icon("receipt"), color = "primary", width = 12)
  })
  output$total_items_sold <- renderbs4ValueBox({
    cur <- query_kpi_val(base_query()$where, "items_sold"); prev <- query_kpi_val(prev_where(), "items_sold")
    bs4ValueBox(value = fmt_num(cur), subtitle = make_subtitle("Total Items Sold", pct_badge(cur, prev)),
                icon = icon("box-open"), color = "info", width = 12)
  })
  output$avg_basket <- renderbs4ValueBox({
    cur <- query_kpi_val(base_query()$where, "basket"); prev <- query_kpi_val(prev_where(), "basket")
    bs4ValueBox(value = ifelse(is.na(cur), "0", round(cur,2)),
                subtitle = make_subtitle("Avg Basket Size", pct_badge(cur, prev)),
                icon = icon("shopping-basket"), color = "warning", width = 12)
  })
  output$avg_aov <- renderbs4ValueBox({
    cur <- query_kpi_val(base_query()$where, "aov"); prev <- query_kpi_val(prev_where(), "aov")
    bs4ValueBox(value = fmt_rupiah(cur), subtitle = make_subtitle("Avg Order Value", pct_badge(cur, prev)),
                icon = icon("chart-bar"), color = "danger", width = 12)
  })
  output$active_store <- renderbs4ValueBox({
    cur <- query_kpi_val(base_query()$where, "active_store"); prev <- query_kpi_val(prev_where(), "active_store")
    bs4ValueBox(value = as.integer(cur), subtitle = make_subtitle("Active Stores", pct_badge(cur, prev)),
                icon = icon("store"), color = "secondary", width = 12)
  })
  
  # =========================================================================
  # SALES CHARTS
  # =========================================================================
  output$main_trend_title <- renderUI({
    kpi <- if (is.null(input$selected_kpi)) "revenue" else input$selected_kpi
    label <- list(revenue="Revenue Trend", transaction="Total Transactions Trend",
                  items_sold="Total Items Sold Trend", basket="Avg Basket Size Trend",
                  aov="Average Order Value Trend", active_store="Active Stores Trend")[[kpi]]
    tagList(icon("chart-area"), " ", label)
  })
  
  output$main_trend_plot <- renderPlotly({
    bq  <- base_query()
    kpi <- if (is.null(input$selected_kpi)) "revenue" else input$selected_kpi
    fmt <- date_fmt()
    need_detail <- kpi %in% c("revenue", "items_sold", "basket", "aov")
    join_detail <- if (need_detail) "JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id" else ""
    select_col  <- switch(kpi,
                          "revenue"="SUM(ftd.product_price * ftd.quantity)",
                          "transaction"="COUNT(DISTINCT ft.invoice_id)",
                          "items_sold"="SUM(ftd.quantity)",
                          "basket"="ROUND(SUM(ftd.quantity) / COUNT(DISTINCT ft.invoice_id), 2)",
                          "aov"="ROUND(SUM(ftd.product_price * ftd.quantity) / COUNT(DISTINCT ft.invoice_id), 0)",
                          "active_store"="COUNT(DISTINCT ft.store_id)",
                          "SUM(ftd.product_price * ftd.quantity)")
    fmt_esc <- gsub("%", "%%", fmt)
    sql <- sprintf(
      paste0("SELECT DATE_FORMAT(ft.invoice_datetime, '", fmt_esc, "') AS period_label, ",
             "%s AS val FROM fact_transaction ft %s ",
             "JOIN dim_store ds ON ft.store_id = ds.store_id %s ",
             "GROUP BY DATE_FORMAT(ft.invoice_datetime, '", fmt_esc, "') ORDER BY period_label"),
      select_col, join_detail, bq$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    col       <- pct_badge(query_kpi_val(bq$where, kpi), query_kpi_val(prev_where(), kpi))$color
    rgb_v     <- col2rgb(col)
    fill_rgba <- sprintf("rgba(%d,%d,%d,0.12)", rgb_v[1], rgb_v[2], rgb_v[3])
    plot_ly(data, x = ~period_label, y = ~val, type = "scatter", mode = "lines+markers",
            line = list(color=col, width=3), marker = list(color=col, size=6, line=list(color="#fff",width=1.5)),
            fill = "tozeroy", fillcolor = fill_rgba,
            hovertemplate = "<b>%{x}</b><br>%{y:,.0f}<extra></extra>") |>
      layout(xaxis=list(title="",showgrid=FALSE), yaxis=list(title="",gridcolor="#E2E8F0"),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10,b=40,l=60,r=10))
  })
  
  output$payment_donut <- renderPlotly({
    bq  <- base_query()
    sql <- sprintf("SELECT ft.payment_method, COUNT(DISTINCT ft.invoice_id) AS n
                    FROM fact_transaction ft JOIN dim_store ds ON ft.store_id = ds.store_id
                    %s GROUP BY ft.payment_method", bq$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    plot_ly(data, labels=~payment_method, values=~n, type="pie", hole=0.55,
            marker=list(colors=c("#2563EB","#10B981","#F59E0B","#06B6D4","#EF4444"),
                        line=list(color="#fff",width=2)),
            textinfo="label+percent",
            hovertemplate="<b>%{label}</b><br>%{value:,} transaksi<extra></extra>") |>
      layout(showlegend=TRUE, legend=list(orientation="h",y=-0.1),
             paper_bgcolor="transparent", margin=list(t=10,b=10,l=10,r=10))
  })
  
  active_kpi <- reactive({
    kpi <- if (is.null(input$selected_kpi)) "revenue" else input$selected_kpi
    if (kpi == "active_store") "revenue" else kpi
  })
  
  output$top_stores_title <- renderUI({
    label <- list(revenue="Revenue",transaction="Transactions",items_sold="Items Sold",
                  basket="Avg Basket",aov="AOV")[[active_kpi()]]
    tagList(icon("trophy"), paste(" Top 10 Stores by", label))
  })
  
  output$top_stores_table <- renderTable({
    bq  <- base_query(); kpi <- active_kpi()
    need_detail <- kpi %in% c("revenue","items_sold","basket","aov")
    join_detail <- if (need_detail) "JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id" else ""
    select_col  <- switch(kpi,
                          "revenue"="SUM(ftd.product_price * ftd.quantity)","transaction"="COUNT(DISTINCT ft.invoice_id)",
                          "items_sold"="SUM(ftd.quantity)","basket"="ROUND(SUM(ftd.quantity)/COUNT(DISTINCT ft.invoice_id),2)",
                          "aov"="ROUND(SUM(ftd.product_price * ftd.quantity)/COUNT(DISTINCT ft.invoice_id),0)")
    cur  <- dbGetQuery(con, sprintf("SELECT ds.store_name, %s AS val FROM fact_transaction ft %s JOIN dim_store ds ON ft.store_id=ds.store_id %s GROUP BY ft.store_id,ds.store_name ORDER BY val DESC LIMIT 10", select_col, join_detail, bq$where))
    if (nrow(cur) == 0) return(data.frame())
    prev_d <- dbGetQuery(con, sprintf("SELECT ds.store_name, %s AS val_prev FROM fact_transaction ft %s JOIN dim_store ds ON ft.store_id=ds.store_id %s GROUP BY ft.store_id,ds.store_name", select_col, join_detail, prev_where()))
    merged <- merge(cur, prev_d, by="store_name", all.x=TRUE)
    merged <- merged[order(-merged$val), ]
    merged$pct <- ifelse(is.na(merged$val_prev)|merged$val_prev==0, NA,
                         (merged$val-merged$val_prev)/abs(merged$val_prev)*100)
    fmt_val    <- if (kpi %in% c("revenue","aov")) sapply(merged$val, fmt_rupiah) else sapply(merged$val, fmt_num)
    fmt_growth <- ifelse(is.na(merged$pct), "N/A",
                         paste0(ifelse(merged$pct>=0,"\u25b2 ","\u25bc "), sprintf("%.1f%%",abs(merged$pct))))
    kpi_label  <- list(revenue="Revenue",transaction="Transactions",items_sold="Items Sold",basket="Avg Basket",aov="AOV")[[kpi]]
    setNames(data.frame(paste0("#",seq_len(nrow(merged))), merged$store_name, fmt_val, fmt_growth,
                        check.names=FALSE, stringsAsFactors=FALSE),
             c("Rank","Store",kpi_label,"Growth"))
  }, striped=TRUE, hover=TRUE, bordered=FALSE, spacing="s", width="100%", align="llrr")
  
  output$heatmap_plot <- renderPlotly({
    bq  <- base_query()
    sql <- sprintf("SELECT DAYOFWEEK(ft.invoice_datetime) AS dow, HOUR(ft.invoice_datetime) AS hour,
                           COUNT(DISTINCT ft.invoice_id) AS n
                    FROM fact_transaction ft JOIN dim_store ds ON ft.store_id=ds.store_id
                    %s GROUP BY dow, hour", bq$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    day_map   <- c("1"="Sun","2"="Mon","3"="Tue","4"="Wed","5"="Thu","6"="Fri","7"="Sat")
    day_order <- c("Mon","Tue","Wed","Thu","Fri","Sat","Sun")
    data$day  <- factor(day_map[as.character(data$dow)], levels=day_order)
    grid      <- expand.grid(hour=0:23, day=day_order)
    grid$day  <- factor(grid$day, levels=day_order)
    data_full <- merge(grid, data[,c("hour","day","n")], by=c("hour","day"), all.x=TRUE)
    data_full$n[is.na(data_full$n)] <- 0
    plot_ly(data_full, x=~hour, y=~day, z=~n, type="heatmap",
            colorscale=list(c(0,"#EFF6FF"),c(0.5,"#60A5FA"),c(1,"#1E3A8A")),
            hovertemplate="<b>%{y} %{x}:00</b><br>Transaksi: %{z:,}<extra></extra>",
            showscale=TRUE) |>
      layout(xaxis=list(title="Hour",tickvals=seq(0,23,3),ticktext=paste0(seq(0,23,3),":00"),showgrid=FALSE),
             yaxis=list(title="",showgrid=FALSE), paper_bgcolor="transparent",
             plot_bgcolor="transparent", margin=list(t=10,b=40,l=50,r=10))
  })
  
  # =========================================================================
  # CUSTOMER KPIs
  # =========================================================================
  output$cust_new_total <- renderbs4ValueBox({
    cf  <- cust_flt()
    cte <- first_trans_cte(cf$where)
    cur <- as.numeric(dbGetQuery(con, paste(cte, "SELECT COUNT(*) AS val FROM first_trans"))$val)
    prv <- as.numeric(dbGetQuery(con, paste(first_trans_cte(cf$where_prev), "SELECT COUNT(*) AS val FROM first_trans"))$val)
    bs4ValueBox(value = fmt_num(cur), subtitle = make_subtitle("New Customers", pct_badge(cur, prv)),
                icon = icon("user-plus"), color = "primary", width = 12)
  })
  
  output$cust_avg_first_purchase <- renderbs4ValueBox({
    cf  <- cust_flt()
    avg_sql <- function(where_c) {
      paste(first_trans_cte(where_c), "
        SELECT ROUND(AVG(iv.total_val), 0) AS val
        FROM first_trans ft2
        JOIN (
          SELECT ft3.invoice_id, SUM(ftd.product_price * ftd.quantity) AS total_val
          FROM fact_transaction ft3
          JOIN fact_transaction_detail ftd ON ft3.invoice_id = ftd.invoice_id
          GROUP BY ft3.invoice_id
        ) iv ON iv.invoice_id = (
          SELECT invoice_id FROM fact_transaction
          WHERE customer_id = ft2.customer_id
            AND invoice_datetime = ft2.first_dt LIMIT 1
        )")
    }
    cur <- as.numeric(dbGetQuery(con, avg_sql(cf$where))$val)
    prv <- as.numeric(dbGetQuery(con, avg_sql(cf$where_prev))$val)
    bs4ValueBox(value = fmt_rupiah(cur), subtitle = make_subtitle("Avg First Purchase", pct_badge(cur, prv)),
                icon = icon("tag"), color = "warning", width = 12)
  })
  
  output$cust_new_returning_ratio <- renderbs4ValueBox({
    cf    <- cust_flt()
    cte   <- first_trans_cte(cf$where)
    n_new <- as.numeric(dbGetQuery(con, paste(cte, "SELECT COUNT(*) AS val FROM first_trans"))$val)
    n_all <- as.numeric(dbGetQuery(con, sprintf(
      "SELECT COUNT(DISTINCT ft.customer_id) AS val
       FROM fact_transaction ft JOIN dim_store ds ON ft.store_id=ds.store_id
       JOIN dim_customer dc ON ft.customer_id=dc.customer_id
       %s AND ft.customer_id > 0", cf$where))$val)
    pct <- if (!is.na(n_all) && n_all > 0) round(n_new / n_all * 100, 1) else 0
    bs4ValueBox(
      value    = paste0(pct, "%"),
      subtitle = tagList(
        tags$div(style="font-size:13px; opacity:0.9;", "New Customer Ratio"),
        tags$div(style="font-size:11px; opacity:0.7; margin-top:2px;",
                 paste0(fmt_num(n_new), " new / ", fmt_num(n_all), " total"))
      ),
      icon = icon("users"), color = "success", width = 12)
  })
  
  # =========================================================================
  # CUSTOMER CHARTS
  # =========================================================================
  
  # Chart 1: New Customer Trend + MoM Growth (dual axis)
  output$cust_trend_plot <- renderPlotly({
    cf  <- cust_flt()
    fmt <- cust_date_fmt()
    fmt_esc <- gsub("%", "%%", fmt)
    cte <- first_trans_cte(cf$where)
    sql <- sprintf(paste0(cte,
                          " SELECT DATE_FORMAT(first_dt, '", fmt_esc, "') AS period_label,
               COUNT(*) AS new_customers
        FROM first_trans
        GROUP BY DATE_FORMAT(first_dt, '", fmt_esc, "')
        ORDER BY period_label"))
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    data$growth <- c(NA, round(diff(data$new_customers) / abs(head(data$new_customers,-1)) * 100, 1))
    plot_ly(data, x = ~period_label) |>
      add_bars(y = ~new_customers, name = "New Customers",
               marker = list(color="#2563EB", opacity=0.8), yaxis = "y",
               hovertemplate = "<b>%{x}</b><br>New Customers: %{y:,}<extra></extra>") |>
      add_lines(y = ~growth, name = "MoM Growth %",
                line = list(color="#F59E0B", width=2.5), yaxis = "y2",
                hovertemplate = "<b>%{x}</b><br>Growth: %{y:.1f}%<extra></extra>") |>
      layout(
        yaxis  = list(title="New Customers", showgrid=TRUE, gridcolor="#E2E8F0"),
        yaxis2 = list(title="MoM Growth (%)", overlaying="y", side="right",
                      showgrid=FALSE, zeroline=TRUE, zerolinecolor="#E2E8F0"),
        xaxis  = list(title="", showgrid=FALSE),
        legend = list(orientation="h", y=-0.15),
        paper_bgcolor="transparent", plot_bgcolor="transparent",
        margin=list(t=10,b=50,l=60,r=60)
      )
  })
  
  # Chart 2: New vs Returning (stacked bar)
  output$cust_new_vs_returning <- renderPlotly({
    cf  <- cust_flt()
    sql <- sprintf("
      WITH first_month AS (
        SELECT ft.customer_id,
               DATE_FORMAT(MIN(ft.invoice_datetime), '%%Y-%%m') AS first_m
        FROM fact_transaction ft
        JOIN dim_store ds ON ft.store_id=ds.store_id
        JOIN dim_customer dc ON ft.customer_id=dc.customer_id
        %s AND ft.customer_id > 0
        GROUP BY ft.customer_id
      )
      SELECT DATE_FORMAT(ft.invoice_datetime, '%%Y-%%m') AS month_label,
        COUNT(DISTINCT CASE WHEN fm.first_m = DATE_FORMAT(ft.invoice_datetime,'%%Y-%%m') THEN ft.customer_id END) AS new_cust,
        COUNT(DISTINCT CASE WHEN fm.first_m < DATE_FORMAT(ft.invoice_datetime,'%%Y-%%m') THEN ft.customer_id END) AS returning_cust
      FROM fact_transaction ft
      JOIN dim_store ds ON ft.store_id=ds.store_id
      JOIN dim_customer dc ON ft.customer_id=dc.customer_id
      JOIN first_month fm ON ft.customer_id=fm.customer_id
      %s AND ft.customer_id > 0
      GROUP BY DATE_FORMAT(ft.invoice_datetime,'%%Y-%%m')
      ORDER BY month_label", cf$where, cf$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    plot_ly(data, x = ~month_label) |>
      add_bars(y=~new_cust, name="New", marker=list(color="#2563EB"),
               hovertemplate="<b>%{x}</b><br>New: %{y:,}<extra></extra>") |>
      add_bars(y=~returning_cust, name="Returning", marker=list(color="#10B981"),
               hovertemplate="<b>%{x}</b><br>Returning: %{y:,}<extra></extra>") |>
      layout(barmode="stack", xaxis=list(title="",showgrid=FALSE),
             yaxis=list(title="Customers",gridcolor="#E2E8F0"),
             legend=list(orientation="h",y=-0.2),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10,b=50,l=60,r=10))
  })
  
  # Chart 3: First Purchase Value (avg/min/max)
  output$cust_first_purchase <- renderPlotly({
    cf  <- cust_flt()
    sql <- sprintf("
      WITH first_invoice AS (
        SELECT ft.customer_id, MIN(ft.invoice_datetime) AS first_dt
        FROM fact_transaction ft
        JOIN dim_store ds ON ft.store_id=ds.store_id
        JOIN dim_customer dc ON ft.customer_id=dc.customer_id
        %s AND ft.customer_id > 0
        GROUP BY ft.customer_id
      ),
      first_value AS (
        SELECT fi.customer_id, fi.first_dt,
               SUM(ftd.product_price * ftd.quantity) AS first_val
        FROM first_invoice fi
        JOIN fact_transaction ft ON ft.customer_id=fi.customer_id AND ft.invoice_datetime=fi.first_dt
        JOIN fact_transaction_detail ftd ON ft.invoice_id=ftd.invoice_id
        GROUP BY fi.customer_id, fi.first_dt
      )
      SELECT DATE_FORMAT(first_dt,'%%Y-%%m') AS month_label,
             ROUND(AVG(first_val),0) AS avg_val,
             MIN(first_val)          AS min_val,
             MAX(first_val)          AS max_val
      FROM first_value
      GROUP BY DATE_FORMAT(first_dt,'%%Y-%%m')
      ORDER BY month_label", cf$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    plot_ly(data, x = ~month_label) |>
      add_lines(y=~avg_val, name="Avg", line=list(color="#F59E0B",width=3),
                hovertemplate="<b>%{x}</b><br>Avg: Rp %{y:,.0f}<extra></extra>") |>
      add_lines(y=~max_val, name="Max", line=list(color="#10B981",width=1.5,dash="dot"),
                hovertemplate="<b>%{x}</b><br>Max: Rp %{y:,.0f}<extra></extra>") |>
      add_lines(y=~min_val, name="Min", line=list(color="#EF4444",width=1.5,dash="dot"),
                hovertemplate="<b>%{x}</b><br>Min: Rp %{y:,.0f}<extra></extra>") |>
      layout(xaxis=list(title="",showgrid=FALSE),
             yaxis=list(title="First Purchase (Rp)",tickformat=".2s",gridcolor="#E2E8F0"),
             legend=list(orientation="h",y=-0.2),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10,b=50,l=60,r=10))
  })
  
  # Chart 4: New Customers by City (calendar vs operational month)
  output$cust_by_city <- renderPlotly({
    cf   <- cust_flt()
    mode <- if (!is.null(input$city_view_mode)) input$city_view_mode else "calendar"
    sql  <- sprintf("
      WITH store_open AS (
        SELECT store_city, MIN(store_open_date) AS city_open_date
        FROM dim_store GROUP BY store_city
      ),
      first_trans AS (
        SELECT ft.customer_id, ds.store_city, MIN(ft.invoice_datetime) AS first_dt
        FROM fact_transaction ft
        JOIN dim_store ds ON ft.store_id=ds.store_id
        JOIN dim_customer dc ON ft.customer_id=dc.customer_id
        %s AND ft.customer_id > 0
        GROUP BY ft.customer_id, ds.store_city
      )
      SELECT ft.store_city,
             DATE_FORMAT(ft.first_dt,'%%Y-%%m') AS month_label,
             TIMESTAMPDIFF(MONTH, so.city_open_date,
               STR_TO_DATE(CONCAT(DATE_FORMAT(ft.first_dt,'%%Y-%%m'),'-01'),'%%Y-%%m-%%d')) + 1
               AS operational_month,
             COUNT(ft.customer_id) AS new_customers
      FROM first_trans ft
      JOIN store_open so ON ft.store_city=so.store_city
      GROUP BY ft.store_city, DATE_FORMAT(ft.first_dt,'%%Y-%%m'), so.city_open_date
      ORDER BY ft.store_city, month_label", cf$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    
    x_col   <- if (mode == "calendar") "month_label" else "operational_month"
    x_title <- if (mode == "calendar") "" else "Operational Month (since store open)"
    
    top_cities <- data |>
      group_by(store_city) |>
      summarise(total = sum(new_customers), .groups="drop") |>
      arrange(dplyr::desc(total)) |>
      slice_head(n=8) |>
      pull(store_city)
    
    data   <- data[data$store_city %in% top_cities, ]
    colors <- c("#2563EB","#10B981","#F59E0B","#EF4444","#06B6D4","#8B5CF6","#EC4899","#64748B")
    
    p <- plot_ly()
    for (i in seq_along(top_cities)) {
      cd <- data[data$store_city == top_cities[i], ]
      p  <- p |> add_lines(
        data = cd, x = ~get(x_col), y = ~new_customers,
        name = top_cities[i],
        line = list(color=colors[i], width=2),
        marker = list(color=colors[i], size=5),
        mode = "lines+markers",
        hovertemplate = paste0("<b>", top_cities[i], "</b><br>",
                               if (mode=="calendar") "%{x}" else "Month %{x}",
                               "<br>New Customers: %{y:,}<extra></extra>")
      )
    }
    p |> layout(
      xaxis  = list(title=x_title, showgrid=FALSE),
      yaxis  = list(title="New Customers", gridcolor="#E2E8F0"),
      legend = list(orientation="h", y=-0.15),
      paper_bgcolor="transparent", plot_bgcolor="transparent",
      margin=list(t=10,b=60,l=60,r=10)
    )
  })
  
  # ── Cleanup ──────────────────────────────────────────────────────────────
  session$onSessionEnded(function() {
    dbDisconnect(con)
    })
}