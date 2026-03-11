# Retail Analytics Dashboard

Dashboard interaktif untuk menganalisis performa penjualan retail menggunakan data transaksi yang dikumpulkan melalui proses web scraping dan data sintetik.

![Retail Dashboard Illustration](assets/alfagift.png)


---

## Deskripsi Dataset

Dataset yang digunakan dalam project ini merupakan **dataset gabungan yang disusun khusus untuk keperluan pembelajaran**. Data diperoleh melalui proses **web scraping dari platform Alfagift**, serta dilengkapi dengan **data bangkitan sintetik** untuk memperkaya struktur data dan meningkatkan kompleksitas kasus analisis.

Seluruh data dalam dataset ini **tidak dimaksudkan untuk merepresentasikan kondisi bisnis aktual secara akurat**, serta **tidak digunakan untuk tujuan komersial**. Data ini juga **tidak mencerminkan data resmi dari pihak terkait**, melainkan hanya digunakan sebagai media pembelajaran dalam analisis data dan pengembangan dashboard analitik.

Dataset yang digunakan merupakan **data transaksi penjualan toko retail** yang terdiri dari **212.170 observasi dan 19 variabel**. Data tersebut mencakup berbagai informasi penting yang berkaitan dengan aktivitas penjualan, antara lain:

- Informasi transaksi penjualan
- Informasi pelanggan (*customer*)
- Informasi toko (*store*)
- Informasi produk (*product*)
- Informasi kategori produk (*category*)

Dataset ini digunakan sebagai dasar dalam melakukan berbagai analisis pada dashboard, seperti analisis performa penjualan, analisis produk, analisis pelanggan, serta analisis pola pembelian produk.

---

## Tujuan Dashboard

Dashboard ini dibuat dengan tujuan untuk membantu memahami performa bisnis retail melalui visualisasi data yang interaktif dan informatif. Melalui dashboard ini, pengguna dapat mengeksplorasi berbagai aspek data transaksi penjualan secara lebih mudah dan intuitif.

Tujuan utama pembuatan dashboard ini antara lain:

- Memantau performa penjualan secara keseluruhan
- Mengidentifikasi toko dengan performa penjualan terbaik
- Menganalisis produk yang memberikan kontribusi penjualan terbesar
- Memahami perilaku dan karakteristik pelanggan
- Mengidentifikasi pola pembelian produk yang sering muncul bersamaan

Dengan adanya dashboard ini, proses eksplorasi dan analisis data dapat dilakukan secara lebih cepat sehingga dapat membantu mendukung pengambilan keputusan berbasis data.

---

## Fitur Dashboard

Dashboard ini dilengkapi dengan berbagai fitur yang memungkinkan pengguna untuk melakukan eksplorasi data secara interaktif.

#### 1. Filtering Data

Dashboard menyediakan beberapa fitur filtering yang memungkinkan pengguna melakukan eksplorasi data secara interaktif berdasarkan berbagai dimensi analisis.

Filter yang tersedia pada dashboard antara lain:

- **Date Range**  
  Digunakan untuk memilih rentang waktu transaksi yang ingin dianalisis.

- **Province**  
  Memungkinkan pengguna memfilter data berdasarkan provinsi tempat toko berada.

- **Store Type**  
  Digunakan untuk melihat performa penjualan berdasarkan tipe toko.

- **Customer City**  
  Digunakan untuk menganalisis distribusi pelanggan berdasarkan kota.

- **Trend KPI**  
  Pengguna dapat memilih indikator utama yang ingin dianalisis dalam grafik tren, seperti revenue atau metrik performa lainnya.

- **Trend Granularity**  
  Mengatur tingkat agregasi data tren menjadi **harian (daily)** atau **bulanan (monthly)**.

- **Customer Trend**  
  Digunakan untuk menampilkan tren pelanggan berdasarkan agregasi waktu **harian** atau **bulanan**.

Fitur filtering ini memungkinkan pengguna melakukan eksplorasi data secara lebih fleksibel untuk memahami berbagai pola dalam data transaksi.

