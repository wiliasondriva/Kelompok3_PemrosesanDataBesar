# Data Analyst Documentation

## Project
Retail Analytics Dashboard

## Fokus Analisis
Dokumentasi ini berisi KPI, analisis data, serta insight yang digunakan dalam pembuatan dashboard retail analytics.

## Dataset yang Digunakan
- fact_transaction
- fact_transaction_detail
- dim_product
- dim_customer
- dim_category

## Tujuan Analisis
1. Mengidentifikasi performa penjualan
2. Menganalisis performa toko
3. Menganalisis produk dan kategori
4. Menganalisis perilaku customer
5. Mengidentifikasi pola pembelian produk

## Output Dashboard
- KPI Metrics
- Sales Performance
- Store Performance
- Product Performance
- Customer Analysis
- Market Basket Analysis

# Sales Performance Analysis

## Penjualan per Waktu

Bentuk Analisis:
Line Chart

Tujuan:
Melihat tren penjualan harian atau bulanan.

Data:
- invoice_datetime
- line_total

Tabel:
- fact_transaction
- fact_transaction_detail

KPI:
Revenue per Periode

---

## Average Order Value per Waktu

Bentuk Analisis:
Line Chart

Tujuan:
Melihat perubahan nilai transaksi rata-rata.

KPI:
Average Order Value (AOV)

Rumus:
SUM(line_total) / COUNT(DISTINCT invoice_id)

---

## Penjualan per Store

Bentuk Analisis:
Bar Chart

Tujuan:
Mengidentifikasi toko dengan performa penjualan tertinggi.

KPI:
Revenue per Store


# Product Analysis

## Top 10 Produk Terlaris

Bentuk Analisis:
Bar Chart

Tujuan:
Mengidentifikasi produk dengan penjualan tertinggi.

KPI:
Revenue per Product

Rumus:
SUM(line_total)

Group by:
product_id

# Customer Analysis

## Jumlah Customer Aktif

KPI:
Total Customer Aktif

Rumus:
COUNT(DISTINCT customer_id)

---

## Revenue per Customer

Tujuan:
Mengidentifikasi customer dengan kontribusi terbesar.

Rumus:
SUM(line_total)

Group by:
customer_id

# Market Basket Analysis

Tujuan:
Mengidentifikasi produk yang sering dibeli bersamaan.

Metode:
Association Rule Mining

Algoritma:
- Apriori
- FP-Growth

Metrics:
- Support
- Confidence
- Lift
