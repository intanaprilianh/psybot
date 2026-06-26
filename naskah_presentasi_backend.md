# Naskah Presentasi PsyBot — Backend & Database

> Aplikasi dukungan kesehatan mental untuk pengguna Indonesia
> Proyek Pemrograman Perangkat Bergerak — ITS Surabaya

---

## SLIDE 1 — Pembuka

**[Naskah]**

"Selamat pagi/siang Bapak/Ibu dosen dan teman-teman semua. Perkenalkan, kami dari kelompok yang mengembangkan **PsyBot** — sebuah aplikasi mobile dukungan kesehatan mental untuk pengguna Indonesia.

Pada presentasi kali ini, kami akan fokus membahas sisi **backend dan database** dari aplikasi PsyBot — yaitu bagaimana data diproses, disimpan dengan aman, dan bagaimana fitur kecerdasan buatan kami bekerja di belakang layar."

---

## SLIDE 2 — Apa itu PsyBot?

**[Naskah]**

"PsyBot adalah aplikasi kesehatan mental yang menyediakan lima layanan utama:

1. **Chatbot AI** — didampingi maskot bernama *Puyo*, yang menjadi teman curhat pengguna.
2. **Konsultasi profesional** — pengguna bisa memesan sesi dengan psikolog terverifikasi.
3. **Mood tracking** — pencatatan suasana hati harian.
4. **Deteksi risiko** — sistem otomatis mendeteksi tanda-tanda krisis dari percakapan.
5. **Rujukan layanan darurat** — menghubungkan ke hotline krisis seperti 119 Kemenkes.

Seluruh antarmuka dan teks aplikasi menggunakan **Bahasa Indonesia**, karena target penggunanya adalah masyarakat Indonesia."

---

## SLIDE 3 — Arsitektur & Tech Stack

**[Naskah]**

"Secara teknis, PsyBot dibangun dengan dua bagian besar:

**Frontend** menggunakan **Flutter** dengan Material Design 3 dan state management Riverpod.

**Backend** menggunakan **Supabase**, yaitu platform berbasis PostgreSQL yang menyediakan:
- Database PostgreSQL versi 17
- Sistem autentikasi
- *Edge Functions* yang ditulis dalam Deno/TypeScript

Untuk kecerdasan buatannya, kami memakai model **DeepSeek** sebagai utama, dengan **OpenAI GPT-4o** sebagai cadangan.

Untuk pembayaran, kami integrasikan **Midtrans** yang mendukung QRIS, GoPay, dan transfer bank. Notifikasi memakai **Firebase Cloud Messaging**."

---

## SLIDE 4 — Struktur Database (Migrasi)

**[Naskah]**

"Database kami dibangun melalui *migration* bernomor 000 sampai 020. Artinya setiap perubahan struktur database tercatat dan bisa direproduksi. Beberapa tabel inti:

- **`users`** dan **`user_profile`** — menyimpan akun dan data onboarding pengguna.
- **`chat_sessions`** dan **`messages`** — sesi dan pesan chatbot AI (terenkripsi).
- **`professionals`** — data psikolog, tarif, dan status verifikasi.
- **`consultations`** dan **`consultation_messages`** — jadwal konsultasi dan chat dengan profesional.
- **`payment_transactions`** — transaksi pembayaran via Midtrans.
- **`risk_alerts`** — catatan deteksi risiko dan eskalasi.
- **`moods`** — pencatatan suasana hati.
- **`notifications`** — notifikasi dalam aplikasi.
- **`self_help_content`** dan **`audit_logs`** — konten bantuan mandiri dan log audit.

Total ada lebih dari 15 tabel yang saling terhubung."

---

## SLIDE 5 — Keamanan: Enkripsi

**[Naskah]**

"Karena ini aplikasi kesehatan mental, **keamanan data adalah prioritas utama** kami.

Semua pesan chatbot AI **dienkripsi** menggunakan algoritma **AES-256-GCM** di lapisan aplikasi. Artinya, pesan disimpan di database sebagai *ciphertext* — teks acak yang tidak bisa dibaca — bukan sebagai teks asli.

Teks asli hanya ada di dua tempat: di dalam Edge Function saat diproses, dan di aplikasi pengguna. Database **tidak pernah** menyimpan pesan dalam bentuk teks biasa.

Ini sejalan dengan **UU PDP No. 27 Tahun 2022** tentang Perlindungan Data Pribadi."

---

## SLIDE 6 — Keamanan: Row Level Security (RLS)

**[Naskah]**

"Selain enkripsi, kami menerapkan **Row Level Security** atau RLS pada semua tabel.

Konsepnya sederhana namun kuat: **setiap pengguna hanya bisa melihat datanya sendiri**. Misalnya, pengguna A tidak akan pernah bisa mengakses chat atau mood pengguna B, meskipun mencoba lewat permintaan langsung ke database.

Untuk profesional, mereka hanya bisa melihat data konsultasi yang memang ditujukan untuk mereka.

Bahkan, penyisipan pesan ke tabel `messages` **diblokir secara langsung** — pesan hanya bisa masuk melalui Edge Function yang sudah terverifikasi. Ini mencegah manipulasi data."

---

## SLIDE 7 — Edge Functions (Logika Backend)

**[Naskah]**

"Logika utama backend berjalan di **Edge Functions** — fungsi serverless yang ditulis dengan Deno dan TypeScript. Yang terpenting:

- **`ai-chat`** — jantung dari chatbot. Menangani autentikasi, deteksi risiko, enkripsi pesan, dan pemanggilan model AI.
- **`payment-create`** dan **`payment-webhook`** — menangani pembuatan dan konfirmasi pembayaran Midtrans.
- **`risk-escalation`** — mencatat keputusan pengguna saat ditawari bantuan krisis.
- **`send-notification`** — mengirim notifikasi push via Firebase.
- **`auth-hook`** — menyisipkan peran pengguna (user/profesional/admin) ke dalam token JWT."