#### 2. Visualisasi Analitik

Dashboard menyajikan berbagai jenis visualisasi data untuk mempermudah analisis, seperti:

- **Line Chart** untuk melihat tren data dari waktu ke waktu
- **Bar Chart** untuk membandingkan performa antar kategori
- **Heatmap** untuk melihat pola aktivitas transaksi
- **Scatter Plot** untuk menganalisis hubungan antar variabel
- **Distribution Plot** untuk memahami distribusi data

Visualisasi ini membantu pengguna memahami pola data secara lebih intuitif dan mendukung proses analisis yang lebih efektif.

### Dashboard Preview
Berikut merupakan tampilan utama dari dashboard interaktif yang dikembangkan menggunakan Shiny.

## Dashboard Screenshots

### Home

![Sales Overview](assets/home.png)

---

### Sales Overview

![Sales Overview](assets/sales_overview.png)

Modul ini memberikan gambaran umum mengenai performa penjualan secara keseluruhan pada periode yang dipilih. Visualisasi pada bagian ini membantu memonitor tren penjualan, distribusi metode pembayaran, serta aktivitas transaksi.

##### KPI
- Total Revenue
- Total Transactions
- Total Items Sold
- Average Basket Size
- Average Order Value
- Active Stores

##### Visualisasi
- Revenue Trend  
  Menampilkan tren revenue dari waktu ke waktu untuk melihat perkembangan penjualan.

- Payment Method Distribution  
  Menunjukkan distribusi metode pembayaran yang digunakan pelanggan seperti cash, debit, dan QRIS.

- Top 10 Stores by Revenue  
  Menampilkan toko dengan kontribusi revenue tertinggi.

- Transaction Heatmap  
  Menampilkan pola aktivitas transaksi berdasarkan hari dan jam.
  
---

### Store Analysis

![Store Analysis](assets/store_analysis.png)

Modul ini digunakan untuk menganalisis performa setiap toko serta kontribusi masing-masing toko terhadap total penjualan.

##### KPI
- Active Stores
- Top Store Revenue
- Average Order Value per Store

##### Visualisasi
- Top Store Revenue  
  Menampilkan toko dengan revenue tertinggi.

- Store Type Revenue  
  Menunjukkan distribusi revenue berdasarkan tipe toko.

- Store AOV  
  Membandingkan rata-rata nilai transaksi antar toko.

- Store Transactions  
  Menampilkan jumlah transaksi yang terjadi pada setiap toko.
  
---

### Product Analysis

![Product Analysis](assets/product_analysis.png)

Modul ini digunakan untuk memahami performa produk, termasuk produk dengan penjualan tertinggi, distribusi harga produk, serta kontribusi kategori dan brand terhadap total revenue.

##### KPI
- Total Products
- Total Brands
- Total Categories

##### Visualisasi
- Top Product Revenue  
  Menampilkan produk dengan kontribusi revenue terbesar.

- Top Product Quantity  
  Menampilkan produk dengan jumlah penjualan tertinggi.

- Category Revenue  
  Menunjukkan kontribusi revenue dari masing-masing kategori produk.

- Brand Revenue  
  Menampilkan brand dengan kontribusi penjualan terbesar.

- Product Velocity  
  Mengukur kecepatan penjualan produk (quantity per day).

- Price vs Quantity  
  Menunjukkan hubungan antara harga produk dan jumlah produk terjual.

- Price Distribution  
  Menampilkan distribusi harga produk dalam dataset.

---

### Customer Analysis

![Customer Analysis](assets/customer_analysis.png)

Modul ini digunakan untuk memahami karakteristik pelanggan serta perilaku pembelian pelanggan.

##### KPI
- Total Active Customers
- New Customer Ratio
- Average First Purchase Value
- Female Customers
- Male Customers

##### Visualisasi
- New Customer Trend  
  Menampilkan tren pelanggan baru dari waktu ke waktu.

- New vs Returning Customers  
  Membandingkan jumlah pelanggan baru dan pelanggan yang kembali.

