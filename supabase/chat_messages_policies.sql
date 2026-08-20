-- CotaFácil: políticas do chat
ALTER TABLE public.quote_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Authenticated users can send quote messages" ON public.quote_messages;
CREATE POLICY "Authenticated users can send quote messages"
ON public.quote_messages
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Authenticated users can read quote messages" ON public.quote_messages;
CREATE POLICY "Authenticated users can read quote messages"
ON public.quote_messages
FOR SELECT
TO authenticated
USING (true);

-- Permite o Realtime entregar novas mensagens aos usuários autenticados.
ALTER TABLE public.quote_messages REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'quote_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.quote_messages;
  END IF;
END $$;
