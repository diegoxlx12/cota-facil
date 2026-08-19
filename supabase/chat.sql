-- CotaFácil: chat por cotação
create table if not exists public.quote_messages (
  id uuid primary key default gen_random_uuid(),
  quote_id uuid not null references public.quotes(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  message text not null check (char_length(trim(message)) > 0),
  created_at timestamptz not null default now()
);
create index if not exists quote_messages_quote_id_idx on public.quote_messages(quote_id, created_at);
alter table public.quote_messages enable row level security;
drop policy if exists "quote_messages_select" on public.quote_messages;
create policy "quote_messages_select" on public.quote_messages for select to authenticated using (
  exists (select 1 from public.quotes q where q.id=quote_id and (q.seller_id=auth.uid() or public.get_my_role() in ('compras','admin')))
);
drop policy if exists "quote_messages_insert" on public.quote_messages;
create policy "quote_messages_insert" on public.quote_messages for insert to authenticated with check (
  user_id=auth.uid() and exists (select 1 from public.quotes q where q.id=quote_id and (q.seller_id=auth.uid() or public.get_my_role() in ('compras','admin')))
);