- First Purchase Value  
  Menampilkan rata-rata nilai transaksi pada pembelian pertama pelanggan.

- Customer by City  
  Menampilkan distribusi pelanggan berdasarkan kota.

- Gender Revenue  
  Membandingkan kontribusi revenue berdasarkan gender pelanggan.

- Top Cities  
  Menampilkan kota dengan jumlah pelanggan terbanyak.

- Top Customers  
  Menampilkan pelanggan dengan total pembelian tertinggi.
  
---

### Market Basket Analysis

![Market Basket Analysis](assets/market_basket.png)

Modul ini digunakan untuk menganalisis pola pembelian pelanggan serta hubungan antar produk atau kategori yang sering dibeli secara bersamaan dalam satu transaksi.

##### KPI
- Member Transactions
- Average Items per Transaction (Member)
- Average Transaction Value (Member)
- Non-Member Transactions
- Average Items per Transaction (Non-Member)
- Average Transaction Value (Non-Member)

##### Visualisasi
- Transaction Trend  
  Menampilkan tren jumlah transaksi antara member dan non-member.

- Average Transaction Value Trend  
  Menunjukkan perbandingan nilai transaksi rata-rata antara member dan non-member.

- Category Affinity (Member)  
  Menampilkan hubungan antar kategori produk yang sering dibeli bersama oleh member.

- Category Affinity (Non-Member)  
  Menampilkan hubungan antar kategori produk yang sering dibeli bersama oleh non-member.

- Top Subcategory Pairs (Member)  
  Menampilkan pasangan subkategori produk yang paling sering dibeli bersama oleh member.

- Top Subcategory Pairs (Non-Member)  
  Menampilkan pasangan subkategori produk yang paling sering dibeli bersama oleh non-member.
  
---

## ERD

### ERD Konseptual

![ERD Konseptual](Doc/ERD_Konseptual.png)

##### 📊 Overview

ERD Konseptual ini menggambarkan **model data konseptual** untuk sistem data warehouse retail menggunakan **Chen Notation**. Diagram ini menekankan pada pemahaman bisnis dan hubungan antar entitas pada level tinggi, tanpa detail implementasi teknis.

---

##### 🎨 Notasi Chen - Penjelasan Simbol

| Simbol | Bentuk | Keterangan |
|--------|--------|------------|
| **Entity** | Rectangle (Kotak) | Objek bisnis utama yang datanya disimpan |
| **Attribute** | Oval (Lingkaran) | Properti atau karakteristik dari entity |
| **Relationship** | Diamond (Belah Ketupat) | Hubungan antar entity |
| **Primary Key** | Underlined text | Identifier unik untuk entity (ditandai garis bawah) |
| **Cardinality** | 1, N, M | Jumlah instance yang terlibat dalam relationship |

---

#### 🏗️ Struktur Database

##### Entitas Utama (6 Entities)

###### 1. **Customer** (Pelanggan)
Menyimpan informasi pelanggan yang melakukan transaksi.

**Attributes:**
- `customer_id` (PK) - ID unik pelanggan
- `customer_name` - Nama lengkap pelanggan
- `gender` - Jenis kelamin (L/P)
- `birth_date` - Tanggal lahir
- `customer_city` - Kota domisili

**Business Rule:** 
- `customer_id = 0` reserved untuk unknown/guest customers

---

###### 2. **Store** (Toko)
Menyimpan informasi lokasi toko retail.

**Attributes:**
- `store_id` (PK) - ID unik toko
- `store_name` - Nama toko
- `store_type` - Klasifikasi jenis toko (A/B/C)
- `store_city` - Kota lokasi toko
- `store_province` - Provinsi lokasi toko
- `store_open_date` - Tanggal toko mulai beroperasi

**Business Rule:**
- `store_id = 0` reserved untuk unknown/online-only stores

---

###### 3. **Transaction** (Transaksi)
Menyimpan header informasi transaksi penjualan.

