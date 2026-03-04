# Kelompok 3 - Pemrosesan Data Besar

# Data Analyst Documentation

## Project Overview

Project ini bertujuan untuk menganalisis data transaksi retail untuk menghasilkan insight bisnis melalui dashboard analitik.

Dashboard ini membantu memahami performa penjualan, performa toko, perilaku pelanggan, serta performa produk.

---

# Dataset

Dataset yang digunakan dalam analisis ini terdiri dari beberapa tabel utama:

- fact_transaction
- fact_transaction_detail
- dim_product
- dim_customer
- dim_category

Tabel fact digunakan untuk menyimpan data transaksi, sedangkan tabel dimensi digunakan untuk mendeskripsikan atribut produk, customer, dan kategori.

---

# KPI Dashboard

Dashboard menampilkan beberapa KPI utama untuk memonitor performa bisnis.

### Total Revenue
Total pendapatan yang dihasilkan dari seluruh transaksi.

Rumus:
SUM(line_total)

---

### Total Transactions
Jumlah transaksi yang terjadi.

Rumus:
COUNT(DISTINCT invoice_id)

---

### Average Order Value (AOV)

Rata-rata nilai transaksi pelanggan.

Rumus:
SUM(line_total) / COUNT(DISTINCT invoice_id)

---

### Total Active Customers

Jumlah customer yang melakukan transaksi.

Rumus:
COUNT(DISTINCT customer_id)

---

### Total Products

Jumlah produk unik yang tersedia.

Rumus:
COUNT(DISTINCT product_id)

---

# Dashboard Analysis

## 1. Sales Performance

Analisis ini bertujuan untuk melihat tren penjualan dari waktu ke waktu.

Visualisasi yang digunakan:

- Line Chart : Penjualan per waktu
- Bar Chart : Penjualan per store
- Donut Chart : Kontribusi store terhadap total revenue
- Bar Chart : Penjualan berdasarkan kota

Tujuan analisis:

- Mengidentifikasi tren penjualan
- Mengetahui toko dengan performa terbaik
- Mengetahui wilayah dengan penjualan tertinggi

---

## 2. Store Performance

Analisis ini digunakan untuk membandingkan performa antar toko.

Visualisasi:

- Revenue per store
- Transaksi per store
- Average order value per store
- Ranking store berdasarkan revenue

Tujuan:

Mengetahui toko dengan performa penjualan terbaik dan mengidentifikasi toko yang perlu ditingkatkan performanya.

---

## 3. Product Analysis

Analisis ini berfokus pada performa produk.

Visualisasi:

- Top 10 produk terlaris
- Distribusi harga produk
- Hubungan harga dan jumlah penjualan
- Brand performance

Tujuan:

Mengidentifikasi produk yang paling berkontribusi terhadap penjualan.

---

## 4. Category Analysis

Analisis kategori produk digunakan untuk mengetahui kontribusi setiap kategori terhadap total penjualan.

Visualisasi:

- Revenue per kategori
- Kontribusi kategori
- Transaksi per kategori
- Average transaction value per kategori

---

## 5. Customer Analysis

Analisis pelanggan bertujuan memahami perilaku pelanggan.

Visualisasi:

- Jumlah customer aktif
- Revenue per customer
- Revenue berdasarkan gender
- Customer berdasarkan kelompok umur

---

## 6. Market Basket Analysis

Market Basket Analysis digunakan untuk menemukan pola pembelian produk yang sering dibeli bersamaan.

Metode yang digunakan:

Association Rule Mining

Algoritma:

- Apriori
- FP-Growth

Metrics yang digunakan:

- Support
- Confidence
- Lift

---

# Business Insight

Beberapa insight yang dapat dihasilkan dari analisis dashboard:

1. Store dengan revenue tertinggi dapat diidentifikasi untuk menjadi benchmark performa.
2. Produk dengan penjualan tertinggi dapat dijadikan fokus strategi promosi.
3. Kota dengan transaksi terbanyak menunjukkan potensi pasar yang lebih besar.
4. Analisis customer membantu memahami segmen pelanggan yang paling menguntungkan.
5. Market basket analysis membantu meningkatkan strategi cross-selling.

---

# Kesimpulan

Dashboard analitik ini membantu memahami performa bisnis retail secara menyeluruh melalui analisis data transaksi, produk, pelanggan, dan kategori produk.

Insight yang dihasilkan dapat digunakan sebagai dasar pengambilan keputusan bisnis yang lebih efektif.
