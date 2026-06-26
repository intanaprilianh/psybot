-- 009_create_self_help_content.sql
-- Konten self-help direkomendasikan berdasarkan KATEGORI RISIKO dari percakapan,
-- bukan berdasarkan skor kuesioner terstruktur.
CREATE TABLE public.self_help_content (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kategori         TEXT NOT NULL CHECK (kategori IN (
                     'mindfulness',
                     'relaksasi',
                     'journaling',
                     'olahraga_ringan',
                     'cognitive_restructuring',
                     'breathing_exercise',
                     'social_support',
                     'edukasi_mental_health',
                     'krisis'
                   )),
  judul            TEXT NOT NULL CHECK (char_length(judul) BETWEEN 3 AND 200),
  konten           TEXT NOT NULL,
  konten_html      TEXT,
  durasi_menit     INTEGER,
  target_risk_level TEXT[] NOT NULL DEFAULT '{low,medium}',
  urutan           INTEGER NOT NULL DEFAULT 100,
  aktif            BOOLEAN NOT NULL DEFAULT TRUE,
  thumbnail_url    TEXT,
  tags             TEXT[],
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_self_help_kategori ON public.self_help_content(kategori);
CREATE INDEX idx_self_help_risk ON public.self_help_content USING gin(target_risk_level);
CREATE INDEX idx_self_help_aktif ON public.self_help_content(aktif) WHERE aktif = TRUE;

CREATE TRIGGER self_help_content_updated_at
  BEFORE UPDATE ON public.self_help_content
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.self_help_content IS 'Konten edukasi dan teknik self-help. Direkomendasikan berdasarkan risk level yang terdeteksi dari percakapan AI, bukan skor kuesioner.';
COMMENT ON COLUMN public.self_help_content.target_risk_level IS 'Array risk level yang relevan: low, medium, high, critical.';
