# Funcionalidades Administrativas - Frontend

Este documento descreve as funcionalidades administrativas implementadas no frontend do myTraderGEO.

## 📋 Resumo

Foram implementadas 3 áreas administrativas completas que integram com os endpoints do backend:

1. **Configuração do Sistema** - Gerenciamento de taxas e limites
2. **Gestão de Usuários** - Concessão e revogação de overrides de plano
3. **Gestão de Planos** - Criação e edição de planos de assinatura

## 🎯 Funcionalidades Implementadas

### 1. Configuração do Sistema (Moderator+)

**Endpoint Backend:** `GET/PUT /api/System/config`

**Componente:** `AdminSystemConfig.vue`

**Recursos:**
- ✅ Visualizar configurações atuais do sistema
- ✅ Editar taxas:
  - Taxa de Corretagem
  - Taxa de Emolumentos B3
  - Taxa de Liquidação
  - Imposto de Renda (Normal e Day Trade)
- ✅ Editar limites:
  - Máximo de estratégias abertas por usuário
  - Máximo de estratégias em template
- ✅ Validação de formulário com Zod
- ✅ Feedback de sucesso/erro
- ✅ Histórico de atualização (quem e quando)

### 2. Gestão de Usuários (Admin Only)

**Endpoints Backend:** `POST/DELETE /api/Users/{id}/plan-override`

**Componente:** `AdminUserManagement.vue`

**Recursos:**
- ✅ Conceder override de plano para usuário
  - Limite personalizado de estratégias
  - Override de recursos individuais (dados em tempo real, alertas, etc.)
  - Data de expiração opcional
  - Motivo obrigatório para auditoria
- ✅ Revogar override de plano
- ✅ Validação de GUID do usuário
- ✅ Feedback de sucesso/erro
- ✅ Seção de ajuda integrada

### 3. Gestão de Planos (Admin Only)

**Endpoint Backend:** `POST /api/Plans`

**Componente:** `AdminPlansManagement.vue`

**Recursos:**
- ✅ Criar novos planos de assinatura
- ✅ Editar planos existentes
- ✅ Configurar:
  - Nome e descrição
  - Status (ativo/inativo)
  - Preços (mensal e anual)
  - Limite de estratégias
  - Recursos incluídos
- ✅ Visualizar lista de planos existentes
- ✅ Sugestão automática de preço anual (15% desconto)
- ✅ Interface intuitiva com badges de recursos

## 📁 Estrutura de Arquivos

### Serviços API (TypeScript)

```
src/services/
├── user-management.service.ts  (NEW) - Gestão de usuários
├── system.service.ts           (NEW) - Configuração do sistema
└── plans.service.ts            (UPDATED) - Adicionado configurePlan()
```

### Tipos TypeScript

```
src/types/
└── api.ts                      (UPDATED) - Novos tipos:
    ├── GrantPlanOverrideRequest/Response
    ├── RevokePlanOverrideResponse
    ├── SystemConfigResponse
    ├── UpdateSystemConfigRequest/Response
    └── ConfigureSubscriptionPlanRequest/Response
```

### Componentes Vue

```
src/components/admin/           (NEW)
├── AdminSystemConfig.vue       - Configuração do sistema
├── AdminUserManagement.vue     - Gestão de usuários
├── AdminPlansManagement.vue    - Gestão de planos
└── index.ts                    - Exports centralizados
```

### Views/Páginas

```
src/views/admin/                (NEW)
└── AdminPanel.vue              - Painel admin com tabs
```

## 🚀 Como Usar

### 1. Importar Componentes Individuais

```vue
<script setup lang="ts">
import { AdminSystemConfig } from '@/components/admin'
</script>

<template>
  <AdminSystemConfig />
</template>
```

### 2. Usar a View Completa do Painel Admin

```vue
<script setup lang="ts">
import AdminPanel from '@/views/admin/AdminPanel.vue'
</script>

<template>
  <AdminPanel />
</template>
```

### 3. Usar Serviços Diretamente

```typescript
import { grantPlanOverride, revokePlanOverride } from '@/services/user-management.service'
import { getSystemConfig, updateSystemConfig } from '@/services/system.service'
import { configurePlan } from '@/services/plans.service'

// Exemplo: Conceder override de plano
const response = await grantPlanOverride('user-guid-here', {
  reason: 'Trial de 30 dias',
  strategyLimitOverride: 100,
  featureRealtimeDataOverride: true,
  expiresAt: '2025-12-31T23:59:59Z'
})
```

## 🔐 Controle de Acesso

### Hierarquia de Permissões

