-- 005_create_professionals.sql
-- CATATAN: Profesional juga memiliki akun di auth.users dengan role='professional'
-- MOVED before risk_alerts to resolve FK dependency
CREATE TABLE public.professionals (
  id                UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  spesialisasi      TEXT NOT NULL CHECK (spesialisasi IN ('psikolog', 'psikiater', 'konselor')),
  nomor_lisensi     TEXT UNIQUE,
  foto_url          TEXT,
  bio               TEXT CHECK (char_length(bio) <= 1000),
  tarif_per_sesi    INTEGER CHECK (tarif_per_sesi >= 0),
  tarif_gratis      BOOLEAN NOT NULL DEFAULT FALSE,
  jadwal_aktif      JSONB NOT NULL DEFAULT '[]'::jsonb,
  rating            NUMERIC(3,2) CHECK (rating BETWEEN 0 AND 5),
  total_sesi        INTEGER NOT NULL DEFAULT 0,
  status_verified   BOOLEAN NOT NULL DEFAULT FALSE,
  status_online     BOOLEAN NOT NULL DEFAULT FALSE,
  institusi_afiliasi TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_professionals_spesialisasi ON public.professionals(spesialisasi);
CREATE INDEX idx_professionals_verified ON public.professionals(status_verified) WHERE status_verified = TRUE;
CREATE INDEX idx_professionals_online ON public.professionals(status_online) WHERE status_online = TRUE;

CREATE TRIGGER professionals_updated_at
  BEFORE UPDATE ON public.professionals
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.professionals IS 'Profil tenaga profesional kesehatan mental. Hanya profesional yang status_verified=TRUE yang tampil ke pengguna.';
COMMENT ON COLUMN public.professionals.jadwal_aktif IS 'Format JSON: [{"hari": "senin", "mulai": "09:00", "selesai": "17:00"}, ...]';
