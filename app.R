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

# ── UI ─────────────────────────────────────────────────────────────

  
ui <- bs4DashPage(
  
  title = "Alfagift Retail Analytics",
  
  header = bs4DashNavbar(
    skin = "dark",
    status = "primary"
  ),
  
  sidebar = bs4DashSidebar(
    
    brand = tagList(
      tags$img(src = "alfagift.png", height = "35px"),
      tags$span("Alfagift", style="margin-left:8px; font-weight:100;")
    ),
    
    skin = "dark",
    
    bs4SidebarMenu(
  id = "sidebar",
      bs4SidebarMenuItem("Home",
                        tabName = "home",
                        icon = icon("home")),
      
      bs4SidebarMenuItem("Sales Overview",
                         tabName = "sales",
                         icon = icon("chart-line")),
      
      bs4SidebarMenuItem("Store Analysis",
                         tabName = "store",
                         icon = icon("store")),
      
      bs4SidebarMenuItem("Product Analysis",
                         tabName = "product",
                         icon = icon("box")),
      
      bs4SidebarMenuItem("Customer Analysis",
                         tabName = "customer",
                         icon = icon("users")),
      
      bs4SidebarMenuItem("Market Basket Analysis",
                         tabName = "basket",
                         icon = icon("shopping-basket")),
  
      bs4SidebarMenuItem("Our Team",
                         tabName = "team",
                         icon = icon("users"))
    ),
    
    hr(),
    
    dateRangeInput(
      inputId = "date_range",
      label   = "Date Range",
      
      start = as.Date("2024-12-01"),
      end   = as.Date("2024-12-31"),
      
      min = as.Date("2021-01-01"),
      max = as.Date("2024-12-31"),
      
      format = "yyyy-mm-dd"
    ),
  
  selectInput(
    "selected_kpi",
    "Trend KPI",
    choices = c(
      "Revenue"="revenue",
      "Transactions"="transaction",
      "Items Sold"="items_sold",
      "Basket Size"="basket",
      "AOV"="aov",
      "Active Store"="active_store"
    ),
    selected="revenue"
  ),
    
    selectInput(
      "province",
      "Province",
      choices = "all"
    ),
    
    selectInput(
      "store_type",
      "Store Type",
      choices = "all"
    ),
    
    selectInput(
      "customer_city",
      "Customer City",
      choices = "all"
    ),
    
    
    radioButtons(
      "trend_granularity",
      "Trend Granularity",
      choices = c("Daily"="daily","Monthly"="monthly"),
      inline = TRUE
    ),
    
    radioButtons(
      "cust_granularity",
      "Customer Trend",
      choices = c("Daily"="daily","Monthly"="monthly"),
      inline = TRUE
    )
    
  ),
  
  body = bs4DashBody(
    tags$head(
      tags$link(
        href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;600;800&display=swap",
        rel="stylesheet"
      )
    ),
    tags$style(HTML("
    
                  .hero-title-dynamic{
                  font-family:'Poppins', sans-serif;
                  font-weight:800;
                  font-size:52px;
                  color:#E11D48;
                  letter-spacing:2px;

                  -webkit-text-stroke:2px white;

                  animation:waveTitle 1s ease-in-out infinite;
                  }

                  @keyframes floatTitle{
                  0%{
                  transform:translateY(0px);
                  }
                  50%{
                  transform:translateY(-10px);
                  }
                  100%{
                  transform:translateY(0px);
                  }
                  }
                  /* =======================================================
                  Landing Page
                  =======================================================*/  
                  .btn-getstarted{
                  background:#E11D48;
                  color:white;
                  font-size:20px;
                  font-weight:600;
                  padding:14px 35px;
                  border-radius:50px;
                  border:none;
                  transition:all 0.3s ease;
                  box-shadow:0 6px 20px rgba(0,0,0,0.25);
                  }
                  
                  .btn-getstarted:hover{
                  background:#BE123C;
                  transform:translateY(-3px) scale(1.05);
                  box-shadow:0 12px 30px rgba(0,0,0,0.35);
                  }
                  .hero-bg{
                  background: linear-gradient(-45deg,#1E3A8A,#2563EB,#38BDF8,#60A5FA);
                  background-size: 400% 400%;
                  animation: gradientMove 5s ease infinite;
                  padding:50px;
                  border-radius:20px;
                  }
                  
                  @keyframes gradientMove{
                  0%{background-position:0% 50%}
                  50%{background-position:100% 50%}
                  100%{background-position:0% 50%}
                  }
                      
                  .small-box .icon{
                  position:absolute;
                  top:15px;
                  right:15px;
                  font-size:60px;
                  opacity:0.25;
                  z-index:0;
                  animation:floatIcon 3s ease-in-out infinite;
                  }
                  
                  .small-box .inner{
                  position:relative;
                  z-index:2;
                  }
                  
                  .small-box{
                  overflow:hidden;
                  }
                  /* =======================================================
                  GLOBAL STYLE
                  =======================================================*/
                  
                  body{
                  background:#F1F5F9;
                  font-family:'Inter', sans-serif;
                  }
                  
                  
                  /* =======================================================
                  NAVBAR
                  =======================================================*/
                  
                  .main-header{
                  background: linear-gradient(90deg,#1E3A8A,#2563EB,#38BDF8);
                  box-shadow:0 4px 15px rgba(0,0,0,0.15);
                  }
                  
                  
                  /* =======================================================
                  SIDEBAR
                  =======================================================*/
                  
                  .main-sidebar{
                  background:#0F172A;
                  }
                  
                  .sidebar .nav-link{
                  transition: all 0.25s ease;
                  border-radius:8px;
                  margin-bottom:4px;
                  }
                  
                  .sidebar .nav-link:hover{
                  background:#1E40AF;
                  transform:translateX(5px);
                  }
                  
                  
                  /* =======================================================
                  CARDS
                  =======================================================*/
                  
                  .card{
                  border-radius:16px;
                  border:none;
                  box-shadow:0 6px 20px rgba(0,0,0,0.06);
                  transition:all 0.3s ease;
                  }
                  
                  .card:hover{
                  transform:translateY(-4px);
                  box-shadow:0 12px 30px rgba(0,0,0,0.15);
                  }
                  
                  
                  /* =======================================================
                  VALUE BOX
                  =======================================================*/
                  
                  .small-box{
                  border-radius:14px;
                  box-shadow:0 8px 18px rgba(0,0,0,0.12);
                  transition:all 0.3s ease;
                  overflow:hidden;
                  }
                  
                  .small-box:hover{
                  transform:translateY(-6px) scale(1.02);
                  box-shadow:0 14px 35px rgba(0,0,0,0.25);
                  }
                  
                  
                  /* animated icon */
                  
                  .small-box .icon{
                  animation:floatIcon 3s ease-in-out infinite;
                  }
                  
                  @keyframes floatIcon{
                  0%{transform:translateY(0)}
                  50%{transform:translateY(-6px)}
                  100%{transform:translateY(0)}
                  }
                  
                  
                  /* =======================================================
                  KPI BADGE
                  =======================================================*/
                  
                  .kpi-badge{
                  animation:pulseBadge 2s infinite;
                  }
                  
                  @keyframes pulseBadge{
                  0%{box-shadow:0 0 0 0 rgba(16,185,129,0.5)}
                  70%{box-shadow:0 0 0 10px rgba(16,185,129,0)}
                  100%{box-shadow:0 0 0 0 rgba(16,185,129,0)}
                  }
                  
                  
                  /* =======================================================
                  HERO TITLE
                  =======================================================*/
                  
                  .hero-title{
                  font-weight:800;
                  font-size:46px;
                  color:#1E3A8A;
                  letter-spacing:1px;
                  margin-bottom:10px;
                  animation:fadeTitle 1s ease;
                  }
                  
                  @keyframes fadeTitle{
                  0%{
                  opacity:0;
                  transform:translateY(-20px);
                  }
                  100%{
                  opacity:1;
                  transform:translateY(0);
                  }
                  }
                  
                  
                  .subtitle-hero{
                  font-size:20px;
                  color:#64748B;
                  margin-top:8px;
                  opacity:0;
                  animation:fadeSlide 1.5s ease forwards;
                  }
                  
                  @keyframes fadeSlide{
                  0%{
                  opacity:0;
                  transform:translateY(25px);
                  }
                  100%{
                  opacity:1;
                  transform:translateY(0);
                  }
                  }
                  
                  
                  /* =======================================================
                  PLOTLY CHART CARD
                  =======================================================*/
                  
                  .js-plotly-plot{
                  transition: all 0.3s ease;
                  }
                  
                  .js-plotly-plot:hover{
                  transform:scale(1.01);
                  }
                  
                  
                  /* =======================================================
                  TABLE STYLE
                  =======================================================*/
                  
                  table{
                  border-radius:12px;
                  overflow:hidden;
                  }
                  
                  table tr:hover{
                  background:#EFF6FF;
                  }
                  
                  /* label input seperti Date Range, Province */
                  
                    .control-label{
                    color:#CBD5F5 !important;
                    font-weight:500;
                    }
                  
                    /* radio button text (Daily Monthly) */
                  
                    .radio label{
                    color:#E2E8F0 !important;
                    }
                  
                    .form-check-label{
                    color:#E2E8F0 !important;
                    }
                  
                    .custom-control-label{
                    color:#E2E8F0 !important;
                    }
                  
                    .shiny-options-group label{
                    color:#E2E8F0 !important;
                    }
                  
                    /* warna bullet radio */
                  
                    input[type='radio']{
                    accent-color:#38BDF8;
                    }
                  /* =======================================================
                  LOADING ANIMATION
                  =======================================================*/
                  
                  .shiny-output-error{
                  visibility:hidden;
                  }
                  
                  .shiny-output-error:before{
                  content:'Loading...';
                  visibility:visible;
                  color:#64748B;
                  animation:loadingDots 1.5s infinite;
                  }
                  
                  @keyframes loadingDots{
                  0%{content:'Loading'}
                  33%{content:'Loading.'}
                  66%{content:'Loading..'}
                  100%{content:'Loading...'}
                  }
                  
                  "
                    )
    ),
   
    
    
    bs4TabItems(
      
      
      # =====================================================
      # HOME
      # =====================================================
      
      bs4TabItem(
        tabName = "home",
        fluidRow(
          column(
            12,
            div(
              style="
              background:#FEF3C7;
              padding:12px 16px;
              border-radius:10px;
              margin-bottom:15px;
              font-size:14px;
              color:#92400E;",
              icon("exclamation-triangle"),
              strong(" Disclaimer: "),
              "This dashboard is intended for analytical insight and may not represent official company financial reports."
            ),
          )
        ),
        fluidRow(
          
          column(
            width = 12,
            offset = 0,
            
            tags$div(
              class = "hero-bg",
              style = "text-align:center;",
              
              tags$h1(
               "Alfagift Retail Analytics",
                class = "hero-title-dynamic"
              ),
              
              tags$p(
                "Interactive Retail Intelligence Dashboard",
                style = "color:white;font-size:20px;font-style:italic;"
              ),
              
              tags$br(),
              
              tags$img(
                src = "alfagift.png",
                height = "425px",
                style = "opacity:0.9;"
              ),
              
              tags$br(),
              tags$br(),
              
              actionButton(
                "go_sales",
                "Get Started",
                icon = icon("rocket"),
                class = "btn-getstarted"
              )
              
            )
            
          )
          
        )
        
      ),
        
      
      # =====================================================
      # SALES OVERVIEW 
      # =====================================================       
      bs4TabItem(
        tabName="sales",
        
        fluidRow(
          
          bs4ValueBoxOutput("total_revenue", width=2),
          bs4ValueBoxOutput("total_transaction", width=2),
          bs4ValueBoxOutput("total_items_sold", width=2),
          bs4ValueBoxOutput("avg_basket", width=2),
          bs4ValueBoxOutput("avg_aov", width=2),
          bs4ValueBoxOutput("active_store", width=2)
          
        ),
        
        fluidRow(
          
          bs4Card(
            width = 12,
            title = tagList(icon("lightbulb"), " Sales Insight"),
            status = "info",
            solidHeader = TRUE,
            htmlOutput("sales_insight")
          )
          
        ),
        
        fluidRow(
          
          bs4Card(
            width = 8,
            title = uiOutput("main_trend_title"),
            plotlyOutput("main_trend_plot", height=350)
          ),
          
          bs4Card(
            width = 4,
            title = "Payment Method",
            plotlyOutput("payment_donut", height=350)
          )
          
        ),
        
        fluidRow(
          
          bs4Card(
            width=6,
            title = tagList(
            uiOutput("top_stores_title", inline = TRUE),
            actionButton("btn_modal_top_stores", "View Full Table",
                         class = "btn btn-xs btn-outline-primary btn-view-table")
          ),
            tableOutput("top_stores_table")
          ),
          
          bs4Card(
            width=6,
            title="Transaction Heatmap",
            plotlyOutput("heatmap_plot", height=350)
          )
          
        )
        
      ),
      
      # =====================================================
      # STORE ANALYSIS
      # =====================================================
      
      bs4TabItem(
        
        tabName="store",
        
        fluidRow(
          
          bs4ValueBoxOutput("store_total", width=4),
          bs4ValueBoxOutput("store_top_revenue", width=4),
          bs4ValueBoxOutput("store_avg_aov", width=4)
          
        ),
        
        fluidRow(
          
          bs4Card(width=6,
                  title="Top Store Revenue",
                  plotlyOutput("store_revenue_bar")),
          
          bs4Card(width=6,
                  title="Store Type Revenue",
                  plotlyOutput("store_type_donut"))
          
        ),
        
        fluidRow(
          
          bs4Card(width=6,
                  title="Store AOV",
                  plotlyOutput("store_aov_bar")),
          
          bs4Card(width=6,
                  title="Store Transactions",
                  plotlyOutput("store_trx_bar"))
          
        ),
        
        fluidRow(
          
          bs4Card(width=5,
                  title="Revenue by Province",
                  plotlyOutput("store_province_bar")),
          
          bs4Card(width=7,
                  title="Store Ranking",
                  tableOutput("store_ranking_table"))
          
        )
        
      ),
      
      # =====================================================
      # PRODUCT ANALYSIS
      # =====================================================
      
      bs4TabItem(
        
        tabName="product",
        
        fluidRow(
          
          bs4ValueBoxOutput("prod_total", width=4),
          bs4ValueBoxOutput("prod_brand", width=4),
          bs4ValueBoxOutput("prod_kategori", width=4)
          
        ),
        
        fluidRow(
          
          bs4Card(width=12,
                  title="Price Distribution",
                  plotlyOutput("prod_price_dist"))
          
        ),
        fluidRow(
          
          bs4Card(width=6,
                  title="Price vs Quantity",
                  plotlyOutput("prod_scatter")),
          bs4Card(width=6,
                  title="Product Velocity",
                  plotlyOutput("prod_velocity"))
          
        ),
        
        fluidRow(
          
          bs4Card(width=6,
                  title="Top Product Revenue",
                  plotlyOutput("prod_top_revenue")),
          
          bs4Card(width=6,
                  title="Top Product Quantity",
                  plotlyOutput("prod_top_qty"))
          
        ),
        
        fluidRow(
          
          bs4Card(width=6,
                  title="Category Revenue",
                  plotlyOutput("prod_kategori_bar")),
          
          bs4Card(width=6,
                  title="Brand Revenue",
                  plotlyOutput("prod_brand_bar"))
          
        )
        
        
      ),
      
      # =====================================================
      # CUSTOMER ANALYSIS
      # =====================================================
      
      bs4TabItem(
        
        tabName="customer",
        
        fluidRow(
          bs4ValueBoxOutput("cust_total_aktif", width = 4),
          bs4ValueBoxOutput("cust_new_returning_ratio", width = 4),
          bs4ValueBoxOutput("cust_avg_first_purchase", width = 4),
          
          
          column(3, offset = 3, bs4ValueBoxOutput("cust_perempuan", width = 12)),
          column(3, bs4ValueBoxOutput("cust_lakilaki", width = 12))
        ),
        
        
        fluidRow(
          
          bs4Card(width=6,
                  title="New Customer Trend",
                  plotlyOutput("cust_trend_plot")),
          
          bs4Card(width=6,
                  title="New vs Returning",
                  plotlyOutput("cust_new_vs_returning"))
          
        ),
        
        fluidRow(
          
          bs4Card(width=6,
                  title="First Purchase Value",
                  plotlyOutput("cust_first_purchase")),
          
          bs4Card(width=6,
                  title="Customer by City",
                  plotlyOutput("cust_by_city"))
          
        ),
        
        fluidRow(
          
          bs4Card(width=6,
                  title="Gender Revenue",
                  plotlyOutput("cust_gender_donut")),
          
          bs4Card(width=6,
                  title="Top Cities",
                  plotlyOutput("cust_kota_bar"))
          
        ),
        
        fluidRow(
          
          bs4Card(width=12,
                  title="Top Customers",
                  tableOutput("cust_top_table"))
          
        )
        
      ),
      
      # =====================================================
      # MARKET BASKET ANALYSIS
      # =====================================================
      
      bs4TabItem(
        
        tabName="basket",
        
        fluidRow(
          
          bs4ValueBoxOutput("basket_kpi_trx_member", width=4),
          bs4ValueBoxOutput("basket_kpi_items_member", width=4),
          bs4ValueBoxOutput("basket_kpi_val_member", width=4),
        ),
        fluidRow(
          bs4ValueBoxOutput("basket_kpi_trx_nonmember", width=4),
          bs4ValueBoxOutput("basket_kpi_items_nonmember", width=4),
          bs4ValueBoxOutput("basket_kpi_val_nonmember", width=4)
          
        ),
        
        fluidRow(
          
          bs4Card(width=6,
                  title="Transaction Trend",
                  plotlyOutput("basket_trend_trx")),
          
          bs4Card(width=6,
                  title="Avg Transaction Value Trend",
                  plotlyOutput("basket_trend_val"))
          
        ),
        
        fluidRow(
          
          bs4Card(width=6,
                  title="Category Affinity (Member)",
                  plotlyOutput("basket_heatmap_member")),
          
          bs4Card(width=6,
                  title="Category Affinity (Non-Member)",
                  plotlyOutput("basket_heatmap_nonmember"))
          
        ),
        
        
        
        fluidRow(
          
          bs4Card(width=6,
                  title="Top Subcategory Pairs (Member)",
                  tableOutput("basket_subcat_member"),
                  actionButton("toggle_sub_member",
                               textOutput("basket_toggle_sub_member_label"))
          ),
          
          bs4Card(width=6,
                  title="Top Subcategory Pairs (Non-Member)",
                  tableOutput("basket_subcat_nonmember"),
                  actionButton("toggle_sub_nonmember",
                               textOutput("basket_toggle_sub_nonmember_label"))
          )
          
        ),
        
        fluidRow(
          
          bs4Card(width=6,
                  title="Top Product Pairs (Member)",
                  tableOutput("basket_pairs_member"),
                  actionButton("toggle_prod_member",
                               textOutput("basket_toggle_prod_member_label"))
          ),
          
          bs4Card(width=6,
                  title="Top Product Pairs (Non-Member)",
                  tableOutput("basket_pairs_nonmember"),
                  actionButton("toggle_prod_nonmember",
                               textOutput("basket_toggle_prod_nonmember_label"))
          )
          
        )
        
      ),
      # =====================================================
      # OUR TEAM
      # =====================================================
      bs4TabItem(
        tabName = "team",
        
        fluidRow(
          
          column(
            width = 12,
            
            tags$h2("Our Team", style="font-weight:700;margin-bottom:30px;"),
            
            fluidRow(
              
              column(
                width = 3,
                
                tags$div(
                  style="
            text-align:center;
            background:white;
            padding:30px;
            border-radius:15px;
            box-shadow:0 8px 20px rgba(0,0,0,0.1);",
                  
                  tags$img(
                    src = "developer1.jpeg",
                    style="
              width:150px;
              height:185px;
              border-radius:50%;
              margin-bottom:15px;"
                  ),
                  
                  tags$h5("Ni Made Ray Diantari"),
                  tags$h6("Database Manager"),
                )
                
              ),
              
              
              column(
                width = 3,
                
                tags$div(
                  style="
            text-align:center;
            background:white;
            padding:30px;
            border-radius:15px;
            box-shadow:0 8px 20px rgba(0,0,0,0.1);",
                  
                  tags$img(
                    src = "developer2.jpeg",
                    style="
              width:150px;
              height:185px;
              border-radius:50%;
              margin-bottom:15px;"
                  ),
                  
                  tags$h5("Naila Nabiha Qonita"),
                  tags$h6("Backend Developer"),
                )
                
              ),
              
              
              column(
                width = 3,
                
                tags$div(
                  style="
            text-align:center;
            background:white;
            padding:30px;
            border-radius:15px;
            box-shadow:0 8px 20px rgba(0,0,0,0.1);",
                  
                  tags$img(
                    src = "developer3.jpeg",
                    style="
              width:150px;
              height:185px;
              border-radius:50%;
              margin-bottom:15px;"
                  ),
                  
                  tags$h5("Rosita Ria Rusesta"),
                  tags$h6("Frontend Developer"),
                )
                
              ),
              
              column(
                width = 3,
                
                tags$div(
                  style="
            text-align:center;
            background:white;
            padding:30px;
            border-radius:15px;
            box-shadow:0 8px 20px rgba(0,0,0,0.1);",
                  
                  tags$img(
                    src = "developer4.jpeg",
                    style="
              width:150px;
              height:185px;
              border-radius:50%;
              margin-bottom:15px;"
                  ),
                  
                  tags$h5("Willia Sondriva"),
                  tags$h6("Data Analyst"),
                )
                
              ),
              
            )
            
          )
          
        )
      )
      
      
      
    )
    
  )
  
)
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
  
  # ── Reactives: Global Filters ────────────────────────────────────────────
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
    f <- flt(); prev <- prev_period(f$start, f$end)
    build_where(prev$start, prev$end, f$province, f$store_type)
  })
  
  gran     <- reactive({ if (!is.null(input$trend_granularity)) input$trend_granularity else "monthly" })
  date_fmt <- reactive({ if (gran() == "daily") "%Y-%m-%d" else "%Y-%m" })
  
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
  
  # ===================== SALES OVERVIEW — KPIs =========================================
  output$total_revenue <- renderbs4ValueBox({
    cur <- query_kpi_val(base_query()$where, "revenue")
    prev <- query_kpi_val(prev_where(), "revenue")
    bs4ValueBox(value = tags$span(style="font-size:20px; font-weight:bold;", fmt_rupiah(cur)), subtitle = make_subtitle("Total Revenue", pct_badge(cur, prev)),
                icon = icon("money-bill-wave"), color = "success", width = 12)
  })
  
  output$total_transaction <- renderbs4ValueBox({
    cur <- query_kpi_val(base_query()$where, "transaction")
    prev <- query_kpi_val(prev_where(), "transaction")
    bs4ValueBox(value = tags$span(style="font-size:20px; font-weight:bold;",fmt_num(cur)), subtitle = make_subtitle("Total Transactions", pct_badge(cur, prev)),
                icon = icon("receipt"), color = "primary", width = 12)
  })
  
  output$total_items_sold <- renderbs4ValueBox({
    cur <- query_kpi_val(base_query()$where, "items_sold")
    prev <- query_kpi_val(prev_where(), "items_sold")
    bs4ValueBox(value = tags$span(style="font-size:20px; font-weight:bold;", fmt_num(cur)), subtitle = make_subtitle("Total Items Sold", pct_badge(cur, prev)),
                icon = icon("box-open"), color = "info", width = 12)
  })
  
  output$avg_basket <- renderbs4ValueBox({
    cur <- query_kpi_val(base_query()$where, "basket")
    prev <- query_kpi_val(prev_where(), "basket")
    bs4ValueBox(value = tags$span(style="font-size:20px; font-weight:bold;",ifelse(is.na(cur), "0", round(cur, 2))),
                subtitle = make_subtitle("Avg Basket Size", pct_badge(cur, prev)),
                icon = icon("shopping-basket"), color = "warning", width = 12)
  })
  
  output$avg_aov <- renderbs4ValueBox({
    cur <- query_kpi_val(base_query()$where, "aov")
    prev <- query_kpi_val(prev_where(), "aov")
    bs4ValueBox(value = tags$span(style="font-size:20px; font-weight:bold;", fmt_rupiah(cur)), subtitle = make_subtitle("Avg Order Value", pct_badge(cur, prev)),
                icon = icon("chart-bar"), color = "danger", width = 12)
  })
  
  output$active_store <- renderbs4ValueBox({
    cur <- query_kpi_val(base_query()$where, "active_store")
    prev <- query_kpi_val(prev_where(), "active_store")
    bs4ValueBox(value = tags$span(style="font-size:20px; font-weight:bold;", as.integer(cur)), subtitle = make_subtitle("Active Stores", pct_badge(cur, prev)),
                icon = icon("store"), color = "secondary", width = 12)
  })
  
  # ==================== SALES OVERVIEW — Charts =================================================
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
                          "revenue"      = "SUM(ftd.product_price * ftd.quantity)",
                          "transaction"  = "COUNT(DISTINCT ft.invoice_id)",
                          "items_sold"   = "SUM(ftd.quantity)",
                          "basket"       = "ROUND(SUM(ftd.quantity) / COUNT(DISTINCT ft.invoice_id), 2)",
                          "aov"          = "ROUND(SUM(ftd.product_price * ftd.quantity) / COUNT(DISTINCT ft.invoice_id), 0)",
                          "active_store" = "COUNT(DISTINCT ft.store_id)",
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
            line = list(color=col, width=3),
            marker = list(color=col, size=6, line=list(color="#fff", width=1.5)),
            fill = "tozeroy", fillcolor = fill_rgba,
            hovertemplate = "<b>%{x}</b><br>%{y:,.0f}<extra></extra>") |>
      layout(xaxis = list(title="", showgrid=FALSE),
             yaxis = list(title="", gridcolor="#E2E8F0"),
             paper_bgcolor = "transparent", plot_bgcolor = "transparent",
             margin = list(t=10, b=40, l=60, r=10))
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
                        line=list(color="#fff", width=2)),
            textinfo="label+percent",
            hovertemplate="<b>%{label}</b><br>%{value:,} transactions<extra></extra>") |>
      layout(showlegend=TRUE, legend=list(orientation="h", y=-0.1),
             paper_bgcolor="transparent", margin=list(t=10, b=10, l=10, r=10))
  })
  
  active_kpi <- reactive({
    kpi <- if (is.null(input$selected_kpi)) "revenue" else input$selected_kpi
    if (kpi == "active_store") "revenue" else kpi
  })
  
  output$top_stores_title <- renderUI({
    label <- list(revenue="Revenue", transaction="Transactions", items_sold="Items Sold",
                  basket="Avg Basket", aov="AOV")[[active_kpi()]]
    tagList(icon("trophy"), paste(" Top 10 Stores by", label))
  })
  
  output$top_stores_table <- renderTable({
    bq  <- base_query(); kpi <- active_kpi()
    need_detail <- kpi %in% c("revenue","items_sold","basket","aov")
    join_detail <- if (need_detail) "JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id" else ""
    select_col  <- switch(kpi,
                          "revenue"     = "SUM(ftd.product_price * ftd.quantity)",
                          "transaction" = "COUNT(DISTINCT ft.invoice_id)",
                          "items_sold"  = "SUM(ftd.quantity)",
                          "basket"      = "ROUND(SUM(ftd.quantity)/COUNT(DISTINCT ft.invoice_id),2)",
                          "aov"         = "ROUND(SUM(ftd.product_price * ftd.quantity)/COUNT(DISTINCT ft.invoice_id),0)")
    cur <- dbGetQuery(con, sprintf(
      "SELECT ds.store_name, %s AS val FROM fact_transaction ft %s
       JOIN dim_store ds ON ft.store_id=ds.store_id %s
       GROUP BY ft.store_id,ds.store_name ORDER BY val DESC",
      select_col, join_detail, bq$where))
    if (nrow(cur) == 0) return(data.frame())
    prev_d <- dbGetQuery(con, sprintf(
      "SELECT ds.store_name, %s AS val_prev FROM fact_transaction ft %s
       JOIN dim_store ds ON ft.store_id=ds.store_id %s
       GROUP BY ft.store_id,ds.store_name",
      select_col, join_detail, prev_where()))
    merged <- merge(cur, prev_d, by="store_name", all.x=TRUE)
    merged <- merged[order(-merged$val), ]
    merged$pct <- ifelse(is.na(merged$val_prev)|merged$val_prev==0, NA,
                         (merged$val-merged$val_prev)/abs(merged$val_prev)*100)
    fmt_val    <- if (kpi %in% c("revenue","aov")) sapply(merged$val, fmt_rupiah) else sapply(merged$val, fmt_num)
    fmt_growth <- ifelse(
      is.na(merged$pct),
      "N/A",
      ifelse(
        merged$pct >= 0,
        paste0("<span style='color:#16A34A;font-weight:600;'>▲ ",
               sprintf("%.1f%%",abs(merged$pct)),"</span>"),
        paste0("<span style='color:#DC2626;font-weight:600;'>▼ ",
               sprintf("%.1f%%",abs(merged$pct)),"</span>")
      )
    )
    kpi_label  <- list(revenue="Revenue", transaction="Transactions", items_sold="Items Sold",
                       basket="Avg Basket", aov="AOV")[[kpi]]
    out <- setNames(data.frame(paste0("#",seq_len(nrow(merged))), merged$store_name, fmt_val, fmt_growth,
                               check.names=FALSE, stringsAsFactors=FALSE),
                    c("Rank","Store",kpi_label,"Growth"))
    head(out, 10)
  }, striped=TRUE, hover=TRUE, bordered=FALSE, spacing="s", width="100%", align="llrr",sanitize.text.function = function(x) x)
  observeEvent(input$btn_modal_top_stores, {
    bq  <- base_query(); kpi <- active_kpi()
    need_detail <- kpi %in% c("revenue","items_sold","basket","aov")
    join_detail <- if (need_detail) "JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id" else ""
    select_col  <- switch(kpi,
                          "revenue"     = "SUM(ftd.product_price * ftd.quantity)",
                          "transaction" = "COUNT(DISTINCT ft.invoice_id)",
                          "items_sold"  = "SUM(ftd.quantity)",
                          "basket"      = "ROUND(SUM(ftd.quantity)/COUNT(DISTINCT ft.invoice_id),2)",
                          "aov"         = "ROUND(SUM(ftd.product_price * ftd.quantity)/COUNT(DISTINCT ft.invoice_id),0)")
    cur <- dbGetQuery(con, sprintf(
      "SELECT ds.store_name, %s AS val FROM fact_transaction ft %s
       JOIN dim_store ds ON ft.store_id=ds.store_id %s
       GROUP BY ft.store_id,ds.store_name ORDER BY val DESC",
      select_col, join_detail, bq$where))
    if (nrow(cur) == 0) return()
    prev_d <- dbGetQuery(con, sprintf(
      "SELECT ds.store_name, %s AS val_prev FROM fact_transaction ft %s
       JOIN dim_store ds ON ft.store_id=ds.store_id %s
       GROUP BY ft.store_id,ds.store_name",
      select_col, join_detail, prev_where()))
    merged <- merge(cur, prev_d, by="store_name", all.x=TRUE)
    merged <- merged[order(-merged$val), ]
    merged$pct <- ifelse(is.na(merged$val_prev)|merged$val_prev==0, NA,
                         (merged$val-merged$val_prev)/abs(merged$val_prev)*100)
    fmt_val    <- if (kpi %in% c("revenue","aov")) sapply(merged$val, fmt_rupiah) else sapply(merged$val, fmt_num)
    fmt_growth <- ifelse(is.na(merged$pct), "N/A",
                         paste0(ifelse(merged$pct>=0,"▲ ","▼ "), sprintf("%.1f%%",abs(merged$pct))))
    kpi_label  <- list(revenue="Revenue", transaction="Transactions", items_sold="Items Sold",
                       basket="Avg Basket", aov="AOV")[[kpi]]
    showModal(
      modalDialog(
        title = "All Stores Ranking",
        size = "l",
        DTOutput("table_all_store"),
        easyClose = TRUE,
        footer = modalButton("Close")
      )
    )
    
    output$table_all_store <- renderDT({
      
      datatable(
        setNames(
          data.frame(
            Rank  = paste0("#", seq_len(nrow(merged))),
            Store = merged$store_name,
            Value = fmt_val,
            Growth = fmt_growth,
            check.names = FALSE
          ),
          c("Rank","Store",kpi_label,"Growth")
        ),
        options = list(
          pageLength = 15,
          scrollX = TRUE
        )
      )
      
    })
  })
  
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
            hovertemplate="<b>%{y} %{x}:00</b><br>Transactions: %{z:,}<extra></extra>",
            showscale=TRUE) |>
      layout(xaxis=list(title="Hour", tickvals=seq(0,23,3), ticktext=paste0(seq(0,23,3),":00"), showgrid=FALSE),
             yaxis=list(title="", showgrid=FALSE),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=40, l=50, r=10))
  })
  
  # ============== STORE ANALYSIS — KPIs ============================================
  store_query <- reactive({
    f    <- flt()
    prev <- prev_period(f$start, f$end)
    list(
      where      = build_where(f$start, f$end, f$province, f$store_type),
      where_prev = build_where(prev$start, prev$end, f$province, f$store_type),
      f = f
    )
  })
  
  output$store_total <- renderbs4ValueBox({
    sq  <- store_query()
    cur <- as.numeric(dbGetQuery(con, sprintf(
      "SELECT COUNT(DISTINCT ft.store_id) AS val
       FROM fact_transaction ft JOIN dim_store ds ON ft.store_id = ds.store_id %s", sq$where))$val)
    prv <- as.numeric(dbGetQuery(con, sprintf(
      "SELECT COUNT(DISTINCT ft.store_id) AS val
       FROM fact_transaction ft JOIN dim_store ds ON ft.store_id = ds.store_id %s", sq$where_prev))$val)
    bs4ValueBox(value = tags$span(style="font-size:30px; font-weight:bold;", as.integer(cur)), 
                subtitle = make_subtitle("Active Stores", pct_badge(cur, prv)),
                icon = icon("store"), color = "primary")
  })
  
  output$store_top_revenue <- renderbs4ValueBox({
    sq  <- store_query()
    res <- dbGetQuery(con, sprintf(
      "SELECT ds.store_name, SUM(ftd.product_price * ftd.quantity) AS val
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id %s
       GROUP BY ft.store_id, ds.store_name ORDER BY val DESC LIMIT 1", sq$where))
    bs4ValueBox(
      value = tags$span(style="font-size:30px; font-weight:bold;",fmt_rupiah(res$val)),
      subtitle = tagList(
        tags$div(style="font-size:18px; opacity:0.9;", "Top Store Revenue"),
        tags$div(style="font-size:15px; opacity:0.7; margin-top:2px;",
                 if (nrow(res) > 0) res$store_name else "-")),
      icon = icon("trophy"), color = "success")
  })
  
  output$store_avg_aov <- renderbs4ValueBox({
    sq  <- store_query()
    aov_sql <- function(w) sprintf(
      "SELECT ROUND(AVG(store_aov), 0) AS val FROM (
         SELECT ft.store_id, SUM(ftd.product_price * ftd.quantity) / COUNT(DISTINCT ft.invoice_id) AS store_aov
         FROM fact_transaction ft
         JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
         JOIN dim_store ds ON ft.store_id = ds.store_id %s
         GROUP BY ft.store_id) t", w)
    cur <- as.numeric(dbGetQuery(con, aov_sql(sq$where))$val)
    prv <- as.numeric(dbGetQuery(con, aov_sql(sq$where_prev))$val)
    bs4ValueBox(value = tags$span(style="font-size:30px; font-weight:bold;", fmt_rupiah(cur)), 
                subtitle = make_subtitle("Avg AOV per Store", pct_badge(cur, prv)),
                icon = icon("chart-bar"), color = "warning", width = 12)
  })
  
  # ===================== STORE ANALYSIS — Charts ==============================================
  output$store_revenue_bar <- renderPlotly({
    sq  <- store_query()
    sql <- sprintf(
      "SELECT ds.store_name, SUM(ftd.product_price * ftd.quantity) AS revenue
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id %s
       GROUP BY ft.store_id, ds.store_name ORDER BY revenue DESC LIMIT 10", sq$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    data <- data[order(data$revenue), ]
    plot_ly(data, x=~revenue, y=~factor(store_name, levels=store_name),
            type="bar", orientation="h",
            marker=list(color="#2563EB", line=list(color="#1E3A8A", width=0.5)),
            hovertemplate="<b>%{y}</b><br>Revenue: Rp %{x:,.0f}<extra></extra>") |>
      layout(xaxis=list(title="Revenue (Rp)", tickformat=".2s", showgrid=TRUE, gridcolor="#E2E8F0"),
             yaxis=list(title="", showgrid=FALSE),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=50, l=160, r=20))
  })
  
  output$store_type_donut <- renderPlotly({
    sq  <- store_query()
    sql <- sprintf(
      "SELECT ds.store_type, SUM(ftd.product_price * ftd.quantity) AS revenue
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id %s
       GROUP BY ds.store_type ORDER BY revenue DESC", sq$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    plot_ly(data, labels=~store_type, values=~revenue, type="pie", hole=0.55,
            marker=list(colors=c("#2563EB","#10B981","#F59E0B","#EF4444","#06B6D4"),
                        line=list(color="#fff", width=2)),
            textinfo="label+percent",
            hovertemplate="<b>Type %{label}</b><br>Revenue: Rp %{value:,.0f}<br>%{percent}<extra></extra>") |>
      layout(showlegend=TRUE, legend=list(orientation="h", y=-0.1),
             paper_bgcolor="transparent", margin=list(t=10, b=10, l=10, r=10))
  })
  
  output$store_aov_bar <- renderPlotly({
    sq  <- store_query()
    sql <- sprintf(
      "SELECT ds.store_name,
              ROUND(SUM(ftd.product_price * ftd.quantity) / COUNT(DISTINCT ft.invoice_id), 0) AS aov
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id %s
       GROUP BY ft.store_id, ds.store_name ORDER BY aov DESC LIMIT 10", sq$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    plot_ly(data, x=~store_name, y=~aov, type="bar",
            marker=list(color="#F59E0B", line=list(color="#D97706", width=0.8)),
            hovertemplate="<b>%{x}</b><br>AOV: Rp %{y:,.0f}<extra></extra>") |>
      layout(xaxis=list(title="", tickangle=-35, showgrid=FALSE),
             yaxis=list(title="AOV (Rp)", tickformat=".2s", gridcolor="#E2E8F0"),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=100, l=60, r=10))
  })
  
  output$store_trx_bar <- renderPlotly({
    sq  <- store_query()
    sql <- sprintf(
      "SELECT ds.store_name, COUNT(DISTINCT ft.invoice_id) AS n_trx
       FROM fact_transaction ft
       JOIN dim_store ds ON ft.store_id = ds.store_id %s
       GROUP BY ft.store_id, ds.store_name ORDER BY n_trx DESC LIMIT 10", sq$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    plot_ly(data, x=~store_name, y=~n_trx, type="bar",
            marker=list(color="#06B6D4", line=list(color="#0891B2", width=0.8)),
            hovertemplate="<b>%{x}</b><br>Transactions: %{y:,}<extra></extra>") |>
      layout(xaxis=list(title="", tickangle=-35, showgrid=FALSE),
             yaxis=list(title="Total Transactions", gridcolor="#E2E8F0"),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=100, l=60, r=10))
  })
  
  output$store_province_bar <- renderPlotly({
    sq  <- store_query()
    sql <- sprintf(
      "SELECT ds.store_province,
              SUM(ftd.product_price * ftd.quantity) AS revenue,
              COUNT(DISTINCT ft.invoice_id) AS n_trx,
              COUNT(DISTINCT ft.store_id)   AS n_stores
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id %s
       GROUP BY ds.store_province ORDER BY revenue DESC", sq$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    data <- data[order(data$revenue), ]
    plot_ly(data, x=~revenue, y=~factor(store_province, levels=store_province),
            type="bar", orientation="h",
            marker=list(color=~revenue, colorscale=list(c(0,"#BFDBFE"),c(1,"#1E3A8A")), showscale=FALSE),
            hovertemplate=paste0("<b>%{y}</b><br>Revenue: Rp %{x:,.0f}<br>",
                                 "Stores: ", data$n_stores, "<br>",
                                 "Transactions: ", scales::comma(data$n_trx), "<extra></extra>")) |>
      layout(xaxis=list(title="Revenue (Rp)", tickformat=".2s", showgrid=TRUE, gridcolor="#E2E8F0"),
             yaxis=list(title="", showgrid=FALSE),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=50, l=140, r=20))
  })
  
  output$store_ranking_table <- renderTable({
    sq      <- store_query()
    cur <- dbGetQuery(con, sprintf(
      "SELECT ds.store_name, ds.store_city, ds.store_type,
              COUNT(DISTINCT ft.invoice_id) AS n_trx,
              SUM(ftd.product_price * ftd.quantity) AS revenue,
              ROUND(SUM(ftd.product_price * ftd.quantity) / COUNT(DISTINCT ft.invoice_id), 0) AS aov
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id %s
       GROUP BY ft.store_id, ds.store_name, ds.store_city, ds.store_type
       ORDER BY revenue DESC LIMIT 10", sq$where))
    prev <- dbGetQuery(con, sprintf(
      "SELECT ds.store_name, SUM(ftd.product_price * ftd.quantity) AS revenue_prev
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id %s
       GROUP BY ft.store_id, ds.store_name", sq$where_prev))
    if (nrow(cur) == 0) return(data.frame())
    merged <- merge(cur, prev, by="store_name", all.x=TRUE)
    merged <- merged[order(-merged$revenue), ]
    merged$growth <- ifelse(is.na(merged$revenue_prev)|merged$revenue_prev==0, NA,
                            (merged$revenue-merged$revenue_prev)/abs(merged$revenue_prev)*100)
    data.frame(
      Rank    = paste0("#", seq_len(nrow(merged))),
      Store   = merged$store_name,
      City    = merged$store_city,
      Type    = merged$store_type,
      Revenue = sapply(merged$revenue, fmt_rupiah),
      AOV     = sapply(merged$aov, fmt_rupiah),
      Trx     = sapply(merged$n_trx, fmt_num),
      Growth  = ifelse(is.na(merged$growth), "N/A",
                       paste0(ifelse(merged$growth>=0,"\u25b2 ","\u25bc "), sprintf("%.1f%%",abs(merged$growth)))),
      check.names=FALSE, stringsAsFactors=FALSE)
  }, striped=TRUE, hover=TRUE, bordered=FALSE, spacing="s", width="100%", align="llllrrrr")
  
  # ====================== PRODUCT ANALYSIS — KPIs =============================================
  prod_query <- reactive({
    f <- flt()
    list(where = build_where(f$start, f$end, f$province, f$store_type), f = f)
  })
  
  output$prod_total <- renderbs4ValueBox({
    n <- as.numeric(dbGetQuery(con,
                               "SELECT COUNT(DISTINCT product_id) AS val FROM dim_product WHERE product_id > 0")$val)
    bs4ValueBox(value = tags$span(style = "font-size:30px; font-weight:bold;", fmt_num(n)),
                subtitle=tags$div(style="font-size:16px;opacity:0.9;","Total Products"),
                icon=icon("box"), color="primary", width=12)
  })
  
  output$prod_brand <- renderbs4ValueBox({
    n <- as.numeric(dbGetQuery(con,
                               "SELECT COUNT(DISTINCT brand) AS val FROM dim_product WHERE product_id > 0")$val)
    bs4ValueBox(value = tags$span(style = "font-size:30px; font-weight:bold;", fmt_num(n)),, subtitle=tags$div(style="font-size:16px;opacity:0.9;","Total Brands"),
                icon=icon("tag"), color="success", width=12)
  })
  
  output$prod_kategori <- renderbs4ValueBox({
    n <- as.numeric(dbGetQuery(con,
                               "SELECT COUNT(DISTINCT category_lvl1) AS val FROM dim_category WHERE category_id > 0")$val)
    bs4ValueBox(value = tags$span(style = "font-size:30px; font-weight:bold;", fmt_num(n)),, subtitle=tags$div(style="font-size:16px;opacity:0.9;","Total Categories"),
                icon=icon("list"), color="warning", width=12)
  })
  
  # =================== PRODUCT ANALYSIS — Charts ===========================================
  output$prod_top_revenue <- renderPlotly({
    pq  <- prod_query()
    sql <- sprintf(
      "SELECT p.product_name, SUM(ftd.product_price * ftd.quantity) AS revenue
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id
       JOIN dim_product p ON ftd.product_id = p.product_id %s
       GROUP BY p.product_id, p.product_name ORDER BY revenue DESC LIMIT 10", pq$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    data <- data[order(data$revenue), ]
    plot_ly(data, x=~revenue, y=~factor(product_name, levels=product_name),
            type="bar", orientation="h",
            marker=list(color="#2563EB", line=list(color="#1E3A8A", width=0.5)),
            hovertemplate="<b>%{y}</b><br>Revenue: Rp %{x:,.0f}<extra></extra>") |>
      layout(xaxis=list(title="Revenue (Rp)", tickformat=".2s", showgrid=TRUE, gridcolor="#E2E8F0"),
             yaxis=list(title="", showgrid=FALSE,tickfont=list(size=7)),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=50, l=200, r=20))
  })
  
  output$prod_top_qty <- renderPlotly({
    pq  <- prod_query()
    sql <- sprintf(
      "SELECT p.product_name, SUM(ftd.quantity) AS qty
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id
       JOIN dim_product p ON ftd.product_id = p.product_id %s
       GROUP BY p.product_id, p.product_name ORDER BY qty DESC LIMIT 10", pq$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    data <- data[order(data$qty), ]
    plot_ly(data, x=~qty, y=~factor(product_name, levels=product_name),
            type="bar", orientation="h",
            marker=list(color="#10B981", line=list(color="#065F46", width=0.5)),
            hovertemplate="<b>%{y}</b><br>Qty: %{x:,}<extra></extra>") |>
      layout(xaxis=list(title="Quantity Sold", showgrid=TRUE, gridcolor="#E2E8F0"),
             yaxis=list(title="", showgrid=FALSE,tickfont=list(size=7)),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=50, l=200, r=20))
  })
  
  output$prod_kategori_bar <- renderPlotly({
    pq  <- prod_query()
    sql <- sprintf(
      "SELECT c.category_lvl1, SUM(ftd.product_price * ftd.quantity) AS revenue
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id
       JOIN dim_product p ON ftd.product_id = p.product_id
       JOIN dim_category c ON p.category_id = c.category_id %s
       GROUP BY c.category_lvl1 ORDER BY revenue DESC", pq$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    data <- data[order(data$revenue), ]
    colors <- colorRampPalette(c("#BFDBFE","#2563EB"))(nrow(data))
    plot_ly(data, x=~revenue, y=~factor(category_lvl1, levels=category_lvl1),
            type="bar", orientation="h",
            marker=list(color=colors, line=list(color="#1E3A8A", width=0.3)),
            hovertemplate="<b>%{y}</b><br>Revenue: Rp %{x:,.0f}<extra></extra>") |>
      layout(xaxis=list(title="Revenue (Rp)", tickformat=".2s", showgrid=TRUE, gridcolor="#E2E8F0"),
             yaxis=list(title="", showgrid=FALSE),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=50, l=160, r=20))
  })
  
  output$prod_brand_bar <- renderPlotly({
    pq  <- prod_query()
    sql <- sprintf(
      "SELECT p.brand, SUM(ftd.product_price * ftd.quantity) AS revenue, SUM(ftd.quantity) AS qty
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id
       JOIN dim_product p ON ftd.product_id = p.product_id %s
       GROUP BY p.brand ORDER BY revenue DESC LIMIT 15", pq$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    data <- data[order(data$revenue), ]
    plot_ly(data, x=~revenue, y=~factor(brand, levels=brand),
            type="bar", orientation="h",
            marker=list(color="#F59E0B", line=list(color="#D97706", width=0.5)),
            customdata=~qty,
            hovertemplate="<b>%{y}</b><br>Revenue: Rp %{x:,.0f}<br>Qty: %{customdata:,}<extra></extra>") |>
      layout(xaxis=list(title="Revenue (Rp)", tickformat=".2s", showgrid=TRUE, gridcolor="#E2E8F0"),
             yaxis=list(title="", showgrid=FALSE),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=50, l=120, r=20))
  })
  
  output$prod_velocity <- renderPlotly({
    pq  <- prod_query()
    sql <- sprintf(
      "SELECT p.product_name, p.brand,
              SUM(ftd.quantity) AS total_qty,
              COUNT(DISTINCT DATE(ft.invoice_datetime)) AS days_sold,
              ROUND(SUM(ftd.quantity) / COUNT(DISTINCT DATE(ft.invoice_datetime)), 2) AS velocity
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id
       JOIN dim_product p ON ftd.product_id = p.product_id %s
       GROUP BY p.product_id, p.product_name, p.brand
       ORDER BY velocity DESC LIMIT 30", pq$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    avg_vel       <- mean(data$velocity, na.rm=TRUE)
    data$color    <- ifelse(data$velocity >= avg_vel, "#10B981", "#EF4444")
    data <- data[order(data$velocity), ]
    plot_ly(data, x=~velocity, y=~factor(product_name, levels=product_name),
            type="bar", orientation="h",
            marker=list(color=~color), customdata=~total_qty,
            hovertemplate="<b>%{y}</b><br>Velocity: %{x:.2f} qty/day<br>Total Qty: %{customdata:,}<extra></extra>") |>
      layout(xaxis=list(title="Velocity (qty/day)", showgrid=TRUE, gridcolor="#E2E8F0"),
             yaxis=list(title="", showgrid=FALSE,tickfont=list(size=7)),
             shapes=list(list(type="line", x0=avg_vel, x1=avg_vel, y0=0, y1=1,
                              yref="paper", line=list(color="#2563EB", dash="dash", width=2))),
             annotations=list(list(x=avg_vel, y=1, yref="paper", text="Avg",
                                   showarrow=FALSE, font=list(color="#2563EB", size=11))),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=50, l=200, r=20))
  })
  
  output$prod_scatter <- renderPlotly({
    pq  <- prod_query()
    sql <- sprintf(
      "SELECT p.product_name, p.brand,
              ROUND(AVG(ftd.product_price), 0) AS avg_price,
              SUM(ftd.quantity) AS total_qty,
              COUNT(DISTINCT ftd.invoice_id) AS n_trx
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id
       JOIN dim_product p ON ftd.product_id = p.product_id %s
       GROUP BY p.product_id, p.product_name, p.brand HAVING total_qty > 0", pq$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    plot_ly(data, x=~avg_price, y=~total_qty, type="scatter", mode="markers",
            marker=list(color="#2563EB", size=~log1p(n_trx)*3,
                        opacity=0.6, line=list(color="#1E3A8A", width=0.5)),
            text=~product_name,
            hovertemplate="<b>%{text}</b><br>Avg Price: Rp %{x:,.0f}<br>Total Qty: %{y:,}<extra></extra>") |>
      layout(xaxis=list(title="Avg Price (Rp)", tickformat=".2s", showgrid=TRUE, gridcolor="#E2E8F0"),
             yaxis=list(title="Total Qty Sold", showgrid=TRUE, gridcolor="#E2E8F0"),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=50, l=60, r=20))
  })
  
  output$prod_price_dist <- renderPlotly({
    pq  <- prod_query()
    sql <- sprintf(
      "SELECT ftd.product_price
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id %s", pq$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    plot_ly(data, x=~product_price, type="histogram", nbinsx=40,
            marker=list(color="#06B6D4", line=list(color="#0891B2", width=0.5)),
            hovertemplate="Price: Rp %{x:,.0f}<br>Count: %{y:,}<extra></extra>") |>
      layout(xaxis=list(title="Product Price (Rp)", tickformat=".2s", showgrid=FALSE),
             yaxis=list(title="Frequency", gridcolor="#E2E8F0"),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=50, l=60, r=20))
  })
  
  # ================= CUSTOMER ANALYSIS — KPIs ==============================================
  output$cust_total_aktif <- renderbs4ValueBox({
    cf  <- cust_flt()
    cur <- as.numeric(dbGetQuery(con, sprintf(
      "SELECT COUNT(DISTINCT ft.customer_id) AS val
       FROM fact_transaction ft JOIN dim_store ds ON ft.store_id=ds.store_id
       JOIN dim_customer dc ON ft.customer_id=dc.customer_id
       %s AND ft.customer_id > 0", cf$where))$val)
    prv <- as.numeric(dbGetQuery(con, sprintf(
      "SELECT COUNT(DISTINCT ft.customer_id) AS val
       FROM fact_transaction ft JOIN dim_store ds ON ft.store_id=ds.store_id
       JOIN dim_customer dc ON ft.customer_id=dc.customer_id
       %s AND ft.customer_id > 0", cf$where_prev))$val)
    bs4ValueBox(value = tags$span(style="font-size:25px; font-weight:bold;",fmt_num(cur)), 
                subtitle=make_subtitle("Total Active Customers", pct_badge(cur, prv)),
                icon=icon("users"), color="primary", width=12)
  })
  
  output$cust_perempuan <- renderbs4ValueBox({
    cf  <- cust_flt()
    cur <- as.numeric(dbGetQuery(con, sprintf(
      "SELECT COUNT(DISTINCT ft.customer_id) AS val
       FROM fact_transaction ft JOIN dim_store ds ON ft.store_id=ds.store_id
       JOIN dim_customer dc ON ft.customer_id=dc.customer_id
       %s AND ft.customer_id > 0 AND dc.gender = 'P'", cf$where))$val)
    prv <- as.numeric(dbGetQuery(con, sprintf(
      "SELECT COUNT(DISTINCT ft.customer_id) AS val
       FROM fact_transaction ft JOIN dim_store ds ON ft.store_id=ds.store_id
       JOIN dim_customer dc ON ft.customer_id=dc.customer_id
       %s AND ft.customer_id > 0 AND dc.gender = 'P'", cf$where_prev))$val)
    bs4ValueBox(value = tags$span(style="font-size:25px; font-weight:bold;",fmt_num(cur)), 
                subtitle=make_subtitle("Female Customers", pct_badge(cur, prv)),
                icon=icon("female"), color="danger", width=12)
  })
  
  output$cust_lakilaki <- renderbs4ValueBox({
    cf  <- cust_flt()
    cur <- as.numeric(dbGetQuery(con, sprintf(
      "SELECT COUNT(DISTINCT ft.customer_id) AS val
       FROM fact_transaction ft JOIN dim_store ds ON ft.store_id=ds.store_id
       JOIN dim_customer dc ON ft.customer_id=dc.customer_id
       %s AND ft.customer_id > 0 AND dc.gender = 'L'", cf$where))$val)
    prv <- as.numeric(dbGetQuery(con, sprintf(
      "SELECT COUNT(DISTINCT ft.customer_id) AS val
       FROM fact_transaction ft JOIN dim_store ds ON ft.store_id=ds.store_id
       JOIN dim_customer dc ON ft.customer_id=dc.customer_id
       %s AND ft.customer_id > 0 AND dc.gender = 'L'", cf$where_prev))$val)
    bs4ValueBox(value = tags$span(style="font-size:25px; font-weight:bold;",fmt_num(cur)), 
                subtitle=make_subtitle("Male Customers", pct_badge(cur, prv)),
                icon=icon("male"), color="info", width=12)
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
    bs4ValueBox(value = tags$span(style="font-size:25px; font-weight:bold;",fmt_rupiah(cur)), 
                subtitle=make_subtitle("Avg First Purchase", pct_badge(cur, prv)),
                icon=icon("tag"), color="warning", width=12)
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
      value = tags$span(style="font-size:30px; font-weight:bold;", paste0(pct, "%")),
      subtitle = tagList(
        tags$div(style="font-size:13px; opacity:0.9;", "New Customer Ratio"),
        tags$div(style="font-size:20px; opacity:0.7; margin-top:2px;",
                 paste0(fmt_num(n_new), " new / ", fmt_num(n_all), " total"))),
      icon=icon("users"), color="success",width=4)
  })
  
  # NOTE: cust_new_total is kept for backward compat but replaced by cust_total_aktif in UI
  output$cust_new_total <- renderbs4ValueBox({
    cf  <- cust_flt()
    cte <- first_trans_cte(cf$where)
    cur <- as.numeric(dbGetQuery(con, paste(cte, "SELECT COUNT(*) AS val FROM first_trans"))$val)
    prv <- as.numeric(dbGetQuery(con, paste(first_trans_cte(cf$where_prev), "SELECT COUNT(*) AS val FROM first_trans"))$val)
    bs4ValueBox(value=fmt_num(cur), subtitle=make_subtitle("New Customers", pct_badge(cur, prv)),
                icon=icon("user-plus"), color="primary", width=12)
  })
  
  # ============== CUSTOMER ANALYSIS — Charts ========================================
  output$cust_trend_plot <- renderPlotly({
    cf      <- cust_flt()
    fmt     <- cust_date_fmt()
    fmt_esc <- gsub("%", "%%", fmt)
    cte     <- first_trans_cte(cf$where)
    sql <- paste0(
      cte,
      " SELECT DATE_FORMAT(first_dt, '", fmt, "') AS period_label,",
      " COUNT(*) AS new_customers",
      " FROM first_trans",
      " GROUP BY DATE_FORMAT(first_dt, '", fmt, "')",
      " ORDER BY period_label"
    )
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    data$growth <- c(NA, round(diff(data$new_customers) / abs(head(data$new_customers,-1)) * 100, 1))
    plot_ly(data, x=~period_label) |>
      add_bars(y=~new_customers, name="New Customers",
               marker=list(color="#2563EB", opacity=0.8), yaxis="y",
               hovertemplate="<b>%{x}</b><br>New Customers: %{y:,}<extra></extra>") |>
      add_lines(y=~growth, name="MoM Growth %",
                line=list(color="#F59E0B", width=2.5), yaxis="y2",
                hovertemplate="<b>%{x}</b><br>Growth: %{y:.1f}%<extra></extra>") |>
      layout(yaxis  = list(title="New Customers", showgrid=TRUE, gridcolor="#E2E8F0"),
             yaxis2 = list(title="MoM Growth (%)", overlaying="y", side="right",
                           showgrid=FALSE, zeroline=TRUE, zerolinecolor="#E2E8F0"),
             xaxis  = list(title="", showgrid=FALSE),
             legend = list(orientation="h", y=-0.5),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=50, l=60, r=60))
  })
  
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
    plot_ly(data, x=~month_label) |>
      add_bars(y=~new_cust, name="New", marker=list(color="#2563EB"),
               hovertemplate="<b>%{x}</b><br>New: %{y:,}<extra></extra>") |>
      add_bars(y=~returning_cust, name="Returning", marker=list(color="#10B981"),
               hovertemplate="<b>%{x}</b><br>Returning: %{y:,}<extra></extra>") |>
      layout(barmode="stack", xaxis=list(title="", showgrid=FALSE),
             yaxis=list(title="Customers", gridcolor="#E2E8F0"),
             legend=list(orientation="h", y=-0.2),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=50, l=60, r=10))
  })
  
  output$cust_first_purchase <- renderPlotly({
    cf  <- cust_flt()
    sql <- sprintf("
      SELECT DATE_FORMAT(fi.first_dt,'%%Y-%%m') AS month_label,
             ROUND(AVG(fv.first_val),0) AS avg_val,
             MIN(fv.first_val) AS min_val,
             MAX(fv.first_val) AS max_val
      FROM (
        SELECT ft.customer_id, MIN(ft.invoice_datetime) AS first_dt
        FROM fact_transaction ft
        JOIN dim_store ds ON ft.store_id=ds.store_id
        JOIN dim_customer dc ON ft.customer_id=dc.customer_id
        %s AND ft.customer_id > 0
        GROUP BY ft.customer_id
      ) fi
      JOIN (
        SELECT ft2.customer_id,
               SUM(ftd.product_price * ftd.quantity) AS first_val
        FROM fact_transaction ft2
        JOIN fact_transaction_detail ftd ON ft2.invoice_id=ftd.invoice_id
        JOIN (
          SELECT customer_id, MIN(invoice_datetime) AS first_dt
          FROM fact_transaction WHERE customer_id > 0
          GROUP BY customer_id
        ) fm ON ft2.customer_id=fm.customer_id AND ft2.invoice_datetime=fm.first_dt
        GROUP BY ft2.customer_id
      ) fv ON fi.customer_id=fv.customer_id
      GROUP BY DATE_FORMAT(fi.first_dt,'%%Y-%%m')
      ORDER BY month_label", cf$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    plot_ly(data, x=~month_label) |>
      add_lines(y=~avg_val, name="Avg", line=list(color="#F59E0B", width=3),
                hovertemplate="<b>%{x}</b><br>Avg: Rp %{y:,.0f}<extra></extra>") |>
      add_lines(y=~max_val, name="Max", line=list(color="#10B981", width=1.5, dash="dash"),
                hovertemplate="<b>%{x}</b><br>Max: Rp %{y:,.0f}<extra></extra>") |>
      add_lines(y=~min_val, name="Min", line=list(color="#EF4444", width=1.5, dash="dash"),
                hovertemplate="<b>%{x}</b><br>Min: Rp %{y:,.0f}<extra></extra>") |>
      layout(xaxis=list(title="", showgrid=FALSE),
             yaxis=list(title="First Purchase (Rp)", tickformat=".2s", gridcolor="#E2E8F0"),
             legend=list(orientation="h", y=-0.2),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=50, l=60, r=10))
  })
  
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
             ANY_VALUE(TIMESTAMPDIFF(MONTH, so.city_open_date,
               DATE(CONCAT(DATE_FORMAT(ft.first_dt,'%%Y-%%m'),'-01'))) + 1) AS operational_month,
             COUNT(ft.customer_id) AS new_customers
      FROM first_trans ft
      JOIN store_open so ON ft.store_city=so.store_city
      GROUP BY ft.store_city, DATE_FORMAT(ft.first_dt,'%%Y-%%m')
      ORDER BY ft.store_city, month_label", cf$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    x_col   <- if (mode == "calendar") "month_label" else "operational_month"
    x_title <- if (mode == "calendar") "" else "Operational Month (since store open)"
    top_cities <- data |>
      dplyr::group_by(store_city) |>
      dplyr::summarise(total=sum(new_customers), .groups="drop") |>
      dplyr::arrange(dplyr::desc(total)) |>
      dplyr::slice_head(n=8) |>
      dplyr::pull(store_city)
    data   <- data[data$store_city %in% top_cities, ]
    colors <- c("#2563EB","#10B981","#F59E0B","#EF4444","#06B6D4","#8B5CF6","#EC4899","#64748B")
    p <- plot_ly()
    for (i in seq_along(top_cities)) {
      cd <- data[data$store_city == top_cities[i], ]
      p  <- p |> add_lines(data=cd, x=~get(x_col), y=~new_customers,
                           name=top_cities[i], line=list(color=colors[i], width=2),
                           marker=list(color=colors[i], size=5), mode="lines+markers",
                           hovertemplate=paste0("<b>", top_cities[i], "</b><br>",
                                                if(mode=="calendar") "%{x}" else "Month %{x}",
                                                "<br>New Customers: %{y:,}<extra></extra>"))
    }
    p |> layout(xaxis=list(title=x_title, showgrid=FALSE),
                yaxis=list(title="New Customers", gridcolor="#E2E8F0"),
                legend=list(orientation="h", y=-0.15),
                paper_bgcolor="transparent", plot_bgcolor="transparent",
                margin=list(t=10, b=60, l=60, r=10))
  })
  
  output$cust_gender_donut <- renderPlotly({
    cf  <- cust_flt()
    sql <- sprintf(
      "SELECT dc.gender, SUM(ftd.product_price * ftd.quantity) AS revenue,
              COUNT(DISTINCT ft.customer_id) AS n_cust
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id
       JOIN dim_customer dc ON ft.customer_id = dc.customer_id
       %s AND ft.customer_id > 0
       GROUP BY dc.gender", cf$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    data$label <- ifelse(data$gender=="P","Female",ifelse(data$gender=="L","Male",data$gender))
    plot_ly(data, labels=~label, values=~revenue, type="pie", hole=0.55,
            marker=list(colors=c("#EC4899","#06B6D4","#94A3B8"),
                        line=list(color="#fff", width=2)),
            textinfo="label+percent",
            hovertemplate="<b>%{label}</b><br>Revenue: Rp %{value:,.0f}<br>%{percent}<extra></extra>") |>
      layout(showlegend=TRUE, legend=list(orientation="h", y=-0.1),
             paper_bgcolor="transparent", margin=list(t=10, b=10, l=10, r=10))
  })
  
  output$cust_kota_bar <- renderPlotly({
    cf  <- cust_flt()
    sql <- sprintf(
      "SELECT dc.customer_city,
              SUM(ftd.product_price * ftd.quantity) AS revenue,
              COUNT(DISTINCT ft.customer_id) AS n_cust
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id
       JOIN dim_customer dc ON ft.customer_id = dc.customer_id
       %s AND ft.customer_id > 0
       GROUP BY dc.customer_city ORDER BY revenue DESC LIMIT 15", cf$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(plotly_empty())
    data <- data[order(data$revenue), ]
    plot_ly(data, x=~revenue, y=~factor(customer_city, levels=customer_city),
            type="bar", orientation="h",
            marker=list(color="#8B5CF6", line=list(color="#6D28D9", width=0.5)),
            customdata=~n_cust,
            hovertemplate="<b>%{y}</b><br>Revenue: Rp %{x:,.0f}<br>Customers: %{customdata:,}<extra></extra>") |>
      layout(xaxis=list(title="Revenue (Rp)", tickformat=".2s", showgrid=TRUE, gridcolor="#E2E8F0"),
             yaxis=list(title="", showgrid=FALSE),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=50, l=120, r=20))
  })
  
  output$cust_top_table <- renderTable({
    cf  <- cust_flt()
    sql <- sprintf(
      "SELECT dc.customer_name, dc.gender, dc.customer_city,
              COUNT(DISTINCT ft.invoice_id) AS n_trx,
              SUM(ftd.product_price * ftd.quantity) AS revenue
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id
       JOIN dim_customer dc ON ft.customer_id = dc.customer_id
       %s AND ft.customer_id > 0
       GROUP BY ft.customer_id, dc.customer_name, dc.gender, dc.customer_city
       ORDER BY revenue DESC LIMIT 20", cf$where)
    data <- dbGetQuery(con, sql)
    if (nrow(data) == 0) return(data.frame())
    data.frame(
      Rank     = paste0("#", seq_len(nrow(data))),
      Customer = data$customer_name,
      Gender   = ifelse(data$gender=="P","Female",ifelse(data$gender=="L","Male",data$gender)),
      City     = data$customer_city,
      Trx      = sapply(data$n_trx, fmt_num),
      Revenue  = sapply(data$revenue, fmt_rupiah),
      check.names=FALSE, stringsAsFactors=FALSE)
  }, striped=TRUE, hover=TRUE, bordered=FALSE, spacing="s", width="100%", align="llllrr")
  
  # =========================================================================
  # MARKET BASKET ANALYSIS — KPIs & Charts
  # =========================================================================
  basket_query <- reactive({
    f <- flt()
    list(where = build_where(f$start, f$end, f$province, f$store_type), f = f)
  })

  basket_stats <- reactive({
    bq  <- basket_query()
    sql <- sprintf("
      SELECT
        CASE WHEN ft.customer_id > 0 THEN 'Member' ELSE 'Non-Member' END AS customer_type,
        COUNT(DISTINCT ft.invoice_id) AS total_trx,
        SUM(ftd.quantity) AS total_items,
        SUM(ftd.product_price * ftd.quantity) AS total_revenue,
        ROUND(SUM(ftd.quantity) / COUNT(DISTINCT ft.invoice_id), 2) AS avg_items,
        ROUND(SUM(ftd.product_price * ftd.quantity) / COUNT(DISTINCT ft.invoice_id), 0) AS avg_trx_value
      FROM fact_transaction ft
      JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
      JOIN dim_store ds ON ft.store_id = ds.store_id
      %s
      GROUP BY CASE WHEN ft.customer_id > 0 THEN 'Member' ELSE 'Non-Member' END",
      bq$where)
    dbGetQuery(con, sql)
  })

  # ── KPI: Member ───────────────────────────────────────────────────────────
  output$basket_kpi_trx_member <- renderbs4ValueBox({
    d <- basket_stats(); m <- d[d$customer_type == "Member", ]
    bs4ValueBox(value = tags$span(style="font-size:20px; font-weight:bold;", if (nrow(m) > 0) fmt_num(m$total_trx) else "0"),
      subtitle = tags$div(style="font-size:16px;opacity:0.9;", "Member Transactions"),
      icon = icon("id-card"), color = "primary", width = 12)
  })

  output$basket_kpi_items_member <- renderbs4ValueBox({
    d <- basket_stats(); m <- d[d$customer_type == "Member", ]
    bs4ValueBox(value = tags$span(style="font-size:20px; font-weight:bold;", if (nrow(m) > 0) m$avg_items else "0"),
      subtitle = tags$div(style="font-size:16px;opacity:0.9;", "Avg Items/Trx (Member)"),
      icon = icon("shopping-basket"), color = "primary", width = 12)
  })

  output$basket_kpi_val_member <- renderbs4ValueBox({
    d <- basket_stats(); m <- d[d$customer_type == "Member", ]
    bs4ValueBox(value = tags$span(style="font-size:20px; font-weight:bold;",if (nrow(m) > 0) fmt_rupiah(m$avg_trx_value) else "Rp 0"),
      subtitle = tags$div(style="font-size:16px;opacity:0.9;", "Avg Trx Value (Member)"),
      icon = icon("receipt"), color = "primary", width = 12)
  })

  # ── KPI: Non-Member ───────────────────────────────────────────────────────
  output$basket_kpi_trx_nonmember <- renderbs4ValueBox({
    d <- basket_stats(); n <- d[d$customer_type == "Non-Member", ]
    bs4ValueBox(value = tags$span(style="font-size:20px; font-weight:bold;", if (nrow(n) > 0) fmt_num(n$total_trx) else "0"),
      subtitle = tags$div(style="font-size:16px;opacity:0.9;", "Non-Member Transactions"),
      icon = icon("user"), color = "success", width = 12)
  })

  output$basket_kpi_items_nonmember <- renderbs4ValueBox({
    d <- basket_stats(); n <- d[d$customer_type == "Non-Member", ]
    bs4ValueBox(value = tags$span(style="font-size:20px; font-weight:bold;", if (nrow(n) > 0) n$avg_items else "0"),
      subtitle = tags$div(style="font-size:16px;opacity:0.9;", "Avg Items/Trx (Non-Member)"),
      icon = icon("shopping-basket"), color = "success", width = 12)
  })

  output$basket_kpi_val_nonmember <- renderbs4ValueBox({
    d <- basket_stats(); n <- d[d$customer_type == "Non-Member", ]
    bs4ValueBox(value = tags$span(style="font-size:20px; font-weight:bold;",if (nrow(n) > 0) fmt_rupiah(n$avg_trx_value) else "Rp 0"),
      subtitle = tags$div(style="font-size:16px;opacity:0.9;", "Avg Trx Value (Non-Member)"),
      icon = icon("receipt"), color = "success", width = 12)
  })

  # ── Helper: fetch member/nonmember trend data ────────────────────────────
  basket_trend_data <- reactive({
    bq      <- basket_query()
    fmt     <- date_fmt()
    fmt_esc <- gsub("%", "%%", fmt)
    sql <- sprintf(paste0(
      "SELECT DATE_FORMAT(ft.invoice_datetime, '", fmt_esc, "') AS period_label,
              CASE WHEN ft.customer_id > 0 THEN 'Member' ELSE 'Non-Member' END AS ctype,
              COUNT(DISTINCT ft.invoice_id) AS n_trx,
              ROUND(SUM(ftd.product_price * ftd.quantity) / COUNT(DISTINCT ft.invoice_id), 0) AS avg_val
       FROM fact_transaction ft
       JOIN fact_transaction_detail ftd ON ft.invoice_id = ftd.invoice_id
       JOIN dim_store ds ON ft.store_id = ds.store_id
       %s
       GROUP BY DATE_FORMAT(ft.invoice_datetime, '", fmt_esc, "'), ctype
       ORDER BY period_label"), bq$where)
    dbGetQuery(con, sql)
  })

  # ── Chart: Trend Jumlah Transaksi ─────────────────────────────────────────
  output$basket_trend_trx <- renderPlotly({
    data <- basket_trend_data()
    if (nrow(data) == 0) return(plotly_empty())
    m <- data[data$ctype == "Member", ]
    n <- data[data$ctype == "Non-Member", ]
    plot_ly() |>
      add_lines(data=m, x=~period_label, y=~n_trx, name="Member",
                line=list(color="#2563EB", width=3), mode="lines+markers",
                marker=list(color="#2563EB", size=6),
                hovertemplate="<b>%{x}</b><br>Member: %{y:,} trx<extra></extra>") |>
      add_lines(data=n, x=~period_label, y=~n_trx, name="Non-Member",
                line=list(color="#10B981", width=3), mode="lines+markers",
                marker=list(color="#10B981", size=6),
                hovertemplate="<b>%{x}</b><br>Non-Member: %{y:,} trx<extra></extra>") |>
      layout(xaxis=list(title="", showgrid=FALSE),
             yaxis=list(title="Transactions", gridcolor="#E2E8F0"),
             legend=list(orientation="h", y=-0.5),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=50, l=60, r=20))
  })

  # ── Chart: Trend Avg Transaction Value ────────────────────────────────────
  output$basket_trend_val <- renderPlotly({
    data <- basket_trend_data()
    if (nrow(data) == 0) return(plotly_empty())
    m <- data[data$ctype == "Member", ]
    n <- data[data$ctype == "Non-Member", ]
    plot_ly() |>
      add_lines(data=m, x=~period_label, y=~avg_val, name="Member",
                line=list(color="#2563EB", width=3), mode="lines+markers",
                marker=list(color="#2563EB", size=6),
                hovertemplate="<b>%{x}</b><br>Member: Rp %{y:,.0f}<extra></extra>") |>
      add_lines(data=n, x=~period_label, y=~avg_val, name="Non-Member",
                line=list(color="#10B981", width=3), mode="lines+markers",
                marker=list(color="#10B981", size=6),
                hovertemplate="<b>%{x}</b><br>Non-Member: Rp %{y:,.0f}<extra></extra>") |>
      layout(xaxis=list(title="", showgrid=FALSE),
             yaxis=list(title="Avg Value (Rp)", tickformat=".2s", gridcolor="#E2E8F0"),
             legend=list(orientation="h", y=-0.5),
             paper_bgcolor="transparent", plot_bgcolor="transparent",
             margin=list(t=10, b=50, l=60, r=20))
  })

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

  output$basket_heatmap_member <- renderPlotly({
    d <- affinity_data(basket_query()$where, is_member=TRUE)
    render_affinity_heatmap(d, colorscale=list(c(0,"#EFF6FF"), c(0.5,"#60A5FA"), c(1,"#1E3A8A")))
  })

  output$basket_heatmap_nonmember <- renderPlotly({
    d <- affinity_data(basket_query()$where, is_member=FALSE)
    render_affinity_heatmap(d, colorscale=list(c(0,"#ECFDF5"), c(0.5,"#34D399"), c(1,"#065F46")))
  })

  # ── Reactive: show more toggles ──────────────────────────────────────────
  pairs_show_more <- reactiveValues(
    prod_member    = FALSE,
    prod_nonmember = FALSE,
    sub_member     = FALSE,
    sub_nonmember  = FALSE
  )
  observeEvent(input$toggle_prod_member,    { pairs_show_more$prod_member    <- !pairs_show_more$prod_member })
  observeEvent(input$toggle_prod_nonmember, { pairs_show_more$prod_nonmember <- !pairs_show_more$prod_nonmember })
  observeEvent(input$toggle_sub_member,     { pairs_show_more$sub_member     <- !pairs_show_more$sub_member })
  observeEvent(input$toggle_sub_nonmember,  { pairs_show_more$sub_nonmember  <- !pairs_show_more$sub_nonmember })

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

  output$basket_pairs_member <- renderTable({
    lim <- if (pairs_show_more$prod_member) 20 else 5
    get_pairs(basket_query()$where, is_member=TRUE, type="product", limit=lim)
  }, striped=TRUE, hover=TRUE, bordered=FALSE, spacing="s", width="100%", align="llllr")

  output$basket_pairs_nonmember <- renderTable({
    lim <- if (pairs_show_more$prod_nonmember) 20 else 5
    get_pairs(basket_query()$where, is_member=FALSE, type="product", limit=lim)
  }, striped=TRUE, hover=TRUE, bordered=FALSE, spacing="s", width="100%", align="llllr")

  output$basket_toggle_prod_member_label <- renderText({
    if (pairs_show_more$prod_member) "Show Less" else "Show More"
  })
  output$basket_toggle_prod_nonmember_label <- renderText({
    if (pairs_show_more$prod_nonmember) "Show Less" else "Show More"
  })


  # ── Table: Subcategory Pairs Member ──────────────────────────────────────
  output$basket_subcat_member <- renderTable({
    lim <- if (pairs_show_more$sub_member) 20 else 10
    get_pairs(basket_query()$where, is_member=TRUE, type="subcat", limit=lim)
  }, striped=TRUE, hover=TRUE, bordered=FALSE, spacing="s", width="100%", align="llllr")

  output$basket_subcat_nonmember <- renderTable({
    lim <- if (pairs_show_more$sub_nonmember) 20 else 10
    get_pairs(basket_query()$where, is_member=FALSE, type="subcat", limit=lim)
  }, striped=TRUE, hover=TRUE, bordered=FALSE, spacing="s", width="100%", align="llllr")

  output$basket_toggle_sub_member_label <- renderText({
    if (pairs_show_more$sub_member) "Show Less" else "Show More"
  })
  output$basket_toggle_sub_nonmember_label <- renderText({
    if (pairs_show_more$sub_nonmember) "Show Less" else "Show More"
  })

  
  
  # ── Sales Insight──────────────────────────────────────
  output$sales_insight <- renderUI({
    
    cur <- query_kpi_val(base_query()$where, "revenue")
    prev <- query_kpi_val(prev_where(), "revenue")
    
    pct <- (cur-prev)/prev*100
    
    insight <- if(pct > 10){
      paste0("🚀 Revenue meningkat signifikan sebesar <b>", round(pct,1),
             "%</b>. Kinerja penjualan sangat baik pada periode ini.")
    } else if(pct > 0){
      paste0("📈 Revenue meningkat <b>", round(pct,1),
             "%</b>. Tren pertumbuhan positif.")
    } else {
      paste0("⚠️ Revenue turun <b>", round(abs(pct),1),
             "%</b>. Perlu analisis lebih lanjut pada store atau produk.")
    }
    
    HTML(paste0(
      "<div style='font-size:20px;'>", insight ,"</div>"
    ))
    
  })
  
  observeEvent(input$go_sales, {
    
    updateTabItems(session,
                   inputId = "sidebar",
                   selected = "sales")
    
  })
  
  # ── Cleanup ──────────────────────────────────────────────────────────────
  session$onSessionEnded(function() {
    tryCatch(dbDisconnect(con), error = function(e) NULL)
  })
  
}
shinyApp(ui, server)
