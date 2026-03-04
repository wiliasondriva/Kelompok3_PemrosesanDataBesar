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

Analisis ini bertujuan untuk memahami kinerja penjualan secara keseluruhan dan tren penjualan dari waktu ke waktu. Analisis ini sangat penting karena memberikan gambaran awal mengenai kondisi bisnis secara umum.

### Analisis yang dilakukan

### Penjualan per Waktu

Menampilkan tren penjualan berdasarkan waktu (harian atau bulanan).

**Visualisasi:** Line Chart

**Tujuan:**

- Mengidentifikasi tren kenaikan atau penurunan penjualan
- Mengetahui pola musiman penjualan
- Mengidentifikasi periode dengan penjualan tertinggi

---
### Penjualan per Store

Membandingkan total penjualan antar toko.

**Visualisasi:** Bar Chart

**Tujuan:**

- Mengetahui toko dengan performa terbaik
- Mengidentifikasi toko dengan performa rendah
- Mengevaluasi distribusi penjualan antar toko

---

### Kontribusi Store terhadap Revenue

Menunjukkan kontribusi masing-masing toko terhadap total revenue.

**Visualisasi:** Donut Chart

**Tujuan:**

- Mengetahui toko dengan kontribusi terbesar
- Memahami distribusi revenue antar toko

---

### Penjualan Berdasarkan Kota

Menampilkan distribusi penjualan berdasarkan kota pelanggan.

**Visualisasi:** Bar Chart

**Tujuan:**

- Mengidentifikasi wilayah dengan penjualan tertinggi
- Mengetahui potensi pasar di masing-masing wilayah
  
---

## 2. Store Performance

Analisis ini bertujuan untuk membandingkan performa masing-masing toko secara lebih detail.

### Analisis yang dilakukan

### Revenue per Store

Menampilkan total revenue yang dihasilkan oleh setiap toko.

**Tujuan:**

- Mengidentifikasi toko dengan kontribusi revenue terbesar
- Mengevaluasi performa toko secara individual

---

### Jumlah Transaksi per Store

Menunjukkan jumlah transaksi pada setiap toko.

**Tujuan:**

- Mengetahui tingkat aktivitas transaksi
- Membandingkan tingkat kunjungan antar toko

---

### Average Order Value per Store

Average Order Value (AOV) menunjukkan nilai rata-rata transaksi pada setiap toko.

**Tujuan:**

- Menilai kualitas transaksi pada setiap toko
- Mengetahui apakah toko menghasilkan transaksi bernilai tinggi

---

### Ranking Store

Mengurutkan toko berdasarkan total revenue.

**Tujuan:**

- Mengidentifikasi toko dengan performa terbaik
- Menentukan benchmark performa toko

---

# 3. Product Analysis

Analisis produk bertujuan untuk memahami performa masing-masing produk dalam menghasilkan penjualan.  
Melalui analisis ini dapat diketahui produk mana yang paling diminati pelanggan serta bagaimana distribusi harga produk dalam sistem.

Analisis ini membantu perusahaan dalam menentukan strategi seperti pengelolaan stok, promosi produk, serta penentuan harga.

## Analisis yang dilakukan

### Top 10 Produk Terlaris

Menampilkan sepuluh produk dengan jumlah penjualan tertinggi berdasarkan data transaksi.

Visualisasi ini membantu mengidentifikasi produk yang paling sering dibeli oleh pelanggan.

**Tujuan:**

- Mengidentifikasi produk yang paling diminati pelanggan
- Menentukan produk unggulan bisnis
- Membantu perencanaan stok produk
- Menentukan produk yang dapat dijadikan fokus promosi

---

### Top 10 Produk Berdasarkan Revenue

Menampilkan sepuluh produk yang menghasilkan total pendapatan terbesar.

Berbeda dengan jumlah unit terjual, analisis ini menekankan pada kontribusi produk terhadap total revenue.

