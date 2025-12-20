-- Ajout colonnes attribution marketing (UTM, referrer) dans orders

alter table public.orders
  add column if not exists utm_source text null,
  add column if not exists utm_medium text null,
  add column if not exists utm_campaign text null,
  add column if not exists utm_term text null,
  add column if not exists utm_content text null,
  add column if not exists referrer text null,
  add column if not exists landing_page text null;

-- Index pour requêtes analytics (filtrer par source/campaign)
create index if not exists orders_utm_source_idx on public.orders (utm_source) where utm_source is not null;
create index if not exists orders_utm_campaign_idx on public.orders (utm_campaign) where utm_campaign is not null;


