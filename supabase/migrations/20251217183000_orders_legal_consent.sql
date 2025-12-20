-- Ajout stockage consentement légal (CGV/Privacy) lors du checkout

alter table public.orders
  add column if not exists legal_consent_at timestamptz null,
  add column if not exists legal_consent_version text null;

create index if not exists orders_legal_consent_at_idx on public.orders (legal_consent_at);


