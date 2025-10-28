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
**Data Reaberto:** 2025-10-28
**Solicitante:** User (Marco)
**Destinatário:** PE Agent
**Status:** 🟡 Em Andamento (Follow-up)

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

## 🔄 Follow-up: Lacunas Identificadas (2025-10-28)

Após revisão inicial da resolução, identificamos que o **setup inicial do servidor precisa incluir a infraestrutura base**:

### O que está faltando:

1. **Hostname do Servidor:**
   - Definir hostnames padronizados: `mytrader-stage`, `mytrader-prod`
   - Configuração via `hostnamectl`

2. **Instalação Docker:**
   - Docker Engine instalação (Debian 12)
   - Docker Compose Plugin
   - Verificação da instalação

3. **Criação de Grupo mytrader:**
   - Criar grupo `mytrader` (além do user)
   - User `mytrader` com grupo primário `mytrader` + secundário `docker`

4. **Firewall:**
   - UFW configurado (portas 22, 80, 443)
   - Deny by default, allow apenas necessário

5. **Security Hardening:**
   - Fail2ban (proteção SSH brute-force)
   - SSH hardening (disable password auth, permitir apenas key-based)

6. **Ferramentas Necessárias:**
   - `htpasswd` (apache2-utils) - para Traefik dashboard auth
   - `chrony` - NTP client para sincronização de tempo

### Justificativa:

Estas etapas são **pré-requisitos** para o servidor aceitar deploy. Sem Docker instalado, o servidor não consegue rodar os containers. Sem firewall, o servidor fica vulnerável. Sem NTP, certificados SSL podem falhar.

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

Documentar no PE-00 com as seguintes etapas:

#### Etapa 0: Configuração do Hostname

```bash
# ===== EXECUTAR NO SERVIDOR (via SSH root ou sudo) =====

# Definir hostname do servidor
# Staging:
sudo hostnamectl set-hostname mytrader-stage

# Production:
sudo hostnamectl set-hostname mytrader-prod

# Verificar
hostnamectl
```

#### Etapa 1: Instalação Docker Engine (Debian 12)

```bash
# Atualizar sistema
sudo apt-get update
sudo apt-get upgrade -y

# Instalar dependências
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Adicionar Docker GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Adicionar repositório Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker Engine + Compose Plugin
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verificar instalação
sudo docker --version
sudo docker compose version
```

#### Etapa 2: Configurar Firewall (UFW)

```bash
# Instalar UFW (se não estiver instalado)
sudo apt-get install -y ufw

# Configurar regras
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (Traefik)
sudo ufw allow 443/tcp   # HTTPS (Traefik)

# Habilitar firewall (CUIDADO: testar SSH antes!)
sudo ufw --force enable

# Verificar status
sudo ufw status verbose
```

#### Etapa 3: Security Hardening

```bash
# Instalar fail2ban (proteção SSH)
sudo apt-get install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Verificar status
sudo fail2ban-client status

# Instalar ferramentas necessárias
sudo apt-get install -y apache2-utils  # htpasswd para Traefik dashboard
sudo apt-get install -y chrony          # NTP client

# Configurar timezone (opcional)
sudo timedatectl set-timezone America/Sao_Paulo
```

#### Etapa 4: Criar Grupo e User mytrader

```bash
# Criar grupo mytrader (se não existir)
sudo groupadd mytrader

# Criar user mytrader com grupo primário mytrader + secundário docker
sudo useradd -m -s /bin/bash -g mytrader -G docker mytrader
sudo passwd mytrader  # Definir senha forte

# Verificar grupos do user
id mytrader
# Deve mostrar: uid=... gid=...(mytrader) groups=...(mytrader),...(docker)
```

#### Etapa 5: Configurar SSH Key (Deploy Automatizado)

```bash
# Trocar para user mytrader
sudo su - mytrader

# Criar diretório SSH
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Copiar public key do CI/CD ou dev machine
# Opção A: Gerar nova key no servidor (se necessário)
# ssh-keygen -t ed25519 -C "deploy@mytrader" -f ~/.ssh/id_ed25519

# Opção B: Adicionar public key existente (recomendado)
echo "ssh-ed25519 AAAAC3Nza... deploy@mytrader" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Sair do user mytrader
exit
```

