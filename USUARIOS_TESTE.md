# 🔐 Usuários de Teste - myTraderGEO

Este documento lista todos os usuários de teste criados nos seeds do banco de dados.

## 📋 Resumo de Usuários

| Email | Senha | Role | Plano | Perfil de Risco | ID |
|-------|-------|------|-------|-----------------|-----|
| admin@mytradergeo.com | `Admin@123` | **Administrator** | - | - | `00000000-0000-0000-0000-000000000001` |
| trader.basico@demo.com | `Trader@123` | Trader | Básico | Conservador | `10000000-0000-0000-0000-000000000001` |
| trader.pleno@demo.com | `Trader@123` | Trader | Pleno | Moderado | `20000000-0000-0000-0000-000000000002` |
| trader.consultor@demo.com | `Trader@123` | Trader | Consultor | Agressivo | `30000000-0000-0000-0000-000000000003` |
| trader.beta@demo.com | `Trader@123` | Trader | Básico + Override | Moderado | `40000000-0000-0000-0000-000000000004` |

---

## 👤 Detalhes dos Usuários

### 1. **Administrador** 👑

```
Email:    admin@mytradergeo.com
Senha:    Admin@123
Role:     Administrator
Status:   Active
```

**Permissões:**
- ✅ Acesso total ao painel administrativo
- ✅ Configurar sistema (taxas e limites)
- ✅ Gestão de usuários (plan overrides)
- ✅ Gestão de planos (criar/editar)

**Acesso:**
- URL: `http://localhost:5173/admin`
- Todas as 3 tabs disponíveis

---

### 2. **Trader Básico** 🆓

```
Email:    trader.basico@demo.com
Senha:    Trader@123
Role:     Trader
Plano:    Básico (Free)
Perfil:   Conservador
```

**Características do Plano:**
- 💰 Gratuito
- 📊 Limite: 1 estratégia
- ❌ Sem dados em tempo real
- ❌ Sem alertas avançados
- ❌ Sem ferramentas de consultoria
- ✅ Acesso à comunidade

**Telefone:** +55 11 987654321 (verificado)

---

### 3. **Trader Pleno** 💎

```
Email:    trader.pleno@demo.com
Senha:    Trader@123
Role:     Trader
Plano:    Pleno (R$ 49,90/mês)
Perfil:   Moderado
```

**Características do Plano:**
- 💰 R$ 49,90/mês ou R$ 479,04/ano (20% desconto)
- 📊 Limite: Ilimitado (999 estratégias)
- ✅ Dados em tempo real
- ✅ Alertas avançados
- ❌ Sem ferramentas de consultoria
- ✅ Acesso à comunidade

**Telefone:** +55 11 987654322 (verificado)
**Período:** Anual

---

### 4. **Trader Consultor** 🌟

```
Email:    trader.consultor@demo.com
Senha:    Trader@123
Role:     Trader
Plano:    Consultor (R$ 99,90/mês)
Perfil:   Agressivo
```

**Características do Plano:**
- 💰 R$ 99,90/mês ou R$ 959,04/ano (20% desconto)
- 📊 Limite: Ilimitado (999 estratégias)
- ✅ Dados em tempo real
- ✅ Alertas avançados
- ✅ Ferramentas de consultoria
- ✅ Acesso à comunidade

**Telefone:** +55 11 987654323 (verificado)
**Período:** Anual

---

### 5. **Trader Beta** 🧪

```
Email:    trader.beta@demo.com
Senha:    Trader@123
Role:     Trader
Plano:    Básico (com Plan Override)
Perfil:   Moderado
```

**Plano Override Ativo:**
- 📊 Limite: 50 estratégias (override)
- ✅ Dados em tempo real (override)
- ✅ Alertas avançados (override)
- ❌ Ferramentas de consultoria
- ✅ Acesso à comunidade

**Detalhes do Override:**
- Motivo: "Beta Tester"
- Concedido por: Admin (`00000000-0000-0000-0000-000000000001`)
- Concedido em: 26/10/2025
- Expira em: 31/12/2025

**Telefone:** +55 11 987654324 (verificado)

---

## 🎯 Casos de Uso para Testes

### Teste 1: Acesso Administrativo
1. Login com `admin@mytradergeo.com` / `Admin@123`
2. Acessar `/admin`
3. Testar todas as 3 tabs:
   - ⚙️ Configuração do Sistema
   - 👥 Gestão de Usuários
   - 💳 Gestão de Planos

### Teste 2: Acesso Negado (Trader tentando acessar Admin)
1. Login com `trader.basico@demo.com` / `Trader@123`
2. Tentar acessar `/admin`
3. Deve ser redirecionado para `/dashboard`
4. Deve ver alerta "Acesso Negado"

