---
name: overnight
description: Controla o loop 24/7 de monitoramento (start/stop/status)
version: 3.0.0
author: arturdr
---

# Overnight Loop Control v3

Controla o loop de monitoramento 24/7 do sistema Claude DevOps.

## Uso

```
/overnight start   # Inicia o loop
/overnight stop    # Para o loop
/overnight status  # Mostra status atual (padrão)
/overnight restart # Reinicia o loop
```

## Execução

Execute o script de controle com a ação desejada:

```bash
./scripts/overnight-control-v3.sh start
./scripts/overnight-control-v3.sh stop
./scripts/overnight-control-v3.sh status
./scripts/overnight-control-v3.sh restart
```

## O que o Loop Faz

A cada 15 minutos:
1. ✅ Executa testes (19/19)
2. ✅ Verifica saúde do Coolify/Docker
3. ✅ Verifica MCPs (5/5)
4. ✅ Verifica recursos (RAM/Disk)
5. 💾 Cria backup a cada 6 ciclos (~1.5h)

## Melhorias v3

| Feature | Descrição |
|---------|-----------|
| **Graceful shutdown** | Aguarda processos filhos terminarem |
| **Trap handlers** | SIGTERM, SIGINT, SIGHUP tratados |
| **Orphan cleanup** | Mata processos órfãos no início |
| **Lock file robusto** | PID file + verificação atômica |
| **Sem zumbis** | `wait` + cleanup de children |
| **Sleep interrompível** | Loop de 1s que responde a signals |

## Logs

- **Detalhado**: `logs/overnight-247-YYYYMMDD.log`
- **Resumo**: `logs/overnight-cycles.log`

## Arquivos

| Arquivo | Função |
|---------|--------|
| `scripts/overnight-loop-247-v3.sh` | Script principal do loop |
| `scripts/overnight-control-v3.sh` | Script de controle (start/stop/status/restart) |
| `/tmp/claude-overnight-247-v3.lock` | Lock file |
| `/tmp/claude-overnight-247-v3.pid` | PID file |

## Troubleshooting

### Loop não para

```bash
# Verificar processos
ps aux | grep overnight

# Forçar parada manual
pkill -f "overnight-loop-247-v3.sh"
rm -f /tmp/claude-overnight-247-v3.*
```

### Lock file travado

```bash
# Limpar lock
rm -f /tmp/claude-overnight-247-v3.lock
rm -f /tmp/claude-overnight-247-v3.pid
```

### Verificar logs

```bash
# Últimos 50 logs
tail -50 logs/overnight-247-$(date +%Y%m%d).log

# Seguir logs em tempo real
tail -f logs/overnight-247-$(date +%Y%m%d).log
```
