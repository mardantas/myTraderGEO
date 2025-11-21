# FEEDBACK-011 - API Testing Checklist

> **Objetivo:** Validar implementação das Fases 1-3 (JSONB Deserialization, Error Handling Middleware, FluentValidation)

---

## Preparação

### 1. Iniciar Ambiente

```bash
# 1. Parar container antigo da API (se estiver rodando)
docker stop mytrader-dev-api

# 2. Garantir que PostgreSQL está rodando
docker ps | grep mytrader-dev-database

# 3. Rodar API localmente com código atualizado
cd c:/Users/Marco/Projetos/myTraderGEO/02-backend/src/MyTraderGEO.WebAPI
dotnet run

# 4. Aguardar API iniciar e verificar porta (geralmente 5024 ou dinâmica)
# Procurar na saída: "Now listening on: http://localhost:XXXX"

# 5. Abrir Swagger no navegador
# http://localhost:XXXX (substituir XXXX pela porta exibida)
```

---

## Testes Manuais via Swagger

### ✅ Teste 1: GET /api/plans (Listar Planos Disponíveis)

**Objetivo:** Validar que endpoint público retorna planos cadastrados

**Request:**
```http
GET /api/plans
```

**Resultado Esperado:**
- Status: `200 OK`
- Body: Array com 3 planos (Básico, Pleno, Consultor)

**Exemplo Response:**
```json
[
  {
    "id": 1,
    "name": "Básico",
    "priceMonthly": { "amount": 0, "currency": "BRL" },
    "priceAnnual": { "amount": 0, "currency": "BRL" },
    "strategyLimit": 3,
    "features": {
      "realtimeData": false,
      "advancedAlerts": false,
      "consultingTools": false,
      "communityAccess": true
    }
  }
]
```

**Validações:**
- ✅ Status code 200
- ✅ Retorna array de planos
- ✅ Cada plano tem `id`, `name`, `priceMonthly`, `features`, `strategyLimit`

---

### ✅ Teste 2: POST /api/auth/register (Registro com Sucesso)

**Objetivo:** Validar FluentValidation e criação de usuário

**Request:**
```http
POST /api/auth/register
Content-Type: application/json

{
  "fullName": "João da Silva Teste",
  "displayName": "João Teste",
  "email": "joao.teste.feedback011@email.com",
  "password": "Senha@1234",
  "subscriptionPlanId": 1,
  "riskProfile": 1,
  "billingPeriod": 1
}
```

**⚠️ IMPORTANTE - Valores dos Enums:**
- `riskProfile`: **NÚMERO** (0 = Conservador, 1 = Moderado, 2 = Agressivo) - NÃO usar strings
- `billingPeriod`: **NÚMERO** (1 = Monthly/Mensal, 12 = Annual/Anual) - NÃO usar strings
- `subscriptionPlanId`: **NÚMERO** (1 = Básico, 2 = Pleno, 3 = Consultor)

**Resultado Esperado:**
- Status: `201 Created`
- Body: Dados do usuário criado + `userId` (GUID)

**Exemplo Response:**
```json
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "email": "joao.teste.feedback011@email.com",
  "message": "Trader registered successfully"
}
```

**Validações:**
- ✅ Status code 201
- ✅ Retorna `userId` (GUID válido)
- ✅ Retorna `email` igual ao enviado
- ✅ Mensagem de sucesso

---

### ✅ Teste 3: POST /api/auth/register (Email Duplicado - Validação)

**Objetivo:** Validar FluentValidation com erro field-level (RFC 7807)

**Request:**
```http
POST /api/auth/register
Content-Type: application/json

{
  "fullName": "João da Silva Teste 2",
  "displayName": "João Teste 2",
  "email": "joao.teste.feedback011@email.com",
  "password": "Senha@1234",
  "subscriptionPlanId": 1,
  "riskProfile": 1,
  "billingPeriod": 1
}
```

**Resultado Esperado:**
- Status: `400 Bad Request`
- Content-Type: `application/problem+json`
- Body: RFC 7807 Problem Details com campo `errors` contendo validação do campo `Email`

