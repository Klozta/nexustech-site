# 🚀 Déploiement Rapide Backend - Guide Express

Guide rapide pour déployer le backend sur Render après les optimisations 2025.

## ⚡ Déploiement en 3 Étapes

### 1. Vérifier le Build

```bash
cd girlycrea-site/backend
npm run build
```

✅ Si le build réussit, vous pouvez déployer.

### 2. Choisir la Méthode de Déploiement

#### Option A : Déploiement Automatique via Git (Recommandé)

```bash
# 1. Ajouter tous les fichiers
git add .

# 2. Commiter
git commit -m "Deploy: Security & optimizations 2025 - Complete"

# 3. Push (Render déploie automatiquement)
git push origin main
```

**Prérequis** : Le repo doit être connecté à Render Dashboard.

#### Option B : Déploiement via Render Dashboard

1. Aller sur https://dashboard.render.com
2. Sélectionner votre service `girlycrea-backend`
3. Cliquer sur **"Manual Deploy"** → **"Deploy latest commit"**

#### Option C : Utiliser le Script

```bash
cd /home/klozta/Projet-Lune
./scripts/DEPLOY-BACKEND.sh
```

### 3. Configurer les Variables d'Environnement

Dans Render Dashboard → Service → Environment → Add Environment Variable :

**Variables requises** :
```env
NODE_ENV=production
SUPABASE_URL=https://votre-projet.supabase.co
SUPABASE_KEY=eyJhbGc...
JWT_SECRET=<générer avec: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))">
JWT_REFRESH_SECRET=<générer avec: node -e "console.log(require('crypto').randomBytes(64).toString('hex'))">
CORS_ORIGIN=https://votre-frontend.vercel.app
```

**Nouvelles variables (sécurité 2025)** :
```env
MASTER_ENCRYPTION_KEY=<générer avec: node -e "console.log(require('crypto').randomBytes(32).toString('hex'))">
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
```

## ✅ Vérification après Déploiement

### Test Health Check

```bash
# Récupérer l'URL depuis Render Dashboard
curl https://girlycrea-backend.onrender.com/health
```

**Résultat attendu** : `{"status":"ok",...}`

### Test API

```bash
curl https://girlycrea-backend.onrender.com/api
```

**Résultat attendu** : Liste des endpoints disponibles

### Utiliser le Script de Test

```bash
cd /home/klozta/Projet-Lune
./scripts/TESTER-RENDER-DEPLOYE.sh https://girlycrea-backend.onrender.com
```

## 🐛 Dépannage

### Le service est en "Sleeping"

Sur le plan gratuit, Render met les services en veille après 15 minutes d'inactivité.

**Solution** :
- Utiliser UptimeRobot pour faire des health checks toutes les 5 minutes
- Ou passer au plan payant

### Erreur de Build

Vérifier les logs dans Render Dashboard → Service → Logs

**Problèmes courants** :
- Variables d'environnement manquantes
- Erreurs TypeScript
- Dépendances manquantes

### Erreur au Démarrage

Vérifier que toutes les variables d'environnement sont configurées, notamment :
- `MASTER_ENCRYPTION_KEY` (nouveau - requis pour le service de chiffrement)

## 📋 Checklist de Déploiement

- [ ] Build local réussi (`npm run build`)
- [ ] Variables d'environnement configurées dans Render
- [ ] `MASTER_ENCRYPTION_KEY` généré et ajouté
- [ ] Code pushé sur GitHub (si déploiement auto)
- [ ] Service déployé sur Render
- [ ] Health check OK
- [ ] Tests API OK

## 🔗 Liens Utiles

- **Render Dashboard** : https://dashboard.render.com
- **Documentation Render** : https://render.com/docs
- **Script de test** : `scripts/TESTER-RENDER-DEPLOYE.sh`
- **Guide complet** : `VERIFIER-DEPLOIEMENT-RENDER.md`

## 🎯 Prochaines Étapes

Après déploiement réussi :

1. ✅ Vérifier que le backend répond correctement
2. ✅ Mettre à jour `NEXT_PUBLIC_API_URL` dans Vercel (frontend)
3. ✅ Redéployer le frontend
4. ✅ Configurer UptimeRobot pour éviter le sleep
5. ✅ Tester les nouvelles fonctionnalités (chiffrement, monitoring, etc.)

---

**Dernière mise à jour** : 2025-01-18  
**Version** : Optimisations & Sécurité 2025