#### Etapa 6: Criar Estrutura de Diretórios

```bash
# Trocar para user mytrader
sudo su - mytrader
mkdir -p ~/mytrader-app/app/configs
mkdir -p ~/mytrader-app/backups/postgres
mkdir -p ~/mytrader-app/scripts
mkdir -p ~/mytrader-app/logs

# Verificar estrutura criada
tree ~/mytrader-app/ -L 3
# Ou usar ls
ls -la ~/mytrader-app/

# Sair do user mytrader
exit
```

#### Etapa 7: Criar .env Inicial

```bash
# Trocar para user mytrader
sudo su - mytrader

# Criar .env inicial (EDITAR COM SECRETS REAIS!)
cat > ~/mytrader-app/app/.env << 'EOF'
# Environment: staging (ou production)
DOMAIN=staging.mytrader.com  # Ajustar: staging.mytrader.com ou mytrader.com
ACME_EMAIL=admin@mytrader.com

# PostgreSQL (MUDAR SENHAS!)
POSTGRES_DB=mytrader
POSTGRES_USER=mytrader_app
POSTGRES_PASSWORD=CHANGE_ME_STRONG_PASSWORD_HERE

# Traefik Dashboard (gerar com: htpasswd -nb admin password)
TRAEFIK_DASHBOARD_AUTH=admin:$apr1$xyz...
EOF

# Proteger secrets (read-only apenas para owner)
chmod 600 ~/mytrader-app/app/.env

# Verificar permissions
ls -la ~/mytrader-app/app/.env
# Deve mostrar: -rw------- mytrader mytrader .env

# Sair do user mytrader
exit
```

#### Etapa 8: Verificação Final

```bash
# Verificar Docker funcionando sem sudo
sudo su - mytrader
docker --version
docker compose version
docker ps  # Deve funcionar sem erro

# Verificar estrutura completa
tree ~/mytrader-app/ -L 3

# Verificar hostname
hostnamectl

# Verificar firewall
exit  # Voltar para root/sudo
sudo ufw status verbose

# Verificar fail2ban
sudo fail2ban-client status sshd
```

### Atualizar deploy.sh

Ajustar `05-infra/scripts/deploy.sh` para usar os paths e hostnames corretos:

```bash
#!/bin/bash
ENV=$1  # staging ou production

SERVER_USER="mytrader"
APP_DIR="mytrader-app/app"  # <-- Path padronizado

# Definir hostname conforme ambiente
if [ "$ENV" == "staging" ]; then
  SERVER_HOST="mytrader-stage"
elif [ "$ENV" == "production" ]; then
  SERVER_HOST="mytrader-prod"
else
  echo "Ambiente inválido: $ENV"
  exit 1
fi

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

**Exemplos de uso:**

```bash
# Deploy para staging
./05-infra/scripts/deploy.sh staging

