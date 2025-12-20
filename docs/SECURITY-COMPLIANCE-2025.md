# 🔒 Sécurité & Compliance E-commerce 2025

Guide complet basé sur les recommandations Perplexity pour une plateforme e-commerce sécurisée et conforme RGPD/PCI-DSS.

## 📋 Vue d'ensemble

Ce guide couvre :
- ✅ Chiffrement des données sensibles (AES-256-CBC)
- ✅ Protection contre attaques OWASP Top 10 (CSRF, XSS, SQL Injection)
- ✅ Sécurisation des paiements Stripe (PCI-DSS compliant)
- ✅ Gestion des cookies et consentement RGPD
- ✅ Audit trail pour compliance
- ✅ Backup et récupération disaster recovery
- ✅ Automatisation security & compliance

---

## 🔐 1. Chiffrement des Données Sensibles

### Service de Chiffrement

**Fichier** : `src/services/encryptionService.ts`

Utilise AES-256-CBC avec IV unique pour chaque chiffrement.

**Usage** :
```typescript
import { getEncryptionService } from '../services/encryptionService.js';

const encryptor = getEncryptionService();

// Chiffrer
const encryptedEmail = encryptor.encrypt('user@example.com');

// Déchiffrer
const decryptedEmail = encryptor.decrypt(encryptedEmail);
```

**Configuration requise** :
```bash
# Générer une clé (une seule fois)
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Ajouter dans .env
MASTER_ENCRYPTION_KEY=your-64-hex-characters-key-here
```

**⚠️ IMPORTANT** :
- Stocker la clé dans AWS Secrets Manager, HashiCorp Vault, ou Google Cloud Secret Manager
- Rotation annuelle de la clé
- Jamais en `.env` ou hardcodé dans le code

---

## 🛡️ 2. Protection Contre les Attaques OWASP Top 10

### 2.1 Protection CSRF

**Fichier** : `src/middleware/csrf.middleware.ts`

**Usage** :
```typescript
import { csrfProtection, generateCsrfToken } from '../middleware/csrf.middleware.js';

// Générer token avant de servir un formulaire
app.get('/checkout', generateCsrfToken, (req, res) => {
  res.render('checkout', {
    csrfToken: res.locals.csrfToken
  });
});

// Vérifier token sur POST
app.post('/process-order', csrfProtection, handleOrder);
```

**Frontend** :
```html
<form action="/process-order" method="POST">
  <input type="hidden" name="_csrf" value="<%= csrfToken %>">
  <!-- ou -->
  <input type="hidden" name="_csrf" value="{{ csrfToken }}">
</form>
```

### 2.2 Protection XSS

**Fichier** : `src/middleware/security.middleware.ts`

**Content Security Policy (CSP)** :
```typescript
import { securityHeaders } from '../middleware/security.middleware.js';

app.use(securityHeaders); // Configure Helmet avec CSP
```

**Sanitization des entrées** :
```typescript
import { sanitizeInput } from '../middleware/security.middleware.js';

app.use(sanitizeInput); // Sanitize automatiquement req.body et req.query
```

### 2.3 Protection SQL Injection

**✅ Déjà implémenté** : Utiliser des requêtes paramétrées (Supabase client fait cela automatiquement)

**Exemple** :
```typescript
// ✅ BON (paramétré)
const { data } = await supabase
  .from('users')
  .select('*')
  .eq('id', userId); // userId est automatiquement échappé

// ❌ MAUVAIS (jamais faire ça)
const query = `SELECT * FROM users WHERE id = ${userId}`; // VULNERABLE
```

### 2.4 Protection Brute Force

**Middleware** : `src/middleware/security.middleware.ts`

Utilise le rate limiting existant dans `src/middleware/rateLimit.middleware.ts`.

---

## 💳 3. Sécurisation des Paiements Stripe

### 3.1 Vérification des Webhooks Stripe

**Fichier** : `src/services/stripeWebhookSecurity.ts`

**⚠️ CRITIQUE** : Toujours vérifier la signature des webhooks Stripe.

