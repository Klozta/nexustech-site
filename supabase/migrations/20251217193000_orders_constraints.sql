-- Orders constraints & indexes

-- Unique order number
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'orders_order_number_unique'
  ) then
    alter table public.orders
      add constraint orders_order_number_unique unique (order_number);
  end if;
end $$;

-- Allowed statuses
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'orders_status_check'
  ) then
    alter table public.orders
      add constraint orders_status_check
      check (status in ('pending','confirmed','shipped','delivered','cancelled'));
  end if;
end $$;

create index if not exists orders_status_created_at_idx on public.orders(status, created_at desc);


