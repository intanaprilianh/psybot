-- 014_add_fcm_token.sql
-- Tambahkan kolom fcm_token ke tabel user_profile untuk push notifications
ALTER TABLE public.user_profile
  ADD COLUMN fcm_token TEXT,
  ADD COLUMN fcm_token_updated_at TIMESTAMPTZ;
