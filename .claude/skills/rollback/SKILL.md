---
name: rollback
description: Rollback automático para Coolify, Kubernetes e Terraform com verificação de saúde
version: 1.0.0
author: arturdr
tags: [devops, rollback, coolify, k8s, terraform, recovery]
dependencies:
  - kubectl
  - terraform
  - curl
  - jq
user-invocable: true
---

# Rollback Automático

## Descrição

Executa rollback automático para Coolify, Kubernetes (OKE) e Terraform com verificação de saúde pós-rollback.

## Uso

```
/rollback
Target: [coolify, k8s, terraform]
App: myapp
Env: [production, staging]
Version: [previous, v1.9.0, latest]
Force: [true, false]
```

## Rollback Coolify

```bash
# 1. Listar versões disponíveis
curl -s "$COOLIFY_BASE_URL/api/applications/$APP_ID/deployments" \
  -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN" | jq '.[].commit'

# 2. Rollback para versão anterior
curl -X POST "$COOLIFY_BASE_URL/api/applications/$APP_ID/rollback" \
  -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"version": "previous"}'

# 3. Rollback para versão específica
curl -X POST "$COOLIFY_BASE_URL/api/applications/$APP_ID/rollback" \
  -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"version": "v1.9.0"}'

# 4. Verificar saúde pós-rollback
sleep 30
curl -sf "https://$APP_URL/health" || echo "ROLLBACK FAILED"
```

## Rollback Kubernetes (OKE)

```bash
# 1. Ver histórico de rollouts
kubectl rollout history deployment/$APP_NAME -n $NAMESPACE

# 2. Rollback para versão anterior
kubectl rollout undo deployment/$APP_NAME -n $NAMESPACE

# 3. Rollback para versão específica
kubectl rollout undo deployment/$APP_NAME -n $NAMESPACE --to-revision=3

# 4. Verificar status do rollback
kubectl rollout status deployment/$APP_NAME -n $NAMESPACE

# 5. Verificar saúde dos pods
kubectl get pods -n $NAMESPACE -l app=$APP_NAME
kubectl logs -n $NAMESPACE -l app=$APP_NAME --tail=50
```

## Rollback Terraform

```bash
# 1. Listar estados anteriores
terraform state list

# 2. Ver plano anterior
terraform show -json terraform.tfstate.backup > previous-state.json

# 3. Rollback para estado anterior
terraform state pull > current-state.tfstate
terraform state push terraform.tfstate.backup

# 4. Aplicar rollback
terraform plan -out=rollback.tfplan
terraform apply rollback.tfplan

# 5. Verificar recursos
terraform state list
```

## Rollback Helm

```bash
# 1. Listar releases
helm history $RELEASE_NAME -n $NAMESPACE

# 2. Rollback para versão anterior
helm rollback $RELEASE_NAME -n $NAMESPACE

# 3. Rollback para versão específica
helm rollback $RELEASE_NAME 3 -n $NAMESPACE

# 4. Verificar status
helm status $RELEASE_NAME -n $NAMESPACE
```

## Rollback Emergencial (Force)

```bash
# Coolify: Scale to zero e restore backup
ssh vps "docker service scale $APP_NAME=0"
ssh vps "coolify-cli backup-restore --app $APP_NAME --version previous"

# K8s: Forçar rollout
kubectl rollout undo deployment/$APP_NAME -n $NAMESPACE --force

# Terraform: Revert com force
terraform apply -auto-approve -target=module.app
```

## Verificação Pós-Rollback

```bash
# Health check
curl -sf "https://$APP_URL/health" | jq '.status == "ok"'

# Check error rate (deve ser < 1%)
curl -s "http://prometheus:9090/api/v1/query?query=rate(http_requests_total{status=~\"5..\"}[5m])" | jq '.data.result[0].value[1] | tonumber < 0.01'

# Check latency (p95 < 200ms)
curl -s "http://prometheus:9090/api/v1/query?query=histogram_quantile(0.95,http_request_duration_seconds)" | jq '.data.result[0].value[1] | tonumber < 0.2'

# Check pods running
kubectl get pods -n $NAMESPACE -l app=$APP_NAME --field-selector=status.phase=Running | wc -l
```

## Checklist de Rollback

### Pré-Rollback
- [ ] Identificar versão alvo
- [ ] Verificar se versão existe
- [ ] Notificar time
- [ ] Documentar motivo do rollback

### Durante Rollback
- [ ] Executar comando de rollback
- [ ] Monitorar progresso
- [ ] Verificar logs em tempo real

### Pós-Rollback
- [ ] Health check passando
- [ ] Error rate < 1%
- [ ] Latência normal
- [ ] Todos pods running
- [ ] Notificar time sobre sucesso

## SLOs de Rollback

| Métrica | Target | Alert |
|---------|--------|-------|
| Rollback Time | < 60s | > 120s |
| Health Check Post-Rollback | 100% | < 95% |
| Zero Data Loss | 100% | Qualquer |
| Service Recovery | < 5min | > 10min |

## Troubleshooting

```bash
# Rollback travou
kubectl rollout undo deployment/$APP_NAME -n $NAMESPACE --force

# Health check falhando
kubectl logs -n $NAMESPACE -l app=$APP_NAME --tail=100 | grep -i error

# Pods não subindo
kubectl describe pods -n $NAMESPACE -l app=$APP_NAME

# Terraform state corrompido
terraform state pull > backup.tfstate
terraform state push backup.tfstate
```
