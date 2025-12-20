# 🚀 Démarrage Rapide - Backend

> **Guide ultra-rapide pour démarrer le backend**

---

## ⚡ 3 ÉTAPES

### 1. Installer dépendances

```bash
cd girlycrea-site/backend
npm install
```

---

### 2. Configurer .env

Le fichier `.env` a été créé automatiquement avec les secrets JWT.

**À compléter** :
- `SUPABASE_URL` : URL de ton projet Supabase
- `SUPABASE_KEY` : Clé API Supabase

**Déjà configuré** :
- ✅ `JWT_SECRET` : Généré automatiquement
- ✅ `JWT_REFRESH_SECRET` : Généré automatiquement
- ✅ `PORT=3001`
- ✅ `CORS_ORIGIN=http://localhost:3000`

---

### 3. Lancer

```bash
# Option 1 : tsx watch (par défaut, plus rapide)
npm run dev

# Option 2 : nodemon (plus robuste si tsx watch ne redémarre pas)
npm run dev:nodemon
```

Le serveur démarre sur `http://localhost:3001`

**Note** : Si le serveur ne redémarre pas automatiquement après modification de fichiers, utilisez `npm run dev:nodemon` qui est plus robuste.

**Vérifier** :
```bash
curl http://localhost:3001/health
```

---

## ✅ VÉRIFICATIONS

### Secrets validés au démarrage

Si les secrets sont manquants ou invalides, le serveur ne démarre pas avec un message d'erreur clair.

**Exemple erreur** :
```
❌ Secret validation failed: Missing required secrets: JWT_SECRET
Please check your .env file and ensure all required secrets are set.
```

---

### Rate Limiting actif

Tester avec :
```bash
# Faire 101 requêtes rapidement
for i in {1..101}; do curl http://localhost:3001/api; done

# La 101ème devrait retourner 429 Too Many Requests
```

---

## 🐛 DÉPANNAGE

### Erreur "Missing required secrets"

→ Vérifier que `.env` contient tous les secrets requis

### Erreur "Module not found"

→ Exécuter `npm install`

### Port 3001 déjà utilisé

→ Arrêter le processus ou changer le port dans `.env`

---

## 📋 PROCHAINES ÉTAPES

Une fois le backend lancé :

1. **Prompt 4** : Service Authentification
2. **Prompt 5** : Service Produits
3. **Prompt 14** : Core Web Vitals (Frontend)

---

**Backend prêt → Prompts 4-5 → API complète ! 🚀**
