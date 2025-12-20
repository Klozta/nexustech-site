# 🚀 Quick Start - Monitoring & Alerting

Guide de démarrage rapide pour mettre en route le système de monitoring et alerting.

## ✅ Prérequis

1. **Prometheus** installé et configuré (ou Grafana Cloud)
2. **Alertmanager** installé (ou intégré dans Grafana Cloud)
3. Variables d'environnement configurées (Slack webhooks, etc.)

## 📦 Étape 1 : Vérifier l'Instrumentation

Les métriques Prometheus sont déjà exposées via `/metrics` :

```bash
# Tester l'exposition des métriques
curl http://localhost:3001/metrics
```

Vous devriez voir des métriques comme :
- `http_request_duration_seconds`
- `http_requests_total`
- `orders_total`
- `database_query_duration_seconds`
- etc.

## 🔧 Étape 2 : Configurer Prometheus

### Option A : Prometheus Local

Créer `prometheus.yml` :

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'girlycrea-backend'
    static_configs:
      - targets: ['localhost:3001']
    metrics_path: '/metrics'
    scrape_interval: 15s

rule_files:
  - 'config/prometheus/alerts.yml'

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']
```

### Option B : Grafana Cloud

1. Aller sur https://grafana.com/auth/sign-up/create-user
2. Créer un compte (gratuit jusqu'à 10K séries)
3. Récupérer les credentials Prometheus
4. Configurer dans votre app via variables d'environnement

## 🚨 Étape 3 : Configurer Alertmanager

1. **Copier la config** : `config/alertmanager/config.yml` est déjà prêt

2. **Configurer les variables d'environnement** :

```bash
# Slack webhooks
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
export SLACK_WEBHOOK_URL_CRITICAL="https://hooks.slack.com/services/YOUR/CRITICAL/WEBHOOK"

# PagerDuty (optionnel)
export PAGERDUTY_SERVICE_KEY="your-pagerduty-key"

# Email on-call (optionnel)
export ONCALL_EMAIL="oncall@girlycrea.com"
```

3. **Démarrer Alertmanager** :

```bash
# Si installé localement
alertmanager --config.file=config/alertmanager/config.yml

# Ou via Docker
docker run -d \
  --name alertmanager \
  -p 9093:9093 \
  -v $(pwd)/config/alertmanager:/etc/alertmanager \
  prom/alertmanager \
  --config.file=/etc/alertmanager/config.yml
```

## 📊 Étape 4 : Créer les Dashboards Grafana

### Dashboard 1 : Golden Signals

**Panels à créer** :

1. **Latency P99**
   ```
   histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
   ```

2. **Throughput**
   ```
   sum(rate(http_requests_total[5m])) by (service)
   ```

3. **Error Rate**
   ```
   sum(rate(http_requests_total{status_code=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))
   ```

4. **Active Requests**
   ```
   sum(http_requests_active) by (service)
   ```

### Dashboard 2 : Business KPIs

1. **Orders per minute**
   ```
   rate(orders_total[5m]) * 60
   ```

2. **Revenue**
   ```
   sum(orders_revenue_total) by (status)
   ```

3. **Active Products**
   ```
   products_active
   ```

## 🧪 Étape 5 : Tester les Alertes

### Test 1 : Alerte HighErrorRate

Simuler des erreurs pour déclencher l'alerte :

```bash
# Faire des requêtes qui génèrent des 500
for i in {1..100}; do
  curl -X POST http://localhost:3001/api/test-error
done
```

Vérifier dans Grafana → Alerts que `HighErrorRate` se déclenche après 2 minutes.

### Test 2 : Alerte HighLatencyP99

Simuler une latence élevée :

```typescript
// Dans votre code de test
await new Promise(resolve => setTimeout(resolve, 2000)); // 2s delay
```

Vérifier que `HighLatencyP99` se déclenche après 5 minutes.

### Test 3 : Notification Slack

Vérifier que les alertes arrivent bien dans Slack :

- Channel `#alerts-critical` pour critiques
- Channel `#alerts-warning` pour warnings
- Channel `#alerts-business` pour business

## ✅ Checklist de Vérification

- [ ] Métriques exposées sur `/metrics`
- [ ] Prometheus scrape les métriques (status = UP)
- [ ] Alertmanager démarré et connecté à Prometheus
- [ ] Règles d'alertes chargées dans Prometheus (Alerts → Rules)
- [ ] Webhook Slack configuré et testé
- [ ] Dashboard Grafana créé (au moins Golden Signals)
- [ ] Test d'alerte fonctionnel (HighErrorRate ou HighLatencyP99)

## 🐛 Dépannage

### Métriques non exposées

```bash
# Vérifier que le serveur écoute
curl http://localhost:3001/metrics

# Vérifier les logs
tail -f logs/app.log | grep metrics
```

### Prometheus ne scrape pas

```bash
# Vérifier la config Prometheus
promtool check config prometheus.yml

# Vérifier les targets dans Prometheus UI
# http://localhost:9090/targets
```

### Alertes ne se déclenchent pas

1. Vérifier que les règles sont chargées : http://localhost:9090/alerts
2. Vérifier les logs Prometheus pour erreurs
3. Tester une règle manuellement dans PromQL

### Notifications Slack ne fonctionnent pas

1. Vérifier l'URL du webhook (doit commencer par `https://hooks.slack.com`)
2. Tester le webhook manuellement :
   ```bash
   curl -X POST $SLACK_WEBHOOK_URL \
     -H 'Content-Type: application/json' \
     -d '{"text":"Test alert"}'
   ```
3. Vérifier les logs Alertmanager

## 🎯 Prochaines Étapes

Une fois le système de base fonctionnel :

1. **Semaine 1** : Créer les 5 dashboards essentiels
2. **Semaine 2** : Tester et ajuster les seuils d'alerte
3. **Semaine 3** : Implémenter les seuils dynamiques (MAD/Z-score)
4. **Semaine 4** : Optimiser l'alert fatigue (<20% faux positifs)
5. **Semaine 5** : Setup SLO tracking et review mensuelle

## 📚 Ressources

- [Guide Complet Monitoring & Alerting](./MONITORING-ALERTING-2025.md)
- [Documentation Prometheus](https://prometheus.io/docs/)
- [Documentation Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Documentation Grafana](https://grafana.com/docs/)