**Exemplo Response:**
```json
{
  "type": "https://api.mytrader.com/errors/validation-error",
  "title": "Validation Error",
  "status": 400,
  "detail": "One or more validation errors occurred.",
  "errors": {
    "Email": [
      "Email já cadastrado"
    ]
  },
  "traceId": "00-abc123..."
}
```

**Validações:**
- ✅ Status code 400
- ✅ `type` contém "validation-error"
- ✅ Campo `errors` é um dicionário
- ✅ `errors.Email` contém array com mensagem "Email já cadastrado"
- ✅ `traceId` presente

**🎯 CRÍTICO:** Este teste valida a **Fase 3 (FluentValidation)** + **Fase 2 (Error Handling Middleware)**

---

### ✅ Teste 4: POST /api/auth/login (Login com Sucesso)

**Objetivo:** Validar autenticação e geração de JWT

**Request:**
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "joao.teste.feedback011@email.com",
  "password": "Senha@1234"
}
```

**Resultado Esperado:**
- Status: `200 OK`
- Body: JWT token + dados do usuário

**Exemplo Response:**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "email": "joao.teste.feedback011@email.com",
  "role": "Trader",
  "message": "Login successful"
}
```

**Validações:**
- ✅ Status code 200
- ✅ `token` presente (string longa JWT)
- ✅ Dados do usuário retornados

**📝 IMPORTANTE:** Copiar o `token` para usar no Teste 6

---

### ✅ Teste 5: POST /api/auth/login (Senha Incorreta)

**Objetivo:** Validar erro de autenticação (401 Unauthorized)

**Request:**
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "joao.teste.feedback011@email.com",
  "password": "SenhaErrada123"
}
```

**Resultado Esperado:**
- Status: `401 Unauthorized`
- Content-Type: `application/problem+json`
- Body: RFC 7807 Problem Details

**Exemplo Response:**
```json
{
  "type": "https://api.mytrader.com/errors/unauthorized",
  "title": "Unauthorized",
  "status": 401,
  "detail": "Invalid credentials",
  "traceId": "00-xyz789..."
}
```

**Validações:**
- ✅ Status code 401
- ✅ `type` contém "unauthorized"
- ✅ `detail` indica credenciais inválidas
- ✅ `traceId` presente

---

### ✅ Teste 6: GET /api/users/me (Usuário Autenticado)

**Objetivo:** Validar autenticação JWT + **JSONB Deserialization (Fase 1)**

**Request:**
```http
GET /api/users/me
Authorization: Bearer {TOKEN_DO_TESTE_4}
```

**⚠️ IMPORTANTE:** Substituir `{TOKEN_DO_TESTE_4}` pelo token obtido no Teste 4

**Resultado Esperado:**
- Status: `200 OK`
- Body: Dados completos do usuário

**Exemplo Response:**
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "joao.teste.feedback011@email.com",
  "fullName": "João da Silva Teste",
  "displayName": "João Teste",
  "role": "Trader",
  "status": "Active",
  "riskProfile": "Moderado",
  "subscriptionPlanId": 1,
  "billingPeriod": "Monthly",
  "planOverride": null,
  "customFees": null,
  "createdAt": "2025-11-15T14:30:00Z",
  "lastLoginAt": "2025-11-15T14:35:00Z"
}
```

**Validações:**
- ✅ Status code 200
- ✅ Todos os campos do usuário retornados
- ✅ `planOverride` e `customFees` aparecem (mesmo que `null`)
- ✅ **Se houver usuário com override no banco, validar que desserialização JSONB funciona**

**🎯 CRÍTICO:** Este teste valida a **Fase 1 (JSONB Deserialization)**

---

### ✅ Teste 7: GET /api/users/me (Não Autenticado)

**Objetivo:** Validar proteção de endpoint autenticado

**Request:**
```http
GET /api/users/me
(SEM header Authorization)
```

**Resultado Esperado:**
- Status: `401 Unauthorized`

**Validações:**
- ✅ Status code 401
- ✅ Endpoint protegido corretamente

---

## Testes Adicionais de Validação

### ✅ Teste 8: POST /api/auth/register (Email Inválido)

**Objetivo:** Validar FluentValidation para email com formato inválido

**Request:**
```json
{
  "fullName": "Teste Email Inválido",
  "displayName": "Teste",
  "email": "email-invalido",
  "password": "Senha@1234",
  "subscriptionPlanId": 1,
  "riskProfile": 1,
  "billingPeriod": 1
}
```

