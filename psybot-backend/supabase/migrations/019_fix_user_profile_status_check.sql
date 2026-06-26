-- 019_fix_user_profile_status_check.sql
-- The profile screen offers a "Pelajar" status option, but the original CHECK
-- constraint on user_profile.status (migration 002) only allowed
-- 'mahasiswa', 'karyawan', 'umum', 'lainnya'. Saving "pelajar" therefore failed
-- with a constraint violation. Broaden the constraint to include 'pelajar'
-- while keeping the legacy values for backward compatibility.

ALTER TABLE public.user_profile
  DROP CONSTRAINT IF EXISTS user_profile_status_check;

ALTER TABLE public.user_profile
  ADD CONSTRAINT user_profile_status_check
  CHECK (status IN ('pelajar', 'mahasiswa', 'karyawan', 'umum', 'lainnya'));
