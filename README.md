# 📊 Retail Analytics Dashboard - Kelompok 3

## 📝 Deskripsi Project
Project ini merupakan dashboard interaktif berbasis **R Shiny** yang dirancang untuk menganalisis performa penjualan retail dari tahun **2021 hingga 2024**. Dashboard ini membantu stakeholder dalam memantau kesehatan bisnis secara *real-time* dan mengambil keputusan berdasarkan data (Data-Driven Decision Making).

---

## 🚀 Fitur Utama
Dashboard ini memiliki dua halaman utama:
1. **Sales Overview:** Menyajikan tren pendapatan harian, performa toko (Top 10 Stores), metode pembayaran favorit pelanggan, dan persebaran waktu transaksi (Heatmap).
2. **Store Analysis:** Analisis mendalam untuk setiap cabang toko (Dapat diakses melalui menu sidebar).

### 🛠️ Fitur Interaktif (Filtering)
Dashboard ini sangat dinamis! User dapat membedah data menggunakan:
* **Date Range:** Memilih rentang waktu spesifik (misal: hanya periode Lebaran).
* **Province & City:** Membandingkan performa antar wilayah.
* **Store Type:** Melihat perbedaan performa toko kecil vs toko besar.
* **Daily/Monthly Toggle:** Mengubah tampilan grafik tren menjadi harian atau bulanan.

---

## 📈 Daftar KPI (Key Performance Indicators)
Berikut adalah metrik utama yang digunakan untuk mengukur keberhasilan bisnis:

| KPI | Deskripsi |
| :--- | :--- |
| **Total Revenue** | Total pendapatan kotor dari penjualan. |
| **Total Transactions** | Jumlah nota/struk unik (menunjukkan jumlah kunjungan). |
| **Total Items Sold** | Total unit barang yang terjual. |
| **Avg Basket Size** | Rata-rata jumlah barang dalam satu transaksi. |
| **Avg Order Value** | Rata-rata uang yang dihabiskan pelanggan per transaksi. |
| **Active Stores** | Jumlah toko yang beroperasi pada periode terpilih. |

---

## 💡 Insight Singkat (Contoh Temuan)
* **Trend:** Terdapat lonjakan signifikan setiap akhir tahun (Desember), dipicu oleh musim liburan.
* **Payment:** Penggunaan metode **Cashless (Debit & QRIS)** mendominasi lebih dari 60% total transaksi.
* **Store Performance:** Toko di wilayah **Palu 7** mencatatkan pertumbuhan tertinggi sebesar 82.5% YoY.

---

## 📁 Struktur Folder
* `Dataset/`: Berisi data mentah (CSV/Excel).
* `Script/`: File `app.R` atau kode sumber R Shiny.
* `Doc/`: Dokumentasi teknis, daftar KPI lengkap, dan analisis mendalam.
