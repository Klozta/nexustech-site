-- Audit tables: order_status_events, stripe_order_refs, order_notifications
-- Pour traçabilité complète des transitions de statut, références Stripe, et notifications idempotentes

-- ============================================
-- TABLE: order_status_events
-- ============================================
CREATE TABLE IF NOT EXISTS public.order_status_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  from_status TEXT NOT NULL CHECK (from_status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled')),
  to_status TEXT NOT NULL CHECK (to_status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled')),
  actor TEXT NOT NULL CHECK (actor IN ('admin', 'stripe', 'system', 'user')),
  stripe_event_id TEXT NULL,
  request_id TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_status_events_order_id ON public.order_status_events(order_id);
CREATE INDEX IF NOT EXISTS idx_order_status_events_created_at ON public.order_status_events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_order_status_events_actor ON public.order_status_events(actor);

-- ============================================
-- TABLE: stripe_order_refs
-- ============================================
CREATE TABLE IF NOT EXISTS public.stripe_order_refs (
  order_id UUID PRIMARY KEY REFERENCES public.orders(id) ON DELETE CASCADE,
  stripe_event_id TEXT NOT NULL,
  stripe_event_type TEXT NOT NULL,
  checkout_session_id TEXT NULL,
  payment_intent_id TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_stripe_order_refs_stripe_event_id ON public.stripe_order_refs(stripe_event_id);
CREATE INDEX IF NOT EXISTS idx_stripe_order_refs_checkout_session_id ON public.stripe_order_refs(checkout_session_id);
CREATE INDEX IF NOT EXISTS idx_stripe_order_refs_payment_intent_id ON public.stripe_order_refs(payment_intent_id);

-- Trigger updated_at
CREATE OR REPLACE FUNCTION update_stripe_order_refs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS stripe_order_refs_updated_at_trigger ON public.stripe_order_refs;
CREATE TRIGGER stripe_order_refs_updated_at_trigger
  BEFORE UPDATE ON public.stripe_order_refs
  FOR EACH ROW
  EXECUTE FUNCTION update_stripe_order_refs_updated_at();

-- ============================================
-- TABLE: order_notifications
-- ============================================
CREATE TABLE IF NOT EXISTS public.order_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('shipped', 'delivered')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Unique constraint pour idempotence (un seul email shipped/delivered par commande)
  UNIQUE(order_id, type)
);

CREATE INDEX IF NOT EXISTS idx_order_notifications_order_id ON public.order_notifications(order_id);
CREATE INDEX IF NOT EXISTS idx_order_notifications_type ON public.order_notifications(type);
CREATE INDEX IF NOT EXISTS idx_order_notifications_created_at ON public.order_notifications(created_at DESC);

-- ============================================
-- RLS (si activé sur orders)
-- ============================================
-- Les tables d'audit sont en lecture seule pour les admins uniquement
-- (pas de RLS car accès via requireAdminAuth uniquement)
