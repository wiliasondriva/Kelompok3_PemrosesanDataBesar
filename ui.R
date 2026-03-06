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
# ── UI ─────────────────────────────────────────────────────────────
ui <- bs4DashPage(
  
  header = bs4DashNavbar(
    title = tagList(icon("chart-line"), "Retail Analytics Dashboard"),
    skin = "dark",
    status = "primary"
  ),
  
  sidebar = bs4DashSidebar(
    
    skin = "light",
    
    bs4SidebarMenu(
      
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
                         icon = icon("shopping-basket"))
    ),
    
    hr(),
    
    dateRangeInput(
      inputId = "date_range",
      label   = "Date Range",
      
      start = as.Date("2024-12-01"),
      end   = as.Date("2024-12-31"),
      
      min = as.Date("2024-01-01"),
      max = as.Date("2024-12-31"),
      
      format = "yyyy-mm-dd"
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
    )
    
  ),
  
  body = bs4DashBody(
    
    bs4TabItems(
      
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
            title = uiOutput("top_stores_title"),
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
          
          bs4Card(width=6,
                  title="Revenue by Province",
                  plotlyOutput("store_province_bar")),
          
          bs4Card(width=6,
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
          
        ),
        
        fluidRow(
          
          bs4Card(width=6,
                  title="Product Velocity",
                  plotlyOutput("prod_velocity")),
          
          bs4Card(width=6,
                  title="Price vs Quantity",
                  plotlyOutput("prod_scatter"))
          
        ),
        
        fluidRow(
          
          bs4Card(width=12,
                  title="Price Distribution",
                  plotlyOutput("prod_price_dist"))
          
        )
        
      ),
      
      # =====================================================
      # CUSTOMER ANALYSIS
      # =====================================================
      
      bs4TabItem(
        
        tabName="customer",
        
        fluidRow(
          
          bs4ValueBoxOutput("cust_total_aktif", width=2),
          bs4ValueBoxOutput("cust_perempuan", width=2),
          bs4ValueBoxOutput("cust_lakilaki", width=2),
          bs4ValueBoxOutput("cust_avg_first_purchase", width=3),
          bs4ValueBoxOutput("cust_new_returning_ratio", width=3)
          
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
          
          bs4ValueBoxOutput("basket_kpi_trx_member", width=2),
          bs4ValueBoxOutput("basket_kpi_items_member", width=2),
          bs4ValueBoxOutput("basket_kpi_val_member", width=2),
          
          bs4ValueBoxOutput("basket_kpi_trx_nonmember", width=2),
          bs4ValueBoxOutput("basket_kpi_items_nonmember", width=2),
          bs4ValueBoxOutput("basket_kpi_val_nonmember", width=2)
          
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
          
        )
        
      )
      
    )
    
  )
  
)