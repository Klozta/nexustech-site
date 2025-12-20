# Guide Complet Monitoring & Alerting 2025 - Basé sur Recommandations Perplexity

Ce guide présente l'implémentation d'un système de monitoring et alerting complet pour l'application GirlyCrea Node.js/Express, basé sur les meilleures pratiques 2025.

## 📊 Vue d'ensemble

**Objectif** : Observabilité production-ready avec réduction de 80-95% de l'alert fatigue.

**Stack recommandé** : Prometheus + Grafana (open-source) pour contrôle total, ou New Relic One pour <20 engineers (coûts ~$17k/an vs $79k Datadog).

## 🎯 Architecture Observabilité Trois-Couches

```
┌─────────────────────────────────────────┐
│ Application Node.js/Express             │
│ - prom-client metrics                   │
│ - Winston/Pino logs structurés          │
│ - OpenTelemetry tracing (optionnel)     │
└─────────────────────────────────────────┘
           ↓ /metrics, logs, traces
┌─────────────────────────────────────────┐
│ Observability Backend                   │
│ - Prometheus (metrics scraping)         │
│ - Loki (logs aggregation)               │
│ - Alertmanager (routing + grouping)     │
└─────────────────────────────────────────┘
           ↓ query
┌─────────────────────────────────────────┐
│ Visualization & Alerting                │
│ - Grafana dashboards                    │
│ - Alertmanager rules                    │
└─────────────────────────────────────────┘
           ↓ notif
┌─────────────────────────────────────────┐
│ Incident Management                     │
│ - Slack webhooks                        │
│ - Email (Resend)                        │
│ - PagerDuty (optionnel)                 │
└─────────────────────────────────────────┘
```

## 🔧 Phase 1 : Instrumentation Complète (Semaine 1)

### 1.1 Métriques Prometheus Avancées

**Fichier** : `src/services/prometheusMetrics.ts` (déjà créé, à améliorer)

**Métriques essentielles** :
- HTTP Request Duration (histogram)
- HTTP Requests Total (counter)
- Active Requests (gauge)
- Database Query Duration (histogram)
- Business Events (counter)
- Error Rate (ratio)

**Labels critiques** :
- `method`, `route`, `status` pour HTTP
- `query_type`, `status` pour DB
- `event_type`, `status` pour business

### 1.2 Middleware d'Instrumentation

Déjà implémenté dans `src/middleware/responseTime.middleware.ts`, à enrichir avec :
- Tracing correlation IDs
- Business events tracking
- Database query instrumentation

### 1.3 Logs Structurés

**Fichier** : `src/utils/structuredLogger.ts` (déjà créé)

**Format JSON** : Compatible avec Loki/Grafana

**Champs essentiels** :
- `timestamp`, `level`, `message`
- `traceId`, `spanId`, `requestId`
- `userId`, `method`, `path`, `status`
- `duration_ms`, `error`

## 📈 Phase 2 : Dashboards Grafana (Semaine 2)

### Dashboard 1 : Golden Signals Service

**Métriques** :
- Latency : `histogram_quantile(0.99, http_request_duration_seconds)`
- Throughput : `rate(http_requests_total[5m])`
- Errors : `rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])`
- Saturation : `http_requests_active`

### Dashboard 2 : Infrastructure

**Métriques** :
- CPU, Memory, Disk (via node_exporter si déployé)
- Network I/O
- Process count

### Dashboard 3 : Business KPIs

**Métriques** :
- Orders/min : `rate(business_events_total{event_type="order_created"}[5m])`
- Revenue : `sum(business_events_total{event_type="order_created"}) by (status)`
- Conversion rate
- Active users

### Dashboard 4 : Database Performance

**Métriques** :
- Query latency P95 : `histogram_quantile(0.95, db_query_duration_seconds)`
- Query rate : `rate(db_query_duration_seconds_count[5m])`
- Error rate : `rate(db_query_duration_seconds{status="error"}[5m])`

### Dashboard 5 : Application Errors

**Métriques** :
- Top exceptions : Logs filtrés par `level=error`
- Stack traces : Logs avec `error.stack`
- Error rate par endpoint

## 🚨 Phase 3 : Alerting Intelligent (Semaine 3)

### 3.1 Règles Alertmanager

**Fichier** : `config/prometheus/alerts.yml` (à créer)

**Seuils critiques** :
- Error rate > 5% pendant 2min → CRITICAL
- Latency P99 > 1s pendant 5min → CRITICAL
- Database down → CRITICAL
- High latency P95 > 0.5s pendant 5min → WARNING

### 3.2 Seuils Dynamiques (Z-score/MAD)

**Implémentation** : Utiliser les fonctions déjà créées dans `src/services/alertingService.ts`

**Z-score robuste (MAD)** :
```typescript
// Déjà implémenté dans alertingService.ts
const zScore = calculateMADScore(currentValue, historicalValues);
if (Math.abs(zScore) > 3.5) {
  // Anomalie détectée
}
```

### 3.3 Grouping & Deduplication

**Configuration Alertmanager** :
- `group_by: ['alertname', 'service']`
- `group_wait: 10s`
- `group_interval: 10m`
- `repeat_interval: 1h`