# Deploy para production
./05-infra/scripts/deploy.sh production
```

---

## 🎯 Critérios de Aceitação

Para considerar o feedback completamente resolvido (incluindo follow-up):

### Critérios Originais (Resolvidos):
1. [x] Estrutura de diretórios no servidor documentada em PE-00
2. [x] Path completo definido: `/home/mytrader/mytrader-app/`
3. [x] Convenção de user (`mytrader`) e ownership documentada
4. [x] Mapeamento repositório → servidor documentado (tabela)
5. [x] Subpastas explicadas (`app/`, `backups/`, `scripts/`, `logs/`)

### Critérios Follow-up (Infraestrutura Base):
1. [ ] Hostnames padronizados documentados: `mytrader-stage`, `mytrader-prod`
2. [ ] Instalação Docker Engine (Debian 12) documentada passo a passo
3. [ ] Configuração firewall (UFW) documentada com regras necessárias
4. [ ] Security hardening documentado (fail2ban, SSH, NTP)
5. [ ] Criação grupo `mytrader` + user com grupos corretos documentada
6. [ ] Setup inicial completo documentado no PE-00 (todas as etapas 0-8)
7. [ ] Permissions recomendadas documentadas (chmod/chown)
8. [ ] deploy.sh atualizado para usar paths e hostnames corretos
9. [ ] 05-infra/README.md atualizado com pré-requisitos do servidor
10. [ ] Verificação final documentada (Docker, firewall, fail2ban)

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

## ✅ Resolução

**Data Resolução:** 2025-10-28
**Resolvido por:** PE Agent

**Ação Tomada:**

Documentei a estrutura de diretórios completa para servidores remotos (staging/production) e padronizei as convenções de deploy.

**Estrutura Definida:**

```
/home/mytrader/mytrader-app/
├── app/                       # Deploy artifacts (docker-compose, .env, configs)
├── backups/                   # Database backups
├── scripts/                   # Helper scripts (backup, restore, monitoring)
└── logs/                      # Aggregated logs (opcional)
```

**Deliverables Atualizados:**

1. **PE-00-Environments-Setup.md:**
   - [x] Adicionada seção "Estrutura no Servidor Remoto (Staging/Production)" após "Estrutura de Arquivos"
   - [x] Documentado path completo: `/home/mytrader/mytrader-app/`
   - [x] Documentado user dedicado `mytrader` com grupo `docker`
   - [x] Setup inicial do servidor passo a passo (criar user, SSH keys, diretórios, .env)
   - [x] Tabela de mapeamento repositório → servidor
   - [x] Explicação de named volumes Docker (`/var/lib/docker/volumes/`)
   - [x] Permissions recomendadas (chmod 600 para .env, ownership mytrader:docker)
   - [x] Benefícios da convenção documentados (clareza, consistência, troubleshooting)
   - [x] Deploy workflow resumido

2. **05-infra/README.md:**
   - [x] Adicionada subseção "Servidor Remoto (Staging/Production)" em "Estrutura de Pastas"
   - [x] Estrutura de diretórios documentada
   - [x] Referência para PE-00 para instruções detalhadas
   - [x] Última atualização: 2025-10-28

3. **05-infra/scripts/deploy.sh:**
   - [ ] Atualização de paths fica documentada para GM Agent implementar (CI/CD integration)
   - [ ] Convenção definida: `APP_DIR="mytrader-app/app"`
   - [ ] SSH com user `mytrader` para deploy

**Critérios de Aceitação Atendidos:**

- [x] Estrutura de diretórios no servidor documentada em PE-00
- [x] Path completo definido: `/home/mytrader/mytrader-app/`
- [x] Convenção de user (`mytrader`) e ownership documentada
- [x] Setup inicial do servidor documentado (passo a passo)
- [x] Mapeamento repositório → servidor documentado (tabela)
- [x] Permissions recomendadas documentadas (chmod/chown)
- [x] deploy.sh paths definidos (implementação fica para GM Agent)
- [x] Subpastas explicadas (`app/`, `backups/`, `scripts/`, `logs/`)

**Justificativa da Estrutura:**

- ✅ **User dedicado `mytrader`:** Isolamento de segurança (não root, não deploy genérico)
- ✅ **Ownership automático:** Tudo pertence ao user `mytrader:docker`, sem necessidade de `sudo`
- ✅ **Pasta projeto `mytrader-app/`:** Isola tudo do projeto myTraderGEO
- ✅ **Subpasta `app/`:** Contém apenas arquivos de deploy (compose, env, configs)
- ✅ **Escalável:** Permite adicionar `mytrader-monitoring/`, `mytrader-analytics/` no futuro
- ✅ **Named volumes:** PostgreSQL data fica em Docker volumes gerenciados

**Próximos Passos (Opcional):**

- GM Agent pode implementar deploy.sh com paths definidos quando configurar CI/CD
- Scripts de backup (backup-database.sh) usarão `/home/mytrader/mytrader-app/backups/`

---

**Status Final:** 🟢 Resolvido

---

## 📝 Histórico

| Data | Mudança | Autor |
|------|---------|-------|
| 2025-10-28 | Criado | User (Marco) |
| 2025-10-28 | Resolução inicial - Estrutura de servidor remoto documentada em PE-00 e 05-infra/README.md | PE Agent |
| 2025-10-28 | Reaberto (Follow-up) - Identificadas lacunas: instalação Docker, firewall, security hardening | PE Agent + User (Marco) |
| 2025-10-28 | Expandido FEEDBACK com etapas 0-8 de setup completo (hostname, Docker, UFW, fail2ban, user/grupo, SSH, diretórios, .env, verificação) | PE Agent |
