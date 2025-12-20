-- Migration: Tables pour système de wishlist partagée / listes de cadeaux
-- Partage, réservation d'items, notifications

-- Table des wishlists partagées
CREATE TABLE IF NOT EXISTS public.shared_wishlists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  type VARCHAR(50) NOT NULL DEFAULT 'personal', -- 'personal', 'gift', 'wedding', 'birthday', 'anniversary', 'custom'
  is_public BOOLEAN NOT NULL DEFAULT FALSE,
  share_token VARCHAR(255) NOT NULL UNIQUE, -- Token unique pour partage
  event_date DATE, -- Date de l'événement (mariage, anniversaire, etc.)
  access_count INTEGER DEFAULT 0, -- Nombre de fois que la wishlist a été consultée
  last_accessed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_shared_wishlists_user ON public.shared_wishlists(user_id);
CREATE INDEX IF NOT EXISTS idx_shared_wishlists_token ON public.shared_wishlists(share_token);
CREATE INDEX IF NOT EXISTS idx_shared_wishlists_public ON public.shared_wishlists(is_public);
CREATE INDEX IF NOT EXISTS idx_shared_wishlists_type ON public.shared_wishlists(type);

-- Table des items de wishlist
CREATE TABLE IF NOT EXISTS public.shared_wishlist_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wishlist_id UUID NOT NULL REFERENCES public.shared_wishlists(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  product_title VARCHAR(255), -- Cache du titre (au cas où le produit est supprimé)
  product_price DECIMAL(10,2), -- Cache du prix
  product_image TEXT, -- Cache de l'image
  quantity INTEGER NOT NULL DEFAULT 1,
  priority VARCHAR(20) NOT NULL DEFAULT 'medium', -- 'low', 'medium', 'high'
  notes TEXT, -- Notes personnelles sur l'item
  reserved_by UUID REFERENCES public.users(id) ON DELETE SET NULL, -- Qui a réservé cet item
  reserved_at TIMESTAMPTZ,
  purchased_by UUID REFERENCES public.users(id) ON DELETE SET NULL, -- Qui a acheté cet item
  purchased_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_wishlist_items_wishlist ON public.shared_wishlist_items(wishlist_id);
CREATE INDEX IF NOT EXISTS idx_wishlist_items_product ON public.shared_wishlist_items(product_id);
CREATE INDEX IF NOT EXISTS idx_wishlist_items_reserved ON public.shared_wishlist_items(reserved_by);
CREATE INDEX IF NOT EXISTS idx_wishlist_items_purchased ON public.shared_wishlist_items(purchased_by);
CREATE INDEX IF NOT EXISTS idx_wishlist_items_priority ON public.shared_wishlist_items(priority);

-- Fonction pour incrémenter le compteur d'accès
CREATE OR REPLACE FUNCTION increment_wishlist_access(p_wishlist_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.shared_wishlists
  SET
    access_count = access_count + 1,
    last_accessed_at = NOW()
  WHERE id = p_wishlist_id;
END;
$$ LANGUAGE plpgsql;

-- RLS Policies
ALTER TABLE public.shared_wishlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shared_wishlist_items ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own wishlists
CREATE POLICY "Users can view own wishlists" ON public.shared_wishlists
  FOR SELECT USING (auth.uid() = user_id);

-- Policy: Public wishlists are viewable by anyone (via share_token)
CREATE POLICY "Public wishlists are viewable" ON public.shared_wishlists
  FOR SELECT USING (is_public = TRUE);

-- Policy: Users can manage their own wishlists
CREATE POLICY "Users can manage own wishlists" ON public.shared_wishlists
  FOR ALL USING (auth.uid() = user_id);

-- Policy: Users can view items of accessible wishlists
CREATE POLICY "Users can view wishlist items" ON public.shared_wishlist_items
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.shared_wishlists
      WHERE id = wishlist_id
      AND (user_id = auth.uid() OR is_public = TRUE)
    )
  );

-- Policy: Users can manage items of their own wishlists
CREATE POLICY "Users can manage own wishlist items" ON public.shared_wishlist_items
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.shared_wishlists
      WHERE id = wishlist_id
      AND user_id = auth.uid()
    )
  );

-- Policy: Anyone can reserve/purchase items in public wishlists
CREATE POLICY "Users can reserve items in public wishlists" ON public.shared_wishlist_items
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.shared_wishlists
      WHERE id = wishlist_id
      AND is_public = TRUE
    )
  );

-- Policy: Service role can manage all
CREATE POLICY "Service role can manage wishlists" ON public.shared_wishlists
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role can manage wishlist items" ON public.shared_wishlist_items
  FOR ALL USING (auth.role() = 'service_role');

