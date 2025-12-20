# 💾 Guide de Configuration du Backup Automatisé

Guide complet pour configurer et utiliser le script de backup automatisé PostgreSQL.

## 📋 Prérequis

- Accès PostgreSQL (local ou Supabase)
- `pg_dump` et `pg_restore` installés
- (Optionnel) AWS CLI configuré pour upload S3
- (Optionnel) GPG installé pour chiffrement

## ⚙️ Configuration

### 1. Variables d'Environnement

Créer un fichier `.env.backup` ou ajouter dans votre `.env` :

```bash
# Configuration PostgreSQL
POSTGRES_HOST=db.your-project.supabase.co
POSTGRES_USER=postgres
POSTGRES_DB=girlycrea
POSTGRES_PORT=5432

# Configuration Backup
BACKUP_DIR=/backups/postgresql
DAYS_RETENTION=30
LOG_FILE=/var/log/backup.log

# Optionnel: Upload S3
S3_BUCKET=your-backup-bucket
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_DEFAULT_REGION=eu-west-1

# Optionnel: Chiffrement GPG
GPG_KEY_ID=your-gpg-key-id

# Optionnel: Webhook notification
BACKUP_WEBHOOK_URL=https://your-monitoring-service.com/webhook/backup
```

### 2. Supabase Configuration

Pour Supabase, récupérer les informations de connexion :

1. Aller dans **Project Settings** > **Database**
2. Copier les informations de connexion :
   - **Host** : `db.xxx.supabase.co`
   - **Database name** : `postgres` (ou votre DB custom)
   - **Port** : `5432`
   - **User** : `postgres`
   - **Password** : Récupérer depuis **Database** > **Connection string**

**Important** : Utiliser le mot de passe depuis les variables d'environnement Supabase ou le secret manager, jamais en dur.

```bash
# Option 1: Variable d'environnement
export PGPASSWORD=your-supabase-password

# Option 2: Fichier .pgpass (recommandé)
# Format: hostname:port:database:username:password
echo "db.xxx.supabase.co:5432:postgres:postgres:your-password" > ~/.pgpass
chmod 600 ~/.pgpass
```

### 3. Configuration S3 (Optionnel)

Si vous souhaitez uploader les backups vers S3 :

```bash
# Installer AWS CLI
# macOS: brew install awscli
# Linux: apt-get install awscli

# Configurer credentials
aws configure
# Entrer: AWS Access Key ID
# Entrer: AWS Secret Access Key
# Entrer: Default region (ex: eu-west-1)
# Entrer: Default output format (json)

# Créer un bucket S3
aws s3 mb s3://your-backup-bucket --region eu-west-1

# Activer versioning (recommandé)
aws s3api put-bucket-versioning \
  --bucket your-backup-bucket \
  --versioning-configuration Status=Enabled

# Configurer lifecycle policy (déplacer vers GLACIER après 30 jours)
aws s3api put-bucket-lifecycle-configuration \
  --bucket your-backup-bucket \
  --lifecycle-configuration file://lifecycle-policy.json
```

**lifecycle-policy.json** :
```json
{
  "Rules": [
    {
      "Id": "MoveToGlacier",
      "Status": "Enabled",
      "Prefix": "postgres/",
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "GLACIER"
        }
      ]
    }
  ]
}
```

### 4. Configuration GPG (Optionnel)

Pour chiffrer les backups :

```bash
# Générer une clé GPG
gpg --gen-key

# Récupérer l'ID de la clé
gpg --list-keys
# Notez l'ID (format: 16 caractères hex)

# Exporter la clé publique (à sauvegarder en lieu sûr)
gpg --export --armor your-key-id > backup-key.pub

# Exporter la clé privée (à sauvegarder en lieu sûr, sécurisé)
gpg --export-secret-keys --armor your-key-id > backup-key-private.asc
```

## 🚀 Utilisation

### Backup Manuel

```bash
# Rendre le script exécutable (si pas déjà fait)
chmod +x scripts/backup-automated.sh

# Exécuter manuellement
cd girlycrea-site/backend
./scripts/backup-automated.sh
```

### Backup Automatisé (Cron)

Ajouter au crontab pour backup quotidien à 02:00 UTC :

```bash
# Éditer crontab
crontab -e

# Ajouter cette ligne (ajuster le chemin)
0 2 * * * cd /path/to/girlycrea-site/backend && /path/to/scripts/backup-automated.sh >> /var/log/backup.log 2>&1
```

**Alternatives** :
- Backup toutes les 6 heures : `0 */6 * * * ...`
- Backup seulement en semaine : `0 2 * * 1-5 ...`

### Backup avec Docker

Si vous utilisez Docker :

```dockerfile
# Dans votre Dockerfile ou docker-compose.yml
# Ajouter un service cron

FROM alpine:latest
RUN apk add --no-cache postgresql-client bash curl aws-cli gnupg

COPY scripts/backup-automated.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/backup-automated.sh

# Installer cron
RUN apk add --no-cache dcron

# Copier crontab
COPY crontab /etc/cron.d/backup
RUN chmod 0644 /etc/cron.d/backup

# Créer répertoire logs
RUN mkdir -p /var/log

CMD ["crond", "-f"]
```

**crontab** :
```
0 2 * * * /usr/local/bin/backup-automated.sh >> /var/log/backup.log 2>&1
```

### Backup sur Render/Railway/Vercel

Pour les plateformes serverless/managed :

#### Option 1: Utiliser GitHub Actions

