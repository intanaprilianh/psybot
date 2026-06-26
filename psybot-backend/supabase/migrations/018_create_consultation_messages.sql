-- 018_create_consultation_messages.sql
-- Pesan antara user dan profesional dalam sesi konsultasi (plaintext, bukan AI chat)
CREATE TABLE public.consultation_messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_consultation UUID NOT NULL REFERENCES public.consultations(id) ON DELETE CASCADE,
  id_sender       UUID NOT NULL REFERENCES public.users(id),
  isi_pesan       TEXT NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_consultation_messages_consultation ON public.consultation_messages(id_consultation);
CREATE INDEX idx_consultation_messages_created ON public.consultation_messages(created_at);

ALTER TABLE public.consultation_messages ENABLE ROW LEVEL SECURITY;

-- User dapat membaca pesan dari konsultasinya sendiri
CREATE POLICY "user_read_consultation_messages"
  ON public.consultation_messages FOR SELECT TO authenticated
  USING (
    id_consultation IN (
      SELECT id FROM public.consultations WHERE id_user = auth.uid()
    )
  );

-- User dapat mengirim pesan ke konsultasinya sendiri
CREATE POLICY "user_send_consultation_messages"
  ON public.consultation_messages FOR INSERT TO authenticated
  WITH CHECK (
    id_sender = auth.uid()
    AND id_consultation IN (
      SELECT id FROM public.consultations WHERE id_user = auth.uid()
    )
  );

-- Profesional dapat membaca dan mengirim pesan di konsultasi mereka
-- professionals.id = auth.users.id (PK references users.id)
CREATE POLICY "professional_read_consultation_messages"
  ON public.consultation_messages FOR SELECT TO authenticated
  USING (
    id_consultation IN (
      SELECT id FROM public.consultations
      WHERE id_professional = auth.uid()
    )
  );

CREATE POLICY "professional_send_consultation_messages"
  ON public.consultation_messages FOR INSERT TO authenticated
  WITH CHECK (
    id_sender = auth.uid()
    AND id_consultation IN (
      SELECT id FROM public.consultations
      WHERE id_professional = auth.uid()
    )
  );

-- Aktifkan Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.consultation_messages;

COMMENT ON TABLE public.consultation_messages IS 'Pesan antara user dan profesional dalam sesi konsultasi.';
