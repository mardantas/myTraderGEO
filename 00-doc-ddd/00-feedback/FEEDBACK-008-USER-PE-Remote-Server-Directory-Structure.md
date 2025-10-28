<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# FEEDBACK-008-USER-PE-Remote-Server-Directory-Structure.md

> **Objetivo:** Documentar estrutura de diretórios nos servidores remotos (staging/production) e convenções de deploy.

---

**Data Abertura:** 2025-10-28
**Solicitante:** User (Marco)
**Destinatário:** PE Agent
**Status:** 🔴 Aberto

**Tipo:**
- [x] Melhoria (sugestão de enhancement)
- [ ] Correção (deliverable já entregue precisa ajuste)
- [ ] Dúvida (esclarecimento necessário)
- [ ] Novo Requisito (mudança de escopo)

**Urgência:** 🟡 Média

**Deliverable(s) Afetado(s):**
- `00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md`
- `05-infra/scripts/deploy.sh`
- `05-infra/README.md`

---

## 📋 Descrição

A documentação PE-00 descreve bem a **estrutura de arquivos no repositório Git** (`05-infra/`), mas **NÃO documenta** onde esses arquivos devem ficar nos **servidores remotos** (VPS de staging/production).

### Lacunas Identificadas

1. **Localização no Servidor:**
   - Onde copiar os arquivos no servidor? `/opt/`? `/home/user/`? Raiz?
   - Qual a estrutura de diretórios recomendada?

2. **Convenções de User/Ownership:**
   - Qual user deve rodar a aplicação? (root? deploy? mytrader?)
   - Quem é dono dos arquivos e diretórios?
   - Quais permissions usar?

3. **Setup Inicial:**
   - Como preparar o servidor pela primeira vez?
   - Criar user, diretórios, SSH keys, `.env`?

4. **Mapeamento Repo → Servidor:**
   - `05-infra/docker/docker-compose.staging.yml` vai para onde?
   - `05-infra/configs/traefik.yml` vai para onde?
   - `.env` (secrets) fica onde?

### Impacto

Sem essa documentação:
- ⚠️ Desenvolvedores não sabem onde colocar arquivos no servidor
- ⚠️ Script `deploy.sh` pode usar paths inconsistentes
- ⚠️ Troubleshooting fica difícil (onde estão os logs? configs?)
- ⚠️ Backup/restore scripts não sabem quais diretórios incluir

---

## 💥 Impacto Estimado

**Outros deliverables afetados:**
- [ ] PE-00-Environments-Setup.md - adicionar seção "Estrutura no Servidor Remoto"
- [ ] 05-infra/scripts/deploy.sh - atualizar paths para usar convenção definida
- [ ] 05-infra/README.md - documentar setup inicial do servidor

**Esforço estimado:** 2-4 horas (análise + documentação + atualização de scripts)
**Risco:** 🟢 Baixo (documentação e padronização)

---

## 💡 Proposta de Solução

### Convenção Recomendada

**Estrutura no servidor remoto (staging/production):**

```
/home/mytrader/mytrader-app/
├── app/                       # Deploy artifacts
│   ├── docker-compose.yml     # Copiado de 05-infra/docker/docker-compose.{env}.yml
│   ├── .env                   # Secrets (criado manualmente, NÃO versionado)
│   └── configs/
│       └── traefik.yml        # Copiado de 05-infra/configs/traefik.yml
│
├── backups/                   # Database backups (gerados por scripts)
│   └── postgres/
│       ├── 2025-10-28.sql.gz
│       └── 2025-10-27.sql.gz
│
├── scripts/                   # Helper scripts
│   ├── backup-db.sh
│   ├── restore-db.sh
│   └── health-check.sh
│
└── logs/                      # Aggregated logs (opcional, se não usar Docker logs)
    ├── deploy-history.log
    └── app/
```

**Justificativa:**

1. **User dedicado `mytrader`:**
   - ✅ Isolamento de segurança (não root, não deploy genérico)
   - ✅ Ownership automático (tudo pertence ao user)
   - ✅ Deploy sem sudo (user mytrader tem permissão Docker)

2. **Pasta projeto `mytrader-app/`:**
   - ✅ Isola tudo do projeto em uma pasta
   - ✅ Escalável (pode ter `mytrader-monitoring/`, `mytrader-analytics/` no futuro)
   - ✅ Nome claro e descritivo

3. **Subpasta `app/`:**
   - ✅ Contém apenas arquivos de deploy (compose, env, configs)
   - ✅ Separado de backups, scripts, logs

### Mapeamento Repositório → Servidor

| Arquivo no Repositório Git | Destino no Servidor | Como |
|----------------------------|---------------------|------|
| `05-infra/docker/docker-compose.staging.yml` | `/home/mytrader/mytrader-app/app/docker-compose.yml` | `deploy.sh` (scp) |
| `05-infra/docker/docker-compose.production.yml` | `/home/mytrader/mytrader-app/app/docker-compose.yml` | `deploy.sh` (scp) |
| `05-infra/configs/traefik.yml` | `/home/mytrader/mytrader-app/app/configs/traefik.yml` | `deploy.sh` (scp) |
| `05-infra/configs/.env.example` | `/home/mytrader/mytrader-app/app/.env` | Manual (primeira vez) |
| `05-infra/scripts/backup-database.sh` | `/home/mytrader/mytrader-app/scripts/backup-db.sh` | Manual ou deploy.sh |

