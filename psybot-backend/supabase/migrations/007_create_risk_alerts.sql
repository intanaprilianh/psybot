-- 007_create_risk_alerts.sql
-- MOVED after professionals (005) to resolve FK dependency
-- Filosofi: risk_alert dibuat saat AI mendeteksi sinyal bahaya dari percakapan.
-- Sistem TIDAK otomatis menghubungi profesional. Pengguna MEMILIH apakah
-- ingin menghubungi call center atau tidak.

CREATE TABLE public.risk_alerts (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_user                  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  id_session               UUID REFERENCES public.chat_sessions(id) ON DELETE SET NULL,
  kategori_risiko          TEXT NOT NULL CHECK (kategori_risiko IN ('low', 'medium', 'high', 'critical')),
  trigger                  TEXT NOT NULL,
  escalation_type          TEXT NOT NULL CHECK (escalation_type IN (
                              'keyword_detected',
                              'ai_context_analysis',
                              'manual'
                            )),
  call_center_offered      BOOLEAN NOT NULL DEFAULT FALSE,
  call_center_contacted    BOOLEAN,
  call_center_name         TEXT,
  user_responded_at        TIMESTAMPTZ,
  id_professional_notified UUID REFERENCES public.professionals(id) ON DELETE SET NULL,
  notified_at              TIMESTAMPTZ,
  status_tindak_lanjut     TEXT NOT NULL DEFAULT 'pending' CHECK (status_tindak_lanjut IN (
                              'pending',
                              'call_center_offered',
                              'user_contacted',
                              'user_declined',
                              'professional_followup',
                              'resolved',
                              'false_positive'
                            )),
  catatan_profesional      TEXT,
  resolved_at              TIMESTAMPTZ,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_risk_alerts_id_user ON public.risk_alerts(id_user);
CREATE INDEX idx_risk_alerts_status ON public.risk_alerts(status_tindak_lanjut) WHERE status_tindak_lanjut = 'pending';
CREATE INDEX idx_risk_alerts_kategori ON public.risk_alerts(kategori_risiko);
CREATE INDEX idx_risk_alerts_professional ON public.risk_alerts(id_professional_notified) WHERE id_professional_notified IS NOT NULL;
CREATE INDEX idx_risk_alerts_created ON public.risk_alerts(created_at DESC);

CREATE TRIGGER risk_alerts_updated_at
  BEFORE UPDATE ON public.risk_alerts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.risk_alerts IS 'Log deteksi sinyal bahaya dari percakapan AI. Pengguna MEMILIH apakah ingin menghubungi call center — tidak ada eskalasi paksa.';
COMMENT ON COLUMN public.risk_alerts.call_center_contacted IS 'NULL = pilihan belum ditampilkan/dibuat. TRUE = user memilih menghubungi. FALSE = user memilih melewati.';