**Attributes:**
- `invoice_id` (PK) - ID unik transaksi
- `invoice_datetime` - Tanggal dan waktu transaksi
- `payment_method` - Metode pembayaran (cash/debit/credit/e-wallet)

**Business Rule:**
- Satu invoice dapat berisi multiple line items (detail transaksi)

---

###### 4. **Transaction_Detail** (Detail Transaksi)
**⚠️ Weak Entity** - Bergantung pada Transaction

Menyimpan detail produk yang dibeli per transaksi.

**Attributes:**
- `quantity` - Jumlah produk yang dibeli
- `product_price` - Harga satuan produk saat transaksi

**Design Decision:**
- ❌ `line_total` **TIDAK disimpan** (Pure 3NF)
- ✅ Dihitung on-the-fly: `quantity × product_price`

---

###### 5. **Product** (Produk)
Menyimpan informasi produk yang dijual.

**Attributes:**
- `product_id` (PK) - ID unik produk
- `product_name` - Nama produk
- `brand` - Merek produk
- `product_description` - Deskripsi detail produk

**Business Rule:**
- Setiap produk harus belong to satu category

---

###### 6. **Category** (Kategori Produk)
Menyimpan kategori produk dengan hierarki 2 level.

**Attributes:**
- `category_id` (PK) - ID unik kategori
- `category_lvl1` - Kategori utama (main category)
- `category_lvl2` - Sub-kategori (detailed category)

**Business Rule:**
- Natural key: Kombinasi `(category_lvl1, category_lvl2)` harus unique

---

#### 🔗 Relationships

##### 1. **Makes** (Customer → Transaction)
**Cardinality:** `1:N` (One-to-Many)

- **Satu customer** dapat melakukan **banyak transaksi**
- **Satu transaksi** dilakukan oleh **satu customer**

**Business Logic:**
```
Customer (1) ----< Makes >---- (N) Transaction
```

---

##### 2. **Occurs_at** (Store → Transaction)
**Cardinality:** `1:N` (One-to-Many)

- **Satu toko** dapat memiliki **banyak transaksi**
- **Satu transaksi** terjadi di **satu toko**

**Business Logic:**
```
Store (1) ----< Occurs_at >---- (N) Transaction
```
---

##### 3. **Contains** (Transaction → Transaction_Detail)
**Cardinality:** `1:N` (One-to-Many)
**Type:** Identifying Relationship (Transaction_Detail adalah weak entity)

- **Satu transaksi** dapat berisi **banyak line items**
- **Satu line item** belong to **satu transaksi**

**Business Logic:**
```
Transaction (1) ----< Contains >---- (N) Transaction_Detail
```

**Note:** `Transaction_Detail` **tidak bisa exist tanpa Transaction**

---

##### 4. **Includes** (Product → Transaction_Detail)
**Cardinality:** `1:N` (One-to-Many)

- **Satu produk** dapat muncul di **banyak line items** (berbeda transaksi)
- **Satu line item** contain **satu produk**

**Business Logic:**
```
Product (1) ----< Includes >---- (N) Transaction_Detail
```

---

###### 5. **Belongs_to** (Product → Category)
**Cardinality:** `N:1` (Many-to-One)

- **Banyak produk** dapat belong to **satu category**
- **Satu produk** belong to **satu category**

**Business Logic:**
```
Product (N) ----< Belongs_to >---- (1) Category
```

---


### ERD Relational

![ERD Design](Doc/ERD_Relational.png)

#### 📊 Overview

ERD Relasional ini menggambarkan **model data fisik** untuk sistem data warehouse retail. Berbeda dari ERD Konseptual yang berfokus pada pemahaman bisnis, ERD Relasional ini menampilkan implementasi teknis lengkap termasuk Primary Key (PK), Foreign Key (FK), dan struktur tabel yang siap diimplementasikan ke dalam database.

---

#### 🎨 Notasi Relasional - Penjelasan Simbol