**Resultado Esperado:**
- Status: `400 Bad Request`
- `errors.Email`: `["Email inválido"]`

---

### ✅ Teste 9: POST /api/auth/register (Senha Curta)

**Objetivo:** Validar FluentValidation para senha com menos de 8 caracteres

**Request:**
```json
{
  "fullName": "Teste Senha Curta",
  "displayName": "Teste",
  "email": "senha.curta@email.com",
  "password": "123",
  "subscriptionPlanId": 1,
  "riskProfile": 1,
  "billingPeriod": 1
}
```

**Resultado Esperado:**
- Status: `400 Bad Request`
- `errors.Password`: `["Senha deve ter no mínimo 8 caracteres"]`

---

### ✅ Teste 10: POST /api/auth/register (Plano Inválido)

**Objetivo:** Validar FluentValidation assíncrona para plano inexistente no banco

**Request:**
```json
{
  "fullName": "Teste Plano Inválido",
  "displayName": "Teste",
  "email": "plano.invalido@email.com",
  "password": "Senha@1234",
  "subscriptionPlanId": 999,
  "riskProfile": 1,
  "billingPeriod": 1
}
```

**Resultado Esperado:**
- Status: `400 Bad Request`
- `errors.SubscriptionPlanId`: `["Plano de assinatura não encontrado"]`

---

## Resumo de Validações

| Teste | Endpoint | Valida | Status Esperado | RFC 7807 |
|-------|----------|--------|-----------------|----------|
| 1 | GET /api/plans | Endpoint público | 200 OK | N/A |
| 2 | POST /api/auth/register | Criação de usuário | 201 Created | N/A |
| 3 | POST /api/auth/register | FluentValidation (email duplicado) | 400 Bad Request | ✅ |
| 4 | POST /api/auth/login | Autenticação JWT | 200 OK | N/A |
| 5 | POST /api/auth/login | Erro de autenticação | 401 Unauthorized | ✅ |
| 6 | GET /api/users/me | JSONB Deserialization | 200 OK | N/A |
| 7 | GET /api/users/me | Proteção JWT | 401 Unauthorized | ✅ |
| 8 | POST /api/auth/register | Validação email | 400 Bad Request | ✅ |
| 9 | POST /api/auth/register | Validação senha | 400 Bad Request | ✅ |
| 10 | POST /api/auth/register | Validação plano | 400 Bad Request | ✅ |

---

## Checklist Final

- [ ] API iniciou sem erros
- [ ] Swagger acessível
- [ ] Teste 1: GET /api/plans retornou 200 OK
- [ ] Teste 2: Registro bem-sucedido (201 Created)
- [ ] Teste 3: Email duplicado retornou RFC 7807 com `errors.Email`
- [ ] Teste 4: Login bem-sucedido retornou JWT
- [ ] Teste 5: Senha incorreta retornou 401 com RFC 7807
- [ ] Teste 6: GET /users/me com JWT retornou dados do usuário
- [ ] Teste 7: GET /users/me sem JWT retornou 401
- [ ] Teste 8-10: Validações de campo retornaram RFC 7807 correto

---

## Resultado Esperado

**✅ APROVADO se:**
- Todos os 10 testes passaram
- Respostas de erro seguem RFC 7807 (Problem Details)
- FluentValidation retorna field-level errors
- JSONB deserialization funciona (Teste 6)
- Middleware captura exceções corretamente

**❌ REPROVADO se:**
- Qualquer teste falhar
- Respostas de erro não seguem RFC 7807
- Validation errors não têm campo específico

---

## Próximos Passos Após Aprovação

1. Reiniciar container Docker da API:
   ```bash
   docker start mytrader-dev-api
   ```

2. Atualizar FEEDBACK-011:
   - Marcar Fase 4 como concluída
   - Adicionar resultados dos testes
   - Atualizar status para "✅ Resolvido"

3. Notificar FE Agent que backend está pronto para integração

---

**Última Atualização:** 2025-11-15
**Responsável:** SE Agent
**Referência:** FEEDBACK-011 Fases 1-3 (JSONB + Error Handling + FluentValidation)