---

## SLIDE 8 — Alur Chatbot AI (`ai-chat`)

**[Naskah]**

"Mari kita lihat alur kerja fungsi `ai-chat` ketika pengguna mengirim pesan:

1. **Autentikasi** — memastikan pengguna valid.
2. **Deteksi risiko** — pesan dipindai untuk kata kunci berisiko.
3. **Enkripsi & simpan** pesan pengguna.
4. Jika risikonya **kritis** — langsung tampilkan layanan darurat, AI dilewati.
5. Jika tidak — ambil 20 pesan terakhir, dekripsi, lalu kirim ke model AI.
6. Respons AI **dienkripsi** dan disimpan.
7. Jika risikonya **tinggi** — buat catatan `risk_alert` dan tawarkan hotline.

Jadi keselamatan pengguna selalu dicek **sebelum** AI menjawab."

---

## SLIDE 9 — Deteksi Risiko Bertingkat

**[Naskah]**

"Sistem deteksi risiko kami punya **tiga tingkat**, berdasarkan kata kunci Bahasa Indonesia:

- **CRITICAL** — isyarat bunuh diri langsung. Aplikasi **otomatis** membuka layar darurat.
- **HIGH** — tanda putus asa. Pengguna **ditawari** hotline, sifatnya *opt-in*.
- **MEDIUM** — seperti 'depresi' atau 'panic attack'. AI memberi jawaban yang lebih hati-hati.

Yang penting kami tekankan: prinsipnya adalah **opt-in** — sistem **tidak pernah memaksa** pengguna menghubungi siapa pun. Pengguna selalu yang memutuskan. Ini penting secara etika dalam konteks kesehatan mental."

---

## SLIDE 10 — Layar Darurat (Catatan Penting)

**[Naskah]**

"Satu hal yang perlu kami jelaskan dengan jujur: layar panggilan darurat di aplikasi adalah **simulasi**.

Aplikasi menampilkan UI seolah sedang menghubungi 119 Kemenkes, namun **tidak benar-benar melakukan panggilan telepon seluler**. Ini karena keterbatasan teknis Android — aplikasi non-dialer tidak diizinkan menempatkan panggilan seluler di dalam aplikasi.

Layar ini muncul otomatis saat risiko kritis terdeteksi, dan juga bisa diakses lewat ikon telepon merah."

---

## SLIDE 11 — Fitur yang Sudah Berjalan End-to-End

**[Naskah]**

"Sampai saat ini, fitur-fitur berikut sudah **berjalan penuh** terhubung backend:

- Autentikasi: daftar, masuk, keluar.
- Chatbot AI dengan pesan terenkripsi.
- Deteksi risiko dan eskalasi bertingkat.
- Mood tracker tersimpan ke database.
- Persistensi profil — nama bertahan setelah aplikasi ditutup.
- Pemesanan profesional dan alur pembayaran Midtrans.
- Chat konsultasi *real-time* dengan psikolog.
- Registrasi token notifikasi FCM.
- Halaman notifikasi terhubung database.

Semua migrasi database dan Edge Function sudah **di-deploy ke server remote**, dan data awal — 11 konten bantuan mandiri serta 5 profesional terverifikasi — sudah aktif."

---

## SLIDE 12 — Yang Masih Dikembangkan

**[Naskah]**

"Untuk transparansi, ada satu fitur yang sengaja kami tunda:

- **Audio Meditasi** — saat ini sesi meditasi memakai timer tanpa audio asli, karena kami belum memiliki aset audio. Ke depannya akan diintegrasikan dengan pemutar audio sungguhan.

Sisanya, baik dari sisi backend maupun database, sudah selesai dan berfungsi."

---

## SLIDE 13 — Penutup

**[Naskah]**

"Sebagai penutup, PsyBot membuktikan bahwa aplikasi kesehatan mental bisa dibangun dengan **mengutamakan keamanan dan etika**:

- Data terenkripsi dengan AES-256.
- Akses diisolasi dengan Row Level Security.
- Deteksi risiko yang menghormati keputusan pengguna.
- Kepatuhan terhadap UU Perlindungan Data Pribadi.

Backend yang kuat inilah yang membuat fitur-fitur di sisi pengguna bisa berjalan dengan aman dan andal.

Sekian presentasi dari kami. Terima kasih, dan kami persilakan jika ada pertanyaan."

---

## Lampiran — Kemungkinan Pertanyaan & Jawaban

**Q: Kenapa pakai Supabase, bukan backend sendiri?**
A: Supabase menyediakan PostgreSQL, Auth, dan Edge Functions dalam satu platform, sehingga kami bisa fokus ke logika aplikasi tanpa mengelola server sendiri. RLS-nya juga sangat cocok untuk isolasi data per pengguna.

**Q: Bagaimana jika model AI utama (DeepSeek) gagal?**
A: Kami punya mekanisme *fallback* ke OpenAI GPT-4o, sehingga layanan tetap berjalan.

**Q: Apakah pesan konsultasi dengan profesional juga dienkripsi?**
A: Untuk demo, `consultation_messages` disimpan sebagai teks biasa. Pada versi produksi, ini sebaiknya dienkripsi seperti pesan chatbot.

**Q: Bagaimana cara mencegah false positive pada deteksi risiko?**
A: Kami menggunakan frasa spesifik, bukan kata pendek. Misalnya kami hindari kata 'mati' saja karena bisa muncul di kata 'otomatis' atau 'lampu mati'. Kata kunci bisa diatur ulang dan di-deploy ulang kapan saja.