### Setup Inicial do Servidor (Primeira Vez)

Documentar no PE-00:

```bash
# ===== EXECUTAR NO SERVIDOR (via SSH root ou sudo) =====

# 1. Criar user mytrader e adicionar ao grupo docker
sudo useradd -m -s /bin/bash -G docker mytrader
sudo passwd mytrader  # Definir senha

# 2. Configurar SSH key (para deploy automatizado)
sudo su - mytrader
mkdir -p ~/.ssh
chmod 700 ~/.ssh
# Copiar public key do CI/CD ou dev machine
echo "ssh-ed25519 AAAA..." >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit

# 3. Criar estrutura de diretórios
sudo su - mytrader
mkdir -p ~/mytrader-app/app/configs
mkdir -p ~/mytrader-app/backups/postgres
mkdir -p ~/mytrader-app/scripts
mkdir -p ~/mytrader-app/logs

# 4. Criar .env inicial (editar com secrets reais)
cat > ~/mytrader-app/app/.env << 'EOF'
# Environment: staging (ou production)
DOMAIN=staging.mytrader.com
ACME_EMAIL=admin@mytrader.com

# PostgreSQL
POSTGRES_DB=mytrader
POSTGRES_USER=mytrader
POSTGRES_PASSWORD=CHANGE_ME_STRONG_PASSWORD

# Traefik Dashboard
TRAEFIK_DASHBOARD_AUTH=admin:$apr1$xyz...  # htpasswd -nb admin password
EOF

chmod 600 ~/mytrader-app/app/.env  # Proteger secrets

# 5. Verificar estrutura
tree ~/mytrader-app/
```

### Atualizar deploy.sh

Ajustar `05-infra/scripts/deploy.sh` para usar os paths corretos:

```bash
#!/bin/bash
ENV=$1  # staging ou production

SERVER_USER="mytrader"
SERVER_HOST="..."  # Ajustar conforme ENV
APP_DIR="mytrader-app/app"  # <-- Path padronizado

# Copiar arquivos
scp 05-infra/docker/docker-compose.$ENV.yml \
    $SERVER_USER@$SERVER_HOST:~/$APP_DIR/docker-compose.yml

scp 05-infra/configs/traefik.yml \
    $SERVER_USER@$SERVER_HOST:~/$APP_DIR/configs/traefik.yml

# Deploy
ssh $SERVER_USER@$SERVER_HOST << EOF
  cd ~/$APP_DIR
  docker compose pull
  docker compose up -d
  docker compose ps
EOF
```

---

## 🎯 Critérios de Aceitação

Para considerar o feedback resolvido:

1. [ ] Estrutura de diretórios no servidor documentada em PE-00
2. [ ] Path completo definido: `/home/mytrader/mytrader-app/`
3. [ ] Convenção de user (`mytrader`) e ownership documentada
4. [ ] Setup inicial do servidor documentado (passo a passo)
5. [ ] Mapeamento repositório → servidor documentado (tabela)
6. [ ] Permissions recomendadas documentadas (chmod/chown)
7. [ ] deploy.sh atualizado para usar paths corretos (ou documentado para GM fazer)
8. [ ] Subpastas explicadas (`app/`, `backups/`, `scripts/`, `logs/`)

---

## 📝 Notas Adicionais

### Onde Documentar no PE-00

Adicionar nova seção **"Estrutura no Servidor Remoto (Staging/Production)"** após a seção atual "Estrutura de Arquivos" (linha ~228).

**Estrutura da nova seção:**

```markdown
### Estrutura no Servidor Remoto (Staging/Production)

**Convenção de Diretórios no VPS:**

[Árvore de diretórios]

**User e Ownership:**

[Explicação do user mytrader, grupo docker, permissions]

**Mapeamento Repositório → Servidor:**

[Tabela com mapeamento de arquivos]

**Setup Inicial (Primeira Vez):**

[Script bash passo a passo para preparar servidor]

**Named Volumes (Docker):**

[Explicação de onde Docker armazena volumes: /var/lib/docker/volumes/]
```

### Benefícios da Padronização

- ✅ **Clareza:** Qualquer desenvolvedor sabe onde estão os arquivos
- ✅ **Consistência:** Staging e production seguem mesma estrutura
- ✅ **Troubleshooting:** Fácil localizar logs, configs, backups
- ✅ **Automation:** Scripts de deploy/backup sabem paths exatos
- ✅ **Onboarding:** Novos membros do time entendem estrutura rapidamente
- ✅ **Disaster Recovery:** Backup sabe quais diretórios incluir

---

## 📝 Histórico

| Data | Mudança | Autor |
|------|---------|-------|
| 2025-10-28 | Criado | User (Marco) |
