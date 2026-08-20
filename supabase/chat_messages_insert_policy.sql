-- CotaFácil: permite que usuários autenticados enviem mensagens no chat.
-- O app já usa o usuário autenticado do Supabase como user_id.

ALTER TABLE public.quote_messages ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'quote_messages'
      AND policyname = 'Authenticated users can send quote messages'
  ) THEN
    CREATE POLICY "Authenticated users can send quote messages"
      ON public.quote_messages
      FOR INSERT
      TO authenticated
      WITH CHECK (user_id = auth.uid());
  END IF;
END
$$;
