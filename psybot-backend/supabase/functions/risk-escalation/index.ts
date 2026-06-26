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

    const { data: { user } } = await createClient(
      SUPABASE_URL,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    ).auth.getUser();

    if (!user) throw new Error('Unauthorized');

    const {
      alertId,
      userChoice,
      callCenterName,
    } = await req.json();

    if (!alertId || !userChoice) throw new Error('alertId and userChoice required');
    if (!['contacted', 'declined'].includes(userChoice)) throw new Error('Invalid userChoice');

    const { data: alert } = await supabase
      .from('risk_alerts')
      .select('id, id_user, kategori_risiko')
      .eq('id', alertId)
      .eq('id_user', user.id)
      .single();

    if (!alert) throw new Error('Alert not found');

    await supabase.from('risk_alerts').update({
      call_center_contacted: userChoice === 'contacted',
      call_center_name: userChoice === 'contacted' ? (callCenterName ?? null) : null,
      user_responded_at: new Date().toISOString(),
      status_tindak_lanjut: userChoice === 'contacted' ? 'user_contacted' : 'user_declined',
    }).eq('id', alertId);

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

        await supabase.functions.invoke('send-notification', {
          body: {
            targetUserId: availableProfessional.id,
            title: 'Update: Pengguna Menghubungi Bantuan',
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