**Tujuan:**

- Mengidentifikasi produk dengan kontribusi revenue terbesar
- Mengetahui produk dengan nilai penjualan tinggi
- Membantu menentukan strategi pricing produk

---

### Distribusi Harga Produk

Menampilkan sebaran harga produk yang tersedia dalam dataset.

Visualisasi distribusi harga membantu memahami bagaimana variasi harga produk yang dijual dalam sistem.

**Tujuan:**

- Memahami rentang harga produk yang dijual
- Mengidentifikasi segmen harga produk
- Melihat apakah mayoritas produk berada pada kategori harga tertentu

---

### Hubungan Harga Produk dan Jumlah Terjual

Analisis ini menunjukkan hubungan antara harga produk dan jumlah unit yang terjual.

Dengan menggunakan visualisasi scatter plot, dapat dilihat apakah produk dengan harga rendah lebih sering dibeli dibandingkan produk dengan harga tinggi.

**Tujuan:**

- Memahami hubungan antara harga dan permintaan produk
- Mengidentifikasi apakah harga mempengaruhi tingkat penjualan
- Membantu menentukan strategi penetapan harga

---

### Brand Performance

Analisis ini menampilkan performa penjualan berdasarkan brand atau merek produk.

Dengan menganalisis kontribusi brand terhadap total penjualan, perusahaan dapat mengetahui brand mana yang memiliki performa terbaik.

**Tujuan:**

- Mengidentifikasi brand dengan penjualan tertinggi
- Membantu strategi kerja sama dengan brand tertentu
- Menentukan brand yang perlu mendapatkan perhatian lebih dalam strategi pemasaran

---

# 4. Category Analysis

Analisis kategori produk digunakan untuk mengetahui kontribusi setiap kategori terhadap total penjualan.

Dengan analisis ini dapat diketahui kategori produk mana yang paling berkontribusi terhadap revenue dan kategori mana yang paling sering dibeli oleh pelanggan.

## Analisis yang dilakukan

### Revenue per Kategori

Menampilkan total revenue yang dihasilkan oleh masing-masing kategori produk.

Visualisasi ini membantu memahami kategori produk yang memberikan kontribusi terbesar terhadap pendapatan bisnis.

**Tujuan:**

- Mengidentifikasi kategori produk dengan revenue tertinggi
- Menentukan kategori utama dalam bisnis
- Membantu pengambilan keputusan terkait pengelolaan kategori produk

---

### Kontribusi Kategori

Menunjukkan persentase kontribusi masing-masing kategori terhadap total revenue.

Analisis ini memberikan gambaran distribusi pendapatan berdasarkan kategori produk.

**Tujuan:**

- Memahami distribusi penjualan antar kategori
- Mengetahui kategori yang mendominasi penjualan
- Mengidentifikasi kategori dengan kontribusi rendah

---

### Jumlah Transaksi per Kategori

Menampilkan jumlah transaksi yang melibatkan produk dari setiap kategori.

Analisis ini membantu memahami kategori produk yang paling sering dibeli oleh pelanggan.

**Tujuan:**

- Mengidentifikasi kategori produk dengan frekuensi pembelian tinggi
- Mengetahui kategori yang paling populer di kalangan pelanggan
- Membantu strategi promosi berdasarkan kategori

---

### Average Transaction Value per Kategori

Average Transaction Value (ATV) menunjukkan rata-rata nilai transaksi yang melibatkan produk dari kategori tertentu.

Analisis ini membantu memahami nilai transaksi rata-rata yang dihasilkan oleh masing-masing kategori.

**Tujuan:**

- Mengidentifikasi kategori dengan nilai transaksi tinggi
- Mengetahui kategori yang cenderung menghasilkan pembelian bernilai besar
- Membantu menentukan strategi pengembangan kategori produk

---

# 5. Customer Analysis

