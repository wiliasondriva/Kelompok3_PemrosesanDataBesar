# Kelompok 3 - Pemrosesan Data Besar

# Data Analyst Documentation

## Project Overview

Project ini bertujuan untuk menganalisis data transaksi retail untuk menghasilkan insight bisnis melalui dashboard analitik.

Dashboard ini membantu memahami performa penjualan, performa toko, perilaku pelanggan, serta performa produk.

---

# Dataset

Dataset yang digunakan dalam analisis ini merupakan data transaksi retail yang telah dimodelkan menggunakan pendekatan **star schema** dalam data warehouse.

Dataset terdiri dari beberapa tabel utama yang terbagi menjadi **fact table** dan **dimension table**.

---

## Fact Tables

Fact table menyimpan data transaksi utama yang berisi nilai numerik yang dapat dianalisis.

### fact_transaction

Tabel ini menyimpan informasi transaksi utama.

Atribut utama:

- invoice_id → ID unik transaksi
- customer_id → ID pelanggan
- store_id → ID toko tempat transaksi
- invoice_datetime → waktu transaksi
- payment_method → metode pembayaran (cash, debit, qris)

Tabel ini digunakan untuk menganalisis jumlah transaksi dan aktivitas penjualan berdasarkan waktu, toko, dan metode pembayaran.

---

### fact_transaction_detail

Tabel ini menyimpan detail setiap produk yang dibeli dalam suatu transaksi.

Atribut utama:

- invoice_id → ID transaksi
- product_id → ID produk
- quantity → jumlah produk yang dibeli
- product_price → harga produk
- line_total → total nilai penjualan per produk

Tabel ini digunakan untuk menganalisis penjualan produk, revenue, serta market basket analysis.

---

## Dimension Tables

Dimension table berfungsi untuk memberikan informasi deskriptif yang digunakan dalam analisis data.

### dim_product

Tabel ini menyimpan informasi produk.

Atribut utama:

- product_id
- product_name
- brand
- product_description
- category_id

Tabel ini digunakan untuk analisis performa produk, brand, dan kategori produk.

---

### dim_customer

Tabel ini menyimpan informasi pelanggan.

Atribut utama:

- customer_id
- customer_name
- gender
- birth_date
- customer_city

Tabel ini digunakan untuk analisis perilaku pelanggan seperti distribusi gender, umur pelanggan, dan lokasi pelanggan.

---

### dim_store

Tabel ini menyimpan informasi toko.

Atribut utama:

- store_id
- store_name
- store_city
- store_type
- store_province
- store_open_date

Tabel ini digunakan untuk analisis performa toko berdasarkan lokasi dan tipe toko.

---

### dim_category

Tabel ini menyimpan informasi kategori produk.

Atribut utama:

- category_id
- category_lvl1
- category_lvl2

Tabel ini digunakan untuk analisis kontribusi penjualan berdasarkan kategori produk.

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
