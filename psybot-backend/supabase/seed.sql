-- seed.sql — Data awal untuk self_help_content
-- Jalankan setelah semua migration berhasil

INSERT INTO public.self_help_content (kategori, judul, konten, durasi_menit, target_risk_level, urutan, tags) VALUES

-- Breathing Exercises
('breathing_exercise', 'Teknik Napas 4-7-8',
 'Tarik napas melalui hidung selama 4 detik. Tahan napas selama 7 detik. Buang napas perlahan melalui mulut selama 8 detik. Ulangi 3-4 kali. Teknik ini membantu menenangkan sistem saraf dan mengurangi kecemasan.',
 5, '{low,medium}', 10, '{napas,relaksasi,cepat}'),

('breathing_exercise', 'Box Breathing (Napas Kotak)',
 'Tarik napas selama 4 detik. Tahan 4 detik. Buang napas 4 detik. Tahan (paru-paru kosong) 4 detik. Ulangi 4 siklus. Teknik ini digunakan oleh Navy SEAL untuk tetap tenang di bawah tekanan.',
 5, '{low,medium,high}', 11, '{napas,fokus,tenang}'),

-- Mindfulness
('mindfulness', 'Grounding 5-4-3-2-1',
 'Saat merasa cemas, gunakan panca indera: Sebutkan 5 hal yang bisa kamu LIHAT. 4 hal yang bisa kamu SENTUH. 3 hal yang bisa kamu DENGAR. 2 hal yang bisa kamu CIUM. 1 hal yang bisa kamu RASAKAN (lidah). Ini membantu membawa pikiranmu kembali ke saat ini.',
 5, '{low,medium,high}', 20, '{grounding,cemas,panik}'),

('mindfulness', 'Body Scan Meditation',
 'Duduk atau berbaring nyaman. Mulai dari ujung kaki, perlahan arahkan perhatian ke setiap bagian tubuh — kaki, betis, paha, perut, dada, tangan, bahu, leher, wajah. Di setiap bagian, perhatikan sensasi yang ada tanpa menghakimi. Jika ada ketegangan, bayangkan napasmu mengalir ke sana.',
 15, '{low,medium}', 21, '{meditasi,tubuh,rileks}'),

-- Relaksasi
('relaksasi', 'Progressive Muscle Relaxation',
 'Tegangkan kelompok otot selama 5 detik, lalu lepaskan. Mulai dari kaki: kepalkan jari kaki (5 detik), lepas. Betis: tekan tumit ke lantai (5 detik), lepas. Lanjutkan ke paha, perut, tangan, bahu, wajah. Rasakan perbedaan antara tegang dan rileks di setiap bagian.',
 10, '{low,medium,high}', 30, '{otot,tegang,rileks}'),

-- Journaling
('journaling', 'Jurnal Syukur 3 Hal',
 'Setiap malam sebelum tidur, tulis 3 hal yang kamu syukuri hari ini. Bisa hal kecil: "cuaca cerah", "teman mengajak makan", "tugas selesai tepat waktu". Penelitian menunjukkan kebiasaan ini meningkatkan well-being dalam 2 minggu.',
 5, '{low,medium}', 40, '{syukur,positif,malam}'),

('journaling', 'Ekspresif Writing',
 'Tulis bebas selama 10-15 menit tentang apa yang kamu rasakan saat ini. Tidak perlu struktur, tidak perlu rapi. Tujuannya bukan menghasilkan tulisan bagus, tapi mengeluarkan apa yang tersimpan di pikiran. Setelah selesai, kamu bisa menyimpan atau membuangnya.',
 15, '{medium,high}', 41, '{ekspresi,bebas,emosi}'),

-- Olahraga Ringan
('olahraga_ringan', 'Stretching Pagi 5 Menit',
 'Peregangan sederhana saat bangun tidur: 1) Angkat tangan ke atas, tarik ke kanan dan kiri (30 detik). 2) Putar bahu ke depan dan belakang (30 detik). 3) Sentuh jari kaki, tahan 20 detik. 4) Putar leher perlahan (30 detik). 5) Tarik napas dalam 3x. Gerakan fisik ringan membantu melepas hormon endorfin.',
 5, '{low,medium}', 50, '{pagi,peregangan,energi}'),

-- Edukasi
('edukasi_mental_health', 'Apa Itu Kecemasan?',
 'Kecemasan adalah respons alami tubuh terhadap stres. Detak jantung meningkat, napas menjadi cepat, otot menegang — ini adalah cara tubuh mempersiapkan diri menghadapi ancaman. Kecemasan menjadi masalah saat: terjadi tanpa pemicu jelas, intensitasnya tidak sebanding dengan situasi, atau mengganggu aktivitas sehari-hari. Jika ini terjadi, kamu tidak sendirian dan ada bantuan yang tersedia.',
 3, '{low,medium}', 60, '{edukasi,cemas,pengertian}'),

('edukasi_mental_health', 'Mitos vs Fakta Kesehatan Mental',
 'MITOS: "Orang dengan masalah mental itu lemah." FAKTA: Masalah mental bisa dialami siapa saja, terlepas dari kekuatan karakter. MITOS: "Kalau curhat artinya cari perhatian." FAKTA: Berbagi perasaan adalah langkah berani untuk mencari bantuan. MITOS: "Harus parah dulu baru boleh ke psikolog." FAKTA: Kamu berhak mencari bantuan kapan pun merasa butuh, tidak harus menunggu kondisi memburuk.',
 3, '{low,medium}', 61, '{mitos,fakta,stigma}'),

-- Krisis
('krisis', 'Kamu Tidak Sendirian',
 'Jika kamu sedang merasa sangat berat saat ini, ketahui bahwa perasaanmu valid dan kamu tidak harus menanggungnya sendiri. Ada orang-orang yang siap mendengarkan dan menemanimu — tanpa menghakimi. Kamu bisa menghubungi layanan bantuan kapan pun kamu siap. Pilihan ada di tanganmu, dan tidak ada tekanan.',
 2, '{high,critical}', 70, '{krisis,bantuan,dukungan}'),

-- Social Support
('social_support', 'Tips Memulai Percakapan Tentang Perasaanmu',
 'Tidak mudah membicarakan perasaan, tapi ini beberapa cara memulai: "Aku lagi nggak baik-baik aja, boleh cerita?" atau "Ada sesuatu yang mengganggu pikiranku belakangan ini." Pilih orang yang kamu percaya. Tidak harus menceritakan semuanya sekaligus. Mulai dari yang nyaman.',
 3, '{low,medium}', 80, '{teman,bicara,dukungan}');

-- NOTE: Seed data profesional tidak bisa dimasukkan via seed.sql karena INSERT ke auth.users
-- membutuhkan akses service_role. Gunakan Edge Function 'seed-professionals':
--   supabase functions deploy seed-professionals
--   supabase functions invoke seed-professionals --no-verify-jwt
