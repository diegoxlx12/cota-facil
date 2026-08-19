-- CotaFácil: distribuidor da cotação
alter table public.quotes
add column if not exists distributor text;
