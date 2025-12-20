-- Stripe webhook idempotence + audit
-- Stores received Stripe events to prevent double-processing.

create table if not exists public.stripe_webhook_events (
  id uuid primary key default gen_random_uuid(),
  stripe_event_id text not null unique,
  event_type text not null,
  order_id uuid null,
  processed_at timestamptz not null default now(),
  raw jsonb null
);

-- Helpful indexes
create index if not exists stripe_webhook_events_order_id_idx on public.stripe_webhook_events(order_id);
create index if not exists stripe_webhook_events_processed_at_idx on public.stripe_webhook_events(processed_at desc);