Créer `.github/workflows/backup.yml` :

```yaml
name: Daily Backup

on:
  schedule:
    - cron: '0 2 * * *' # 02:00 UTC daily
  workflow_dispatch: # Permettre exécution manuelle

jobs:
  backup:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup PostgreSQL client
        run: |
          sudo apt-get update
          sudo apt-get install -y postgresql-client

      - name: Configure AWS credentials
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          mkdir -p ~/.aws
          echo "[default]" > ~/.aws/credentials
          echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> ~/.aws/credentials
          echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> ~/.aws/credentials

      - name: Run backup
        env:
          POSTGRES_HOST: ${{ secrets.POSTGRES_HOST }}
          POSTGRES_USER: ${{ secrets.POSTGRES_USER }}
          POSTGRES_DB: ${{ secrets.POSTGRES_DB }}
          PGPASSWORD: ${{ secrets.POSTGRES_PASSWORD }}
          BACKUP_DIR: ./backups
          S3_BUCKET: ${{ secrets.S3_BUCKET }}
        run: |
          cd girlycrea-site/backend
          bash scripts/backup-automated.sh

      - name: Upload backup artifact
        uses: actions/upload-artifact@v3
        with:
          name: backup-${{ github.run_number }}
          path: backups/
          retention-days: 7
```

#### Option 2: Utiliser un service externe (Aiven, Supabase Backup)

Supabase offre des backups automatiques :
- **Free tier** : Backups quotidiens, retention 7 jours
- **Pro tier** : Backups quotidiens + point-in-time recovery

Activer dans **Project Settings** > **Database** > **Backups**.

## 🔍 Vérification et Monitoring

### Vérifier le Backup

```bash
# Lister les backups locaux
ls -lh $BACKUP_DIR

# Vérifier l'intégrité d'un backup
pg_restore --list /path/to/backup.dump | head -20

# Tester la restauration sur DB de test
pg_restore \
  --host=test-db-host \
  --user=postgres \
  --dbname=test_db \
  --clean \
  /path/to/backup.dump
```

### Monitoring

Le script log automatiquement :
- Démarrage/fin du backup
- Taille du backup
- Erreurs éventuelles
- Upload S3 (si configuré)

Consulter les logs :
```bash
tail -f /var/log/backup.log
```

### Alertes

Configurer un webhook pour recevoir des notifications :

```bash
# Dans .env
BACKUP_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Le script enverra une notification en cas de succès ou échec
```

**Exemple webhook Slack** :
```json
{
  "text": "Backup PostgreSQL terminé",
  "attachments": [
    {
      "color": "good",
      "fields": [
        {"title": "Fichier", "value": "full_20250118_020000.dump.gpg"},
        {"title": "Taille", "value": "125 MB"},
        {"title": "Timestamp", "value": "2025-01-18 02:00:00"}
      ]
    }
  ]
}
```

## 🔄 Restauration

### Restauration Complète

```bash
# 1. Arrêter l'application (si nécessaire)
systemctl stop your-app

# 2. Télécharger le backup depuis S3 (si applicable)
aws s3 cp s3://your-backup-bucket/postgres/2025/01/full_20250118_020000.dump.gpg ./

# 3. Déchiffrer (si GPG)
gpg --decrypt full_20250118_020000.dump.gpg > backup.dump

# 4. Restaurer
pg_restore \
  --host=$POSTGRES_HOST \
  --user=$POSTGRES_USER \
  --dbname=$POSTGRES_DB \
  --clean \
  --if-exists \
  --verbose \
  backup.dump

# 5. Vérifier
psql -h $POSTGRES_HOST -U $POSTGRES_USER -d $POSTGRES_DB -c "SELECT COUNT(*) FROM orders;"
```

### Restauration Partielle (une table)

```bash
# Restaurer seulement la table users
pg_restore \
  --host=$POSTGRES_HOST \
  --user=$POSTGRES_USER \
  --dbname=$POSTGRES_DB \
  --table=users \
  --data-only \
  backup.dump
```

## 📊 RTO/RPO Targets

| Système | RTO | RPO | Stratégie |
|---------|-----|-----|-----------|
| Base de données prod | 2h | 1h | Backup quotidien + retention 30 jours |
| Files (uploads) | 4h | 4h | Backup séparé ou CDN |
| Logs audit | 24h | 24h | Archive S3 GLACIER |

## ⚠️ Bonnes Pratiques

1. **Tester régulièrement** : Restaurer sur un environnement de test mensuellement
2. **Retention policy** : Garder 30 jours minimum, 90 jours recommandé
3. **Stockage multiple** : Local + S3 pour redondance
4. **Chiffrement** : Toujours chiffrer les backups contenant des données personnelles
5. **Monitoring** : Vérifier les logs quotidiennement
6. **Documentation** : Documenter la procédure de restauration

## 🔐 Sécurité

- ✅ Ne jamais commit les fichiers `.env` avec les passwords
- ✅ Utiliser des secrets managers (AWS Secrets Manager, HashiCorp Vault)
- ✅ Restreindre l'accès aux backups (IAM policies S3)
- ✅ Chiffrer les backups avec GPG
- ✅ Rotation des clés GPG annuellement

## 📚 Références

- Script backup : `scripts/backup-automated.sh`
- Documentation sécurité : `docs/SECURITY-COMPLIANCE-2025.md`
- Documentation disaster recovery : `docs/SECURITY-COMPLIANCE-2025.md#backup-et-récupération-disaster-recovery`

