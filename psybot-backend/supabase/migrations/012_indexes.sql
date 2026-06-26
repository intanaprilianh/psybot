-- 012_indexes.sql
-- Composite indexes untuk query yang paling sering

CREATE INDEX idx_messages_session_waktu ON public.messages(id_session, waktu DESC)
  WHERE deleted_at IS NULL;

CREATE INDEX idx_consultations_user_jadwal ON public.consultations(id_user, jadwal DESC);

CREATE INDEX idx_consultations_professional_status ON public.consultations(id_professional, status)
  WHERE status IN ('pending', 'confirmed', 'ongoing');

CREATE INDEX idx_risk_alerts_pending ON public.risk_alerts(created_at DESC)
  WHERE status_tindak_lanjut = 'pending';

-- Partial index untuk mode anonim
CREATE INDEX idx_user_profile_anonymous ON public.user_profile(id_user)
  WHERE (preferensi_privasi->>'anonymous_mode')::boolean = TRUE;