Analisis pelanggan bertujuan untuk memahami perilaku pelanggan dalam melakukan transaksi.  
Melalui analisis ini dapat diketahui karakteristik pelanggan, kontribusi pelanggan terhadap revenue, serta segmentasi pelanggan berdasarkan gender dan kelompok umur.

Analisis pelanggan sangat penting karena membantu bisnis memahami siapa pelanggan utama mereka dan bagaimana pola pembelian pelanggan tersebut.

## Analisis yang dilakukan

### Jumlah Customer Aktif

Menampilkan jumlah pelanggan unik yang melakukan transaksi dalam dataset.

Analisis ini dihitung berdasarkan jumlah **customer_id unik** yang muncul dalam data transaksi.

**Tujuan:**

- Mengetahui jumlah pelanggan aktif yang melakukan pembelian
- Mengukur ukuran basis pelanggan dalam bisnis
- Mengetahui tingkat partisipasi pelanggan dalam transaksi

---

### Revenue per Customer

Menampilkan kontribusi revenue yang dihasilkan oleh masing-masing pelanggan.

Melalui analisis ini dapat diketahui pelanggan dengan nilai pembelian tertinggi.

**Tujuan:**

- Mengidentifikasi pelanggan dengan kontribusi revenue terbesar
- Mengetahui pelanggan dengan nilai transaksi tinggi
- Membantu mengidentifikasi pelanggan yang berpotensi menjadi pelanggan loyal

---

### Revenue berdasarkan Gender

Menunjukkan distribusi revenue berdasarkan gender pelanggan.

Analisis ini membantu memahami segmen pelanggan yang memberikan kontribusi terbesar terhadap penjualan.

**Tujuan:**

- Mengetahui distribusi pelanggan berdasarkan gender
- Mengidentifikasi gender dengan kontribusi revenue terbesar
- Membantu memahami segmentasi pasar berdasarkan gender

---

### Customer berdasarkan Kelompok Umur

Analisis ini mengelompokkan pelanggan berdasarkan umur yang dihitung dari atribut **birth_date**.

Pelanggan dikelompokkan ke dalam beberapa kategori umur untuk memahami demografi pelanggan.

Contoh kelompok umur:

- < 20 tahun
- 20 – 30 tahun
- 30 – 40 tahun
- 40 – 50 tahun
- > 50 tahun

**Tujuan:**

- Memahami distribusi pelanggan berdasarkan umur
- Mengidentifikasi kelompok umur dengan kontribusi penjualan terbesar
- Membantu menentukan strategi pemasaran berdasarkan segmen umur

---

# 6. Market Basket Analysis

Market Basket Analysis merupakan teknik analisis data yang digunakan untuk menemukan pola pembelian produk yang sering dibeli secara bersamaan dalam satu transaksi.

Analisis ini bertujuan untuk memahami hubungan antar produk yang dibeli oleh pelanggan sehingga perusahaan dapat mengidentifikasi kombinasi produk yang sering muncul dalam satu keranjang belanja.

Dengan memahami pola pembelian tersebut, perusahaan dapat mengembangkan berbagai strategi bisnis seperti:

- strategi **cross-selling**
- penempatan produk yang lebih efektif di toko
- pembuatan paket promosi produk
- rekomendasi produk kepada pelanggan

Market Basket Analysis memanfaatkan data transaksi pada tabel **fact_transaction_detail**, dimana setiap transaksi dapat berisi lebih dari satu produk yang dibeli oleh pelanggan.

---

## Metode yang Digunakan

Metode yang digunakan dalam analisis ini adalah **Association Rule Mining**.

Association Rule Mining merupakan metode dalam data mining yang digunakan untuk menemukan hubungan atau asosiasi antara item yang sering muncul bersama dalam suatu dataset transaksi.

Hasil dari metode ini berupa **association rules**, yaitu aturan yang menunjukkan hubungan antara dua atau lebih produk dalam bentuk:

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
