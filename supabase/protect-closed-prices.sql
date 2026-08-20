-- CotaFácil: impede alteração de preço/distribuidor/marcas similares depois que a cotação foi concluída.
create or replace function public.prevent_closed_quote_price_change()
returns trigger
language plpgsql
as $$
begin
  if old.status not in ('AGUARDANDO_COTACAO', 'AGUARDANDO_DECISAO')
     and (
       new.cash is distinct from old.cash
       or new.credit is distinct from old.credit
       or new.distributor is distinct from old.distributor
       or new.alternatives is distinct from old.alternatives
     ) then
    raise exception 'Cotação encerrada: preço, distribuidor e marcas similares não podem mais ser alterados.';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_protect_closed_quote_price on public.quotes;
create trigger trg_protect_closed_quote_price
before update on public.quotes
for each row execute function public.prevent_closed_quote_price_change();

notify pgrst, 'reload schema';