| Funcionalidade | Moderator | Administrator |
|----------------|-----------|---------------|
| Visualizar Config Sistema | ✅ | ✅ |
| Editar Config Sistema | ❌ | ✅ |
| Gestão de Usuários | ❌ | ✅ |
| Gestão de Planos | ❌ | ✅ |

### Implementação no Componente

O componente `AdminPanel.vue` já implementa verificações de permissão:

```typescript
const isAdmin = computed(() => user.value?.role === 'Administrator')
const isModerator = computed(() => user.value?.role === 'Moderator' || isAdmin.value)
```

## 📝 Validação de Dados

Todos os formulários usam **Zod** para validação:

- ✅ Validação de tipos
- ✅ Validação de ranges (min/max)
- ✅ Validação de GUID para IDs de usuário
- ✅ Validação de strings (comprimento, obrigatoriedade)
- ✅ Mensagens de erro em português

## 🎨 UI/UX

### Componentes UI Utilizados

- `Card`, `CardHeader`, `CardTitle`, `CardContent` - Layout
- `Input`, `Label` - Formulários
- `Button` - Ações
- `Checkbox` - Features toggle
- `Alert` - Feedback de sucesso/erro

### Features UI

- ✅ Loading states em todas as operações
- ✅ Feedback visual (sucesso/erro)
- ✅ Animações suaves (fade in)
- ✅ Responsive design
- ✅ Dark mode support
- ✅ Acessibilidade (labels, ARIA)

## 🔄 Integração com Backend

### Headers Automáticos

Todos os serviços usam o cliente API base (`api.ts`) que:
- ✅ Adiciona automaticamente o token JWT
- ✅ Configura Content-Type: application/json
- ✅ Trata erros RFC 7807 Problem Details
- ✅ Suporta mensagens de erro em português

### Exemplo de Request

```typescript
// O serviço automaticamente:
// 1. Adiciona Authorization: Bearer {token}
// 2. Serializa JSON
// 3. Trata erros
const response = await updateSystemConfig({
  brokerCommissionRate: 0.0003,
  maxOpenStrategiesPerUser: 50
})
```

## 🧪 Testando as Funcionalidades

### 1. Configuração do Sistema

1. Acesse o painel admin
2. Navegue para a tab "Configuração do Sistema"
3. Edite as taxas (valores decimais: 0.15 = 15%)
4. Edite os limites (valores inteiros)
5. Clique em "Salvar Configuração"

### 2. Gestão de Usuários

1. Obtenha o GUID do usuário (via GET /api/Users/me)
2. Navegue para a tab "Gestão de Usuários"
3. Preencha o ID do usuário e motivo
4. Configure overrides desejados
5. Clique em "Conceder Override"

### 3. Gestão de Planos

1. Navegue para a tab "Gestão de Planos"
2. Preencha os detalhes do plano
3. Configure recursos (checkboxes)
4. Clique em "Criar Plano" ou "Atualizar Plano"
5. Veja o plano aparecer na lista abaixo

## 📚 Próximos Passos Sugeridos

### Melhorias Futuras

1. **Roteamento**
   - Adicionar rota `/admin` no Vue Router
   - Guard de rota verificando role do usuário

2. **Listagem de Usuários**
   - Endpoint GET /api/Users (com paginação)
   - Tabela de usuários com busca
   - Ação de override direta da tabela

3. **Dashboard Admin**
   - Estatísticas gerais (total de usuários, planos ativos, etc.)
   - Gráficos de uso
   - Logs de auditoria

4. **Histórico de Mudanças**
   - Log de todas as alterações administrativas
   - Quem, quando, o que foi alterado

5. **Testes**
   - Unit tests para serviços
   - Component tests para Vue components
   - E2E tests para fluxos admin

## ⚠️ Notas Importantes

1. **Segurança**: Todos os endpoints admin requerem autenticação e autorização adequada no backend
2. **Auditoria**: Todas as ações são registradas com ID do administrador no backend
3. **Validação**: Validação dupla (frontend + backend) para segurança
4. **Mensagens**: Todas as mensagens estão em português (backend e frontend)

## 🐛 Troubleshooting

### Erro: "ID de usuário inválido no token"
- Verifique se o token JWT é válido
- Faça login novamente

### Erro: "Acesso Negado"
- Verifique se seu usuário tem role Administrator ou Moderator
- Entre em contato com um administrador

### Formulário não salva
- Verifique mensagens de validação em vermelho
- Verifique console do navegador para erros de rede
- Verifique se o backend está rodando

## 📞 Suporte

Para dúvidas ou problemas:
1. Verifique este documento
2. Consulte a documentação da API backend
3. Verifique os logs do navegador (Console)
4. Entre em contato com a equipe de desenvolvimento
