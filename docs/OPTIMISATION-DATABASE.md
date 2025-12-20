# Guide d'Optimisation Database - Basé sur Recommandations Perplexity

Ce guide présente les optimisations PostgreSQL/Supabase à implémenter pour améliorer les performances de l'application e-commerce GirlyCrea.

## 📊 Vue d'ensemble

Pour des volumes moyens (milliers de produits, centaines de commandes/jour), les optimisations suivantes permettent d'atteindre :
- **87-97% d'amélioration** sur les requêtes fréquentes
- **Latence < 200ms** pour 99% des requêtes
- **Scalabilité linéaire** jusqu'à plusieurs millions de produits

## 🎯 Plan d'Implémentation par Phases

### Phase 1 : Index Composites Avancés (Semaine 1)

**Objectif** : Réduire les temps de requête de 40-60%

**Scripts à exécuter** :
1. `optimize-indexes.sql` (déjà créé - index de base)
2. `optimize-indexes-advanced.sql` (index avec INCLUDE pour index couvrants)

**Ordre d'exécution** :
```bash
# 1. Dans Supabase SQL Editor, exécuter d'abord:
optimize-indexes.sql

# 2. Puis exécuter (après vérification):
optimize-indexes-advanced.sql
```

**Validation** :
```sql
-- Vérifier les index créés
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('products', 'orders', 'order_items')
ORDER BY tablename, indexname;

-- Vérifier la taille
SELECT tablename, indexname, pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE schemaname = 'public' AND tablename IN ('products', 'orders');
```

**Gains attendus** :
- Recherche produit : 350ms → 45ms (87%)
- Liste catégorie : 280ms → 28ms (90%)

---

### Phase 2 : Vues Matérialisées (Semaine 2-3)

**Objectif** : Pré-agréger les données pour dashboard et rapports (50-60% amélioration)

**Script à exécuter** :
- `materialized-views.sql`

**Vues créées** :
1. `sales_summary_daily` - Résumé ventes par jour/catégorie
2. `top_products_hourly` - Produits populaires par heure
3. `sales_dashboard_realtime` - Dashboard ventes temps réel
4. `products_stats` - Statistiques produits (stock, ventes)

**Planification du rafraîchissement** (à configurer dans Supabase Dashboard → Database → Extensions → pg_cron) :
- `sales_dashboard_realtime` : Toutes les 15 minutes
- `top_products_hourly` : Toutes les heures
- `sales_summary_daily` : Quotidien à 2h
- `products_stats` : Quotidien à 3h

**Utilisation dans le code** :
```typescript
// Dashboard ventes 7 derniers jours
const { data } = await supabase
  .from('sales_dashboard_realtime')
  .select('*')
  .gte('period', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
  .order('period', { ascending: false });
```

**Gains attendus** :
- Dashboard ventes 30j : 2500ms → 120ms (95%)

---

### Phase 3 : Configuration Monitoring (Semaine 3)

**Objectif** : Identifier les requêtes lentes et goulots d'étranglement

**Script à exécuter** :
- `configure-pg-stat-statements.sql`

**Prérequis** : Extension `pg_stat_statements` activée (vérifier dans Supabase Dashboard)

**Requêtes utiles** (à exécuter périodiquement) :
```sql
-- Top 10 requêtes les plus lentes
SELECT * FROM analyze_slow_queries(10);

-- Requêtes avec cache hit rate faible (< 99%)
SELECT query, cache_hit_rate
FROM analyze_slow_queries(20)
WHERE cache_hit_rate < 99;
```

**Action** : Analyser mensuellement et créer de nouveaux index si nécessaire

---

### Phase 4 : Cache PostgreSQL Unlogged (Semaine 4)

**Objectif** : Alternative/complément à Redis pour volumes moyens (~7425 req/s)

**Script à exécuter** :
- `cache-postgresql-unlogged.sql`

**Quand l'utiliser** :
- Si Redis est indisponible ou coûteux
- Pour cache de session simple
- Pour compléter Redis (cache secondaire)

**Utilisation dans le code** :
```typescript
// Obtenir depuis cache
const { data } = await supabase.rpc('cache_get', {
  p_key: 'products:category:5'
});
if (data) return JSON.parse(data);

// Mettre en cache
await supabase.rpc('cache_set', {
  p_key: 'products:category:5',
  p_value: JSON.stringify(products),
  p_ttl_seconds: 3600
});

// Statistiques
const { data: stats } = await supabase.rpc('cache_stats');
```

**Planification nettoyage** :
- Nettoyer expirés : Toutes les 15 minutes
- Nettoyer LRU : Toutes les heures (si > 10K entrées)

**Gains attendus** :
- Inventaire temps réel : 450ms → 15ms (cache hit) (97%)

