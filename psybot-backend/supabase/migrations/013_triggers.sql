-- 013_triggers.sql

-- Prevent perubahan role melalui UPDATE biasa (hanya admin/service_role)
CREATE OR REPLACE FUNCTION public.prevent_role_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF OLD.role != NEW.role AND current_setting('role') != 'service_role' THEN
    RAISE EXCEPTION 'Role change requires service_role permissions';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER users_prevent_role_change
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.prevent_role_change();

-- Auto-close sesi yang tidak aktif lebih dari 24 jam
CREATE OR REPLACE FUNCTION public.close_inactive_sessions()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.chat_sessions
  SET status_sesi = 'closed',
      ditutup_pada = NOW()
  WHERE status_sesi = 'active'
    AND updated_at < NOW() - INTERVAL '24 hours';
END;
$$;

-- Jadwalkan via pg_cron (aktifkan extension terlebih dahulu di Supabase dashboard)
-- SELECT cron.schedule('close-inactive-sessions', '0 * * * *', 'SELECT public.close_inactive_sessions()');

-- Prevent hard-delete pada messages (soft delete only)
CREATE OR REPLACE FUNCTION public.prevent_message_hard_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RAISE EXCEPTION 'Hard delete tidak diizinkan pada messages. Gunakan soft delete (deleted_at).';
END;
$$;

CREATE TRIGGER messages_no_hard_delete
  BEFORE DELETE ON public.messages
  FOR EACH ROW EXECUTE FUNCTION public.prevent_message_hard_delete();
