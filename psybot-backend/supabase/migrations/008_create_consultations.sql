-- 008_create_consultations.sql
-- MOVED after professionals (005), payment_transactions (006), risk_alerts (007)
-- to resolve all FK dependencies
CREATE TABLE public.consultations (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_user               UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  id_professional       UUID NOT NULL REFERENCES public.professionals(id),
  jadwal                TIMESTAMPTZ NOT NULL,
  durasi_menit          INTEGER NOT NULL DEFAULT 60 CHECK (durasi_menit IN (30, 60, 90)),
  status                TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
                          'pending', 'confirmed', 'ongoing', 'completed', 'cancelled', 'no_show'
                        )),
  jenis_konsultasi      TEXT NOT NULL CHECK (jenis_konsultasi IN ('chat', 'video_call', 'voice_call')),
  platform_url          TEXT,
  catatan_professional  TEXT,
  catatan_terenkripsi   BOOLEAN NOT NULL DEFAULT TRUE,
  status_pembayaran     TEXT NOT NULL DEFAULT 'unpaid' CHECK (status_pembayaran IN (
                          'unpaid', 'pending', 'paid', 'refunded', 'free'
                        )),
  id_transaksi          UUID REFERENCES public.payment_transactions(id) ON DELETE SET NULL,
  is_emergency          BOOLEAN NOT NULL DEFAULT FALSE,
  id_risk_alert         UUID REFERENCES public.risk_alerts(id) ON DELETE SET NULL,
  cancel_reason         TEXT,
  cancelled_at          TIMESTAMPTZ,
  completed_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_consultations_id_user ON public.consultations(id_user);
CREATE INDEX idx_consultations_id_professional ON public.consultations(id_professional);
CREATE INDEX idx_consultations_jadwal ON public.consultations(jadwal);
CREATE INDEX idx_consultations_status ON public.consultations(status);
CREATE INDEX idx_consultations_emergency ON public.consultations(is_emergency) WHERE is_emergency = TRUE;

CREATE TRIGGER consultations_updated_at
  BEFORE UPDATE ON public.consultations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Trigger: update total_sesi profesional setelah konsultasi selesai
CREATE OR REPLACE FUNCTION public.update_professional_total_sesi()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS DISTINCT FROM 'completed') THEN
    UPDATE public.professionals
    SET total_sesi = total_sesi + 1,
        updated_at = NOW()
    WHERE id = NEW.id_professional;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER consultations_complete_update_professional
  AFTER UPDATE ON public.consultations
  FOR EACH ROW EXECUTE FUNCTION public.update_professional_total_sesi();

COMMENT ON TABLE public.consultations IS 'Jadwal dan riwayat konsultasi antara user dan profesional.';
