-- Email idempotence for order confirmations

alter table public.orders
  add column if not exists email_sent_at timestamptz null;

create index if not exists orders_email_sent_at_idx on public.orders(email_sent_at);


