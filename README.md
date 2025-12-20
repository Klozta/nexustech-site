# 🚀 GirlyCrea Backend API

> **Stack** : Node.js 20+ | Express | TypeScript | Supabase | Redis

---

## 🚀 Démarrage Rapide

### 1. Installation

```bash
cd girlycrea-site/backend
npm install
```

### 2. Configuration

```bash
# Copier le template
cp .env.template .env

# Éditer .env et ajouter :
# - SUPABASE_URL
# - SUPABASE_KEY
# - JWT_SECRET (générer avec: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))")
# - JWT_REFRESH_SECRET (générer de la même manière)
```

### 3. Lancer

```bash
npm run dev
```

Le serveur démarre sur `http://localhost:3001`

---

## 📁 Structure

```
backend/
├── src/
│   ├── config/
│   │   └── secrets.ts          # Validation secrets
│   ├── middleware/
│   │   ├── rateLimit.middleware.ts  # Rate limiting
│   │   ├── validate.middleware.ts   # Validation inputs
│   │   └── timeout.middleware.ts    # Timeout requêtes
│   ├── routes/                  # Routes API (à créer)
│   ├── services/                # Logique métier (à créer)
│   ├── utils/
│   │   └── securityLogger.ts   # Logging sécurité
│   └── validations/
│       └── schemas.ts           # Schemas Zod
└── index.ts                     # Point d'entrée
```

---

## 🔒 Sécurité

### Implémenté ✅

- ✅ Validation secrets au démarrage
- ✅ Rate limiting global (100 req/15min)
- ✅ Rate limiting auth (5 req/15min)
- ✅ Timeout requêtes (30s)
- ✅ Validation inputs (Zod)
- ✅ Logging sécurité
- ✅ Helmet (headers sécurité)
- ✅ CORS configuré

### Implémenté ✅ (suite)

- ✅ Authentification JWT
- ✅ Middleware auth
- ✅ Documentation API interactive (Swagger/OpenAPI)
- ⏳ RLS Policies Supabase

---

## 📋 Endpoints

### Disponibles

- `GET /health` - Health check
- `GET /api` - Info API
- `GET /api-docs/swagger` - **Documentation API interactive (Swagger UI)**
- `GET /api-docs/swagger.json` - Spécification OpenAPI (JSON)

### Documentation API

La documentation API est disponible via Swagger UI :

**URL**: `http://localhost:3001/api-docs/swagger`

La documentation interactive permet de :
- 📖 Parcourir tous les endpoints
- 🔍 Tester les endpoints directement depuis le navigateur
- 📝 Voir les schémas de requêtes/réponses
- 🔑 Tester l'authentification (Bearer token ou Cookie)

### À créer (Prompts 4-5)

- `POST /api/auth/register` - Inscription
- `POST /api/auth/login` - Connexion
- `POST /api/auth/refresh` - Refresh token
- `POST /api/auth/logout` - Déconnexion
- `GET /api/auth/me` - Utilisateur actuel
- `GET /api/products` - Liste produits
- `GET /api/products/search` - Recherche
- `GET /api/products/:id` - Détail produit

---

## 🛠️ Scripts

```bash
npm run dev        # Développement (watch mode)
npm run build      # Build production
npm run start      # Production
npm run type-check # Vérification types
npm run lint       # Linter
```

---

## 🔧 Configuration

### Variables d'environnement

Voir `.env.template` pour la liste complète.

**Requis** :
- `SUPABASE_URL`
- `SUPABASE_KEY`
- `JWT_SECRET` (min 32 chars)
- `JWT_REFRESH_SECRET` (min 32 chars)

**Optionnel** :
- `PORT` (défaut: 3001)
- `NODE_ENV` (défaut: development)
- `CORS_ORIGIN` (défaut: http://localhost:3000)

---

## 📊 Monitoring

- **Sentry** : Erreurs (à configurer)
- **PostHog** : Analytics (à configurer)
- **Logs** : Console + Security Logger

---

## 🚀 Prochaines Étapes

1. **Prompt 4** : Service Authentification
2. **Prompt 5** : Service Produits
3. **Prompt 14** : Core Web Vitals (Frontend)

---

**Backend prêt → Prompts 4-5 → API complète ! 🚀**
