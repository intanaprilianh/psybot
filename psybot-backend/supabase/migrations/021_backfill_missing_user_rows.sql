-- 021_backfill_missing_user_rows.sql
-- Some accounts (created via the dashboard, or before the signup triggers in
-- migrations 001/002 were active on the remote DB) are missing their
-- public.users and/or public.user_profile rows. Because RLS allows UPDATE but
-- not INSERT on these tables, the client's `.update().eq(...)` silently affects
-- zero rows for such accounts — the app reports success but nothing persists,
-- and the profile appears blank on every reload.
--
-- This backfill creates the missing rows. It is idempotent. Inserting into
-- public.users fires on_public_user_created, which auto-creates the matching
-- user_profile row; step 2 is a safety net for any users row that still lacks
-- a profile.

-- 1. Create missing public.users rows from auth.users
INSERT INTO public.users (id, nama, email, email_verified)
SELECT
  au.id,
  -- nama has a CHECK (length BETWEEN 2 AND 100); guard against short local-parts
  CASE
    WHEN length(COALESCE(au.raw_user_meta_data->>'nama', split_part(au.email, '@', 1))) >= 2
      THEN COALESCE(au.raw_user_meta_data->>'nama', split_part(au.email, '@', 1))
    ELSE 'User'
  END,
  au.email,
  au.email_confirmed_at IS NOT NULL
FROM auth.users au
LEFT JOIN public.users pu ON pu.id = au.id
WHERE pu.id IS NULL;

-- 2. Safety net: create missing user_profile rows
INSERT INTO public.user_profile (id_user)
SELECT u.id
FROM public.users u
LEFT JOIN public.user_profile up ON up.id_user = u.id
WHERE up.id IS NULL;
