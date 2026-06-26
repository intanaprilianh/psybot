-- 017_create_moods.sql
-- Tabel untuk menyimpan riwayat mood harian pengguna

CREATE TABLE public.moods (
  id         UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  id_user    UUID        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  jenis_mood TEXT        NOT NULL CHECK (jenis_mood IN (
                           'senang','sedih','marah','tenang',
                           'cemas','lelah','semangat','bingung'
                         )),
  catatan    TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_moods_user      ON public.moods(id_user);
CREATE INDEX idx_moods_user_date ON public.moods(id_user, created_at DESC);

ALTER TABLE public.moods ENABLE ROW LEVEL SECURITY;

CREATE POLICY "moods_select_own" ON public.moods
  FOR SELECT TO authenticated USING (id_user = auth.uid());

CREATE POLICY "moods_insert_own" ON public.moods
  FOR INSERT TO authenticated WITH CHECK (id_user = auth.uid());

CREATE POLICY "moods_delete_own" ON public.moods
  FOR DELETE TO authenticated USING (id_user = auth.uid());

COMMENT ON TABLE public.moods IS 'Riwayat mood harian pengguna PsyBot.';
