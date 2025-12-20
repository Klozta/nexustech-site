# 🤖 Bot Detection Middleware - Documentation

## Vue d'ensemble

Le middleware `botDetectionMiddleware` identifie et log les requêtes provenant de bots (crawlers, scrapers) tout en excluant automatiquement les processus automatisés légitimes du site.

## Routes Exclues Automatiquement

Les routes suivantes sont **automatiquement exclues** de la détection de bots :

### Génération Automatique de Produits
- `/api/products/auto-generate` - Génération depuis image
- `/api/products/auto-generate/create` - Génération + création
- `/api/products/auto-generate/recognize` - Reconnaissance image

### Import de Produits
- `/api/products/import` - Import depuis URL
- `/api/products/batch-import` - Import batch
- `/api/products/auto-queue` - Queue AliExpress (toutes les sous-routes)

### Tâches Système
- `/api/cron/*` - Toutes les tâches cron/scheduled
- `/api/health/*` - Health checks
- `/api/metrics/*` - Métriques système

## Bypass avec Headers

Vous pouvez aussi utiliser des headers spéciaux pour identifier les requêtes automatisées :

```bash
# Header pour requête automatisée
X-Automated-Request: true

# Header pour requête cron
X-Cron-Key: votre-clé-cron

# Header pour requête interne
X-Internal-Request: true
```

## Comportement

### Routes Publiques (Non Exclues)
- Les bots sont détectés et loggés en niveau `DEBUG`
- Un header `X-Bot-Detected: true` est ajouté à la réponse
- Les requêtes ne sont **PAS bloquées**, seulement identifiées

### Routes Automatisées (Exclues)
- Aucune détection de bot
- Aucun log
- Fonctionnement normal garanti

## Exemple d'Utilisation

### Requête Automatisée Légitime

```bash
# Avec header spécial
curl -X POST https://api.girlycrea.com/api/products/auto-generate \
  -H "X-Automated-Request: true" \
  -H "Content-Type: multipart/form-data" \
  -F "image=@product.jpg"

# Ou simplement utiliser une route exclue
curl -X POST https://api.girlycrea.com/api/products/import \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com/product"}'
```

### Requête Bot Détectée

```bash
# Bot détecté (mais pas bloqué)
curl -H "User-Agent: Googlebot/2.1" \
  https://api.girlycrea.com/api/products

# Réponse inclut :
# X-Bot-Detected: true
```

## Logs

Les bots détectés sont loggés avec `structuredLogger.debug()` :

```json
{
  "level": "debug",
  "message": "Bot detected",
  "userAgent": "Googlebot/2.1",
  "path": "/api/products",
  "ip": "66.249.64.1"
}
```

## Configuration

Le middleware est configuré dans `backend/src/index.ts` :

```typescript
// Détection de bots (après requestContextMiddleware)
app.use(botDetectionMiddleware);
```

**Position importante** : Le middleware doit être placé après `requestContextMiddleware` pour avoir accès au contexte enrichi.

---

**Note** : Ce middleware ne bloque jamais les requêtes, il les identifie seulement pour le monitoring et l'analytique.





