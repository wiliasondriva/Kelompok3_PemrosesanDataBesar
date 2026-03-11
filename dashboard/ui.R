


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

