-- CotaFácil: marcas similares por cotação
alter table public.quotes
add column if not exists alternatives jsonb not null default '[]'::jsonb;

-- Atualiza o cache do PostgREST para a nova coluna ficar disponível na API.
notify pgrst, 'reload schema';
