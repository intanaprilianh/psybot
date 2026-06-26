-- 010_create_audit_logs.sql
-- Tabel ini adalah append-only (INSERT only, tidak boleh UPDATE/DELETE)
CREATE TABLE public.audit_logs (
  id              BIGSERIAL PRIMARY KEY,
  aktor_id        UUID,
  aktor_tipe      TEXT NOT NULL CHECK (aktor_tipe IN ('user', 'professional', 'admin', 'system', 'edge_function')),
  aksi            TEXT NOT NULL,
  resource_tipe   TEXT,
  resource_id     UUID,
  detail          JSONB,
  ip_address      INET,
  user_agent      TEXT,
  sukses          BOOLEAN NOT NULL DEFAULT TRUE,
  error_message   TEXT,
  timestamp       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_aktor ON public.audit_logs(aktor_id);
CREATE INDEX idx_audit_aksi ON public.audit_logs(aksi);
CREATE INDEX idx_audit_resource ON public.audit_logs(resource_tipe, resource_id);
CREATE INDEX idx_audit_timestamp ON public.audit_logs(timestamp DESC);

-- Prevent UPDATE dan DELETE pada audit_logs (append-only enforcement)
CREATE OR REPLACE RULE audit_logs_no_update AS
  ON UPDATE TO public.audit_logs DO INSTEAD NOTHING;

CREATE OR REPLACE RULE audit_logs_no_delete AS
  ON DELETE TO public.audit_logs DO INSTEAD NOTHING;

-- Helper function untuk insert audit log dari Edge Functions
CREATE OR REPLACE FUNCTION public.log_audit(
  p_aktor_id UUID,
  p_aktor_tipe TEXT,
  p_aksi TEXT,
  p_resource_tipe TEXT DEFAULT NULL,
  p_resource_id UUID DEFAULT NULL,
  p_detail JSONB DEFAULT NULL,
  p_ip_address TEXT DEFAULT NULL,
  p_sukses BOOLEAN DEFAULT TRUE,
  p_error_message TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.audit_logs (
    aktor_id, aktor_tipe, aksi, resource_tipe, resource_id,
    detail, ip_address, sukses, error_message
  ) VALUES (
    p_aktor_id, p_aktor_tipe, p_aksi, p_resource_tipe, p_resource_id,
    p_detail, p_ip_address::INET, p_sukses, p_error_message
  );
END;
$$;

COMMENT ON TABLE public.audit_logs IS 'Log audit append-only untuk semua aksi sensitif. Sesuai UU PDP — tidak boleh dimodifikasi/dihapus.';
