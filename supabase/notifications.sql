create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  quote_id uuid references public.quotes(id) on delete cascade,
  title text not null,
  message text not null,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists notifications_user_created_idx
on public.notifications(user_id, created_at desc);

alter table public.notifications enable row level security;

drop policy if exists "Users can read own notifications" on public.notifications;
create policy "Users can read own notifications"
on public.notifications for select to authenticated
using (user_id = auth.uid());

drop policy if exists "Users can mark own notifications read" on public.notifications;
create policy "Users can mark own notifications read"
on public.notifications for update to authenticated
using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "Users can delete own notifications" on public.notifications;
create policy "Users can delete own notifications"
on public.notifications for delete to authenticated
using (user_id = auth.uid());

create or replace function public.create_quote_notifications()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  p record;
begin
  -- Nova cotação: avisa todos os usuários internos (qualquer perfil que não seja vendedor).
  if tg_op = 'INSERT' then
    for p in
      select id from public.profiles
      where role is distinct from 'vendedor'
    loop
      insert into public.notifications(user_id, quote_id, title, message)
      values(p.id, new.id, 'Nova cotação',
             'Uma nova cotação foi enviada para Compras.');
    end loop;

  -- Mudança de status: avisa o vendedor dono da cotação.
  elsif tg_op = 'UPDATE' and old.status is distinct from new.status then
    if new.status in ('AGUARDANDO_DECISAO','PEDIDO','VENDIDA','NAO_VENDIDA') then
      insert into public.notifications(user_id, quote_id, title, message)
      values(
        new.seller_id,
        new.id,
        'Cotação atualizada',
        case new.status
          when 'AGUARDANDO_DECISAO' then 'Sua cotação foi respondida e aguarda sua decisão.'
          when 'PEDIDO' then 'Um pedido foi confirmado.'
          when 'VENDIDA' then 'Uma peça foi registrada como vendida.'
          when 'NAO_VENDIDA' then 'Uma peça foi marcada como não vendida.'
        end
      );
    end if;
  end if;

  return new;
end;
$$;

drop trigger if exists quotes_create_notifications on public.quotes;
create trigger quotes_create_notifications
after insert or update of status on public.quotes
for each row execute function public.create_quote_notifications();

alter table public.notifications replica identity full;

-- Habilita atualizações em tempo real para o sino do sistema.
do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'notifications'
  ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;
