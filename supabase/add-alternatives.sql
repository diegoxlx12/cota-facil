-- CotaFácil: marcas similares por cotação
alter table public.quotes
add column if not exists alternatives jsonb not null default '[]'::jsonb;

alter table public.quotes
add column if not exists selected_alternative jsonb;

notify pgrst, 'reload schema';
