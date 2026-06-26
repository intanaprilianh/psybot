import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const MIDTRANS_SERVER_KEY = Deno.env.get('MIDTRANS_SERVER_KEY')!;

serve(async (req) => {
  try {
    const payload = await req.json();

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

    if (newStatus === 'success' && transaction) {
      const { data: consultation } = await supabase
        .from('consultations')
        .update({ status_pembayaran: 'paid', status: 'confirmed' })
        .eq('id_transaksi', transaction.id)
        .select('id, id_user, id_professional')
        .single();

      if (consultation) {
        await supabase.functions.invoke('send-notification', {
          body: {
            targetUserId: consultation.id_user,
            title: 'Pembayaran Berhasil',
            body: 'Konsultasi kamu sudah dikonfirmasi. Cek jadwalmu!',
            data: { type: 'payment_success', consultationId: consultation.id },
          },
        });

        await supabase.functions.invoke('send-notification', {
          body: {
            targetUserId: consultation.id_professional,
            title: 'Konsultasi Baru',
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
