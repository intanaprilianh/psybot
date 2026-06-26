-- Add gender and phone number columns to user_profile
-- These fields are collected during onboarding but were missing from the schema

ALTER TABLE public.user_profile
  ADD COLUMN IF NOT EXISTS jenis_kelamin TEXT,
  ADD COLUMN IF NOT EXISTS no_telp TEXT;
