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

    const { data: consultation } = await supabase
      .from('consultations')
      .select('*, professionals(tarif_per_sesi, tarif_gratis), users!consultations_id_user_fkey(nama, email)')
      .eq('id', consultationId)
      .eq('id_user', user.id)
      .single();

    if (!consultation) throw new Error('Consultation not found');
    if (consultation.status_pembayaran === 'paid') throw new Error('Already paid');
    if (consultation.professionals.tarif_gratis) {
      await supabase.from('consultations').update({ status_pembayaran: 'free', status: 'confirmed' }).eq('id', consultationId);
      return new Response(JSON.stringify({ free: true }), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } });
    }

    const amount = consultation.professionals.tarif_per_sesi;
    const orderId = `PSYBOT-${consultationId.slice(0, 8)}-${Date.now()}`;

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
