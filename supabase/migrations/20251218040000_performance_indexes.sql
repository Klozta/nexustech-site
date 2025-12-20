-- Performance indexes: Index composites pour optimiser les queries fréquentes
-- Améliore les performances des requêtes sur orders, products, users

-- ============================================
-- ORDERS: Index composites pour filtres fréquents
-- ============================================

-- Index pour: WHERE status = ? AND created_at BETWEEN ? AND ?
-- Utilisé dans: /api/metrics/orders, /api/admin/orders
CREATE INDEX IF NOT EXISTS idx_orders_status_created_at
ON public.orders(status, created_at DESC);

-- Index pour: WHERE user_id = ? AND status = ? ORDER BY created_at DESC
-- Utilisé dans: /api/orders (liste commandes utilisateur)
CREATE INDEX IF NOT EXISTS idx_orders_user_status_created
ON public.orders(user_id, status, created_at DESC)
WHERE user_id IS NOT NULL;

-- Index pour: WHERE status = ? ORDER BY total DESC
-- Utilisé dans: métriques revenus, top commandes
CREATE INDEX IF NOT EXISTS idx_orders_status_total
ON public.orders(status, total DESC)
WHERE status != 'cancelled';

-- ============================================
-- PRODUCTS: Index composites pour recherche et filtres
-- ============================================

-- Index pour: WHERE category = ? AND stock > ? ORDER BY created_at DESC
-- Utilisé dans: /api/products (filtres catégorie + stock)
CREATE INDEX IF NOT EXISTS idx_products_category_stock_created
ON public.products(category, stock, created_at DESC)
WHERE deleted_at IS NULL;

-- Index pour: WHERE price BETWEEN ? AND ? AND category = ?
-- Utilisé dans: /api/products (filtres prix + catégorie)
CREATE INDEX IF NOT EXISTS idx_products_price_category
ON public.products(price, category)
WHERE deleted_at IS NULL;

-- Index pour: recherche full-text + filtres
-- Utilisé dans: /api/products/search
CREATE INDEX IF NOT EXISTS idx_products_title_tsvector
ON public.products USING gin(to_tsvector('french', coalesce(title, '') || ' ' || coalesce(description, '')))
WHERE deleted_at IS NULL;

-- ============================================
-- USERS: Index composites pour métriques
-- ============================================

-- Index pour: WHERE created_at BETWEEN ? AND ?
-- Utilisé dans: /api/metrics/users (inscriptions par période)
CREATE INDEX IF NOT EXISTS idx_users_created_at
ON public.users(created_at DESC);

-- Index pour: WHERE role = ? AND created_at BETWEEN ? AND ?
-- Utilisé dans: métriques utilisateurs actifs
CREATE INDEX IF NOT EXISTS idx_users_role_created
ON public.users(role, created_at DESC);

-- ============================================
-- ORDER_ITEMS: Index pour agrégations
-- ============================================

-- Index pour: GROUP BY product_id avec SUM(quantity)
-- Utilisé dans: métriques produits vendus
CREATE INDEX IF NOT EXISTS idx_order_items_product_quantity
ON public.order_items(product_id, quantity);

-- Index pour: WHERE order_id = ? (déjà couvert par FK, mais optimise les JOINs)
CREATE INDEX IF NOT EXISTS idx_order_items_order_id
ON public.order_items(order_id);

-- ============================================
-- REVIEWS: Index pour métriques avis
-- ============================================

-- Index pour: WHERE product_id = ? AND rating = ? ORDER BY created_at DESC
-- Utilisé dans: métriques reviews, affichage avis produits
CREATE INDEX IF NOT EXISTS idx_reviews_product_rating_created
ON public.reviews(product_id, rating, created_at DESC)
WHERE approved = true;

-- ============================================
-- ANALYTICS: Index pour attribution marketing
-- ============================================

-- Index pour: WHERE utm_source = ? AND created_at BETWEEN ? AND ?
-- Utilisé dans: /api/metrics/attribution
CREATE INDEX IF NOT EXISTS idx_orders_utm_source_created
ON public.orders(utm_source, created_at DESC)
WHERE utm_source IS NOT NULL;

-- Index pour: WHERE utm_campaign = ? AND created_at BETWEEN ? AND ?
CREATE INDEX IF NOT EXISTS idx_orders_utm_campaign_created
ON public.orders(utm_campaign, created_at DESC)
WHERE utm_campaign IS NOT NULL;

-- ============================================
-- COMMENTS
-- ============================================

-- Index pour optimiser les queries sur les commentaires
COMMENT ON INDEX idx_orders_status_created_at IS 'Optimise les requêtes métriques commandes par statut et date';
COMMENT ON INDEX idx_orders_user_status_created IS 'Optimise la liste des commandes utilisateur avec filtres';
COMMENT ON INDEX idx_products_category_stock_created IS 'Optimise les filtres produits par catégorie et stock';
COMMENT ON INDEX idx_products_price_category IS 'Optimise les filtres prix + catégorie';
COMMENT ON INDEX idx_products_title_tsvector IS 'Optimise la recherche full-text produits';
COMMENT ON INDEX idx_users_created_at IS 'Optimise les métriques utilisateurs par période';
COMMENT ON INDEX idx_order_items_product_quantity IS 'Optimise les agrégations produits vendus';
COMMENT ON INDEX idx_reviews_product_rating_created IS 'Optimise l''affichage et métriques des avis';
COMMENT ON INDEX idx_orders_utm_source_created IS 'Optimise les métriques attribution marketing par source';
COMMENT ON INDEX idx_orders_utm_campaign_created IS 'Optimise les métriques attribution marketing par campagne';

