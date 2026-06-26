-- 020_create_notifications.sql
-- In-app notifications shown on the Notifikasi page. Written from the Flutter
-- client when an FCM message arrives in the foreground (onMessage), and read
-- back by the user. Push delivery itself is still handled by FCM.

CREATE TABLE public.notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_user     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  judul       TEXT NOT NULL CHECK (char_length(judul) <= 200),
  deskripsi   TEXT NOT NULL DEFAULT '',
  tipe        TEXT NOT NULL DEFAULT 'sistem'
              CHECK (tipe IN ('chat', 'konsultasi', 'meditasi', 'mood', 'sistem')),
  dibaca      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user
  ON public.notifications(id_user, created_at DESC);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications_select_own" ON public.notifications
  FOR SELECT USING (auth.uid() = id_user);

CREATE POLICY "notifications_insert_own" ON public.notifications
  FOR INSERT WITH CHECK (auth.uid() = id_user);

CREATE POLICY "notifications_update_own" ON public.notifications
  FOR UPDATE USING (auth.uid() = id_user)
  WITH CHECK (auth.uid() = id_user);

CREATE POLICY "notifications_delete_own" ON public.notifications
  FOR DELETE USING (auth.uid() = id_user);

COMMENT ON TABLE public.notifications IS 'Notifikasi in-app pengguna; ditulis dari FCM onMessage (foreground) dan dibaca oleh halaman Notifikasi.';
