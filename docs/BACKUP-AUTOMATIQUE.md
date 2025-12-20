# 💾 Backup Automatique de la Base de Données

## Vue d'ensemble

Le système de backup automatique permet de sauvegarder régulièrement la base de données Supabase PostgreSQL avec :
- ✅ Backup automatique via cron job
- ✅ Backup manuel via API (admin)
- ✅ Upload vers stockage distant (S3, R2, Supabase Storage)
- ✅ Nettoyage automatique des anciens backups
- ✅ Notifications email en cas de succès/échec

## Configuration

### Variables d'environnement

Ajoutez dans votre `.env` :

```bash
# Configuration backup
BACKUP_STORAGE_TYPE=local                    # local | s3 | r2 | supabase-storage
BACKUP_LOCAL_PATH=./backups                  # Chemin local (si storageType=local)
BACKUP_RETENTION_DAYS=30                     # Nombre de jours de rétention
BACKUP_COMPRESS=true                         # Compresser les backups
BACKUP_NOTIFICATION_EMAIL=admin@example.com  # Email pour notifications

# Connexion DB (pour pg_dump)
SUPABASE_DB_HOST=db.xxxxx.supabase.co        # Host DB (auto-détecté depuis SUPABASE_URL si non fourni)
SUPABASE_DB_NAME=postgres                    # Nom de la DB (défaut: postgres)
SUPABASE_DB_USER=postgres                    # User DB (défaut: postgres)
SUPABASE_DB_PASSWORD=your_db_password        # Mot de passe DB (requis)

# Pour S3 (si storageType=s3)
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
BACKUP_S3_BUCKET=your-bucket-name
BACKUP_S3_REGION=us-east-1

# Pour Cloudflare R2 (si storageType=r2)
BACKUP_R2_BUCKET=your-bucket-name
BACKUP_R2_ACCOUNT_ID=your_account_id
AWS_ACCESS_KEY_ID=your_r2_access_key
AWS_SECRET_ACCESS_KEY=your_r2_secret_key

# Pour Supabase Storage (si storageType=supabase-storage)
# Utilise SUPABASE_URL et SUPABASE_KEY existants
# Crée automatiquement un bucket "backups" si nécessaire
```

## Installation

### 1. Installer PostgreSQL client tools

Le backup utilise `pg_dump` qui doit être installé sur le serveur :

```bash
# Ubuntu/Debian
sudo apt-get install postgresql-client

# macOS
brew install postgresql

# Vérifier l'installation
pg_dump --version
```

### 2. Configuration du cron job automatique

#### Option A : Via script automatique

```bash
npm run backup:setup
```

#### Option B : Configuration manuelle

```bash
# Éditer le crontab
crontab -e

# Ajouter (backup quotidien à 2h du matin)
0 2 * * * /path/to/backend/scripts/backup-automatic.sh >> /var/log/girlycrea-backup.log 2>&1
```

**Autres exemples de schedule** :
- Quotidien à 2h : `0 2 * * *`
- Toutes les 6 heures : `0 */6 * * *`
- Hebdomadaire (dimanche 3h) : `0 3 * * 0`
- Quotidien + hebdomadaire : `0 2 * * *` et `0 3 * * 0`

## Utilisation

### Backup manuel via API

```bash
# 1. Login admin
curl -X POST http://localhost:3001/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{"token":"YOUR_ADMIN_TOKEN"}' \
  -c cookies.txt

# 2. Créer un backup
curl -X POST http://localhost:3001/api/cron/backup \
  -b cookies.txt

# 3. Lister les backups
curl http://localhost:3001/api/cron/backups \
  -b cookies.txt
```

### Backup manuel via script

```bash
# Définir les variables d'environnement
export CRON_API_KEY=your_admin_token
export API_URL=http://localhost:3001/api

# Exécuter le script
./scripts/backup-automatic.sh
```

## Structure des backups

### Format des fichiers

Les backups sont nommés : `backup-YYYY-MM-DDTHH-MM-SS-sssZ.sql`

Exemple : `backup-2025-12-17T14-30-45-123Z.sql`

### Emplacement

- **Local** : `./backups/` (ou `BACKUP_LOCAL_PATH`)
- **S3** : `s3://bucket-name/backup-*.sql`
- **R2** : `r2://bucket-name/backup-*.sql`
- **Supabase Storage** : Bucket `backups`

## Nettoyage automatique

Les backups plus anciens que `BACKUP_RETENTION_DAYS` (défaut: 30 jours) sont automatiquement supprimés lors de chaque backup.

## Notifications

Si `BACKUP_NOTIFICATION_EMAIL` est configuré, des emails sont envoyés :
- ✅ **Succès** : Confirmation avec taille et durée
- ❌ **Échec** : Alerte avec détails de l'erreur

## Monitoring

### Vérifier les backups

```bash
# Via API
curl http://localhost:3001/api/cron/backups \
  -H "Cookie: admin_session=YOUR_SESSION" \
  | jq

# Via fichiers locaux
ls -lh ./backups/
```

### Logs

Les logs du backup automatique sont écrits dans :
- Script cron : `/var/log/girlycrea-backup.log` (ou chemin configuré)
- Application : Logs standard (console + fichier si configuré)

## Dépannage

### Erreur "pg_dump is not installed"

```bash
# Installer PostgreSQL client tools
sudo apt-get install postgresql-client  # Ubuntu/Debian
brew install postgresql                  # macOS
```

### Erreur "Cannot determine database host"

Définir explicitement `SUPABASE_DB_HOST` dans `.env` :
```bash
SUPABASE_DB_HOST=db.xxxxx.supabase.co
```

### Erreur "Authentication failed"

Vérifier que `SUPABASE_DB_PASSWORD` est correct. Le mot de passe DB est différent de `SUPABASE_KEY`.

Pour obtenir le mot de passe DB :
1. Aller sur Supabase Dashboard
2. Settings → Database → Connection string
3. Extraire le mot de passe de la connection string

### Backup trop volumineux

Les backups sont compressés par défaut (format custom PostgreSQL). Pour désactiver :
```bash
BACKUP_COMPRESS=false
```

## Restauration

### Depuis un backup local

```bash
# Restaurer
pg_restore -h db.xxxxx.supabase.co \
  -U postgres \
  -d postgres \
  --clean \
  --if-exists \
  ./backups/backup-2025-12-17T14-30-45-123Z.sql
```

### Depuis S3/R2

```bash
# Télécharger depuis S3
aws s3 cp s3://bucket-name/backup-2025-12-17T14-30-45-123Z.sql ./restore.sql

# Restaurer
pg_restore -h db.xxxxx.supabase.co -U postgres -d postgres --clean --if-exists ./restore.sql
```

## Sécurité

⚠️ **Important** :
- Les backups contiennent **toutes les données** (utilisateurs, commandes, etc.)
- Stocker les backups dans un endroit **sécurisé**
- Chiffrer les backups si sensibles (optionnel, non implémenté par défaut)
- Ne pas commiter les backups dans Git
- Limiter l'accès aux endpoints de backup (admin uniquement)

## Améliorations futures

- [ ] Chiffrement des backups
- [ ] Backup incrémental
- [ ] Test automatique de restauration
- [ ] Dashboard de monitoring des backups
- [ ] Intégration avec services de backup cloud (Backblaze, etc.)

