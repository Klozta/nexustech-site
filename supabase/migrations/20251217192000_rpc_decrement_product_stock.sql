-- Atomic stock decrement RPC to avoid oversell

create or replace function public.decrement_product_stock(p_product_id uuid, p_quantity int)
returns int
language plpgsql
security definer
set search_path = public
as $$
declare
  new_stock int;
begin
  if p_quantity is null or p_quantity <= 0 then
    raise exception 'quantity must be positive';
  end if;

  update public.products
    set stock = stock - p_quantity
    where id = p_product_id
      and stock >= p_quantity
    returning stock into new_stock;

  if new_stock is null then
    raise exception 'insufficient_stock';
  end if;

  return new_stock;
end;
$$;

grant execute on function public.decrement_product_stock(uuid, int) to anon, authenticated;


