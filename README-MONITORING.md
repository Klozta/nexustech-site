# 📊 Monitoring & Alerting - Guide Rapide

## 🚀 Démarrage Rapide

1. **Vérifier le setup** :
   ```bash
   npm run monitoring:verify
   ```

2. **Consulter le guide complet** :
   - [Quick Start](./docs/QUICK-START-MONITORING.md)
   - [Guide Complet 2025](./docs/MONITORING-ALERTING-2025.md)

## 📁 Structure

```
backend/
├── config/
│   ├── prometheus/
│   │   └── alerts.yml          # Règles d'alerting
│   └── alertmanager/
│       └── config.yml          # Configuration routing notifications
├── src/
│   ├── services/
│   │   ├── prometheusMetrics.ts    # Métriques Prometheus
│   │   ├── alertingService.ts      # Service d'alerting (seuils dynamiques)
│   │   └── notificationsService.ts # Notifications (Slack/Email)
│   └── routes/
│       └── prometheusMetrics.routes.ts  # Endpoint /metrics
└── docs/
    ├── QUICK-START-MONITORING.md       # Guide démarrage rapide
    └── MONITORING-ALERTING-2025.md     # Guide complet
```

## 🔗 Endpoints

- **Métriques** : `GET /metrics` (format Prometheus)
- **Health** : `GET /health` (health check simple)
- **Health détaillé** : `GET /health/detailed` (avec métriques)

## 📈 Métriques Disponibles

### HTTP
- `http_request_duration_seconds` - Durée des requêtes (histogram)
- `http_requests_total` - Total requêtes (counter)
- `http_request_errors_total` - Erreurs HTTP (counter)
- `http_requests_active` - Requêtes actives (gauge)

### Business
- `orders_total` - Total commandes (counter)
- `orders_revenue_total` - Revenue total (counter)
- `products_active` - Produits actifs (gauge)
- `users_total` - Total utilisateurs (gauge)

### Infrastructure
- `database_query_duration_seconds` - Durée queries DB (histogram)
- `cache_hits_total` / `cache_misses_total` - Cache stats
- `auth_attempts_total` - Tentatives auth
- `rate_limit_hits_total` - Rate limit hits

## 🚨 Alertes Configurées

### Critiques
- `HighErrorRate` - Taux d'erreur >5% pendant 2min
- `HighLatencyP99` - Latence P99 >1s pendant 5min
- `DatabaseDown` - Base de données inaccessible
- `ServiceDown` - Service complètement down

### Warnings
- `AnomalousRequestRate` - Trafic anormal (>20% variation)
- `HighDatabaseLatency` - Latence DB P95 >0.5s
- `ModerateErrorRate` - Taux d'erreur 2-5%

### Business
- `OrderDrop` - Chute commandes >30%
- `NoOrders` - Aucune commande depuis 30min

## 🔧 Configuration

### Variables d'environnement

```bash
# Slack
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
SLACK_WEBHOOK_URL_CRITICAL=https://hooks.slack.com/services/...

# PagerDuty (optionnel)
PAGERDUTY_SERVICE_KEY=your-key

# Email on-call (optionnel)
ONCALL_EMAIL=oncall@example.com
RESEND_API_KEY=your-resend-key
```

## 📚 Documentation

- [Quick Start Guide](./docs/QUICK-START-MONITORING.md)
- [Guide Complet 2025](./docs/MONITORING-ALERTING-2025.md)
- [Prometheus Docs](https://prometheus.io/docs/)
- [Alertmanager Docs](https://prometheus.io/docs/alerting/latest/alertmanager/)

