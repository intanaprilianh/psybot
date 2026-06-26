# PsyBot — Architecture & Development Guide

This document describes the architecture, build commands, and conventions for this repository.

## Project Overview

PsyBot is a mental health support mobile app for Indonesian users. It provides AI chatbot support (via "Puyo" mascot), professional mental health consultations, mood tracking, risk detection, and emergency service referrals. Built as an ITS Surabaya mobile programming course project.

**Language:** Indonesian — all UI strings, variable comments, user-facing text, and LLM prompts are in Bahasa Indonesia.

## Tech Stack

- **Frontend:** Flutter (Dart 3.11+), Material Design 3, Riverpod
- **Backend:** Supabase (PostgreSQL 17, Auth, Edge Functions in Deno/TypeScript)
- **AI/LLM:** DeepSeek `deepseek-chat` (primary), OpenAI GPT-4o (fallback)
- **Payments:** Midtrans (QRIS, GoPay, Bank Transfer)
- **Notifications:** Firebase Cloud Messaging (project: psybot-promob, Android app: com.example.aplikasii)
- **Encryption:** AES-256-GCM at application layer (messages never stored as plaintext)

## Build & Run Commands

### Frontend (Flutter)
```bash
cd frontend
flutter pub get          # Install dependencies
flutter run              # Run on connected device/emulator
flutter analyze          # Lint/static analysis (uses flutter_lints)
flutter build apk        # Build Android APK
```

Environment: create `frontend/.env` with `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

### Backend (Supabase)
```bash
cd psybot-backend
supabase start                          # Start local Supabase
supabase db reset                       # Reset DB and run all migrations + seed
supabase functions serve                # Serve edge functions locally
supabase functions deploy <name>        # Deploy a specific edge function
```

Environment: copy `psybot-backend/.env.local.example` to `.env.local`. Required secrets: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `LLM_API_KEY`, `LLM_BASE_URL`, `LLM_MODEL`, `MIDTRANS_SERVER_KEY`, `MIDTRANS_CLIENT_KEY`, `MIDTRANS_ENVIRONMENT`, `FCM_PROJECT_ID`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `MESSAGE_ENCRYPTION_KEY` (generate: `openssl rand -hex 32`).

No test infrastructure exists yet.

## Architecture

### Repository Layout
```
frontend/              Flutter mobile app
psybot-backend/        Supabase project (DB migrations + edge functions)
design/pages/          Figma SVG exports (dark/light variants)
docs/context/          Backend engineering spec, pipeline docs
```

### Frontend Architecture

**State management (current):** `UserProfileStore` (static, `lib/models/user_profile_model.dart`) is now a secondary cache kept in sync by `profileProvider`. True Riverpod state lives in `lib/providers/`:
- `profileProvider` (`AsyncNotifierProvider<UserProfileNotifier, UserProfileData>`) — fetches name from `users` table, keeps `UserProfileStore` in sync as side-effect.
- `chatSessionsProvider` (`AsyncNotifierProvider<ChatSessionsNotifier, List<Map>>`) — fetches chat sessions from `chat_sessions` table; invalidated after any chat navigation.
- `todayMoodsProvider` (`AsyncNotifierProvider<TodayMoodsNotifier, List<Map>>`) — fetches today's moods from `moods` table; invalidated after `MoodTrackerPage` saves.
- `moodServiceProvider` (plain `Provider<MoodService>`) — scoped `MoodService` instance used by `mood_tracker_page.dart`.
- `chatServiceProvider` (plain `Provider<ChatService>`), `authServiceProvider`, `profileServiceProvider`.

`ChatHistoryStore` remains as an in-memory store for the active chat session only (messages are encrypted server-side and cannot be loaded back). `ProfessionalStore` is unused.

**Services layer** (`lib/services/`): Wraps Supabase calls. Implemented: `auth_service.dart` (signup/signin/signout/authStateChanges), `chat_service.dart` (createSession, sendMessage → calls `ai-chat` edge function), `professional_service.dart` (getVerifiedProfessionals), `profile_service.dart` (getProfile, updateProfile, updateUserName), `mood_service.dart` (saveMood, getTodayMoods), `consultation_service.dart` (createConsultation, createPayment → calls `payment-create` edge function, sendMessage, messagesStream for Realtime), `notification_service.dart` (initialize, registerToken, clearToken on logout). Also present but not yet fully wired: `risk_service.dart`, `self_help_service.dart`.

**Navigation:** No named routes. Uses `Navigator.push`/`pushReplacement` with custom `PageTransition` animations (`fadeSlide`, `fadeUp`) from `lib/routes/page_transition.dart`.

**Screen flow:**
```
Splash → Welcome → SignUp/SignIn → Onboarding → InformedConsent → Home
Home → Chatbot | MoodTracker | Meditasi | ProfessionalList | EmergencyCall
Home (bell) → Notifikasi
Home (bottom nav person) → Profil
Chatbot → RiwayatChatbot
Meditasi → SesiMeditasi
ProfessionalList → BookingProfesional → JanjiTemu → ChatProfesional
```

All 22 screens are implemented in `lib/screens/`. Screen names use Bahasa Indonesia (e.g., `riwayat_chatbot.dart`, `janji_temu_page.dart`, `booking_profesional_page.dart`).

**Design System:** All colors are centralized in `lib/constants/app_colors.dart`. Never hardcode hex values — always use `AppColors.*` constants.

Key palette:
- Dark screens (splash, welcome, auth): `AppColors.darkPurple` (#020018) background
- Light screens (home, booking, history): `AppColors.lightBackground` (#F8F2FA) background
- Primary accent: `AppColors.purple` (#420D4B)
- Interactive elements: `AppColors.accentPurple` (#7B337E)
- Form focus / secondary: `AppColors.softPurple` (#595BD5)
- Emergency: `AppColors.emergencyRed` (#C44B4B)
- Meditation session background: `#FFEDEA` (warm peach, hardcoded — not in AppColors yet)