**Résultat** : 100 alertes HighCPU → 1 groupe

### 3.4 Inhibition Intelligente

**Règles** :
- Si `DatabaseDown` → supprimer `HighQueryLatency`
- Si `NetworkPartition` → supprimer tous les `Timeout` alerts
- Si `Critical` → supprimer `Warning` pour même service

## 💬 Phase 4 : Intégrations Notifications (Semaine 4)

### 4.1 Slack Enrichi

**Fichier** : `src/services/notificationsService.ts` (déjà créé, à améliorer)

**Fonctionnalités** :
- Grouping par sévérité
- Liens vers Grafana
- Actions (Silence, Acknowledge)
- Format rich blocks

### 4.2 Email (Resend)

**Déjà implémenté** dans `notificationsService.ts`

**Templates** :
- Alert critique → Email immédiat
- Résumé quotidien → Email à 8h
- Résumé hebdomadaire → Email lundi matin

### 4.3 PagerDuty (Optionnel)

Pour équipes avec on-call rotation :
- Escalation automatique
- Integration avec calendrier
- Tracking MTTR

## 📋 Checklist d'Implémentation

### Semaine 1 : Setup
- [x] Instrumentation Prometheus (déjà fait)
- [x] Logs structurés (déjà fait)
- [ ] Déployer Prometheus (local ou Grafana Cloud)
- [ ] Configurer scraping `/metrics`
- [ ] Tester exposition métriques

### Semaine 2 : Dashboards
- [ ] Créer dashboard Golden Signals
- [ ] Créer dashboard Infrastructure
- [ ] Créer dashboard Business KPIs
- [ ] Créer dashboard Database
- [ ] Créer dashboard Errors
- [ ] Configurer variables (service, instance)

### Semaine 3 : Alerting
- [ ] Créer `config/prometheus/alerts.yml`
- [ ] Configurer Alertmanager
- [ ] Tester règles critiques
- [ ] Implémenter seuils dynamiques (MAD)
- [ ] Configurer grouping/deduplication
- [ ] Configurer inhibition rules

### Semaine 4 : Notifications
- [x] Intégration Slack (déjà fait)
- [x] Intégration Email (déjà fait)
- [ ] Enrichir format Slack (blocks)
- [ ] Tester flux complet (alerte → notification)
- [ ] Configurer silence windows
- [ ] Documenter runbooks

### Semaine 5 : Optimisation
- [ ] Analyser 1 semaine d'alertes (ratio signal/bruit)
- [ ] Tuning seuils dynamiques
- [ ] Baseline : <20% false positive rate
- [ ] Setup SLO tracking
- [ ] Planifier review mensuelle

## 💰 Comparaison Coûts

### Stack Prometheus + Grafana (Open-Source)
- **Coût logiciel** : $0/an
- **Infrastructure** : ~$50-100/mois (VM ou cloud)
- **Maintenance** : 10h/mois × $100/h = $12k/an
- **Total année 1** : ~$13k-15k

### New Relic One (Cloud Managed)
- **Full Platform Users (5)** : 5 × $99 = $495/mois
- **Core Users (15)** : 15 × $49 = $735/mois
- **Data Ingestion (600GB/mois)** : (600-100) × $0.40 = $200/mois
- **Total** : $1,430/mois = **$17,160/an**

### Datadog (Cloud Managed)
- **Infrastructure (100 hosts)** : 100 × $15 = $1,500/mois
- **APM (100 hosts)** : 100 × $31 = $3,100/mois
- **Logs (50GB/jour)** : 50 × $1.27 = $63.5/mois
- **Total** : $4,663.5/mois = **$55,962/an**

**Recommandation pour GirlyCrea** :
- **<20 engineers** : New Relic One ($17k/an) - transparent, scalable
- **20-50 engineers** : Prometheus auto-hébergé ($15k/an) - contrôle total
- **>50 engineers** : Datadog Enterprise ($56k/an) - intégrations riches

## 🔍 Monitoring Continu

### Métriques à Surveiller

**Quotidien** :
- Error rate par endpoint
- Latency P99
- Database query performance
- Business KPIs (orders, revenue)

**Hebdomadaire** :
- Alert fatigue rate (faux positifs / total)
- SLO compliance
- Top slow queries
- Infrastructure trends

**Mensuel** :
- Review alertes (tuning)
- Analyse incidents (post-mortem)
- Optimization dashboards
- Capacity planning

## 🛠️ Fichiers à Créer/Améliorer

1. **`config/prometheus/alerts.yml`** - Règles d'alerting
2. **`config/alertmanager/config.yml`** - Configuration routing
3. **`scripts/setup-monitoring.sh`** - Script déploiement
4. **`docs/runbooks/`** - Documentation par type d'alerte
5. **`grafana/dashboards/`** - JSON dashboards (si export)

## 📚 Références

- [Prometheus Best Practices](https://prometheus.io/docs/practices/)
- [Alertmanager Configuration](https://prometheus.io/docs/alerting/latest/configuration/)
- [Grafana Dashboards](https://grafana.com/docs/grafana/latest/dashboards/)
- [New Relic Documentation](https://docs.newrelic.com/)
- [Datadog Documentation](https://docs.datadoghq.com/)

