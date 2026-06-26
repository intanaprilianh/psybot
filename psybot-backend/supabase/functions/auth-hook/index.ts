import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

serve(async (req) => {
  const { user } = await req.json();

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  );

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