**Usage** :
```typescript
import { verifyStripeWebhookSignature } from '../services/stripeWebhookSecurity.js';

// Route webhook SANS bodyParser.json() (utiliser raw body)
app.post('/stripe/webhook',
  express.raw({ type: 'application/json' }),
  async (req, res) => {
    const sig = req.headers['stripe-signature'];
    const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

    try {
      const event = verifyStripeWebhookSignature(
        req.body,
        sig,
        webhookSecret
      );

      // Traiter l'événement
      switch (event.type) {
        case 'payment_intent.succeeded':
          await handlePaymentSuccess(event.data.object);
          break;
        // ...
      }

      res.json({ received: true });
    } catch (error) {
      res.status(400).json({ error: 'Webhook verification failed' });
    }
  }
);
```

### 3.2 Validation PaymentIntent

**Vérifications critiques** :
1. Montant exact (protection contre modification)
2. Commande existe et correspond
3. Status valide

Voir `validatePaymentIntent()` dans `stripeWebhookSecurity.ts`.

---

## 🍪 4. Gestion des Cookies et Consentement RGPD

### 4.1 Consent Management Platform (CMP)

**Options recommandées** :
- **consentmanager** (€50-500/mois)
- **Cookiebot** (gratuit → payant)
- **Didomi** (€200+/mois)
- **Axeptio** (€99/mois)

**Intégration frontend** :
```html
<!-- Script CMP -->
<script
  id="consentmanager"
  src="https://consent.cookiebot.com/uc.js"
  data-cbid="your-id"
  data-lang="fr"
  async>
</script>

<!-- Google Analytics (bloqué jusqu'à consentement) -->
<script>
  if (window.CookieConsent?.acceptedCategory('analytics')) {
    // Charger GA seulement après consentement
    gtag('event', 'page_view');
  }
</script>
```

### 4.2 Respecter les Consentements Côté Serveur

**Middleware** :
```typescript
app.use((req, res, next) => {
  const consentCookie = req.cookies['CookieConsent'];
  const consents = consentCookie ? JSON.parse(consentCookie) : {};

  res.locals.userConsents = {
    analytics: consents.analytics === 'true',
    marketing: consents.marketing === 'true',
    functional: consents.functional === 'true',
  };

  next();
});
```

---

## 📝 5. Audit Trail pour Compliance

### 5.1 Logging Structuré

**Déjà implémenté** : `src/utils/structuredLogger.ts`

**Usage** :
```typescript
import { structuredLogger } from '../utils/structuredLogger.js';

structuredLogger.info('Order created', {
  orderId: order.id,
  userId: user.id,
  amount: order.total,
  timestamp: new Date().toISOString(),
});
```

### 5.2 Audit Database (pgAudit)

**Script SQL** : `scripts/configure-pg-audit.sql` (à créer si nécessaire)

**Configuration** :
```sql
CREATE EXTENSION IF NOT EXISTS pgaudit;
ALTER SYSTEM SET pgaudit.log = 'ALL';
```

---

## 💾 6. Backup et Récupération Disaster Recovery

### 6.1 Script de Backup Automatisé

**Fichier** : `scripts/backup-automated.sh`

**Configuration** :
```bash
# Variables d'environnement
export POSTGRES_HOST="your-host"
export POSTGRES_USER="your-user"
export POSTGRES_DB="girlycrea"
export BACKUP_DIR="/backups/postgresql"
export DAYS_RETENTION=30
export S3_BUCKET="your-backup-bucket"  # Optionnel
export GPG_KEY_ID="your-gpg-key-id"     # Optionnel (chiffrement)
```

**Cronjob** :
```bash
# Backup quotidien à 02:00 UTC
0 2 * * * /path/to/backup-automated.sh >> /var/log/backup.log 2>&1
```

**Fonctionnalités** :
- ✅ Dump PostgreSQL complet
- ✅ Chiffrement GPG (optionnel)
- ✅ Upload S3 avec classe GLACIER
- ✅ Nettoyage automatique (anciens backups)
- ✅ Vérification d'intégrité
- ✅ Notification webhook