**Entry point** (`lib/main.dart`): loads `.env`, initializes Supabase, sets system UI overlay to dark (using `AppColors.darkPurple`), wraps in `ProviderScope`, starts at `SplashScreen`. `SplashScreen` checks auth + onboarding status to decide where to route.

### Backend Architecture

**Database migrations** (`psybot-backend/supabase/migrations/`, numbered `000`–`018`):

| Migration | Purpose |
|-----------|---------|
| 000 | Extensions |
| 001–002 | `users` + `user_profile` (onboarding_complete, preferensi_privasi JSON) |
| 003–004 | `chat_sessions` + `messages` (encrypted; soft deletes) |
| 005 | `professionals` (id = users.id PK, spesialisasi, tarif_per_sesi, status_verified, status_online) |
| 006 | `payment_transactions` (Midtrans snap_token, order_id PSYBOT-{id}-{ts}) |
| 007 | `risk_alerts` (kategori_risiko, escalation_type, call_center_contacted, opt-in tracking) |
| 008 | `consultations` (jadwal, durasi_menit, jenis_konsultasi, status_pembayaran) |
| 009–010 | `self_help_content` + `audit_logs` |
| 011 | RLS policies (all tables — see Security below) |
| 012–013 | Indexes + triggers (auto-update pesan_count, total_sesi) |
| 014–016 | FCM token, Realtime, additional profile fields |
| 017 | `moods` (id_user, jenis_mood CHECK 8 values, catatan, created_at) + RLS |
| 018 | `consultation_messages` (id_consultation, id_sender, isi_pesan plaintext) + RLS + Realtime |
| 019 | Broaden `user_profile.status` CHECK to include `'pelajar'` (was rejecting the profile screen's option) |
| 020 | `notifications` (id_user, judul, deskripsi, tipe CHECK 5 values, dibaca, created_at) + RLS (select/insert/update/delete own) |

**Edge Functions** (Deno/TypeScript in `psybot-backend/supabase/functions/`):

- **`ai-chat`** — Core chat endpoint. Flow: authenticate → keyword risk detection → save encrypted user message → if **critical** risk, return escalation immediately (skip LLM) → else fetch + decrypt last 20 messages → call LLM → save encrypted AI response → if **high** risk, create risk_alert + return call center services. For **medium/high** (non-critical) risk an extra "PERHATIAN KHUSUS" system instruction is injected so the LLM replies with extra care (validate, no triggering words, one open question, gently mention help is available — no pressure). Returns `{ response, riskLevel, showCallCenter, alertId, callCenterServices }`. **Client behavior:** `chatbot_page.dart` auto-opens the (simulated) `EmergencyCallPage` when `riskLevel == 'critical'`; high risk shows the opt-in call-center bottom sheet; medium just gets the cautious reply.
- **`auth-hook`** — Custom JWT claims: queries `users.role` and injects it into `user_metadata.role` and `app_metadata.role`.
- **`payment-create`** — Creates Midtrans Snap transaction for a consultation. Auto-confirms if professional offers free sessions. Uses deep-link callbacks (`psybot://`).
- **`payment-webhook`** — Handles Midtrans payment completion callbacks.
- **`risk-escalation`** — Records user's opt-in decision (contacted/declined) on call center referral. If user contacted, finds available professional and sends FCM notification.
- **`send-notification`** — Firebase Cloud Messaging push notifications.
- **`seed-professionals`** — One-time dev seeding function. Creates 5 professional auth accounts + `professionals` table entries using service role. Safe to re-invoke (idempotent). Run: `curl -X POST https://fearqtemsztziyvyykrm.supabase.co/functions/v1/seed-professionals`.

**Shared utilities** (`functions/_shared/`):
- `encryption.ts` — `encryptMessage()` / `decryptMessage()` using AES-256-GCM with `MESSAGE_ENCRYPTION_KEY`. Returns `{ ciphertext, iv }` as base64url strings.
- `risk-keywords.ts` — `detectRiskFromText(text)` → `{ level, triggeredKeywords }` via case-insensitive **substring** match (checked CRITICAL → HIGH → MEDIUM, first hit wins). Three tiers: `CRITICAL_KEYWORDS` (direct + indirect suicidal cues — bunuh diri, mau mati, ini perpisahan, kalau aku nggak ada, ingin menghilang…), `HIGH_RISK_KEYWORDS` (putus asa, tidak ada harapan…), `MEDIUM_RISK_KEYWORDS` (depresi, panic attack + ambiguous phrases like "ingin lebih tenang", "tidak ada yang peduli", "benci tuhan" that should get a cautious reply, NOT a call). All Indonesian + some English variants. **Substring-match caveat:** avoid short bare tokens like `mati` (false-fires inside `otomatis`, `dramatis`, `lampu mati`); use specific phrases. To make a phrase auto-open the call, put it in CRITICAL; to make it opt-in only, HIGH; cautious-reply only, MEDIUM. Edit + redeploy (`supabase functions deploy ai-chat`) to take effect.
- `call-center.ts` — `getServicesForRiskLevel(level)` returns relevant Indonesian crisis hotlines (Kemenkes 119, Into The Light, Yayasan Pulih, Sebaya.id, RSJ Amino Gondohutomo).
- `cors.ts` — CORS headers.

**Security architecture:**
- **Encryption:** AI chat messages stored as `isi_pesan_terenkripsi` (ciphertext) + `iv` in `messages` table. Plaintext only exists inside edge functions or the Flutter client — never in the database. `consultation_messages` stores plaintext (demo trade-off — production should encrypt).
- **RLS:** Row Level Security on all tables. Users see only their own data. Professionals see data only for consultations where `id_professional = auth.uid()` (professionals.id IS their auth user ID). Direct inserts to `messages` are blocked — insertion only via edge functions.
  - **Gotcha:** `users` and `user_profile` have only SELECT + UPDATE policies (no INSERT) — their rows are auto-created by the signup triggers. So client writes must use `.update().eq(...)`, **never `.upsert()`** (PostgREST upsert = `INSERT … ON CONFLICT`, which the missing INSERT policy rejects). This is why `ProfileService` uses `.update()`.
- **Opt-in escalation:** Risk detection never forces contact. `risk_alerts` records whether the call center option was shown and what the user chose (`call_center_contacted` boolean). Users always decide.
- **Audit logging:** Sensitive operations write to `audit_logs` via RPC.
- **Compliance:** UU PDP No. 27/2022 (Indonesian data protection law).
- **Key schema note:** `professionals.id` is a UUID that doubles as the auth user ID (PK references `public.users(id)`). There is no separate `id_user` column on the `professionals` table.

## Current Progress

### Done — fully working end-to-end
- Auth: signup, signin, signout (wired via `AuthService` + Supabase Auth)
- AI chatbot: `chatbot_page.dart` → `chat_service.dart` → `ai-chat` edge function (encrypted messages, session management)
- Risk detection escalation: **critical** → auto-opens simulated `EmergencyCallPage`; **high** → opt-in call-center bottom sheet; **medium** → cautious AI reply. Keyword tiers are editable in `risk-keywords.ts` (redeploy `ai-chat` after changes)
- **Emergency call screen** (`emergency_call.dart`): a *simulated* in-app call UI ("Layanan Darurat — 119 / Kemenkes RI / Menghubungi…"); it does **not** place a real phone call (Android won't let a non-default-dialer app host a cellular call in-app). Reachable via the red call icon in the chatbot + consultation chat headers, and auto-opened on critical risk
- All DB migrations (000–018) and RLS policies — pushed to remote
- All edge functions deployed (ai-chat, auth-hook, payment-create, payment-webhook, risk-escalation, send-notification, seed-professionals)
- **Seed data live:** 11 `self_help_content` items + 5 verified professionals in remote DB
- **Mood tracker** (`mood_tracker_page.dart`): saves mood to `moods` table via `MoodService`; home page loads today's moods from DB on init
- **Profile persistence** (`profile_provider.dart`): `profileProvider` (`UserProfileNotifier`) fetches user name from DB on first access, survives app restarts; `home_page.dart`, `profil_page.dart`, `onboarding_page.dart` all wired to it
- **Professional booking + payment** (`booking_profesional_page.dart`): `ConsultationService.createConsultation()` inserts into `consultations` table → `createPayment()` calls `payment-create` edge function → free sessions navigate directly to `JanjiTemuPage`, paid sessions open Midtrans Snap URL via `url_launcher`. `Professional.id` captured from DB via `fromJson`. Falls back to in-memory mode for hardcoded static professionals (no DB id).
- **Consultation chat** (`chat_profesional.dart`): subscribes to `consultation_messages` table via Supabase Realtime (`ConsultationService.messagesStream()`); sends messages via direct DB insert; auto-scrolls on new messages. Falls back to hardcoded demo messages when no `consultationId` provided.
- **FCM token registration** (`notification_service.dart`): registers FCM token to `users.fcm_token` on login, auto-refreshes on token rotation, clears on logout. Firebase initialized in `main.dart` via `firebase_options.dart` (project: psybot-promob). `google-services.json` live at `android/app/`. Wired in `splash_screen.dart` (login) and `profil_page.dart` (logout).

### Done — UI complete, backend wired
- **Profil page** (`profil_page.dart`): saves name + demographics to DB; updates `profileProvider` on save; uses `profileProvider.notifier.setLocalImagePath()` for avatar; clears provider on sign-out.
- **Self-help page** (`self_help_page.dart`): `SelfHelpService.getContent()` — wired and seeded (11 items live).
- **Professional list** (`riwayat_daftarprofesional_page.dart`): `ProfessionalService.getVerifiedProfessionals()` — wired and seeded (5 professionals live).
- **Janji temu page** (`janji_temu_page.dart`): passes `consultationId` from `AppointmentSession` through to `ChatProfesionalPage`.

### Done — Riverpod state layer complete
- **`chatSessionsProvider`** (`lib/providers/chat_provider.dart`): `ChatSessionsNotifier` fetches sessions from DB; `riwayat_chatbot.dart` watches it and invalidates on navigation.
- **`todayMoodsProvider`** (`lib/providers/mood_provider.dart`): `TodayMoodsNotifier` fetches today's moods; `home_page.dart` watches it and invalidates after `MoodTrackerPage` returns.
- **`moodServiceProvider`**: scoped `MoodService` used by `mood_tracker_page.dart` (no longer creates service manually).
- **Riwayat chatbot** (`riwayat_chatbot.dart`): fully wired — loads sessions from `chat_sessions` table via `chatSessionsProvider`; opens DB-only sessions by resuming their existing session ID (Goal 7 fix in `chatbot_page.dart`); avatar reads from `profileProvider`.

### Done — UI complete, no backend connection yet
- **Notifikasi** (`notifikasi_page.dart`): hardcoded placeholder items; no notifications table or FCM foreground handling
- **Meditasi** (`meditasi_page.dart`) + **Sesi Meditasi** (`sesi_meditasi_page.dart`): 4 hardcoded sessions, fake timer (no audio package), no backend table. Sessions with `kategori` `'Pernapasan'` or `'Relaksasi'` (Relaksasi Napas, Tenangkan Pikiran) show a **breathing guide**: the phase text (Tarik napas → Tahan → Hembuskan) and the expanding/contracting circle are derived from `_elapsedSeconds` so they stay in sync with the timeline (including skip forward/back)

### Not started
- **Meditasi audio** — sessions are hardcoded with a timer-based player; needs `just_audio` or `audioplayers`, real audio assets, and optionally a `meditation_sessions` table. (Deferred by user — no audio assets yet.)

### Done — goals 9–11 (notifications + deep links)
- **FCM foreground notification UI** (`notification_service.dart`): `_handleForegroundMessage` shows an in-app SnackBar via global `scaffoldMessengerKey` (`lib/core/app_keys.dart`).
- **Notifikasi page backend** (`020_create_notifications.sql`, `app_notification_service.dart`, `notification_provider.dart`): foreground pushes are persisted to `notifications` and `notifikasi_page.dart` reads them via `notificationsProvider` (mark-all-read, swipe-delete, unread styling).
- **Midtrans deep-link callback** (`app_links` package, `AndroidManifest.xml` `psybot://` intent-filter, `main.dart`): `PsyBotApp` listens for `psybot://payment/finish|error` and routes to `JanjiTemuPage` via global `navigatorKey`.

## Goals — Prioritized Roadmap

Work through these in order. Each item is one task session.

1. ~~**Seed data**~~ ✅ — `self_help_content` (11 items) + `professionals` (5 accounts) live in remote DB.

2. ~~**Wire mood tracker**~~ ✅ — `017_create_moods.sql` pushed; `MoodService` implemented; `mood_tracker_page.dart` saves to DB; home page loads today's moods on init.

3. ~~**Wire profile persistence**~~ ✅ — `profileProvider` (AsyncNotifier) fetches from `users` table; `home_page.dart` + `profil_page.dart` + `onboarding_page.dart` wired; name survives restarts.

4. ~~**Wire professional booking + payment flow**~~ ✅ — `ConsultationService` creates consultation in DB + calls `payment-create`; paid sessions open Midtrans Snap URL via `url_launcher`; `Professional.id` now captured from DB; `AppointmentSession` carries `consultationId`.

5. ~~**FCM token registration**~~ ✅ — `notification_service.dart` registers/clears token; `google-services.json` + `firebase_options.dart` generated via `flutterfire configure` for project psybot-promob; wired in `main.dart`, `splash_screen.dart`, `profil_page.dart`.

6. ~~**Wire consultation chat**~~ ✅ — Migration 018 adds `consultation_messages` table with Realtime + RLS; `chat_profesional.dart` subscribes to live stream via `ConsultationService.messagesStream()`; `janji_temu_page.dart` passes `consultationId` through.

7. ~~**Wire riwayat chatbot**~~ ✅ — `chatSessionsProvider` watches DB; `riwayat_chatbot.dart` invalidates on nav; `chatbot_page.dart` resumes DB-only sessions without creating a new one.

8. ~~**Full Riverpod state layer**~~ ✅ — `chatSessionsProvider` + `todayMoodsProvider` + `moodServiceProvider` added; `home_page.dart`, `riwayat_chatbot.dart`, `mood_tracker_page.dart` all observe provider state.

9. ~~**FCM foreground notification UI**~~ ✅ — `NotificationService._handleForegroundMessage` now shows an in-app SnackBar banner via a global `scaffoldMessengerKey` (`lib/core/app_keys.dart`, wired into `MaterialApp`).

10. ~~**Wire Notifikasi page**~~ ✅ — Migration `020_create_notifications.sql` adds `notifications` table + RLS (select/insert/update/delete own). `_handleForegroundMessage` inserts incoming pushes via `AppNotificationService.insert()`. `notifikasi_page.dart` reads from DB through `notificationsProvider` (`lib/providers/notification_provider.dart`); "Tandai dibaca" marks all read, swipe deletes, unread cards use the accent style.

11. ~~**Midtrans deep-link callback**~~ ✅ — Added `app_links` package + `psybot://` intent-filter in `AndroidManifest.xml`. `PsyBotApp` (now stateful) listens to `AppLinks().uriLinkStream`; `psybot://payment/finish` navigates to `JanjiTemuPage` (via global `navigatorKey`) with a confirmation SnackBar, `/error` shows a failure SnackBar.

12. **Meditasi audio** — Deferred by user decision (no audio assets available). Meditation sessions keep the timer-based playback for now. To complete later: integrate `just_audio`/`audioplayers`, add audio assets (or a `meditation_sessions` DB table), and replace the fake timer in `sesi_meditasi_page.dart`.

## Conventions

- App name in `pubspec.yaml` is `aplikasii`; display name is "PsyBot"
- AI mascot is "Puyo" — referenced throughout UI and assets
- Emergency hotline 119 = Kemenkes RI (Indonesian Ministry of Health)
- Design SVGs in `design/pages/` are large Figma exports — grep `fill="#hexcode"` to extract colors rather than opening them whole; text is rendered as paths (not `<text>` elements)
- User roles in the database: `user` / `professional` / `admin`; injected into JWT via `auth-hook`
- `MeditasiSession` data class is defined in `sesi_meditasi_page.dart` and imported by `meditasi_page.dart`
