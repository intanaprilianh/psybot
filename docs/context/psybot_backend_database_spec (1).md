# PsyBot — Backend & Database: Full Engineering Specification

> **Role:** Senior Software Engineer  
> **Target:** AI executor (backend + database setup, production-ready)  
> **Stack:** Flutter · Supabase (PostgreSQL + Auth + Storage + Edge Functions) · OpenAI/Gemini API · FCM · Midtrans  
> **Compliance:** UU PDP No. 27/2022 · HIPAA-aligned best practices

---

## Table of Contents

1. [Project Context & Architecture](#1-project-context--architecture)
2. [Development Environment Setup](#2-development-environment-setup)
3. [Phase 1 — Supabase Project & Database Migration](#3-phase-1--supabase-project--database-migration)
4. [Phase 2 — Row Level Security (RLS) Policies](#4-phase-2--row-level-security-rls-policies)
5. [Phase 3 — Authentication System](#5-phase-3--authentication-system)
6. [Phase 4 — AI Backend Integration](#6-phase-4--ai-backend-integration)
7. [Phase 5 — Security Layer (E2EE, RBAC, Audit)](#7-phase-5--security-layer-e2ee-rbac-audit)
8. [Phase 6 — Notification Service (FCM)](#8-phase-6--notification-service-fcm)
9. [Phase 7 — Payment Gateway (Midtrans)](#9-phase-7--payment-gateway-midtrans)
10. [Phase 8 — API Contract for Flutter](#10-phase-8--api-contract-for-flutter)
11. [Phase 9 — Testing Strategy](#11-phase-9--testing-strategy)
12. [Phase 10 — Deployment & CI/CD](#12-phase-10--deployment--cicd)
13. [Environment Variables Reference](#13-environment-variables-reference)
14. [Error Handling Standard](#14-error-handling-standard)

---

## 1. Project Context & Architecture

### 1.1 Tentang PsyBot

PsyBot adalah aplikasi mobile kesehatan mental yang dirancang sebagai **ruang aman awal** bagi pengguna — terutama mahasiswa dan anak kos — untuk mengenali kondisi emosionalnya. Aplikasi ini **bukan alat diagnosis medis**. Fungsinya adalah:

- **Chatbot AI empatik** dengan guardrails ketat (tidak boleh mendiagnosis)
- **Deteksi risiko berbasis percakapan** — AI belajar dari pola kata dan konteks kalimat, bukan kuesioner terstruktur
- **Notifikasi call center** — saat AI mendeteksi sinyal bahaya, pengguna *ditawarkan* (bukan dipaksa) menghubungi layanan bantuan krisis
- **Pilihan ada di tangan pengguna** — pengguna bebas memilih untuk menghubungi atau tidak
- **Telehealth** — booking konsultasi dengan psikolog/psikiater
- **Enkripsi end-to-end** pada semua percakapan (UU PDP compliant)

### 1.2 Architecture Decision Records (ADRs)

| Keputusan | Pilihan | Alasan |
|-----------|---------|--------|
| Backend-as-a-Service | **Supabase** | PostgreSQL + Auth + Storage + Edge Functions dalam satu platform; open-source; RLS native |
| AI LLM | **OpenAI GPT-4o** (primary) / Gemini 2.0 Flash (fallback) | GPT-4o terbaik untuk empati + instruction following; fallback cost optimization |
| Risk Detection | **Hybrid**: keyword dict + LLM context analysis | Keyword untuk latensi rendah; LLM untuk analisis konteks dan nuansa bahasa percakapan |
| Call Center Referral | **Opt-in user choice** | Pengguna tidak dipaksa menghubungi; pilihan ada di tangan mereka |
| Encryption | **AES-256-GCM** pada kolom `isi_pesan_terenkripsi` | Kolom sensitif dienkripsi di application layer sebelum masuk DB |
| Notifications | **FCM via Supabase Edge Function** | Satu endpoint; support Android + iOS |
| Payment | **Midtrans** | PCI DSS compliant; support QRIS, GoPay, Bank Transfer |
| State Management (Flutter) | **Riverpod** | Diserahkan ke tim frontend; backend hanya perlu expose REST/Realtime API |

### 1.3 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        FLUTTER APP                               │
│  (Android / iOS — UI layer, state management, local encryption) │
└────────────────────────┬────────────────────────────────────────┘
                         │ HTTPS / WebSocket (Supabase Realtime)
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SUPABASE PLATFORM                             │
│                                                                  │
│  ┌──────────┐  ┌──────────────┐  ┌───────────┐  ┌──────────┐   │
│  │ Auth     │  │ PostgreSQL   │  │  Storage  │  │  Edge    │   │
│  │ (JWT +   │  │ (11 tables + │  │ (avatars, │  │  Fns     │   │
│  │ refresh) │  │  RLS + audit)│  │  consent) │  │ (AI, FCM,│   │
│  └──────────┘  └──────────────┘  └───────────┘  │  pay)    │   │
│                                                   └──────────┘   │
└──────────────────────────────┬──────────────────────────────────┘
                               │
        ┌──────────────────────┼───────────────────┐
        ▼                      ▼                   ▼
┌──────────────┐   ┌────────────────────┐  ┌────────────────┐
│ OpenAI API   │   │  FCM (Firebase)    │  │  Midtrans API  │
│ GPT-4o       │   │  Push Notification │  │  Payment GW    │
└──────────────┘   └────────────────────┘  └────────────────┘
```

### 1.4 User Roles

| Role | Deskripsi | Akses |
|------|-----------|-------|
| `user` | Pengguna umum (mahasiswa/masyarakat) | Data miliknya sendiri |
| `professional` | Psikolog / Psikiater terdaftar | Data user yang sudah consent + dashboard |
| `admin` | Admin sistem | Semua data (audit only) |
| `service_role` | Supabase internal / Edge Functions | Bypass RLS (server-side only) |

---

## 2. Development Environment Setup

### 2.1 Prerequisites

```bash
# Install Supabase CLI
npm install -g supabase

# Install Deno (untuk Edge Functions)
curl -fsSL https://deno.land/x/install/install.sh | sh

# Login ke Supabase
supabase login

# Inisialisasi project (jalankan di root folder project)
supabase init
```

### 2.2 Project Structure

```
psybot-backend/
├── supabase/
│   ├── config.toml                # Supabase project config
│   ├── migrations/
│   │   ├── 001_create_users.sql
│   │   ├── 002_create_user_profile.sql
│   │   ├── 003_create_chat_sessions.sql
│   │   ├── 004_create_messages.sql
│   │   ├── 005_create_risk_alerts.sql
│   │   ├── 006_create_consultations.sql
│   │   ├── 007_create_professionals.sql
│   │   ├── 008_create_payment_transactions.sql
│   │   ├── 009_create_self_help_content.sql
│   │   ├── 010_create_audit_logs.sql
│   │   ├── 011_rls_policies.sql
│   │   ├── 012_indexes.sql
│   │   └── 013_triggers.sql
│   ├── functions/
│   │   ├── ai-chat/
│   │   │   └── index.ts           # LLM + risk detection dari percakapan
│   │   ├── risk-escalation/
│   │   │   └── index.ts           # Kirim info call center ke user (opt-in)
│   │   ├── send-notification/
│   │   │   └── index.ts           # FCM push notification
│   │   ├── payment-webhook/
│   │   │   └── index.ts           # Midtrans webhook handler
│   │   └── _shared/
│   │       ├── encryption.ts      # AES-256-GCM helpers
│   │       ├── risk-keywords.ts   # Kamus kata kunci bahaya (ID)
│   │       ├── call-center.ts     # Daftar layanan krisis mental health
│   │       └── cors.ts            # CORS headers
│   └── seed.sql                   # Data awal (self_help_content, dll)
├── .env.local                     # Secrets lokal (JANGAN di-commit)
└── README.md
```

### 2.3 Supabase Config (config.toml)

```toml
# supabase/config.toml
[api]
port = 54321
schemas = ["public", "storage", "auth"]
extra_search_path = ["public", "extensions"]
max_rows = 1000

[db]
port = 54322
major_version = 15

[studio]
port = 54323

[auth]
site_url = "psybot://callback"
additional_redirect_urls = ["https://psybot.app/callback"]
jwt_expiry = 3600
enable_refresh_token_rotation = true
refresh_token_reuse_interval = 10
enable_signup = true
email_double_confirm_changes = true
email_enable_signup = true

[auth.email]
enable_signup = true
double_confirm_changes = true
enable_confirmations = true

[edge_runtime]
policy = "per_worker"

[analytics]
enabled = false
```

---

## 3. Phase 1 — Supabase Project & Database Migration

> **Eksekusi urutan**: Jalankan migration files secara berurutan (001 → 014). Gunakan `supabase db push` atau jalankan langsung di SQL editor Supabase dashboard.

### 3.1 Enable Extensions

```sql
-- supabase/migrations/000_extensions.sql
-- Aktifkan extensions yang diperlukan
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";  -- Untuk full-text search nama profesional
```

### 3.2 Migration 001 — Tabel `users`

```sql
-- supabase/migrations/001_create_users.sql
-- CATATAN: Supabase Auth mengelola tabel auth.users secara internal.
-- Tabel ini adalah extension public untuk data tambahan yang tidak ada di auth.users.
-- Sinkronisasi dilakukan via trigger.

CREATE TABLE public.users (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nama            TEXT NOT NULL CHECK (char_length(nama) BETWEEN 2 AND 100),
  email           TEXT NOT NULL UNIQUE CHECK (email ~* '^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$'),
  role            TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'professional', 'admin')),
  tanggal_daftar  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- password_hash tidak disimpan di sini — dikelola Supabase Auth
  status_akun     TEXT NOT NULL DEFAULT 'active' CHECK (status_akun IN ('active', 'suspended', 'deleted')),
  last_login      TIMESTAMPTZ,
  email_verified  BOOLEAN NOT NULL DEFAULT FALSE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index untuk query performa
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_role ON public.users(role);
CREATE INDEX idx_users_status ON public.users(status_akun);

-- Trigger: auto-sync saat user baru dibuat via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.users (id, nama, email, email_verified)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'nama', split_part(NEW.email, '@', 1)),
    NEW.email,
    NEW.email_confirmed_at IS NOT NULL
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger: sync email_verified saat email dikonfirmasi
CREATE OR REPLACE FUNCTION public.handle_user_email_confirmed()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF OLD.email_confirmed_at IS NULL AND NEW.email_confirmed_at IS NOT NULL THEN
    UPDATE public.users
    SET email_verified = TRUE, updated_at = NOW()
    WHERE id = NEW.id;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_email_confirmed
  AFTER UPDATE ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_user_email_confirmed();

-- Trigger: auto-update `updated_at`
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

CREATE TRIGGER users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.users IS 'Extension dari auth.users — menyimpan data profil publik dan role pengguna PsyBot.';
```

### 3.3 Migration 002 — Tabel `user_profile`

```sql
-- supabase/migrations/002_create_user_profile.sql
CREATE TABLE public.user_profile (
  id                   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_user              UUID NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE CASCADE,
  usia                 INTEGER CHECK (usia BETWEEN 13 AND 120),
  status               TEXT CHECK (status IN ('mahasiswa', 'karyawan', 'umum', 'lainnya')),
  institusi            TEXT CHECK (char_length(institusi) <= 200),   -- nama kampus/kantor (opsional)
  preferensi_privasi   JSONB NOT NULL DEFAULT '{"anonymous_mode": false, "share_with_professional": false}'::jsonb,
  consent_diberikan    BOOLEAN NOT NULL DEFAULT FALSE,
  consent_timestamp    TIMESTAMPTZ,
  consent_version      TEXT,                                          -- e.g. "v1.2"
  onboarding_complete  BOOLEAN NOT NULL DEFAULT FALSE,
  avatar_url           TEXT,                                          -- Supabase Storage URL
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
```

### 3.4 Migration 003 — Tabel `chat_sessions`

```sql
-- supabase/migrations/003_create_chat_sessions.sql
CREATE TABLE public.chat_sessions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_user         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  tanggal         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status_risiko   TEXT NOT NULL DEFAULT 'low' CHECK (status_risiko IN ('low', 'medium', 'high', 'critical')),
  status_sesi     TEXT NOT NULL DEFAULT 'active' CHECK (status_sesi IN ('active', 'closed', 'escalated')),
  -- Ringkasan singkat sesi (diisi oleh AI di akhir sesi, TIDAK mengandung detail sensitif)
  summary         TEXT,
  -- Mood score 1-10 (diisi AI berdasarkan analisis sentimen sesi)
  mood_score      SMALLINT CHECK (mood_score BETWEEN 1 AND 10),
  pesan_count     INTEGER NOT NULL DEFAULT 0,
  ditutup_pada    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_chat_sessions_id_user ON public.chat_sessions(id_user);
CREATE INDEX idx_chat_sessions_tanggal ON public.chat_sessions(tanggal DESC);
CREATE INDEX idx_chat_sessions_risiko ON public.chat_sessions(status_risiko) WHERE status_risiko IN ('high', 'critical');
CREATE INDEX idx_chat_sessions_aktif ON public.chat_sessions(id_user, status_sesi) WHERE status_sesi = 'active';

CREATE TRIGGER chat_sessions_updated_at
  BEFORE UPDATE ON public.chat_sessions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.chat_sessions IS 'Ringkasan sesi chatbot. Konten percakapan detail ada di tabel messages (terenkripsi).';
```

### 3.5 Migration 004 — Tabel `messages`

```sql
-- supabase/migrations/004_create_messages.sql
-- KRITIS: isi_pesan_terenkripsi adalah kolom sensitif.
-- Enkripsi dilakukan di APPLICATION LAYER (Edge Function / Flutter)
-- menggunakan AES-256-GCM SEBELUM data masuk database.
-- Database hanya menyimpan ciphertext.

CREATE TABLE public.messages (
  id                     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_session             UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
  -- Siapa pengirim pesan
  pengirim_tipe          TEXT NOT NULL CHECK (pengirim_tipe IN ('user', 'ai', 'professional')),
  -- Teks terenkripsi: format "iv:ciphertext:authTag" (base64url)
  isi_pesan_terenkripsi  TEXT NOT NULL,
  -- IV (initialization vector) — disimpan terpisah untuk kemudahan dekripsi
  iv                     TEXT NOT NULL,
  -- Apakah pesan ini memicu flag risiko oleh sistem deteksi
  is_flagged             BOOLEAN NOT NULL DEFAULT FALSE,
  -- Alasan flag (diisi sistem, bukan AI)
  flag_reason            TEXT CHECK (flag_reason IN ('keyword_detected', 'high_phq_score', 'manual_review')),
  -- Soft delete: pesan tidak benar-benar dihapus dari DB, hanya ditandai
  deleted_at             TIMESTAMPTZ,
  waktu                  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_id_session ON public.messages(id_session);
CREATE INDEX idx_messages_waktu ON public.messages(waktu DESC);
CREATE INDEX idx_messages_flagged ON public.messages(is_flagged) WHERE is_flagged = TRUE;
-- Excludes soft-deleted messages dari hasil normal query
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
```

### 3.6 Migration 005 — Tabel `risk_alerts`

```sql
-- supabase/migrations/005_create_risk_alerts.sql
-- Filosofi: risk_alert dibuat saat AI mendeteksi sinyal bahaya dari percakapan.
-- Sistem TIDAK otomatis menghubungi profesional. Pengguna MEMILIH apakah
-- ingin menghubungi call center atau tidak. Pilihan itu juga dicatat di sini.

CREATE TABLE public.risk_alerts (
  id                       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_user                  UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  id_session               UUID REFERENCES public.chat_sessions(id) ON DELETE SET NULL,
  kategori_risiko          TEXT NOT NULL CHECK (kategori_risiko IN ('low', 'medium', 'high', 'critical')),
  -- Apa yang memicu alert (konteks dari percakapan, bukan skor tes)
  trigger                  TEXT NOT NULL,  -- e.g., "keyword: mau mati", "konteks: ekspresi keputusasaan berulang"
  -- Tipe deteksi
  escalation_type          TEXT NOT NULL CHECK (escalation_type IN (
                              'keyword_detected',     -- Kata kunci eksplisit terdeteksi
                              'ai_context_analysis',  -- AI mendeteksi dari konteks percakapan
                              'manual'                -- Dipicu manual oleh profesional/admin
                            )),
  -- Apakah user diberikan opsi call center
  call_center_offered      BOOLEAN NOT NULL DEFAULT FALSE,
  -- Apakah user memilih untuk menghubungi call center
  -- NULL = belum ada pilihan, TRUE = ya, FALSE = tidak/abaikan
  call_center_contacted    BOOLEAN,
  call_center_name         TEXT,  -- Nama layanan yang dipilih user (jika ada)
  user_responded_at        TIMESTAMPTZ,
  -- Siapa yang menerima notifikasi monitoring (opsional, bukan rute wajib)
  id_professional_notified UUID REFERENCES public.professionals(id) ON DELETE SET NULL,
  notified_at              TIMESTAMPTZ,
  -- Status penanganan
  status_tindak_lanjut     TEXT NOT NULL DEFAULT 'pending' CHECK (status_tindak_lanjut IN (
                              'pending',              -- Belum ada tindakan
                              'call_center_offered',  -- Opsi call center sudah ditampilkan ke user
                              'user_contacted',       -- User memilih menghubungi call center
                              'user_declined',        -- User memilih tidak menghubungi
                              'professional_followup',-- Profesional melakukan tindak lanjut
                              'resolved',             -- Sudah ditangani
                              'false_positive'        -- Ternyata bukan risiko nyata
                            )),
  catatan_profesional      TEXT,
  resolved_at              TIMESTAMPTZ,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_risk_alerts_id_user ON public.risk_alerts(id_user);
CREATE INDEX idx_risk_alerts_status ON public.risk_alerts(status_tindak_lanjut) WHERE status_tindak_lanjut = 'pending';
CREATE INDEX idx_risk_alerts_kategori ON public.risk_alerts(kategori_risiko);
CREATE INDEX idx_risk_alerts_professional ON public.risk_alerts(id_professional_notified) WHERE id_professional_notified IS NOT NULL;
CREATE INDEX idx_risk_alerts_created ON public.risk_alerts(created_at DESC);

CREATE TRIGGER risk_alerts_updated_at
  BEFORE UPDATE ON public.risk_alerts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.risk_alerts IS 'Log deteksi sinyal bahaya dari percakapan AI. Pengguna MEMILIH apakah ingin menghubungi call center — tidak ada eskalasi paksa.';
COMMENT ON COLUMN public.risk_alerts.call_center_contacted IS 'NULL = pilihan belum ditampilkan/dibuat. TRUE = user memilih menghubungi. FALSE = user memilih melewati.';
```

### 3.7 Migration 006 — Tabel `professionals`

```sql
-- supabase/migrations/006_create_professionals.sql
-- CATATAN: Profesional juga memiliki akun di auth.users dengan role='professional'
CREATE TABLE public.professionals (
  id                UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  spesialisasi      TEXT NOT NULL CHECK (spesialisasi IN ('psikolog', 'psikiater', 'konselor')),
  nomor_lisensi     TEXT UNIQUE,                              -- No. SIPP/STR
  foto_url          TEXT,                                     -- Supabase Storage
  bio               TEXT CHECK (char_length(bio) <= 1000),
  tarif_per_sesi    INTEGER CHECK (tarif_per_sesi >= 0),      -- Rupiah
  tarif_gratis      BOOLEAN NOT NULL DEFAULT FALSE,           -- Untuk konselor kampus
  jadwal_aktif      JSONB NOT NULL DEFAULT '[]'::jsonb,       -- Array slot waktu tersedia
  rating            NUMERIC(3,2) CHECK (rating BETWEEN 0 AND 5),
  total_sesi        INTEGER NOT NULL DEFAULT 0,
  status_verified   BOOLEAN NOT NULL DEFAULT FALSE,           -- Diverifikasi admin
  status_online     BOOLEAN NOT NULL DEFAULT FALSE,           -- Sedang online/tersedia
  institusi_afiliasi TEXT,                                    -- Kampus/klinik afiliasi
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_professionals_spesialisasi ON public.professionals(spesialisasi);
CREATE INDEX idx_professionals_verified ON public.professionals(status_verified) WHERE status_verified = TRUE;
CREATE INDEX idx_professionals_online ON public.professionals(status_online) WHERE status_online = TRUE;
-- Full-text search nama profesional
CREATE INDEX idx_professionals_nama_fts ON public.users USING gin(to_tsvector('indonesian', nama))
  WHERE id IN (SELECT id FROM public.professionals);

CREATE TRIGGER professionals_updated_at
  BEFORE UPDATE ON public.professionals
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.professionals IS 'Profil tenaga profesional kesehatan mental. Hanya profesional yang status_verified=TRUE yang tampil ke pengguna.';
COMMENT ON COLUMN public.professionals.jadwal_aktif IS 'Format JSON: [{"hari": "senin", "mulai": "09:00", "selesai": "17:00"}, ...]';
```

### 3.8 Migration 007 — Tabel `consultations`

```sql
-- supabase/migrations/007_create_consultations.sql
CREATE TABLE public.consultations (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_user               UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  id_professional       UUID NOT NULL REFERENCES public.professionals(id),
  jadwal                TIMESTAMPTZ NOT NULL,
  durasi_menit          INTEGER NOT NULL DEFAULT 60 CHECK (durasi_menit IN (30, 60, 90)),
  status                TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
                          'pending',    -- Menunggu konfirmasi profesional
                          'confirmed',  -- Dikonfirmasi
                          'ongoing',    -- Sedang berlangsung
                          'completed',  -- Selesai
                          'cancelled',  -- Dibatalkan
                          'no_show'     -- User tidak hadir
                        )),
  jenis_konsultasi      TEXT NOT NULL CHECK (jenis_konsultasi IN ('chat', 'video_call', 'voice_call')),
  platform_url          TEXT,                                  -- Jitsi/Whereby room URL
  -- Catatan profesional (terenkripsi di app layer sebelum disimpan)
  catatan_professional  TEXT,
  catatan_terenkripsi   BOOLEAN NOT NULL DEFAULT TRUE,
  status_pembayaran     TEXT NOT NULL DEFAULT 'unpaid' CHECK (status_pembayaran IN (
                          'unpaid', 'pending', 'paid', 'refunded', 'free'
                        )),
  id_transaksi          UUID REFERENCES public.payment_transactions(id) ON DELETE SET NULL,
  -- Flag untuk sesi darurat (dari risk_alert)
  is_emergency          BOOLEAN NOT NULL DEFAULT FALSE,
  id_risk_alert         UUID REFERENCES public.risk_alerts(id) ON DELETE SET NULL,
  cancel_reason         TEXT,
  cancelled_at          TIMESTAMPTZ,
  completed_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_consultations_id_user ON public.consultations(id_user);
CREATE INDEX idx_consultations_id_professional ON public.consultations(id_professional);
CREATE INDEX idx_consultations_jadwal ON public.consultations(jadwal);
CREATE INDEX idx_consultations_status ON public.consultations(status);
CREATE INDEX idx_consultations_emergency ON public.consultations(is_emergency) WHERE is_emergency = TRUE;

CREATE TRIGGER consultations_updated_at
  BEFORE UPDATE ON public.consultations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Trigger: update total_sesi profesional setelah konsultasi selesai
CREATE OR REPLACE FUNCTION public.update_professional_total_sesi()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'completed' AND (OLD.status IS DISTINCT FROM 'completed') THEN
    UPDATE public.professionals
    SET total_sesi = total_sesi + 1,
        updated_at = NOW()
    WHERE id = NEW.id_professional;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER consultations_complete_update_professional
  AFTER UPDATE ON public.consultations
  FOR EACH ROW EXECUTE FUNCTION public.update_professional_total_sesi();

COMMENT ON TABLE public.consultations IS 'Jadwal dan riwayat konsultasi antara user dan profesional.';
```

### 3.9 Migration 008 — Tabel `payment_transactions`

```sql
-- supabase/migrations/008_create_payment_transactions.sql
CREATE TABLE public.payment_transactions (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  id_user         UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  -- Referensi ke consultations (foreign key di consultations.id_transaksi)
  amount          INTEGER NOT NULL CHECK (amount >= 0),       -- Rupiah
  status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN (
                    'pending',   -- Dibuat, menunggu pembayaran
                    'success',   -- Pembayaran berhasil
                    'failed',    -- Pembayaran gagal
                    'expired',   -- Timeout
                    'refunded',  -- Dana dikembalikan
                    'cancelled'  -- Dibatalkan sebelum bayar
                  )),
  -- Midtrans order ID (unique per transaksi)
  order_id        TEXT NOT NULL UNIQUE,
  -- Midtrans transaction ID (diisi setelah payment sukses)
  gateway_ref     TEXT,
  -- Metode pembayaran yang digunakan
  payment_method  TEXT CHECK (payment_method IN ('qris', 'gopay', 'ovo', 'bca_va', 'bni_va', 'mandiri_va', 'bri_va', 'permata_va', 'dana', 'linkaja', 'credit_card')),
  -- Snap token dari Midtrans (kadaluarsa 24 jam)
  snap_token      TEXT,
  snap_redirect_url TEXT,
  -- Webhook payload dari Midtrans (untuk audit)
  midtrans_payload JSONB,
  expired_at      TIMESTAMPTZ,
  paid_at         TIMESTAMPTZ,
  timestamp       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payment_id_user ON public.payment_transactions(id_user);
CREATE INDEX idx_payment_status ON public.payment_transactions(status);
CREATE INDEX idx_payment_order_id ON public.payment_transactions(order_id);
CREATE INDEX idx_payment_timestamp ON public.payment_transactions(timestamp DESC);

CREATE TRIGGER payment_transactions_updated_at
  BEFORE UPDATE ON public.payment_transactions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.payment_transactions IS 'Riwayat transaksi Midtrans. midtrans_payload disimpan untuk keperluan audit dan reconciliation.';
```

### 3.10 Migration 009 — Tabel `self_help_content`

```sql
-- supabase/migrations/009_create_self_help_content.sql
-- Konten self-help direkomendasikan berdasarkan KATEGORI RISIKO dari percakapan,
-- bukan berdasarkan skor kuesioner terstruktur.
CREATE TABLE public.self_help_content (
  id               UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  kategori         TEXT NOT NULL CHECK (kategori IN (
                     'mindfulness',
                     'relaksasi',
                     'journaling',
                     'olahraga_ringan',
                     'cognitive_restructuring',
                     'breathing_exercise',
                     'social_support',
                     'edukasi_mental_health',
                     'krisis'                   -- Konten untuk kondisi high/critical risk
                   )),
  judul            TEXT NOT NULL CHECK (char_length(judul) BETWEEN 3 AND 200),
  konten           TEXT NOT NULL,
  konten_html      TEXT,
  durasi_menit     INTEGER,
  -- Konten ini relevan untuk risk level mana (bisa multiple via array)
  -- e.g. ['low', 'medium'] atau ['high', 'critical']
  target_risk_level TEXT[] NOT NULL DEFAULT '{low,medium}',
  urutan           INTEGER NOT NULL DEFAULT 100,
  aktif            BOOLEAN NOT NULL DEFAULT TRUE,
  thumbnail_url    TEXT,
  tags             TEXT[],
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_self_help_kategori ON public.self_help_content(kategori);
CREATE INDEX idx_self_help_risk ON public.self_help_content USING gin(target_risk_level);
CREATE INDEX idx_self_help_aktif ON public.self_help_content(aktif) WHERE aktif = TRUE;

CREATE TRIGGER self_help_content_updated_at
  BEFORE UPDATE ON public.self_help_content
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

COMMENT ON TABLE public.self_help_content IS 'Konten edukasi dan teknik self-help. Direkomendasikan berdasarkan risk level yang terdeteksi dari percakapan AI, bukan skor kuesioner.';
COMMENT ON COLUMN public.self_help_content.target_risk_level IS 'Array risk level yang relevan: low, medium, high, critical.';
```

### 3.11 Migration 010 — Tabel `audit_logs`

```sql
-- supabase/migrations/010_create_audit_logs.sql
-- Tabel ini adalah append-only (INSERT only, tidak boleh UPDATE/DELETE)
CREATE TABLE public.audit_logs (
  id              BIGSERIAL PRIMARY KEY,
  -- Siapa yang melakukan aksi
  aktor_id        UUID,                                        -- null = system action
  aktor_tipe      TEXT NOT NULL CHECK (aktor_tipe IN ('user', 'professional', 'admin', 'system', 'edge_function')),
  -- Apa yang dilakukan
  aksi            TEXT NOT NULL,                               -- e.g. 'login', 'view_messages', 'update_consent'
  -- Pada resource apa
  resource_tipe   TEXT,                                        -- e.g. 'messages', 'risk_alerts', 'consultations'
  resource_id     UUID,
  -- Detail tambahan (JSON — JANGAN simpan data sensitif di sini)
  detail          JSONB,
  -- Metadata
  ip_address      INET,
  user_agent      TEXT,
  -- Apakah aksi ini sukses
  sukses          BOOLEAN NOT NULL DEFAULT TRUE,
  error_message   TEXT,
  timestamp       TIMESTAMPTZ NOT NULL DEFAULT NOW()
  -- Tidak ada updated_at karena tabel ini append-only
);

-- Partisi berdasarkan bulan untuk performa (opsional, enable jika data > 1 juta baris/bulan)
-- Untuk skala awal, tanpa partisi sudah cukup.

CREATE INDEX idx_audit_aktor ON public.audit_logs(aktor_id);
CREATE INDEX idx_audit_aksi ON public.audit_logs(aksi);
CREATE INDEX idx_audit_resource ON public.audit_logs(resource_tipe, resource_id);
CREATE INDEX idx_audit_timestamp ON public.audit_logs(timestamp DESC);

-- Prevent UPDATE dan DELETE pada audit_logs (append-only enforcement)
CREATE OR REPLACE RULE audit_logs_no_update AS
  ON UPDATE TO public.audit_logs DO INSTEAD NOTHING;

CREATE OR REPLACE RULE audit_logs_no_delete AS
  ON DELETE TO public.audit_logs DO INSTEAD NOTHING;

-- Helper function untuk insert audit log dengan mudah dari Edge Functions
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
```

---

## 4. Phase 2 — Row Level Security (RLS) Policies

> **Prinsip**: Setiap pengguna hanya bisa mengakses data miliknya sendiri. Profesional hanya bisa mengakses data user yang sudah memberikan consent. Admin hanya lewat service_role.

```sql
-- supabase/migrations/011_rls_policies.sql

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
-- User bisa lihat profil sendiri
CREATE POLICY "users_select_own" ON public.users
  FOR SELECT USING (auth.uid() = id);

-- User bisa update nama (tidak bisa ubah role/status)
CREATE POLICY "users_update_own" ON public.users
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id AND role = 'user' AND status_akun = 'active');

-- Profesional bisa lihat nama user yang sudah consent
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

-- Insert dibuat otomatis oleh trigger, tidak perlu policy khusus
-- (trigger menggunakan SECURITY DEFINER)

-- Profesional bisa lihat profile user yang sudah consent
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

-- Profesional bisa lihat sesi (ringkasan, bukan isi pesan) user yang consent
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
-- User hanya bisa lihat pesan di sesinya sendiri
CREATE POLICY "messages_select_own_session" ON public.messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.chat_sessions cs
      WHERE cs.id = messages.id_session
        AND cs.id_user = auth.uid()
    )
    AND deleted_at IS NULL
  );

-- Insert pesan hanya via Edge Function (SECURITY DEFINER) — user tidak langsung insert
-- Ini mencegah user memasukkan plaintext ke database
-- Policy ini sengaja restrictive:
CREATE POLICY "messages_insert_via_function" ON public.messages
  FOR INSERT WITH CHECK (FALSE);  -- Hanya bisa via SECURITY DEFINER function/trigger

-- Profesional bisa lihat pesan (ciphertext) session user yang consent + terlibat konsultasi
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
-- User bisa lihat alert miliknya + update pilihan call center mereka
CREATE POLICY "risk_alerts_select_own" ON public.risk_alerts
  FOR SELECT USING (auth.uid() = id_user);

-- User bisa update HANYA kolom pilihan call center mereka sendiri
CREATE POLICY "risk_alerts_user_update_callcenter" ON public.risk_alerts
  FOR UPDATE USING (auth.uid() = id_user)
  WITH CHECK (auth.uid() = id_user);

-- Insert hanya via system/edge function
CREATE POLICY "risk_alerts_insert_system" ON public.risk_alerts
  FOR INSERT WITH CHECK (FALSE);  -- Hanya via SECURITY DEFINER

-- Profesional bisa lihat dan update alert yang di-assign ke mereka (monitoring)
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
-- Semua authenticated user bisa lihat daftar profesional verified
CREATE POLICY "professionals_select_verified" ON public.professionals
  FOR SELECT USING (status_verified = TRUE);

-- Profesional bisa update data mereka sendiri
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

-- Update status pembayaran hanya via webhook handler (SECURITY DEFINER)
CREATE POLICY "payment_update_system" ON public.payment_transactions
  FOR UPDATE USING (FALSE);  -- Hanya via SECURITY DEFINER

-- ==========================================
-- TABEL: self_help_content
-- ==========================================
-- Semua authenticated user bisa baca konten aktif
CREATE POLICY "self_help_select_active" ON public.self_help_content
  FOR SELECT USING (aktif = TRUE);

-- ==========================================
-- TABEL: audit_logs
-- ==========================================
-- Hanya admin (via service_role) yang bisa baca audit logs
-- User dan profesional tidak bisa akses langsung
CREATE POLICY "audit_logs_admin_only" ON public.audit_logs
  FOR SELECT USING (FALSE);  -- Akses hanya via service_role (bypass RLS)

-- Insert via service_role / SECURITY DEFINER function log_audit()
CREATE POLICY "audit_logs_insert_system" ON public.audit_logs
  FOR INSERT WITH CHECK (FALSE);
```

---

## 5. Phase 3 — Authentication System

### 5.1 Supabase Auth Configuration

Konfigurasi di Supabase Dashboard → Authentication → Settings:

```
Site URL: psybot://callback (untuk deep link Flutter)
Additional redirect URLs:
  - https://psybot.app/callback
  - exp://192.168.x.x:8081 (untuk Expo dev, jika ada)

Email confirmations: ENABLED
JWT Expiry: 3600 (1 jam)
Refresh token rotation: ENABLED
Refresh token reuse interval: 10 detik
```

### 5.2 Edge Function: Custom JWT Claims

Supabase Auth secara default tidak memasukkan custom claims ke JWT. Kita perlu hook untuk menambahkan `role` ke token.

```typescript
// supabase/functions/auth-hook/index.ts
// CATATAN: Ini adalah Supabase Auth Hook — daftarkan di Dashboard → Auth → Hooks → Custom JWT Claims

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  const { user } = await req.json();
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );
  
  // Ambil role dari tabel users
  const { data } = await supabase
    .from('users')
    .select('role')
    .eq('id', user.id)
    .single();
  
  return new Response(
    JSON.stringify({
      ...user,
      user_metadata: {
        ...user.user_metadata,
        role: data?.role ?? 'user',
      },
      app_metadata: {
        ...user.app_metadata,
        role: data?.role ?? 'user',
      }
    }),
    { headers: { 'Content-Type': 'application/json' } }
  );
});
```

### 5.3 Rate Limiting & Brute Force Protection

Supabase Auth sudah built-in CAPTCHA support. Aktifkan di dashboard:

```
Auth → Settings → CAPTCHA provider: hCaptcha
CAPTCHA secret: [isi dari hCaptcha dashboard]
```

Tambahkan rate limiting di Edge Function untuk endpoint sensitif:

```typescript
// supabase/functions/_shared/rate-limiter.ts
const RATE_LIMIT_WINDOW = 60 * 1000; // 1 menit
const MAX_REQUESTS = 10;

const requestMap = new Map<string, { count: number; resetAt: number }>();

export function checkRateLimit(identifier: string): boolean {
  const now = Date.now();
  const entry = requestMap.get(identifier);
  
  if (!entry || now > entry.resetAt) {
    requestMap.set(identifier, { count: 1, resetAt: now + RATE_LIMIT_WINDOW });
    return true;
  }
  
  if (entry.count >= MAX_REQUESTS) return false;
  
  entry.count++;
  return true;
}
```

---

## 6. Phase 4 — AI Backend Integration

### 6.1 Shared: Kamus Kata Kunci Risiko (Bahasa Indonesia)

```typescript
// supabase/functions/_shared/risk-keywords.ts
// Dikembangkan bersama psikiater — HARUS divalidasi secara klinis sebelum production

export const CRITICAL_KEYWORDS = [
  // Kata kunci bunuh diri
  'bunuh diri', 'mau mati', 'ingin mati', 'sudah mau mati', 'tidak mau hidup lagi',
  'mengakhiri hidup', 'akhiri hidup', 'tidak ada gunanya hidup', 'lebih baik mati',
  'kapan aku mati', 'mau bunuh diri', 'mo bunuh diri', 'pengen mati aja',
  'tired of living', 'end my life', 'kill myself',
  // Self-harm
  'nyakitin diri', 'menyakiti diri', 'mau nyakitin diri sendiri',
  'potong diri', 'bakar diri', 'banting diri',
  'lukai diri', 'melukai diri',
];

export const HIGH_RISK_KEYWORDS = [
  'hopeless', 'tidak ada harapan', 'tidak ada yang peduli',
  'sendirian terus', 'tidak ada yang mau', 'tidak berguna',
  'beban buat semua', 'semua lebih baik tanpa aku',
  'sudah tidak kuat', 'tidak sanggup lagi', 'menyerah',
  'putus asa', 'cape banget hidup', 'capek hidup',
];

export const MEDIUM_RISK_KEYWORDS = [
  'sedih banget', 'nangis terus', 'tidak bisa tidur',
  'tidak nafsu makan', 'panic attack', 'anxiety',
  'depresi', 'galau banget', 'stress banget',
];

export type RiskLevel = 'critical' | 'high' | 'medium' | 'low';

export function detectRiskFromText(text: string): {
  level: RiskLevel;
  triggeredKeywords: string[];
} {
  const lowerText = text.toLowerCase();
  const triggered: string[] = [];
  
  for (const kw of CRITICAL_KEYWORDS) {
    if (lowerText.includes(kw)) triggered.push(kw);
  }
  if (triggered.length > 0) return { level: 'critical', triggeredKeywords: triggered };
  
  for (const kw of HIGH_RISK_KEYWORDS) {
    if (lowerText.includes(kw)) triggered.push(kw);
  }
  if (triggered.length > 0) return { level: 'high', triggeredKeywords: triggered };
  
  for (const kw of MEDIUM_RISK_KEYWORDS) {
    if (lowerText.includes(kw)) triggered.push(kw);
  }
  if (triggered.length > 0) return { level: 'medium', triggeredKeywords: triggered };
  
  return { level: 'low', triggeredKeywords: [] };
}
```

### 6.2 Shared: Daftar Layanan Krisis Mental Health

```typescript
// supabase/functions/_shared/call-center.ts
// Daftar layanan bantuan krisis yang ditampilkan ke pengguna saat AI mendeteksi risiko.
// PENTING: verifikasi nomor aktif secara berkala — nomor bisa berubah.

export interface CallCenterService {
  id: string;
  nama: string;
  deskripsi: string;
  nomor: string;        // Format: tel:+62...
  jam_operasional: string;
  tipe: 'telepon' | 'chat' | 'whatsapp';
  gratis: boolean;
  url?: string;
}

export const CALL_CENTER_SERVICES: CallCenterService[] = [
  {
    id: 'kemenkes_119',
    nama: 'Hotline Kemenkes RI',
    deskripsi: 'Layanan darurat kesehatan termasuk krisis mental, tersedia 24 jam',
    nomor: 'tel:119',
    jam_operasional: '24 jam / 7 hari',
    tipe: 'telepon',
    gratis: true,
  },
  {
    id: 'into_the_light',
    nama: 'Into The Light Indonesia',
    deskripsi: 'Layanan pencegahan bunuh diri dan dukungan kesehatan mental',
    nomor: 'tel:119',
    jam_operasional: '24 jam (ext 8)',
    tipe: 'telepon',
    gratis: true,
    url: 'https://www.intothelightid.org',
  },
  {
    id: 'yayasan_pulih',
    nama: 'Yayasan Pulih',
    deskripsi: 'Konseling psikologis dan dukungan mental health',
    nomor: 'tel:+62217884258',
    jam_operasional: 'Senin–Jumat 09.00–17.00',
    tipe: 'telepon',
    gratis: false,
    url: 'https://www.yayasanpulih.org',
  },
  {
    id: 'sebaya_id',
    nama: 'Sebaya.id',
    deskripsi: 'Dukungan sebaya untuk kesehatan mental remaja dan mahasiswa',
    nomor: 'tel:+6281287877788',
    jam_operasional: 'Senin–Sabtu 08.00–22.00',
    tipe: 'whatsapp',
    gratis: true,
    url: 'https://www.sebaya.id',
  },
  {
    id: 'rsj_cisarua',
    nama: 'RSJ Amino Gondohutomo (Jawa Tengah)',
    deskripsi: 'Hotline Rumah Sakit Jiwa Provinsi',
    nomor: 'tel:+62245860038',
    jam_operasional: '24 jam',
    tipe: 'telepon',
    gratis: false,
  },
];

// Filter berdasarkan risk level — untuk high/critical tampilkan lebih banyak
export function getServicesForRiskLevel(level: 'high' | 'critical'): CallCenterService[] {
  if (level === 'critical') {
    // Prioritaskan yang 24 jam untuk critical
    return CALL_CENTER_SERVICES.filter(s =>
      s.jam_operasional.includes('24 jam') || s.id === 'into_the_light'
    );
  }
  // high: semua layanan
  return CALL_CENTER_SERVICES;
}
```

### 6.2 Shared: Enkripsi AES-256-GCM

```typescript
// supabase/functions/_shared/encryption.ts
// Semua pesan HARUS dienkripsi sebelum masuk database

const ENCRYPTION_KEY_HEX = Deno.env.get('MESSAGE_ENCRYPTION_KEY')!;
// KEY harus 32 byte (256-bit) — generate dengan: openssl rand -hex 32

async function getKey(): Promise<CryptoKey> {
  const keyBytes = hexToBytes(ENCRYPTION_KEY_HEX);
  return await crypto.subtle.importKey(
    'raw',
    keyBytes,
    { name: 'AES-GCM' },
    false,
    ['encrypt', 'decrypt']
  );
}

export async function encryptMessage(plaintext: string): Promise<{
  ciphertext: string;  // base64url
  iv: string;          // base64url
}> {
  const key = await getKey();
  const iv = crypto.getRandomValues(new Uint8Array(12)); // 96-bit IV
  const encoded = new TextEncoder().encode(plaintext);
  
  const encrypted = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    key,
    encoded
  );
  
  return {
    ciphertext: bytesToBase64Url(new Uint8Array(encrypted)),
    iv: bytesToBase64Url(iv),
  };
}

export async function decryptMessage(ciphertext: string, iv: string): Promise<string> {
  const key = await getKey();
  const ivBytes = base64UrlToBytes(iv);
  const ciphertextBytes = base64UrlToBytes(ciphertext);
  
  const decrypted = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: ivBytes },
    key,
    ciphertextBytes
  );
  
  return new TextDecoder().decode(decrypted);
}

// Helpers
function hexToBytes(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) {
    bytes[i / 2] = parseInt(hex.substr(i, 2), 16);
  }
  return bytes;
}

function bytesToBase64Url(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '');
}

function base64UrlToBytes(b64: string): Uint8Array {
  const padded = b64.replace(/-/g, '+').replace(/_/g, '/');
  const binary = atob(padded);
  return Uint8Array.from(binary, c => c.charCodeAt(0));
}
```

### 6.3 Edge Function: AI Chat

```typescript
// supabase/functions/ai-chat/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';
import { encryptMessage, decryptMessage } from '../_shared/encryption.ts';
import { detectRiskFromText, RiskLevel } from '../_shared/risk-keywords.ts';
import { getServicesForRiskLevel } from '../_shared/call-center.ts';

const OPENAI_API_KEY = Deno.env.get('OPENAI_API_KEY')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

// ============================================================
// SYSTEM PROMPT — Validasi klinis WAJIB sebelum production
// ============================================================
const SYSTEM_PROMPT = `Kamu adalah PsyBot, asisten dukungan emosional dari aplikasi PsyBot — platform kesehatan mental digital.

IDENTITAS:
- Kamu bukan dokter, psikolog, atau psikiater
- Kamu adalah pendamping emosional awal yang empatis dan tidak menghakimi
- Kamu berbicara dalam Bahasa Indonesia yang hangat, santai namun profesional

TUGAS UTAMA:
- Dengarkan pengguna dengan aktif dan validasi perasaan mereka
- Berikan respons yang empatik, supportif, dan membesarkan hati
- Jika ada tanda distres ringan: tawarkan teknik mindfulness atau breathing exercise

JIKA PENGGUNA MENUNJUKKAN TANDA BAHAYA:
Sampaikan dengan tenang dan penuh kasih: "Aku dengar kamu, dan aku sangat peduli dengan kondisimu sekarang. Kamu tidak sendirian. Aku ingin memperkenalkan kamu dengan beberapa orang yang bisa menemanimu lebih jauh — sepenuhnya pilihanmu apakah ingin menghubungi atau tidak."
Jangan terus melanjutkan percakapan normal setelah ini. Biarkan UI aplikasi yang menampilkan opsi layanan bantuan.

LARANGAN KERAS (GUARDRAILS):
❌ Jangan memberikan diagnosis medis dalam bentuk apapun
❌ Jangan merekomendasikan obat-obatan atau dosis
❌ Jangan menggantikan atau menyarankan penghentian terapi yang sedang berjalan
❌ Jangan memberikan saran medis spesifik
❌ Jangan berperilaku seolah-olah kamu manusia sungguhan jika ditanya langsung
❌ Jangan menggunakan kata-kata yang bisa memicu atau memperparah kondisi pengguna
❌ Jangan memaksa pengguna untuk menghubungi siapa pun — pilihan selalu ada di tangan mereka

FORMAT RESPONS:
- Maksimal 3 paragraf per respons
- Mulai dengan memvalidasi perasaan pengguna
- Gunakan kalimat yang hangat, bukan klinis/teknis
- Akhiri dengan pertanyaan terbuka atau tawaran teknik self-help jika relevan`;

// ============================================================
// Fungsi untuk mendapatkan riwayat chat (untuk context window)
// ============================================================
async function getChatHistory(
  supabase: ReturnType<typeof createClient>,
  sessionId: string,
  maxMessages = 20  // Batas context window
): Promise<Array<{ role: 'user' | 'assistant'; content: string }>> {
  const { data: messages } = await supabase
    .from('messages')
    .select('pengirim_tipe, isi_pesan_terenkripsi, iv')
    .eq('id_session', sessionId)
    .is('deleted_at', null)
    .order('waktu', { ascending: false })
    .limit(maxMessages);
  
  if (!messages) return [];
  
  // Dekripsi dan format untuk OpenAI
  const decryptedMessages = await Promise.all(
    messages.reverse().map(async (msg) => ({
      role: msg.pengirim_tipe === 'user' ? 'user' as const : 'assistant' as const,
      content: await decryptMessage(msg.isi_pesan_terenkripsi, msg.iv),
    }))
  );
  
  return decryptedMessages;
}

// ============================================================
// Fungsi untuk menyimpan pesan (terenkripsi)
// ============================================================
async function saveMessage(
  supabase: ReturnType<typeof createClient>,
  sessionId: string,
  senderType: 'user' | 'ai',
  plaintext: string,
  isFlagged = false,
  flagReason?: string
): Promise<void> {
  const { ciphertext, iv } = await encryptMessage(plaintext);
  
  // Bypass RLS menggunakan service_role
  await supabase.from('messages').insert({
    id_session: sessionId,
    pengirim_tipe: senderType,
    isi_pesan_terenkripsi: ciphertext,
    iv,
    is_flagged: isFlagged,
    flag_reason: flagReason ?? null,
  });
}

// ============================================================
// Main handler
// ============================================================
serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }
  
  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) throw new Error('Missing authorization');
    
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    
    // Verifikasi JWT pengguna
    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await createClient(
      SUPABASE_URL,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    ).auth.getUser(token);
    
    if (authError || !user) throw new Error('Unauthorized');
    
    const { sessionId, message } = await req.json();
    if (!sessionId || !message) throw new Error('sessionId and message required');
    
    // Verifikasi session milik user ini
    const { data: session } = await supabase
      .from('chat_sessions')
      .select('id, id_user, status_risiko, status_sesi')
      .eq('id', sessionId)
      .eq('id_user', user.id)
      .single();
    
    if (!session) throw new Error('Session not found');
    if (session.status_sesi !== 'active') throw new Error('Session is not active');
    
    // 1. Deteksi risiko dari input user (cepat, sebelum LLM)
    const riskDetection = detectRiskFromText(message);
    
    // 2. Simpan pesan user
    await saveMessage(
      supabase, sessionId, 'user', message,
      riskDetection.level !== 'low',
      riskDetection.level !== 'low' ? 'keyword_detected' : undefined
    );
    
    // 3. Log audit
    await supabase.rpc('log_audit', {
      p_aktor_id: user.id,
      p_aktor_tipe: 'user',
      p_aksi: 'send_chat_message',
      p_resource_tipe: 'chat_sessions',
      p_resource_id: sessionId,
      p_detail: { risk_level: riskDetection.level, keyword_count: riskDetection.triggeredKeywords.length },
    });
    
    // 4. Jika risiko CRITICAL: AI memberi respons empatik, APP tampilkan opsi call center
    if (riskDetection.level === 'critical') {
      const escalationMessage = 'Aku dengar kamu, dan aku sangat peduli dengan kondisimu sekarang. Kamu tidak sendirian dalam hal ini. Aku ingin memperkenalkan kamu dengan beberapa orang yang bisa menemanimu lebih jauh — sepenuhnya pilihanmu apakah ingin menghubungi atau tidak. Tidak ada tekanan sama sekali.';
      
      await saveMessage(supabase, sessionId, 'ai', escalationMessage, true, 'keyword_detected');
      
      // Buat risk alert (untuk log dan monitoring profesional)
      // Perubahan status call center akan di-update oleh Flutter saat user memilih
      const { data: alert } = await supabase.from('risk_alerts').insert({
        id_user: user.id,
        id_session: sessionId,
        kategori_risiko: 'critical',
        trigger: `keyword_detected: ${riskDetection.triggeredKeywords.join(', ')}`,
        escalation_type: 'keyword_detected',
        call_center_offered: true,
        status_tindak_lanjut: 'call_center_offered',
      }).select().single();
      
      // Update status sesi
      await supabase.from('chat_sessions')
        .update({ status_risiko: 'critical' })
        .eq('id', sessionId);
      
      // Ambil daftar call center yang relevan untuk dikirim ke Flutter
      const callCenterServices = getServicesForRiskLevel('critical');
      
      return new Response(
        JSON.stringify({
          response: escalationMessage,
          riskLevel: 'critical',
          showCallCenter: true,          // Signal ke Flutter untuk tampilkan UI call center
          alertId: alert?.id,            // Untuk update pilihan user nanti
          callCenterServices,            // Daftar layanan yang ditampilkan
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    // 5. Ambil riwayat percakapan untuk context
    const history = await getChatHistory(supabase, sessionId);
    
    // 6. Panggil OpenAI API
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        messages: [
          { role: 'system', content: SYSTEM_PROMPT },
          ...history,
          { role: 'user', content: message },
        ],
        max_tokens: 500,
        temperature: 0.7,
        // Mencegah respons terlalu panjang
        frequency_penalty: 0.3,
      }),
    });
    
    if (!openaiResponse.ok) {
      const err = await openaiResponse.text();
      throw new Error(`OpenAI API error: ${err}`);
    }
    
    const aiData = await openaiResponse.json();
    const aiMessage = aiData.choices[0].message.content;
    
    // 7. Simpan respons AI
    await saveMessage(supabase, sessionId, 'ai', aiMessage);
    
    // 8. Update status risiko sesi dan tawarkan call center untuk high risk
    if (riskDetection.level === 'high' && session.status_risiko !== 'high' && session.status_risiko !== 'critical') {
      await supabase
        .from('chat_sessions')
        .update({ status_risiko: 'high' })
        .eq('id', sessionId);
      
      // Buat risk alert untuk high risk (tanpa auto-eskalasi)
      const { data: alert } = await supabase.from('risk_alerts').insert({
        id_user: user.id,
        id_session: sessionId,
        kategori_risiko: 'high',
        trigger: `keyword_detected: ${riskDetection.triggeredKeywords.join(', ')}`,
        escalation_type: 'keyword_detected',
        call_center_offered: true,
        status_tindak_lanjut: 'call_center_offered',
      }).select().single();
      
      const callCenterServices = getServicesForRiskLevel('high');
      
      return new Response(
        JSON.stringify({
          response: aiMessage,
          riskLevel: 'high',
          showCallCenter: true,          // Flutter tampilkan banner/card call center
          alertId: alert?.id,
          callCenterServices,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
    
    return new Response(
      JSON.stringify({
        response: aiMessage,
        riskLevel: riskDetection.level,
        showCallCenter: false,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    console.error('ai-chat error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
```

### 6.4 Edge Function: Risk Escalation — Catat Pilihan Pengguna

```typescript
// supabase/functions/risk-escalation/index.ts
// Fungsi ini dipanggil Flutter SETELAH user membuat pilihan di UI call center.
// Tugasnya: mencatat pilihan user (hubungi / tidak) ke risk_alerts.
// Tidak ada auto-routing ke profesional — kontrol penuh ada di tangan pengguna.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }
  
  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) throw new Error('Missing authorization');
    
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    
    // Verifikasi JWT user
    const { data: { user } } = await createClient(
      SUPABASE_URL,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    ).auth.getUser();
    
    if (!user) throw new Error('Unauthorized');
    
    const {
      alertId,          // UUID dari risk_alert yang sudah dibuat oleh ai-chat
      userChoice,       // 'contacted' | 'declined'
      callCenterName,   // Nama layanan yang dipilih (jika userChoice = 'contacted')
    } = await req.json();
    
    if (!alertId || !userChoice) throw new Error('alertId and userChoice required');
    if (!['contacted', 'declined'].includes(userChoice)) throw new Error('Invalid userChoice');
    
    // Verifikasi alert milik user ini
    const { data: alert } = await supabase
      .from('risk_alerts')
      .select('id, id_user, kategori_risiko')
      .eq('id', alertId)
      .eq('id_user', user.id)
      .single();
    
    if (!alert) throw new Error('Alert not found');
    
    // Catat pilihan pengguna
    await supabase.from('risk_alerts').update({
      call_center_contacted: userChoice === 'contacted',
      call_center_name: userChoice === 'contacted' ? (callCenterName ?? null) : null,
      user_responded_at: new Date().toISOString(),
      status_tindak_lanjut: userChoice === 'contacted' ? 'user_contacted' : 'user_declined',
    }).eq('id', alertId);
    
    // Log audit
    await supabase.rpc('log_audit', {
      p_aktor_id: user.id,
      p_aktor_tipe: 'user',
      p_aksi: userChoice === 'contacted' ? 'call_center_contacted' : 'call_center_declined',
      p_resource_tipe: 'risk_alerts',
      p_resource_id: alertId,
      p_detail: {
        call_center_name: callCenterName ?? null,
        risk_level: alert.kategori_risiko,
      },
    });
    
    // Jika user menghubungi, kirim notifikasi ke profesional (monitoring saja, bukan intervensi)
    // Profesional mendapat info bahwa user sudah mengambil langkah menghubungi bantuan
    if (userChoice === 'contacted') {
      const { data: availableProfessional } = await supabase
        .from('professionals')
        .select('id')
        .eq('status_verified', true)
        .eq('status_online', true)
        .order('total_sesi', { ascending: true })
        .limit(1)
        .single();
      
      if (availableProfessional) {
        await supabase.from('risk_alerts').update({
          id_professional_notified: availableProfessional.id,
          notified_at: new Date().toISOString(),
          status_tindak_lanjut: 'user_contacted',
        }).eq('id', alertId);
        
        // Notifikasi pasif ke profesional (informational, bukan perintah)
        await supabase.functions.invoke('send-notification', {
          body: {
            targetUserId: availableProfessional.id,
            title: '📋 Update: Pengguna Menghubungi Bantuan',
            body: `Pengguna dengan sinyal risiko ${alert.kategori_risiko} sudah mengambil langkah menghubungi layanan bantuan: ${callCenterName ?? 'call center'}.`,
            data: {
              type: 'risk_update',
              alertId,
              action: 'user_self_initiated_contact',
            },
          },
        });
      }
    }
    
    return new Response(
      JSON.stringify({ success: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    console.error('risk-escalation error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: error.message === 'Unauthorized' ? 401 : 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
```

### 6.5 Shared: CORS Headers

```typescript
// supabase/functions/_shared/cors.ts
export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
};
```

---

## 7. Phase 5 — Security Layer (E2EE, RBAC, Audit)

### 7.1 Supabase Vault — Penyimpanan Kunci Enkripsi

Jangan simpan kunci enkripsi sebagai environment variable biasa. Gunakan Supabase Vault:

```sql
-- Jalankan di SQL editor Supabase Dashboard
-- Simpan kunci enkripsi di Vault (terenkripsi di database)

SELECT vault.create_secret(
  'MESSAGE_ENCRYPTION_KEY',
  'your-32-byte-hex-key-here',  -- Generate: openssl rand -hex 32
  'Kunci AES-256-GCM untuk enkripsi pesan PsyBot'
);

-- Ambil kunci dari Vault di Edge Function menggunakan:
-- const { data } = await supabase.from('vault.decrypted_secrets').select('decrypted_secret').eq('name', 'MESSAGE_ENCRYPTION_KEY').single();
```

### 7.2 Indexes Performa

```sql
-- supabase/migrations/013_indexes.sql

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
```

### 7.3 Database-Level Triggers untuk Keamanan

```sql
-- supabase/migrations/014_triggers.sql

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
```

---

## 8. Phase 6 — Notification Service (FCM)

### 8.1 Setup FCM

1. Buat project di Firebase Console
2. Aktifkan Cloud Messaging
3. Download `google-services.json` → tambahkan ke Flutter project Android
4. Download `GoogleService-Info.plist` → tambahkan ke Flutter project iOS

### 8.2 Simpan FCM Token di Database

```sql
-- Tambahkan kolom fcm_token ke tabel user_profile
ALTER TABLE public.user_profile
  ADD COLUMN fcm_token TEXT,
  ADD COLUMN fcm_token_updated_at TIMESTAMPTZ;
```

### 8.3 Edge Function: Send Notification

```typescript
// supabase/functions/send-notification/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

serve(async (req) => {
  try {
    const { targetUserId, title, body, data } = await req.json();
    
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    
    // Ambil FCM token dari database
    const { data: profile } = await supabase
      .from('user_profile')
      .select('fcm_token')
      .eq('id_user', targetUserId)
      .single();
    
    if (!profile?.fcm_token) {
      console.log(`No FCM token for user ${targetUserId}`);
      return new Response(JSON.stringify({ skipped: true }), { status: 200 });
    }
    
    // Kirim via FCM HTTP v1 API
    const fcmPayload = {
      message: {
        token: profile.fcm_token,
        notification: { title, body },
        data: Object.fromEntries(
          Object.entries(data || {}).map(([k, v]) => [k, String(v)])
        ),
        android: {
          priority: data?.type === 'risk_alert' ? 'HIGH' : 'NORMAL',
          notification: {
            channel_id: data?.type === 'risk_alert' ? 'emergency' : 'general',
          },
        },
        apns: {
          payload: {
            aps: {
              alert: { title, body },
              badge: 1,
              sound: data?.type === 'risk_alert' ? 'emergency.caf' : 'default',
            },
          },
        },
      },
    };
    
    // Gunakan FCM HTTP v1 API (Legacy API deprecated 2024)
    // Perlu Google OAuth2 access token — gunakan service account
    const accessToken = await getGoogleAccessToken();
    
    const fcmProjectId = Deno.env.get('FCM_PROJECT_ID')!;
    const fcmResponse = await fetch(
      `https://fcm.googleapis.com/v1/projects/${fcmProjectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(fcmPayload),
      }
    );
    
    if (!fcmResponse.ok) {
      const errorBody = await fcmResponse.text();
      console.error('FCM error:', errorBody);
      
      // Jika token invalid, hapus dari database
      if (fcmResponse.status === 404 || errorBody.includes('UNREGISTERED')) {
        await supabase
          .from('user_profile')
          .update({ fcm_token: null })
          .eq('id_user', targetUserId);
      }
    }
    
    return new Response(
      JSON.stringify({ success: fcmResponse.ok }),
      { headers: { 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    console.error('send-notification error:', error);
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    );
  }
});

// Helper: dapatkan Google OAuth2 access token dari service account
async function getGoogleAccessToken(): Promise<string> {
  const serviceAccountJson = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')!);
  
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: serviceAccountJson.client_email,
    sub: serviceAccountJson.client_email,
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
  };
  
  // JWT signing menggunakan private key
  // Implementasi lengkap: https://deno.land/x/djwt
  // Untuk production, gunakan library djwt atau jose
  // Placeholder — implementasikan sesuai library yang dipilih
  throw new Error('Implement JWT signing with serviceAccountJson.private_key');
}
```

---

## 9. Phase 7 — Payment Gateway (Midtrans)

### 9.1 Edge Function: Create Payment

```typescript
// supabase/functions/payment-create/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

const MIDTRANS_SERVER_KEY = Deno.env.get('MIDTRANS_SERVER_KEY')!;
const MIDTRANS_BASE_URL = Deno.env.get('MIDTRANS_ENVIRONMENT') === 'production'
  ? 'https://app.midtrans.com'
  : 'https://app.sandbox.midtrans.com';

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }
  
  try {
    const authHeader = req.headers.get('Authorization');
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );
    
    const { data: { user } } = await createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader! } } }
    ).auth.getUser();
    
    if (!user) throw new Error('Unauthorized');
    
    const { consultationId } = await req.json();
    
    // Ambil detail konsultasi
    const { data: consultation } = await supabase
      .from('consultations')
      .select('*, professionals(tarif_per_sesi, tarif_gratis), users!consultations_id_user_fkey(nama, email)')
      .eq('id', consultationId)
      .eq('id_user', user.id)
      .single();
    
    if (!consultation) throw new Error('Consultation not found');
    if (consultation.status_pembayaran === 'paid') throw new Error('Already paid');
    if (consultation.professionals.tarif_gratis) {
      // Update status langsung tanpa payment
      await supabase.from('consultations').update({ status_pembayaran: 'free', status: 'confirmed' }).eq('id', consultationId);
      return new Response(JSON.stringify({ free: true }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }
    
    const amount = consultation.professionals.tarif_per_sesi;
    const orderId = `PSYBOT-${consultationId.slice(0, 8)}-${Date.now()}`;
    
    // Buat Midtrans Snap token
    const snapPayload = {
      transaction_details: {
        order_id: orderId,
        gross_amount: amount,
      },
      customer_details: {
        first_name: consultation.users.nama,
        email: consultation.users.email,
      },
      item_details: [{
        id: consultationId,
        price: amount,
        quantity: 1,
        name: `Konsultasi ${consultation.jenis_konsultasi} - ${consultation.durasi_menit} menit`,
      }],
      callbacks: {
        finish: `psybot://payment/finish?order_id=${orderId}`,
        error: `psybot://payment/error?order_id=${orderId}`,
      },
    };
    
    const midtransResponse = await fetch(`${MIDTRANS_BASE_URL}/snap/v1/transactions`, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${btoa(MIDTRANS_SERVER_KEY + ':')}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(snapPayload),
    });
    
    const snapData = await midtransResponse.json();
    
    // Simpan transaksi ke database
    const { data: transaction } = await supabase
      .from('payment_transactions')
      .insert({
        id_user: user.id,
        amount,
        order_id: orderId,
        snap_token: snapData.token,
        snap_redirect_url: snapData.redirect_url,
        expired_at: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      })
      .select()
      .single();
    
    // Update consultation dengan id_transaksi
    await supabase
      .from('consultations')
      .update({ id_transaksi: transaction.id })
      .eq('id', consultationId);
    
    return new Response(
      JSON.stringify({
        snapToken: snapData.token,
        snapUrl: snapData.redirect_url,
        orderId,
        amount,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
    
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
```

### 9.2 Edge Function: Payment Webhook

```typescript
// supabase/functions/payment-webhook/index.ts
// Midtrans akan memanggil endpoint ini setelah pembayaran

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const MIDTRANS_SERVER_KEY = Deno.env.get('MIDTRANS_SERVER_KEY')!;

serve(async (req) => {
  try {
    const payload = await req.json();
    
    // Verifikasi signature dari Midtrans
    const expectedSignature = await computeMidtransSignature(
      payload.order_id,
      payload.status_code,
      payload.gross_amount,
      MIDTRANS_SERVER_KEY
    );
    
    if (payload.signature_key !== expectedSignature) {
      return new Response('Invalid signature', { status: 403 });
    }
    
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    );
    
    // Mapping status Midtrans ke status internal
    const statusMap: Record<string, string> = {
      'capture': 'success',
      'settlement': 'success',
      'pending': 'pending',
      'deny': 'failed',
      'expire': 'expired',
      'cancel': 'cancelled',
      'refund': 'refunded',
    };
    
    const newStatus = statusMap[payload.transaction_status] ?? 'pending';
    
    // Update payment_transactions
    const { data: transaction } = await supabase
      .from('payment_transactions')
      .update({
        status: newStatus,
        gateway_ref: payload.transaction_id,
        payment_method: payload.payment_type,
        midtrans_payload: payload,
        paid_at: newStatus === 'success' ? new Date().toISOString() : null,
      })
      .eq('order_id', payload.order_id)
      .select()
      .single();
    
    // Jika pembayaran sukses, konfirmasi konsultasi
    if (newStatus === 'success' && transaction) {
      const { data: consultation } = await supabase
        .from('consultations')
        .update({ status_pembayaran: 'paid', status: 'confirmed' })
        .eq('id_transaksi', transaction.id)
        .select('id, id_user, id_professional')
        .single();
      
      if (consultation) {
        // Notifikasi user
        await supabase.functions.invoke('send-notification', {
          body: {
            targetUserId: consultation.id_user,
            title: 'Pembayaran Berhasil ✅',
            body: 'Konsultasi kamu sudah dikonfirmasi. Cek jadwalmu!',
            data: { type: 'payment_success', consultationId: consultation.id },
          },
        });
        
        // Notifikasi profesional
        await supabase.functions.invoke('send-notification', {
          body: {
            targetUserId: consultation.id_professional,
            title: 'Konsultasi Baru 📅',
            body: 'Ada konsultasi baru yang sudah dikonfirmasi.',
            data: { type: 'new_consultation', consultationId: consultation.id },
          },
        });
      }
    }
    
    return new Response('OK', { status: 200 });
    
  } catch (error) {
    console.error('payment-webhook error:', error);
    return new Response('Internal Server Error', { status: 500 });
  }
});

async function computeMidtransSignature(
  orderId: string,
  statusCode: string,
  grossAmount: string,
  serverKey: string
): Promise<string> {
  const message = `${orderId}${statusCode}${grossAmount}${serverKey}`;
  const encoder = new TextEncoder();
  const data = encoder.encode(message);
  const hashBuffer = await crypto.subtle.digest('SHA-512', data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}
```

---

## 10. Phase 8 — API Contract for Flutter

> API contract ini adalah referensi untuk tim frontend Flutter. Semua endpoint menggunakan Supabase client SDK, bukan raw HTTP.

### 10.1 Authentication

```dart
// Flutter: lib/services/auth_service.dart

// Register
final response = await supabase.auth.signUp(
  email: email,
  password: password,
  data: {'nama': nama},  // Akan otomatis tersimpan di users.nama via trigger
);

// Login
final response = await supabase.auth.signInWithPassword(
  email: email,
  password: password,
);

// Logout
await supabase.auth.signOut();

// Session listener
supabase.auth.onAuthStateChange.listen((data) {
  final AuthChangeEvent event = data.event;
  // Handle: SIGNED_IN, SIGNED_OUT, TOKEN_REFRESHED, etc.
});
```

### 10.2 Chat Session

```dart
// Buat sesi baru
final session = await supabase
  .from('chat_sessions')
  .insert({'id_user': userId})
  .select()
  .single();

// Kirim pesan (via Edge Function — tidak langsung ke tabel messages)
final response = await supabase.functions.invoke('ai-chat', body: {
  'sessionId': sessionId,
  'message': userMessage,
});
// Response: {'response': '...', 'riskLevel': 'low', 'escalated': false}

// Real-time listener untuk respons AI
supabase
  .from('messages')
  .stream(primaryKey: ['id'])
  .eq('id_session', sessionId)
  .order('waktu', ascending: true)
  .listen((List<Map<String, dynamic>> messages) {
    // Update UI
  });
```

### 10.3 Menangani Respons Risiko & Call Center (Flutter)

```dart
// Flutter: lib/services/chat_service.dart

// Kirim pesan dan handle respons risiko
Future<void> sendMessage(String sessionId, String message) async {
  final response = await supabase.functions.invoke('ai-chat', body: {
    'sessionId': sessionId,
    'message': message,
  });
  
  final data = response.data as Map<String, dynamic>;
  final riskLevel = data['riskLevel'] as String;
  final showCallCenter = data['showCallCenter'] as bool? ?? false;
  
  // Tampilkan respons AI di UI
  displayAiMessage(data['response'] as String);
  
  // Jika ada sinyal bahaya, tampilkan card call center
  if (showCallCenter) {
    final alertId = data['alertId'] as String;
    final services = (data['callCenterServices'] as List)
      .map((s) => CallCenterService.fromJson(s))
      .toList();
    
    // Tampilkan bottom sheet atau dialog — BUKAN popup paksa
    // User bisa swipe down untuk menutupnya
    showCallCenterBottomSheet(
      alertId: alertId,
      services: services,
      riskLevel: riskLevel,
    );
  }
}

// Catat pilihan user setelah melihat opsi call center
Future<void> recordCallCenterChoice({
  required String alertId,
  required bool contacted,
  String? callCenterName,
}) async {
  await supabase.functions.invoke('risk-escalation', body: {
    'alertId': alertId,
    'userChoice': contacted ? 'contacted' : 'declined',
    if (callCenterName != null) 'callCenterName': callCenterName,
  });
}

// Contoh bottom sheet Flutter (pseudocode)
void showCallCenterBottomSheet({
  required String alertId,
  required List<CallCenterService> services,
  required String riskLevel,
}) {
  showModalBottomSheet(
    context: context,
    isDismissible: true,     // User BISA menutupnya
    enableDrag: true,
    builder: (_) => CallCenterSheet(
      alertId: alertId,
      services: services,
      onContacted: (serviceName) {
        recordCallCenterChoice(alertId: alertId, contacted: true, callCenterName: serviceName);
      },
      onDeclined: () {
        recordCallCenterChoice(alertId: alertId, contacted: false);
      },
    ),
  );
}
```

### 10.4 Ambil Konten Self-Help Berdasarkan Risk Level

```dart
// Konten ditampilkan setelah chat — bukan berdasarkan skor kuesioner
final content = await supabase
  .from('self_help_content')
  .select()
  .eq('aktif', true)
  .contains('target_risk_level', [currentRiskLevel])  // 'low', 'medium', 'high', 'critical'
  .order('urutan', ascending: true)
  .limit(3);
```

### 10.4 Update FCM Token

```dart
// Update FCM token ke database saat app start atau token refresh
await supabase
  .from('user_profile')
  .update({
    'fcm_token': fcmToken,
    'fcm_token_updated_at': DateTime.now().toIso8601String(),
  })
  .eq('id_user', userId);
```

### 10.5 Consent & Privacy

```dart
// Simpan informed consent
await supabase
  .from('user_profile')
  .update({
    'consent_diberikan': true,
    'consent_timestamp': DateTime.now().toIso8601String(),
    'consent_version': 'v1.0',
    'preferensi_privasi': {
      'anonymous_mode': false,
      'share_with_professional': true,
      'allow_research_data': false,
    },
  })
  .eq('id_user', userId);
```

---

## 11. Phase 9 — Testing Strategy

### 11.1 Database Tests

```sql
-- test/database_tests.sql
-- Jalankan di Supabase Test environment

BEGIN;

-- Test 1: RLS — user tidak bisa lihat data user lain
SET LOCAL role = anon;
SET LOCAL request.jwt.claims = '{"sub": "user-a-uuid", "role": "user"}';

-- Harus 0 rows (user A tidak bisa lihat chat session user B)
SELECT count(*) FROM public.chat_sessions WHERE id_user = 'user-b-uuid';

-- Test 2: Audit log append-only
INSERT INTO public.audit_logs (aktor_id, aktor_tipe, aksi) VALUES (NULL, 'system', 'test');
UPDATE public.audit_logs SET aksi = 'modified' WHERE aksi = 'test';  -- Harus ditolak
DELETE FROM public.audit_logs WHERE aksi = 'test';  -- Harus ditolak

-- Test 3: risk_alerts call_center fields
INSERT INTO public.risk_alerts (id_user, kategori_risiko, trigger, escalation_type)
VALUES ('user-test-uuid', 'high', 'keyword: putus asa', 'keyword_detected');
-- call_center_contacted harus NULL (belum ada pilihan)
SELECT call_center_contacted FROM public.risk_alerts WHERE id_user = 'user-test-uuid';  -- Harus NULL

-- Test 4: Update pilihan call center user
UPDATE public.risk_alerts
SET call_center_contacted = TRUE,
    call_center_name = 'Hotline Kemenkes RI',
    status_tindak_lanjut = 'user_contacted'
WHERE id_user = 'user-test-uuid';
SELECT status_tindak_lanjut FROM public.risk_alerts WHERE id_user = 'user-test-uuid';  -- Harus 'user_contacted'

ROLLBACK;
```

### 11.2 Edge Function Tests

```typescript
// test/ai-chat.test.ts (Deno test)
import { assertEquals } from 'https://deno.land/std@0.168.0/testing/asserts.ts';
import { detectRiskFromText } from '../supabase/functions/_shared/risk-keywords.ts';
import { encryptMessage, decryptMessage } from '../supabase/functions/_shared/encryption.ts';
import { getServicesForRiskLevel } from '../supabase/functions/_shared/call-center.ts';

Deno.test('detectRiskFromText - critical keyword bahasa Indonesia', () => {
  const result = detectRiskFromText('aku mau bunuh diri saja');
  assertEquals(result.level, 'critical');
  assertEquals(result.triggeredKeywords.includes('bunuh diri'), true);
});

Deno.test('detectRiskFromText - critical keyword dengan variasi penulisan', () => {
  const result = detectRiskFromText('udah capek hidup, pengen mati aja');
  assertEquals(result.level, 'critical');
});

Deno.test('detectRiskFromText - high risk keywords', () => {
  const result = detectRiskFromText('aku ini beban buat semua orang, tidak berguna');
  assertEquals(result.level, 'high');
});

Deno.test('detectRiskFromText - low risk (curhat biasa)', () => {
  const result = detectRiskFromText('hari ini aku sedih karena nilai jelek dan capek kuliah');
  assertEquals(result.level, 'low');
  assertEquals(result.triggeredKeywords.length, 0);
});

Deno.test('encrypt-decrypt roundtrip', async () => {
  const original = 'Halo, ini pesan rahasia pengguna PsyBot';
  const { ciphertext, iv } = await encryptMessage(original);
  const decrypted = await decryptMessage(ciphertext, iv);
  assertEquals(decrypted, original);
});

Deno.test('getServicesForRiskLevel - critical returns 24h services', () => {
  const services = getServicesForRiskLevel('critical');
  const all24h = services.every(s => s.jam_operasional.includes('24 jam') || s.id === 'into_the_light');
  assertEquals(all24h, true);
});

Deno.test('getServicesForRiskLevel - high returns all services', () => {
  const services = getServicesForRiskLevel('high');
  assertEquals(services.length > 2, true);
});
```

### 11.3 Security Tests

```bash
# Test 1: Pastikan endpoint tidak bisa diakses tanpa Auth header
curl -X POST https://[PROJECT].supabase.co/functions/v1/ai-chat \
  -H "Content-Type: application/json" \
  -d '{"sessionId": "any", "message": "test"}'
# Expected: 400 Unauthorized

# Test 2: Pastikan RLS aktif
curl https://[PROJECT].supabase.co/rest/v1/messages \
  -H "apikey: [ANON_KEY]"
# Expected: 401 atau empty array (tidak ada data)

# Test 3: Pastikan rate limiting berjalan
for i in {1..15}; do
  curl -X POST https://[PROJECT].supabase.co/functions/v1/ai-chat \
    -H "Authorization: Bearer [VALID_TOKEN]" \
    -H "Content-Type: application/json" \
    -d '{"sessionId": "test", "message": "test"}'
done
# Expected: setelah 10 request dalam 1 menit, mendapat 429 Too Many Requests
```

---

## 12. Phase 10 — Deployment & CI/CD

### 12.1 Deploy Edge Functions

```bash
# Deploy semua function
supabase functions deploy ai-chat
supabase functions deploy risk-escalation
supabase functions deploy send-notification
supabase functions deploy payment-create
supabase functions deploy payment-webhook

# Set secrets (hanya sekali, tidak perlu di-commit)
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets set MIDTRANS_SERVER_KEY=...
supabase secrets set MIDTRANS_ENVIRONMENT=sandbox
supabase secrets set FCM_PROJECT_ID=...
supabase secrets set FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
supabase secrets set MESSAGE_ENCRYPTION_KEY=$(openssl rand -hex 32)
supabase secrets set MIDTRANS_SERVER_KEY=...
```

### 12.2 Database Migration

```bash
# Apply semua migration ke production
supabase db push

# Atau step by step
supabase migration up
```

### 12.3 GitHub Actions CI/CD

```yaml
# .github/workflows/deploy.yml
name: Deploy PsyBot Backend

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: denoland/setup-deno@v1
      - name: Run Edge Function Tests
        run: deno test --allow-env --allow-net test/

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
      - name: Deploy Functions
        run: |
          supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
          supabase functions deploy ai-chat
          supabase functions deploy risk-escalation
          supabase functions deploy send-notification
          supabase functions deploy payment-create
          supabase functions deploy payment-webhook
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
      - name: Run DB Migrations
        run: supabase db push
        env:
          SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
          SUPABASE_DB_PASSWORD: ${{ secrets.SUPABASE_DB_PASSWORD }}
```

### 12.4 Monitoring

Setup alerts di Supabase Dashboard → Database → Query Performance:

1. **Slow queries** > 500ms → alert ke Slack/email
2. **Error rate** Edge Functions > 1% → alert
3. **Storage usage** > 80% → alert
4. **Active connections** > 80% max → alert

```sql
-- Query untuk monitoring: sesi aktif per hari (pantau penggunaan)
SELECT
  DATE_TRUNC('day', tanggal) as hari,
  COUNT(*) as total_sesi,
  COUNT(*) FILTER (WHERE status_risiko IN ('high', 'critical')) as sesi_berisiko,
  AVG(pesan_count) as rata_pesan
FROM public.chat_sessions
WHERE tanggal >= NOW() - INTERVAL '30 days'
GROUP BY 1
ORDER BY 1 DESC;

-- Query untuk monitoring: alert yang belum ditangani
SELECT
  kategori_risiko,
  escalation_type,
  COUNT(*) as jumlah,
  MIN(created_at) as paling_lama
FROM public.risk_alerts
WHERE status_tindak_lanjut = 'pending'
GROUP BY 1, 2
ORDER BY jumlah DESC;
```

---

## 13. Environment Variables Reference

| Variable | Deskripsi | Wajib | Cara Generate |
|----------|-----------|-------|---------------|
| `SUPABASE_URL` | URL project Supabase | ✅ | Supabase Dashboard → Settings → API |
| `SUPABASE_ANON_KEY` | Public anon key | ✅ | Supabase Dashboard → Settings → API |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key (RAHASIA) | ✅ | Supabase Dashboard → Settings → API |
| `OPENAI_API_KEY` | OpenAI API key | ✅ | platform.openai.com |
| `MIDTRANS_SERVER_KEY` | Midtrans server key | ✅ | dashboard.midtrans.com |
| `MIDTRANS_CLIENT_KEY` | Midtrans client key (Flutter) | ✅ | dashboard.midtrans.com |
| `MIDTRANS_ENVIRONMENT` | `sandbox` atau `production` | ✅ | Manual |
| `FCM_PROJECT_ID` | Firebase project ID | ✅ | Firebase Console |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Firebase service account JSON | ✅ | Firebase Console → Service Accounts |
| `MESSAGE_ENCRYPTION_KEY` | 32-byte hex key untuk E2EE | ✅ | `openssl rand -hex 32` |
| `MIDTRANS_PROJECT_REF` | Supabase project ref | ✅ | Supabase Dashboard |

### File `.env.local` (JANGAN commit ke Git)

```bash
# .env.local — tambahkan ke .gitignore
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...  # SANGAT RAHASIA
OPENAI_API_KEY=sk-proj-...
MIDTRANS_SERVER_KEY=SB-Mid-server-...
MIDTRANS_CLIENT_KEY=SB-Mid-client-...
MIDTRANS_ENVIRONMENT=sandbox
FCM_PROJECT_ID=psybot-xxxxx
MESSAGE_ENCRYPTION_KEY=<output openssl rand -hex 32>
```

---

## 14. Error Handling Standard

Semua Edge Function harus mengembalikan error dalam format yang konsisten:

```typescript
// Standard error response
interface ErrorResponse {
  error: string;          // Pesan error yang bisa ditampilkan ke user
  code?: string;          // Error code untuk handling di Flutter
  details?: unknown;      // Detail tambahan (hanya di development)
}

// Error codes standar
const ERROR_CODES = {
  UNAUTHORIZED: 'AUTH_001',
  INVALID_INPUT: 'INPUT_001',
  SESSION_NOT_FOUND: 'SESSION_001',
  SESSION_CLOSED: 'SESSION_002',
  AI_UNAVAILABLE: 'AI_001',
  PAYMENT_FAILED: 'PAY_001',
  RATE_LIMITED: 'RATE_001',
  INTERNAL_ERROR: 'SRV_001',
} as const;

// Helper function
function errorResponse(
  message: string,
  code: string,
  status: number,
  headers: Record<string, string> = {}
): Response {
  return new Response(
    JSON.stringify({ error: message, code }),
    { status, headers: { 'Content-Type': 'application/json', ...headers } }
  );
}
```

---

## Checklist Production Readiness

Sebelum go-live, verifikasi semua item berikut:

### Security
- [ ] RLS aktif dan diuji pada semua tabel
- [ ] Message encryption berfungsi (uji encrypt-decrypt roundtrip)
- [ ] Audit log append-only (uji UPDATE/DELETE → harus gagal)
- [ ] JWT expiry dan refresh rotation dikonfigurasi
- [ ] Rate limiting aktif di semua endpoint sensitif
- [ ] Semua secrets menggunakan `supabase secrets set` (tidak hardcoded)
- [ ] `.gitignore` menyertakan `.env.local` dan semua file secrets
- [ ] FCM Server Key tidak di-expose ke client

### Compliance UU PDP
- [ ] Informed consent tersimpan dengan versi dan timestamp
- [ ] User bisa hapus akun (soft-delete + cascade)
- [ ] Data minimisasi: hanya simpan data yang diperlukan
- [ ] Akses data dibatasi berdasarkan consent (RLS policy)
- [ ] Audit trail lengkap di `audit_logs`

### AI Safety
- [ ] System prompt sudah divalidasi oleh dokter/psikiater
- [ ] Guardrails mencegah AI memberikan diagnosis medis
- [ ] Kamus kata kunci risiko sudah divalidasi secara klinis
- [ ] Deteksi risiko dari konteks percakapan berfungsi (bukan dari skor kuesioner)
- [ ] Respons AI saat risiko terdeteksi tidak memaksa — hanya menawarkan opsi
- [ ] UI call center bisa di-dismiss oleh user (bukan popup paksa)
- [ ] Pilihan user (hubungi / abaikan) tercatat di `risk_alerts`
- [ ] Nomor call center di `call-center.ts` sudah diverifikasi aktif
- [ ] `showCallCenter: false` untuk low/medium risk (tidak menampilkan card)

### Database
- [ ] Semua **10 tabel** + extension terbuat (users, user_profile, chat_sessions, messages, risk_alerts, consultations, professionals, payment_transactions, self_help_content, audit_logs)
- [ ] Indexes performa terpasang
- [ ] Triggers berfungsi (set_updated_at, handle_new_user, dll)
- [ ] Foreign key constraints benar
- [ ] Backup otomatis aktif (Supabase Dashboard)
- [ ] Kolom `call_center_offered` dan `call_center_contacted` di `risk_alerts` terisi dengan benar

### Testing
- [ ] Unit test encryption lulus
- [ ] Unit test risk detection lulus (berbagai variasi bahasa Indonesia)
- [ ] Unit test `getServicesForRiskLevel` lulus
- [ ] Integration test alur lengkap: register → onboarding → chat → deteksi risiko → tampil call center → user pilih → tercatat di DB
- [ ] Test UI call center bisa di-dismiss tanpa menghubungi
- [ ] Security test RLS berhasil menolak akses tidak sah

### Flutter Integration
- [ ] API contract didokumentasikan dan dikomunikasikan ke tim frontend
- [ ] Handler `showCallCenter: true` sudah diimplementasikan di Flutter
- [ ] Call center bottom sheet bisa di-dismiss (tidak memaksa)
- [ ] `recordCallCenterChoice` dipanggil saat user memilih atau menutup sheet
- [ ] FCM token update berfungsi
- [ ] Deep link untuk payment callback dikonfigurasi
- [ ] Error handling sesuai standar

---

*Dokumen ini disiapkan untuk AI executor. Jalankan setiap phase secara berurutan. Jika ada pertanyaan atau ambiguitas, prioritaskan keamanan data pengguna (UU PDP) dan keselamatan klinis (guardrails AI).*

**Versi:** 1.0.0  
**Proyek:** PsyBot — Aplikasi Kesehatan Mental  
**Institusi:** Institut Teknologi Sepuluh Nopember (ITS)  
**Mata Kuliah:** Pemrograman Perangkat Bergerak