### Teste 3: Plan Override
1. Login como admin
2. Acessar `/admin` > Tab "Gestão de Usuários"
3. Conceder override para `trader.basico@demo.com`
   - User ID: `10000000-0000-0000-0000-000000000001`
   - Motivo: "Teste de override"
   - Limite: 10 estratégias
   - Features: Dados em tempo real
4. Verificar no perfil do trader

### Teste 4: Criar Novo Plano
1. Login como admin
2. Acessar `/admin` > Tab "Gestão de Planos"
3. Criar plano "Premium"
   - Preço mensal: R$ 149,90
   - Preço anual: R$ 1.439,04
   - Limite: Ilimitado (0)
   - Todos os recursos ativados
4. Verificar na lista de planos

### Teste 5: Editar Configuração do Sistema
1. Login como admin
2. Acessar `/admin` > Tab "Configuração do Sistema"
3. Alterar taxas:
   - Taxa de Corretagem: 0.0005 (0.05%)
   - IR Day Trade: 0.22 (22%)
4. Salvar e verificar histórico

---

## 🔒 Segurança

### Senhas (BCrypt Hash)

Todas as senhas são hasheadas com BCrypt (cost=11):
- `Admin@123` → `$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy`
- `Trader@123` → `$2a$11$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy`

### Observações de Segurança

⚠️ **IMPORTANTE:**
1. Estas senhas são para **ambiente de desenvolvimento/teste apenas**
2. Em **produção**, use senhas fortes e únicas
3. O usuário admin deve alterar a senha no primeiro login
4. Nunca commite credenciais reais no repositório

---

## 📊 Planos de Assinatura Disponíveis

| ID | Nome | Preço Mensal | Preço Anual | Estratégias | Real-time | Alertas | Consultoria | Comunidade |
|----|------|--------------|-------------|-------------|-----------|---------|-------------|------------|
| 1 | Básico | R$ 0,00 | R$ 0,00 | 1 | ❌ | ❌ | ❌ | ✅ |
| 2 | Pleno | R$ 49,90 | R$ 479,04 | Ilimitado | ✅ | ✅ | ❌ | ✅ |
| 3 | Consultor | R$ 99,90 | R$ 959,04 | Ilimitado | ✅ | ✅ | ✅ | ✅ |

---

## 🧪 Configuração do Sistema Padrão

```json
{
  "taxas": {
    "brokerCommissionRate": 0.00000000,    // 0%
    "b3EmolumentRate": 0.00032500,         // 0.0325%
    "settlementFeeRate": 0.00027500,       // 0.0275%
    "issRate": 0.05000000,                 // 5% (ISS sobre emolumentos)
    "incomeTaxRate": 0.15000000,           // 15% (IR swing-trade)
    "dayTradeIncomeTaxRate": 0.20000000    // 20% (IR day-trade)
  },
  "limites": {
    "maxOpenStrategiesPerUser": 100,
    "maxStrategiesInTemplate": 10
  }
}
```

---

## 🚀 Como Testar

### 1. Frontend (Vite)
```bash
cd 01-frontend
npm run dev
```
Acesse: `http://localhost:5173`

### 2. Backend (ASP.NET Core)
```bash
cd 02-backend
dotnet run --project src/MyTraderGEO.WebAPI
```
API: `http://localhost:5000`

### 3. Login
1. Acesse `http://localhost:5173/login`
2. Use uma das credenciais acima
3. Navegue para `/admin` (se admin/moderator)

---

## 📝 Notas Adicionais

- **Usuário System** (`00000000-0000-0000-0000-000000000000`) é usado internamente e não pode fazer login
- Todos os traders demo têm telefones verificados
- O trader beta tem um override que expira em 31/12/2025
- IDs de usuários são GUIDs fixos para facilitar testes

---

## 🐛 Troubleshooting

### Erro: "Invalid email or password" (em português: "Email ou senha inválidos")
- Verifique se digitou o email e senha corretamente
- Emails são case-sensitive
- Senhas também são case-sensitive

### Erro: "Acesso Negado" ao acessar /admin
- Apenas usuários com role `Moderator` ou `Administrator` podem acessar
- Traders não têm acesso ao painel admin

### Backend não conecta ao banco
- Verifique se o PostgreSQL está rodando
- Confirme a string de conexão em `appsettings.json`
- Execute as migrations: `04-database/migrations/001_create_user_management_schema.sql`
- Execute os seeds: `04-database/seeds/001_seed_user_management_defaults.sql`

---

**Última atualização:** 2025-01-21
**Versão do Seed:** 001
**Epic:** EPIC-01-A - User Management