| Simbol | Keterangan |
|--------|------------|
| **PK** | Primary Key — identifier unik untuk setiap record dalam tabel |
| **FK** | Foreign Key — referensi ke Primary Key tabel lain |
| **PK, FK** | Kolom yang sekaligus berfungsi sebagai Primary Key dan Foreign Key |
| **Garis tunggal** | Sisi "satu" pada relasi One-to-Many |
| **Garis bercabang (crow's foot)** | Sisi "banyak" pada relasi One-to-Many |

---

#### 🏗️ Struktur Tabel

##### 1. **Customer**
Menyimpan informasi pelanggan yang melakukan transaksi.

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `customer_id` | PK | ID unik pelanggan |
| `customer_name` | | Nama lengkap pelanggan |
| `gender` | | Jenis kelamin (L/P) |
| `birth_date` | | Tanggal lahir |
| `customer_city` | | Kota domisili pelanggan |

> **Business Rule:** `customer_id = 0` reserved untuk unknown/guest customers.

---

##### 2. **Store**
Menyimpan informasi lokasi toko retail.

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `store_id` | PK | ID unik toko |
| `store_name` | | Nama toko |
| `store_type` | | Klasifikasi jenis toko (A/B/C) |
| `store_city` | | Kota lokasi toko |
| `store_province` | | Provinsi lokasi toko |
| `store_open_date` | | Tanggal toko mulai beroperasi |

> **Business Rule:** `store_id = 0` reserved untuk unknown/online-only stores.

---

##### 3. **Category**
Menyimpan kategori produk dengan hierarki 2 level.

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `category_id` | PK | ID unik kategori |
| `category_lvl1` | | Kategori utama (main category) |
| `category_lvl2` | | Sub-kategori (detailed category) |

> **Business Rule:** Kombinasi `(category_lvl1, category_lvl2)` harus unik.

---

##### 4. **Product**
Menyimpan informasi produk yang dijual.

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `product_id` | PK | ID unik produk |
| `product_name` | | Nama produk |
| `brand` | | Merek produk |
| `product_description` | | Deskripsi detail produk |
| `category_id` | FK | Referensi ke tabel Category |

> **Business Rule:** Setiap produk harus belong to satu kategori.

---

##### 5. **Transaction (invoice)**
Menyimpan header informasi transaksi penjualan.

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `invoice_id` | PK | ID unik transaksi |
| `invoice_datetime` | | Tanggal dan waktu transaksi |
| `payment_method` | | Metode pembayaran (cash/debit/credit/e-wallet) |
| `store_id` | FK | Referensi ke tabel Store |
| `customer_id` | FK | Referensi ke tabel Customer |

> **Business Rule:** Satu invoice dapat berisi multiple line items (detail transaksi).

---

##### 6. **Transaction_Detail**
⚠️ **Weak Entity** — Bergantung pada tabel Transaction dan Product.

Menyimpan detail produk yang dibeli per transaksi.

| Kolom | Tipe | Keterangan |
|-------|------|------------|
| `invoice_id` | PK, FK1 | Referensi ke tabel Transaction |
| `product_id` | PK, FK2 | Referensi ke tabel Product |
| `quantity` | | Jumlah produk yang dibeli |
| `product_price` | | Harga satuan produk saat transaksi |

> **Design Decision:** `line_total` **tidak disimpan** (Pure 3NF). Nilai total dihitung on-the-fly: `quantity × product_price`.

---

#### 🔗 Relasi Antar Tabel

| Relasi | Tabel Asal | Tabel Tujuan | Kardinalitas | Keterangan |
|--------|-----------|--------------|--------------|------------|
| Makes | Customer | Transaction | 1 : N | Satu customer dapat melakukan banyak transaksi |
| Occurs_at | Store | Transaction | 1 : N | Satu toko dapat memiliki banyak transaksi |
| Contains | Transaction | Transaction_Detail | 1 : N | Satu transaksi dapat berisi banyak line items |
| Includes | Product | Transaction_Detail | 1 : N | Satu produk dapat muncul di banyak line items |
| Belongs_to | Product | Category | N : 1 | Banyak produk dapat belong to satu kategori |

---

#### 🔄 Perbedaan ERD Konseptual vs Relasional

| Aspek | ERD Konseptual | ERD Relasional |
|-------|---------------|----------------|
| **Notasi** | Chen Notation (diamond, oval) | Crow's Foot Notation |
| **Level** | Bisnis / konseptual | Teknis / implementasi |
| **FK** | Tidak ditampilkan | Ditampilkan eksplisit |
| **Weak Entity** | Ditandai double rectangle | Ditandai dengan PK,FK |
| **Tujuan** | Pemahaman domain bisnis | Implementasi database |

---

#### 📌 Catatan Desain

- **Normalisasi:** Skema mengikuti **3NF (Third Normal Form)** — tidak ada kolom kalkulasi yang disimpan, semua derived attribute dihitung saat query.
- **Surrogate Key:** Semua tabel menggunakan surrogate key (`_id`) sebagai Primary Key untuk konsistensi dan performa join.
- **Reserved ID = 0:** Digunakan pada Customer dan Store untuk menangani data yang tidak diketahui (unknown/guest) tanpa menggunakan NULL pada FK.


---

#### Tools Digunakan

| Tool | Kategori | Fungsi |
|-----|-----|-----|
| **R Studio** | IDE & Programming Environment | Digunakan sebagai lingkungan utama untuk menulis, menjalankan, dan mengelola skrip R dalam proses pengembangan dashboard analitik. |
| **R Shiny** | Web Framework | Digunakan untuk membangun dashboard interaktif berbasis web yang memungkinkan pengguna melakukan eksplorasi data dan visualisasi secara dinamis. |
| **DBngin** | Database Engine Manager | Digunakan untuk menjalankan dan mengelola instance database secara lokal yang digunakan sebagai penyimpanan data dalam project. |
| **TablePlus** | Database Management Tool | Digunakan untuk mengelola database secara visual, termasuk melihat tabel, melakukan query SQL, dan memvalidasi struktur data. |
| **GitHub** | Version Control & Documentation | Digunakan untuk menyimpan source code project, mengelola versi pengembangan, serta mendokumentasikan hasil project melalui repository. |

----

## Interpretation & Key Insights

Dataset mencakup periode transaksi dari 5 Januari 2021 hingga 30 Desember 2024. Dashboard menyediakan fitur filtering yang memungkinkan pengguna untuk melakukan analisis data pada berbagai rentang waktu sesuai kebutuhan.

Pada dokumentasi ini, interpretasi hasil difokuskan pada periode tahun 2024 dengan tujuan untuk memberikan gambaran kondisi penjualan terbaru berdasarkan data yang tersedia.

Pemilihan periode ini dilakukan untuk memperoleh insight yang lebih relevan terhadap kondisi bisnis terkini, sehingga analisis yang dihasilkan dapat menggambarkan pola transaksi, performa penjualan, serta perilaku pelanggan pada periode terbaru.

Berdasarkan analisis pada dashboard, beberapa interpretasi hasil dan insight utama yang diperoleh adalah sebagai berikut.

## 👨‍💻 Tim Pengembang

### 📊 Data Analyst
**Wilia Sondriva**  
NIM: M0501251019  
Peran: Analisis data, identifikasi KPI, validasi dashboard, serta penyusunan insight utama dari data transaksi.

---

### 🗄️ Database Manager
**Ni Made Ray Diantari**  
NIM: M0501251033  
Peran: Mendesain struktur database, menyusun ERD, serta menyiapkan query SQL untuk kebutuhan dashboard.

---

### 🎨 Frontend Developer
**Rosita Ria Rusesta**  
NIM: M0501251016  
Peran: Mendesain tampilan UI dashboard, mengatur layout visualisasi, serta memastikan interaksi pengguna berjalan dengan baik.

---

### ⚙️ Backend Developer
**Naila Nabiha Qonita**  
NIM: M0501251060  
Peran: Menghubungkan aplikasi R Shiny dengan database, mengelola reaktivitas server, serta memproses data untuk visualisasi.
