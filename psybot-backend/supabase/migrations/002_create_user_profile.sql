-- 002_create_user_profile.sql
CREATE TABLE public.user_profile (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_user              UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  usia                 INTEGER CHECK (usia BETWEEN 13 AND 120),
  status               TEXT CHECK (status IN ('mahasiswa', 'karyawan', 'umum', 'lainnya')),
  institusi            TEXT CHECK (char_length(institusi) <= 200),
  preferensi_privasi   JSONB NOT NULL DEFAULT '{"anonymous_mode": false, "share_with_professional": false}'::jsonb,
  consent_diberikan    BOOLEAN NOT NULL DEFAULT FALSE,
  consent_timestamp    TIMESTAMPTZ,
  consent_version      TEXT,
  onboarding_complete  BOOLEAN NOT NULL DEFAULT FALSE,
  avatar_url           TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_profile_id_user ON public.user_profile(id_user);
CREATE INDEX idx_user_profile_consent ON public.user_profile(consent_diberikan);

CREATE TRIGGER user_profile_updated_at
  BEFORE UPDATE ON public.user_profile
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Auto-create profile saat user baru terdaftar
CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.user_profile (id_user) VALUES (NEW.id);
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_public_user_created
  AFTER INSERT ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_profile();

COMMENT ON TABLE public.user_profile IS 'Data profil lanjutan pengguna, termasuk consent dan preferensi privasi sesuai UU PDP.';
COMMENT ON COLUMN public.user_profile.consent_version IS 'Versi dokumen informed consent yang disetujui pengguna. Diperbarui jika ada perubahan kebijakan.';
COMMENT ON COLUMN public.user_profile.preferensi_privasi IS 'JSON: {anonymous_mode: bool, share_with_professional: bool, allow_research_data: bool}';