---

### Phase 5 : Partitionnement Temporel (Optionnel - Semaine 5+)

**Objectif** : Optimiser les requêtes temporelles pour table `orders` (70-90% réduction I/O)

**Quand l'implémenter** :
- Si table `orders` dépasse 100K lignes
- Si requêtes filtrant par date sont fréquentes
- Pour faciliter archivage des anciennes données

**Note** : Nécessite migration importante, à planifier avec précaution.

**Script** : À créer si nécessaire (non inclus pour l'instant)

---

## 📈 Benchmarks Réalistes

Pour **5000 produits**, **100-200 commandes/jour**, **50-100 users simultanés** :

| Opération | Avant | Après | Gain |
|-----------|-------|-------|------|
| Recherche produit (20 résultats) | 350ms | 45ms | **87%** |
| Liste catégorie (pagination) | 280ms | 28ms | **90%** |
| Dashboard ventes 30j | 2500ms | 120ms | **95%** |
| Détails commande + items | 180ms | 22ms | **88%** |
| Inventaire temps réel | 450ms | 15ms (cache) | **97%** |

---

## ✅ Checklist d'Implémentation

### Semaine 1 : Index
- [ ] Exécuter `optimize-indexes.sql`
- [ ] Valider index créés
- [ ] Exécuter `optimize-indexes-advanced.sql`
- [ ] Vérifier taille index (ne pas dépasser 50% de la taille des tables)
- [ ] Monitorer performances avec `EXPLAIN ANALYZE`

### Semaine 2 : Vues Matérialisées
- [ ] Exécuter `materialized-views.sql`
- [ ] Configurer pg_cron pour rafraîchissement automatique
- [ ] Tester requêtes sur vues matérialisées
- [ ] Intégrer dans code (routes métriques)
- [ ] Monitorer taille des vues (ne pas dépasser 10% de DB)

### Semaine 3 : Monitoring
- [ ] Activer extension `pg_stat_statements` (si disponible)
- [ ] Exécuter `configure-pg-stat-statements.sql`
- [ ] Créer dashboard de monitoring (requêtes lentes)
- [ ] Planifier analyse mensuelle
- [ ] Configurer alertes sur hit rate < 99%

### Semaine 4 : Cache
- [ ] Décider si cache PostgreSQL nécessaire (vs Redis actuel)
- [ ] Si oui, exécuter `cache-postgresql-unlogged.sql`
- [ ] Tester fonctions cache_get/cache_set
- [ ] Intégrer dans code (remplacer/complémenter Redis)
- [ ] Configurer nettoyage automatique
- [ ] Monitorer stats cache (cache_stats)

---

## 🔍 Monitoring Continu

### Cache Hit Rate (cible : 99%+)
```sql
SELECT
  'index hit rate' as metric,
  ROUND(100 * SUM(idx_blks_hit) / NULLIF(SUM(idx_blks_hit + idx_blks_read), 0), 2) as ratio
FROM pg_statio_user_indexes
UNION ALL
SELECT
  'table hit rate',
  ROUND(100 * SUM(heap_blks_hit) / NULLIF(SUM(heap_blks_hit + heap_blks_read), 0), 2)
FROM pg_statio_user_tables;
```

**Action si < 99%** : Upgrade plan Supabase (plus de RAM/shared_buffers)

### Requêtes Lentes (mensuel)
```sql
SELECT * FROM analyze_slow_queries(20);
```

**Action** : Créer index pour top 5 requêtes lentes

### Taille Vues Matérialisées
```sql
SELECT schemaname, matviewname,
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||matviewname)) AS size
FROM pg_matviews
WHERE schemaname = 'public';
```

**Action** : Si > 10% de la DB, optimiser ou archiver

---

## 📝 Notes Importantes

1. **Tester en staging d'abord** : Tous les scripts doivent être testés en environnement de développement/staging avant production

2. **Backup avant migration** : Toujours faire un backup avant d'exécuter les scripts en production

3. **Rollback plan** : Avoir un plan de rollback pour chaque phase

4. **Monitoring** : Surveiller les performances après chaque phase avant de passer à la suivante

5. **RLS Policies** : Optimiser les politiques RLS si nécessaire (éviter sous-requêtes complexes dans USING)

6. **Connection Pooling** : Supabase gère automatiquement, mais vérifier config dans Dashboard si problèmes de connexions

---

## 🔗 Références

- [Documentation Supabase](https://supabase.com/docs/guides/database/performance)
- [PostgreSQL Index Types](https://www.postgresql.org/docs/current/indexes-types.html)
- [Materialized Views](https://www.postgresql.org/docs/current/sql-creatematerializedview.html)
- [pg_stat_statements](https://www.postgresql.org/docs/current/pgstatstatements.html)

