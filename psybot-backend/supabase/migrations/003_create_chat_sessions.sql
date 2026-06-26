-- 003_create_chat_sessions.sql
CREATE TABLE public.chat_sessions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_user         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  tanggal         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status_risiko   TEXT NOT NULL DEFAULT 'low' CHECK (status_risiko IN ('low', 'medium', 'high', 'critical')),
  status_sesi     TEXT NOT NULL DEFAULT 'active' CHECK (status_sesi IN ('active', 'closed', 'escalated')),
  summary         TEXT,
  mood_score      SMALLINT CHECK (mood_score BETWEEN 1 AND 10),
  pesan_count     INTEGER NOT NULL DEFAULT 0,
  ditutup_pada    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_chat_sessions_id_user ON public.chat_sessions(id_user);
CREATE INDEX idx_chat_sessions_tanggal ON public.chat_sessions(tanggal DESC);
CREATE INDEX idx_chat_sessions_risiko ON public.chat_sessions(status_risiko) WHERE status_risiko IN ('high', 'critical');
CREATE INDEX idx_chat_sessions_aktif ON public.chat_sessions(id_user, status_sesi) WHERE status_sesi = 'active';

CREATE TRIGGER chat_sessions_updated_at
  BEFORE UPDATE ON public.chat_sessions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.chat_sessions IS 'Ringkasan sesi chatbot. Konten percakapan detail ada di tabel messages (terenkripsi).';
