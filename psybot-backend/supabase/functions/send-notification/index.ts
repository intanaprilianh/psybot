import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

serve(async (req) => {
  try {
    const { targetUserId, title, body, data } = await req.json();

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: profile } = await supabase
      .from('user_profile')
      .select('fcm_token')
      .eq('id_user', targetUserId)
      .single();

    if (!profile?.fcm_token) {
      console.log(`No FCM token for user ${targetUserId}`);
      return new Response(JSON.stringify({ skipped: true }), { status: 200 });
    }

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

  // TODO: Implement JWT signing with serviceAccountJson.private_key
  // For production, use library djwt or jose
  throw new Error('Implement JWT signing with serviceAccountJson.private_key');
}
