// seed-professionals — One-time function to seed professional accounts.
// Deploy: supabase functions deploy seed-professionals
// Invoke: supabase functions invoke seed-professionals --no-verify-jwt
//
// This function uses the service_role key to create auth users + professional records.
// Password seed dibaca dari secret SEED_PROF_PASSWORD (bukan hardcode).
// Safe to run multiple times: akun baru dibuat, akun lama password-nya di-rotate.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';

const professionals = [
  {
    email: 'dr.sari@psybot.id',
    nama: 'Dr. Sari Kusuma, Sp.KJ',
    spesialisasi: 'psikiater',
    nomor_lisensi: 'STR-PSYCH-001',
    bio: 'Psikiater berpengalaman 12 tahun dalam menangani depresi, kecemasan, bipolar, dan trauma. Lulusan FK Universitas Airlangga dengan spesialisasi kesehatan jiwa anak dan remaja.',
    tarif_per_sesi: 350000,
    tarif_gratis: false,
    jadwal_aktif: [
      { hari: 'senin', mulai: '09:00', selesai: '17:00' },
      { hari: 'rabu', mulai: '09:00', selesai: '15:00' },
      { hari: 'jumat', mulai: '10:00', selesai: '16:00' },
    ],
    rating: 4.9,
    total_sesi: 203,
    status_online: true,
    institusi_afiliasi: 'RS Jiwa Menur Surabaya',
  },
  {
    email: 'dr.budi@psybot.id',
    nama: 'Dr. Budi Santoso, Sp.KJ',
    spesialisasi: 'psikiater',
    nomor_lisensi: 'STR-PSYCH-002',
    bio: 'Psikiater dengan fokus pada gangguan mood, kecemasan, dan gangguan tidur. Pengalaman 8 tahun di RS Jiwa. Memberikan layanan konsultasi secara empatik dan berbasis bukti ilmiah.',
    tarif_per_sesi: 300000,
    tarif_gratis: false,
    jadwal_aktif: [
      { hari: 'selasa', mulai: '08:00', selesai: '14:00' },
      { hari: 'kamis', mulai: '08:00', selesai: '14:00' },
      { hari: 'sabtu', mulai: '09:00', selesai: '12:00' },
    ],
    rating: 4.7,
    total_sesi: 145,
    status_online: false,
    institusi_afiliasi: 'RSAL Dr. Ramelan Surabaya',
  },
  {
    email: 'maya.psi@psybot.id',
    nama: 'Maya Putri, M.Psi., Psikolog',
    spesialisasi: 'psikolog',
    nomor_lisensi: 'SIPP-PSI-003',
    bio: 'Psikolog klinis dengan keahlian dalam Cognitive Behavioral Therapy (CBT), terapi trauma, dan self-esteem. Lulusan S2 Psikologi Klinis UI. Berpengalaman mendampingi mahasiswa dan profesional muda.',
    tarif_per_sesi: 200000,
    tarif_gratis: false,
    jadwal_aktif: [
      { hari: 'senin', mulai: '10:00', selesai: '18:00' },
      { hari: 'rabu', mulai: '10:00', selesai: '18:00' },
      { hari: 'sabtu', mulai: '09:00', selesai: '13:00' },
    ],
    rating: 4.8,
    total_sesi: 178,
    status_online: true,
    institusi_afiliasi: 'Klinik Psikologi Mandiri Surabaya',
  },
  {
    email: 'rizky.psi@psybot.id',
    nama: 'Rizky Pratama, S.Psi., M.Psi.',
    spesialisasi: 'psikolog',
    nomor_lisensi: 'SIPP-PSI-004',
    bio: 'Psikolog dengan spesialisasi psikoterapi remaja dan dewasa muda. Menggunakan pendekatan humanistik dan mindfulness-based. Berpengalaman 5 tahun di komunitas kesehatan mental kampus.',
    tarif_per_sesi: 175000,
    tarif_gratis: false,
    jadwal_aktif: [
      { hari: 'selasa', mulai: '13:00', selesai: '20:00' },
      { hari: 'kamis', mulai: '13:00', selesai: '20:00' },
      { hari: 'minggu', mulai: '10:00', selesai: '14:00' },
    ],
    rating: 4.6,
    total_sesi: 89,
    status_online: true,
    institusi_afiliasi: 'Institut Teknologi Sepuluh Nopember (ITS)',
  },
  {
    email: 'dian.konselor@psybot.id',
    nama: 'Dian Anggraeni, M.Pd., Konselor',
    spesialisasi: 'konselor',
    nomor_lisensi: 'KONS-BKPI-005',
    bio: 'Konselor pendidikan dan karir dengan latar belakang Bimbingan dan Konseling. Spesialisasi: stres akademik, manajemen waktu, dan perencanaan karir. Melayani mahasiswa dan fresh graduate.',
    tarif_per_sesi: 100000,
    tarif_gratis: true,
    jadwal_aktif: [
      { hari: 'senin', mulai: '08:00', selesai: '16:00' },
      { hari: 'selasa', mulai: '08:00', selesai: '16:00' },
      { hari: 'rabu', mulai: '08:00', selesai: '16:00' },
      { hari: 'kamis', mulai: '08:00', selesai: '16:00' },
      { hari: 'jumat', mulai: '08:00', selesai: '12:00' },
    ],
    rating: 4.5,
    total_sesi: 67,
    status_online: false,
    institusi_afiliasi: 'BK Pusat Universitas Surabaya',
  },
];

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Password diambil dari secret (jangan hardcode di source — repo ini publik).
  // Set dengan: supabase secrets set SEED_PROF_PASSWORD=<password kuat>
  const seedPassword = Deno.env.get('SEED_PROF_PASSWORD');
  if (!seedPassword) {
    return new Response(
      JSON.stringify({ error: 'SEED_PROF_PASSWORD belum di-set. Jalankan: supabase secrets set SEED_PROF_PASSWORD=...' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }

  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const results: { email: string; status: string; error?: string }[] = [];

  for (const prof of professionals) {
    const { email, nama, ...profData } = prof;

    // Create auth user (idempotent via listUsers check)
    const { data: existingUsers } = await supabaseAdmin.auth.admin.listUsers();
    const existing = existingUsers?.users.find((u) => u.email === email);

    let userId: string;

    if (existing) {
      userId = existing.id;
      // Rotate password untuk akun yang sudah ada.
      const { error: pwError } = await supabaseAdmin.auth.admin.updateUserById(userId, {
        password: seedPassword,
      });
      results.push({
        email,
        status: pwError ? 'exists, password rotate failed' : 'exists, password rotated',
        error: pwError?.message,
      });
    } else {
      const { data, error } = await supabaseAdmin.auth.admin.createUser({
        email,
        password: seedPassword,
        user_metadata: { nama },
        email_confirm: true,
      });

      if (error || !data.user) {
        results.push({ email, status: 'error', error: error?.message });
        continue;
      }
      userId = data.user.id;
    }

    // Update role in public.users
    await supabaseAdmin
      .from('users')
      .update({ role: 'professional' })
      .eq('id', userId);

    // Insert into professionals (idempotent)
    const { error: profError } = await supabaseAdmin
      .from('professionals')
      .upsert(
        {
          id: userId,
          ...profData,
          status_verified: true,
        },
        { onConflict: 'id' },
      );

    if (profError) {
      results.push({ email, status: 'user ok, professional error', error: profError.message });
    } else {
      results.push({ email, status: existing ? 'professional upserted' : 'created' });
    }
  }

  return new Response(JSON.stringify({ results }), {
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
});
