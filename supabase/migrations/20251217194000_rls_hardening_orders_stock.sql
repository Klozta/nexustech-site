-- RLS hardening: prevent guest order leakage + protect stock RPC

-- ORDERS: do not allow anonymous access to orders where user_id is NULL.
-- Guests should use the public-status endpoint (orderId+orderNumber) instead.
alter table public.orders enable row level security;

drop policy if exists "Own orders only" on public.orders;
create policy "Own orders only" on public.orders
for select
using (user_id = auth.uid());

-- Keep service_role and admin policies (if present) unchanged.

-- STOCK RPC: should not be executable by anon/authenticated.
revoke execute on function public.decrement_product_stock(uuid, int) from anon;
revoke execute on function public.decrement_product_stock(uuid, int) from authenticated;
grant execute on function public.decrement_product_stock(uuid, int) to service_role;


