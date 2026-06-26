import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { corsHeaders } from '../_shared/cors.ts';
import { encryptMessage, decryptMessage } from '../_shared/encryption.ts';
import { detectRiskFromText, RiskLevel } from '../_shared/risk-keywords.ts';
import { getServicesForRiskLevel } from '../_shared/call-center.ts';

const LLM_API_KEY = Deno.env.get('LLM_API_KEY')!;
const LLM_BASE_URL = Deno.env.get('LLM_BASE_URL') || 'https://api.deepseek.com';
const LLM_MODEL = Deno.env.get('LLM_MODEL') || 'deepseek-chat';
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

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
- Jangan memberikan diagnosis medis dalam bentuk apapun
- Jangan merekomendasikan obat-obatan atau dosis
- Jangan menggantikan atau menyarankan penghentian terapi yang sedang berjalan
- Jangan memberikan saran medis spesifik
- Jangan berperilaku seolah-olah kamu manusia sungguhan jika ditanya langsung
- Jangan menggunakan kata-kata yang bisa memicu atau memperparah kondisi pengguna
- Jangan memaksa pengguna untuk menghubungi siapa pun — pilihan selalu ada di tangan mereka

FORMAT RESPONS:
- Maksimal 3 paragraf per respons
- Mulai dengan memvalidasi perasaan pengguna
- Gunakan kalimat yang hangat, bukan klinis/teknis
- Akhiri dengan pertanyaan terbuka atau tawaran teknik self-help jika relevan`;

async function getChatHistory(
  supabase: ReturnType<typeof createClient>,
  sessionId: string,
  maxMessages = 20
): Promise<Array<{ role: 'user' | 'assistant'; content: string }>> {
  const { data: messages } = await supabase
    .from('messages')
    .select('pengirim_tipe, isi_pesan_terenkripsi, iv')
    .eq('id_session', sessionId)
    .is('deleted_at', null)
    .order('waktu', { ascending: false })
    .limit(maxMessages);

  if (!messages) return [];

  const decryptedMessages = await Promise.all(
    messages.reverse().map(async (msg) => ({
      role: msg.pengirim_tipe === 'user' ? 'user' as const : 'assistant' as const,
      content: await decryptMessage(msg.isi_pesan_terenkripsi, msg.iv),
    }))
  );

  return decryptedMessages;
}

async function saveMessage(
  supabase: ReturnType<typeof createClient>,
  sessionId: string,
  senderType: 'user' | 'ai',
  plaintext: string,
  isFlagged = false,
  flagReason?: string
): Promise<void> {
  const { ciphertext, iv } = await encryptMessage(plaintext);

  await supabase.from('messages').insert({
    id_session: sessionId,
    pengirim_tipe: senderType,
    isi_pesan_terenkripsi: ciphertext,
    iv,
    is_flagged: isFlagged,
    flag_reason: flagReason ?? null,
  });
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) throw new Error('Missing authorization');

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const token = authHeader.replace('Bearer ', '');
    const { data: { user }, error: authError } = await createClient(
      SUPABASE_URL,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    ).auth.getUser(token);

    if (authError || !user) throw new Error('Unauthorized');

    const { sessionId, message } = await req.json();
    if (!sessionId || !message) throw new Error('sessionId and message required');

    const { data: session } = await supabase
      .from('chat_sessions')
      .select('id, id_user, status_risiko, status_sesi')
      .eq('id', sessionId)
      .eq('id_user', user.id)
      .single();

    if (!session) throw new Error('Session not found');
    if (session.status_sesi !== 'active') throw new Error('Session is not active');

    const riskDetection = detectRiskFromText(message);

    await saveMessage(
      supabase, sessionId, 'user', message,
      riskDetection.level !== 'low',
      riskDetection.level !== 'low' ? 'keyword_detected' : undefined
    );

    await supabase.rpc('log_audit', {
      p_aktor_id: user.id,
      p_aktor_tipe: 'user',
      p_aksi: 'send_chat_message',
      p_resource_tipe: 'chat_sessions',
      p_resource_id: sessionId,
      p_detail: { risk_level: riskDetection.level, keyword_count: riskDetection.triggeredKeywords.length },
    });

    if (riskDetection.level === 'critical') {
      const escalationMessage = 'Aku dengar kamu, dan aku sangat peduli dengan kondisimu sekarang. Kamu tidak sendirian dalam hal ini. Aku ingin memperkenalkan kamu dengan beberapa orang yang bisa menemanimu lebih jauh — sepenuhnya pilihanmu apakah ingin menghubungi atau tidak. Tidak ada tekanan sama sekali.';

      await saveMessage(supabase, sessionId, 'ai', escalationMessage, true, 'keyword_detected');

      const { data: alert } = await supabase.from('risk_alerts').insert({
        id_user: user.id,
        id_session: sessionId,
        kategori_risiko: 'critical',
        trigger: `keyword_detected: ${riskDetection.triggeredKeywords.join(', ')}`,
        escalation_type: 'keyword_detected',
        call_center_offered: true,
        status_tindak_lanjut: 'call_center_offered',
      }).select().single();

      await supabase.from('chat_sessions')
        .update({ status_risiko: 'critical' })
        .eq('id', sessionId);

      const callCenterServices = getServicesForRiskLevel('critical');

      return new Response(
        JSON.stringify({
          response: escalationMessage,
          riskLevel: 'critical',
          showCallCenter: true,
          alertId: alert?.id,
          callCenterServices,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const history = await getChatHistory(supabase, sessionId);

    const llmMessages: Array<{ role: string; content: string }> = [
      { role: 'system', content: SYSTEM_PROMPT },
    ];

    // Risiko menengah/tinggi (tapi belum kritis): minta AI membalas ekstra
    // hati-hati. Tidak memicu panggilan darurat — hanya balasan yang lebih peka.
    if (riskDetection.level === 'high' || riskDetection.level === 'medium') {
      llmMessages.push({
        role: 'system',
        content:
          'PERHATIAN KHUSUS: Pesan pengguna mengandung sinyal emosional yang perlu diperhatikan, walau belum kritis. Balas dengan ekstra hati-hati dan lembut: validasi perasaannya tanpa menghakimi, hindari kata-kata yang bisa memicu, gali perasaannya dengan satu pertanyaan terbuka, dan ingatkan secara halus bahwa dia tidak sendirian serta ada bantuan profesional bila dia mau — tanpa memaksa.',
      });
    }

    llmMessages.push(...history, { role: 'user', content: message });

    const openaiResponse = await fetch(`${LLM_BASE_URL}/v1/chat/completions`, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${LLM_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: LLM_MODEL,
        messages: llmMessages,
        max_tokens: 500,
        temperature: 0.7,
        frequency_penalty: 0.3,
      }),
    });

    if (!openaiResponse.ok) {
      const err = await openaiResponse.text();
      throw new Error(`OpenAI API error: ${err}`);
    }

    const aiData = await openaiResponse.json();
    const aiMessage = aiData.choices[0].message.content;

    await saveMessage(supabase, sessionId, 'ai', aiMessage);

    if (riskDetection.level === 'high' && session.status_risiko !== 'high' && session.status_risiko !== 'critical') {
      await supabase
        .from('chat_sessions')
        .update({ status_risiko: 'high' })
        .eq('id', sessionId);

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
          showCallCenter: true,
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