### 6.2 RTO/RPO Targets

| Système | RTO | RPO | Justification |
|---------|-----|-----|---------------|
| Base données prod | 2h | 1h | Données critiques |
| Files (uploads) | 4h | 4h | Reconstruction possible |
| Logs audit | 24h | 24h | Archived sufficient |
| Caches | N/A | N/A | Non-critique, rebuild |

---

## ✅ 7. Checklist de Compliance

### Phase 1 : Audit Initial (Semaine 1)
- [ ] Cartographie données personnelles collectées
- [ ] Identifier bases légales (contrat, consentement, obligation)
- [ ] Lister tous processeurs (Stripe, Sendgrid, etc.)
- [ ] Évaluer risques DPIA si données sensibles
- [ ] Vérifier DPA (Data Processing Agreement) avec processeurs

### Phase 2 : Sécurité (Semaine 2-3)
- [x] Implémenter chiffrement AES-256 données sensibles
- [ ] Setup pgAudit pour audit trail
- [x] Configurer HTTPS/TLS 1.3
- [ ] Activer WAF (Web Application Firewall)
- [x] Implémenter CSP headers (Helmet)
- [x] Protection CSRF
- [x] Sanitization XSS
- [x] Validation SQL injection

### Phase 3 : Protection Paiements (Semaine 3)
- [x] Utiliser Stripe Checkout (zéro PCI)
- [x] Implémenter webhook signature verification
- [ ] Tester fraude detection Stripe
- [ ] Setup 3D Secure obligatoire
- [ ] Limiter données retenues post-transaction

### Phase 4 : Cookies & Consentement (Semaine 4)
- [ ] Intégrer CMP (consentmanager, Cookiebot)
- [ ] Configurer Google Consent Mode v2
- [ ] Bloquer scripts tiers sans consentement
- [ ] Tester consentement par GEO-IP
- [ ] Publier politique de confidentialité
- [ ] Setup cookie audit logging

### Phase 5 : Tests & Monitoring (Semaine 5+)
- [ ] SAST scan CI/CD (Snyk, SonarQube, Semgrep)
- [ ] DAST penetration testing
- [ ] Test data export GDPR
- [ ] Test data deletion (right to erasure)
- [ ] Test restore procedure (monthly)
- [ ] Setup alerting sécurité (anomalies)

---

## 🔧 8. Configuration Requise

### Variables d'Environnement

```bash
# Chiffrement
MASTER_ENCRYPTION_KEY=your-64-hex-characters-key

# Stripe
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Backup
POSTGRES_HOST=localhost
POSTGRES_USER=postgres
POSTGRES_DB=girlycrea
BACKUP_DIR=/backups/postgresql
DAYS_RETENTION=30
S3_BUCKET=your-backup-bucket  # Optionnel
GPG_KEY_ID=your-gpg-key-id    # Optionnel
```

### Middlewares à Activer

```typescript
import { securityHeaders } from './middleware/security.middleware.js';
import { sanitizeInput, suspiciousActivityLogging } from './middleware/security.middleware.js';
import { csrfProtection } from './middleware/csrf.middleware.js';

app.use(securityHeaders);
app.use(sanitizeInput);
app.use(suspiciousActivityLogging);
app.use(csrfProtection); // Sur routes sensibles
```

---

## 📚 Références

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [RGPD CNIL](https://www.cnil.fr/fr/rgpd-de-quoi-parle-t-on)
- [PCI-DSS Standards](https://www.pcisecuritystandards.org/)
- [Stripe Security](https://stripe.com/docs/security)
- [Helmet.js Documentation](https://helmetjs.github.io/)

---

## 🎯 Prochaines Étapes

1. **Générer la clé de chiffrement** : `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`
2. **Configurer les variables d'environnement**
3. **Activer les middlewares de sécurité**
4. **Tester les webhooks Stripe avec signature**
5. **Configurer le backup automatisé**
6. **Intégrer un CMP pour les cookies**

