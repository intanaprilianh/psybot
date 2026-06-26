-- 004_create_messages.sql
-- KRITIS: isi_pesan_terenkripsi adalah kolom sensitif.
-- Enkripsi dilakukan di APPLICATION LAYER (Edge Function / Flutter)
-- menggunakan AES-256-GCM SEBELUM data masuk database.
-- Database hanya menyimpan ciphertext.

CREATE TABLE public.messages (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_session             UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
  pengirim_tipe          TEXT NOT NULL CHECK (pengirim_tipe IN ('user', 'ai', 'professional')),
  isi_pesan_terenkripsi  TEXT NOT NULL,
  iv                     TEXT NOT NULL,
  is_flagged             BOOLEAN NOT NULL DEFAULT FALSE,
  flag_reason            TEXT CHECK (flag_reason IN ('keyword_detected', 'high_phq_score', 'manual_review')),
  deleted_at             TIMESTAMPTZ,
  waktu                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_id_session ON public.messages(id_session);
CREATE INDEX idx_messages_waktu ON public.messages(waktu DESC);
CREATE INDEX idx_messages_flagged ON public.messages(is_flagged) WHERE is_flagged = TRUE;
CREATE INDEX idx_messages_active ON public.messages(id_session, waktu) WHERE deleted_at IS NULL;

-- Trigger: update pesan_count di chat_sessions
CREATE OR REPLACE FUNCTION public.update_session_message_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.chat_sessions
    SET pesan_count = pesan_count + 1,
        updated_at = NOW()
    WHERE id = NEW.id_session;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.chat_sessions
    SET pesan_count = GREATEST(pesan_count - 1, 0),
        updated_at = NOW()
    WHERE id = OLD.id_session;
  END IF;
  RETURN NULL;
END;
$$;

CREATE TRIGGER messages_count_update
  AFTER INSERT OR DELETE ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.update_session_message_count();

COMMENT ON TABLE public.messages IS 'Percakapan terenkripsi E2E. isi_pesan_terenkripsi adalah AES-256-GCM ciphertext. Database tidak pernah menyimpan plaintext.';
COMMENT ON COLUMN public.messages.isi_pesan_terenkripsi IS 'Format: base64url(ciphertext). Dekripsi hanya bisa dilakukan dengan kunci yang tersimpan di Vault (tidak ada di database).';
COMMENT ON COLUMN public.messages.iv IS 'Initialization Vector AES-GCM. Unik per pesan. Format: base64url (12 bytes = 16 karakter base64url).';
