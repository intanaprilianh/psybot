-- 011_rls_policies.sql
-- Prinsip: Setiap pengguna hanya bisa mengakses data miliknya sendiri.
-- Profesional hanya bisa mengakses data user yang sudah memberikan consent.
-- Admin hanya lewat service_role.

-- Enable RLS pada semua tabel publik
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.risk_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.consultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.professionals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.self_help_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- Helper: ambil role dari JWT custom claims
-- ==========================================
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$;

-- ==========================================
-- TABEL: users
-- ==========================================
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id AND role = 'user' AND status_akun = 'active');

CREATE POLICY "professional_select_consented_users" ON public.users
  FOR SELECT USING (
    get_user_role() = 'professional'
    AND EXISTS (
      SELECT 1 FROM public.user_profile up
      WHERE up.id_user = users.id
        AND (up.preferensi_privasi->>'share_with_professional')::boolean = TRUE
    )
  );

-- ==========================================
-- TABEL: user_profile
-- ==========================================
CREATE POLICY "profile_select_own" ON public.user_profile
  FOR SELECT USING (auth.uid() = id_user);

CREATE POLICY "profile_update_own" ON public.user_profile
  FOR UPDATE USING (auth.uid() = id_user)
  WITH CHECK (auth.uid() = id_user);

CREATE POLICY "professional_select_profile" ON public.user_profile
  FOR SELECT USING (
    get_user_role() = 'professional'
    AND (preferensi_privasi->>'share_with_professional')::boolean = TRUE
  );

-- ==========================================
-- TABEL: chat_sessions
-- ==========================================
CREATE POLICY "sessions_select_own" ON public.chat_sessions
  FOR SELECT USING (auth.uid() = id_user);

CREATE POLICY "sessions_insert_own" ON public.chat_sessions
  FOR INSERT WITH CHECK (auth.uid() = id_user);

CREATE POLICY "sessions_update_own" ON public.chat_sessions
  FOR UPDATE USING (auth.uid() = id_user AND status_sesi = 'active')
  WITH CHECK (auth.uid() = id_user);

CREATE POLICY "professional_select_sessions" ON public.chat_sessions
  FOR SELECT USING (
    get_user_role() = 'professional'
    AND EXISTS (
      SELECT 1 FROM public.user_profile up
      WHERE up.id_user = chat_sessions.id_user
        AND (up.preferensi_privasi->>'share_with_professional')::boolean = TRUE
    )
  );

-- ==========================================
-- TABEL: messages
-- ==========================================
CREATE POLICY "messages_select_own_session" ON public.messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.chat_sessions cs
      WHERE cs.id = messages.id_session
        AND cs.id_user = auth.uid()
    )
    AND deleted_at IS NULL
  );

-- Insert pesan hanya via Edge Function (SECURITY DEFINER)
CREATE POLICY "messages_insert_via_function" ON public.messages
  FOR INSERT WITH CHECK (FALSE);

CREATE POLICY "professional_select_messages" ON public.messages
  FOR SELECT USING (
    get_user_role() = 'professional'
    AND EXISTS (
      SELECT 1 FROM public.chat_sessions cs
      JOIN public.user_profile up ON up.id_user = cs.id_user
      WHERE cs.id = messages.id_session
        AND (up.preferensi_privasi->>'share_with_professional')::boolean = TRUE
    )
    AND deleted_at IS NULL
  );

-- ==========================================
-- TABEL: risk_alerts
-- ==========================================
CREATE POLICY "risk_alerts_select_own" ON public.risk_alerts
  FOR SELECT USING (auth.uid() = id_user);

CREATE POLICY "risk_alerts_user_update_callcenter" ON public.risk_alerts
  FOR UPDATE USING (auth.uid() = id_user)
  WITH CHECK (auth.uid() = id_user);

CREATE POLICY "risk_alerts_insert_system" ON public.risk_alerts
  FOR INSERT WITH CHECK (FALSE);

CREATE POLICY "professional_select_assigned_alerts" ON public.risk_alerts
  FOR SELECT USING (
    get_user_role() = 'professional'
    AND id_professional_notified = auth.uid()
  );

CREATE POLICY "professional_update_assigned_alerts" ON public.risk_alerts
  FOR UPDATE USING (
    get_user_role() = 'professional'
    AND id_professional_notified = auth.uid()
  )
  WITH CHECK (
    get_user_role() = 'professional'
    AND id_professional_notified = auth.uid()
  );

-- ==========================================
-- TABEL: professionals
-- ==========================================
CREATE POLICY "professionals_select_verified" ON public.professionals
  FOR SELECT USING (status_verified = TRUE);

CREATE POLICY "professionals_update_own" ON public.professionals
  FOR UPDATE USING (auth.uid() = id AND get_user_role() = 'professional')
  WITH CHECK (auth.uid() = id);

-- ==========================================
-- TABEL: consultations
-- ==========================================
CREATE POLICY "consultations_select_own" ON public.consultations
  FOR SELECT USING (auth.uid() = id_user OR (auth.uid() = id_professional AND get_user_role() = 'professional'));

CREATE POLICY "consultations_insert_own" ON public.consultations
  FOR INSERT WITH CHECK (auth.uid() = id_user);

CREATE POLICY "consultations_update" ON public.consultations
  FOR UPDATE USING (
    auth.uid() = id_user
    OR (auth.uid() = id_professional AND get_user_role() = 'professional')
  );

-- ==========================================
-- TABEL: payment_transactions
-- ==========================================
CREATE POLICY "payment_select_own" ON public.payment_transactions
  FOR SELECT USING (auth.uid() = id_user);

CREATE POLICY "payment_insert_own" ON public.payment_transactions
  FOR INSERT WITH CHECK (auth.uid() = id_user);

CREATE POLICY "payment_update_system" ON public.payment_transactions
  FOR UPDATE USING (FALSE);

-- ==========================================
-- TABEL: self_help_content
-- ==========================================
CREATE POLICY "self_help_select_active" ON public.self_help_content
  FOR SELECT USING (aktif = TRUE);

-- ==========================================
-- TABEL: audit_logs
-- ==========================================
CREATE POLICY "audit_logs_admin_only" ON public.audit_logs
  FOR SELECT USING (FALSE);

CREATE POLICY "audit_logs_insert_system" ON public.audit_logs
  FOR INSERT WITH CHECK (FALSE);
