# 🧪 Guia de Testes Locais - Frontend Vue 3

## 📋 Pré-requisitos

```bash
cd 01-frontend
npm install
npm run dev
```

Acesse: **http://localhost:5174** (ou 5173)

---

## 🔧 Modo de Desenvolvimento (Sem Backend)

Como o backend ainda não está implementado, criamos **helpers de desenvolvimento** para testar a aplicação.

### ✅ Como Simular Login

1. **Abra o Console do Navegador** (F12 → Console)

2. **Execute o comando:**
   ```js
   window.mockLogin()
   ```

3. **Recarregue a página ou navegue para:**
   ```
   http://localhost:5174/dashboard
   ```

4. **Pronto!** Você está logado como usuário mock

### 🧹 Como Fazer Logout

No console do navegador:
```js
window.mockLogout()
```

### 👤 Ver Dados do Usuário Mock

```js
console.log(window.MOCK_USER)
```

**Dados do usuário mock:**
- Nome: João da Silva
- Email: joao@email.com
- Plano: Pleno (R$ 49,90/mês)
- Telefone: +55 11 98765-4321 (verificado)

---

## 🧭 Roteiro de Testes

### 1️⃣ Páginas Públicas (Sem Login)

#### Login Page
- **URL:** http://localhost:5174/login
- **Testar:**
  - ✅ Layout e design
  - ✅ Validação de email inválido
  - ✅ Validação de senha vazia
  - ✅ Checkbox "Lembrar-me"
  - ✅ Link "Esqueci minha senha" (visual apenas)
  - ✅ Botão Google OAuth (desabilitado - futuro)
  - ✅ Link "Criar conta" → redireciona para /signup
  - ⚠️ Submit vai dar erro (sem backend)

#### Sign Up Page
- **URL:** http://localhost:5174/signup
- **Testar:**
  - ✅ Todos os campos do formulário
  - ✅ Validação de nome completo
  - ✅ Validação de email
  - ✅ Validação de senha (força da senha)
  - ✅ Confirmação de senha
  - ✅ Telefone OPCIONAL:
    - Código do país: `+55` (Brasil)
    - Número: `11987654321` (apenas dígitos)
  - ✅ Seleção de Perfil de Risco
  - ✅ **Seletor de Planos:**
    - 3 planos: Básico (grátis), Pleno (R$ 49,90), Consultor (R$ 99,90)
    - Toggle Mensal/Anual (mostra desconto de 20%)
    - Badge "Recomendado" no plano Pleno
  - ✅ Checkbox Termos & Condições (obrigatório)
  - ✅ Link "Já tem conta?" → redireciona para /login
  - ⚠️ Submit vai dar erro (sem backend)

---

### 2️⃣ Páginas Autenticadas (Com Mock Login)

**⚠️ Execute `window.mockLogin()` no console primeiro!**

#### Dashboard Home
- **URL:** http://localhost:5174/dashboard
- **Testar:**
  - ✅ Navbar com logo, menu, badges
  - ✅ Badge "Mercado Aberto" (verde)
  - ✅ Badge do plano do usuário ("Pleno")
  - ✅ Ícone de notificações (com contador)
  - ✅ Menu do usuário (avatar com iniciais "JS")
  - ✅ Welcome alert (se vier de signup com `?welcome=true`)
  - ✅ 4 cards de estatísticas (vazios por enquanto)
  - ✅ Empty state "Nenhuma Estratégia Criada"
  - ✅ Botão "Criar Primeira Estratégia"

#### View Profile
- **URL:** http://localhost:5174/dashboard/profile
- **Testar:**
  - ✅ **Card 1: Informações Pessoais**
    - Nome Completo
    - Nome de Exibição
    - Email
    - Telefone com badge "Verificado"
    - Botão "Alterar" telefone
    - Ícone de edição (lápis) no canto superior direito
  - ✅ **Card 2: Perfil de Trading**
    - Badge "Trader" (função)
    - Badge "Moderado" (perfil de risco)
    - Badge "Pleno" (plano)
    - Badge "Ativo" (status)
  - ✅ **Card 3: Detalhes do Plano**
    - Limite de estratégias: "Ilimitado"
    - Features com checkmarks:
      - ✅ Dados em Tempo Real
      - ✅ Alertas Avançados
      - ❌ Ferramentas de Consultoria
      - ✅ Acesso à Comunidade
    - Próxima cobrança: 14/12/2025 - R$ 49,90
    - Botão "Upgrade de Plano"

#### Edit Profile
- **URL:** http://localhost:5174/dashboard/profile/edit
- **Testar:**
  - ✅ Breadcrumb: Dashboard > Perfil > Editar
  - ✅ Campo "Nome Completo" (read-only, cinza)
  - ✅ Campo "Nome de Exibição" (editável)
  - ✅ Campo "Email" (read-only, cinza)
  - ✅ Select "Perfil de Risco" (editável)
    - Conservador
    - Moderado
    - Agressivo
  - ✅ Botão "Cancelar" → volta para /dashboard/profile
  - ✅ Botão "Salvar Alterações"
  - ⚠️ Submit vai dar erro (sem backend)

---

### 3️⃣ Navegação e Guards

**Com Mock Login:**
- ✅ Acesso ao `/dashboard` → OK
- ✅ Acesso ao `/login` → redireciona para /dashboard
- ✅ Clicar em "Sair" no menu → logout e redireciona para /login

**Sem Mock Login:**
- ✅ Acesso ao `/dashboard` → redireciona para /login
- ✅ Acesso ao `/login` → OK
- ✅ Acesso ao `/signup` → OK

---

### 4️⃣ Navbar (Quando Logado)

- ✅ Logo "myTraderGEO" → redireciona para /dashboard
- ✅ Links de navegação:
  - Dashboard (ativo)
  - Estratégias
  - Análises
  - Comunidade
- ✅ Badge "Mercado Aberto" (verde)
- ✅ Badge "Pleno" (roxo)
- ✅ Ícone de notificações com contador vermelho
- ✅ Avatar com iniciais do usuário (JS)
- ✅ Dropdown do usuário:
  - Nome completo + email
  - Meu Perfil → /dashboard/profile
  - Configurações → /dashboard/settings
  - Sair → logout

---

### 5️⃣ Design System e Responsividade

**Componentes Base:**
- ✅ Button (7 variantes: primary, secondary, danger, success, ghost, link, icon)
- ✅ Input (com error states, helper text, prefix/suffix)
- ✅ Card (com Header, Title, Content, Footer)
- ✅ Badge (15+ variantes)
- ✅ Alert (4 variantes: info, success, warning, error)
- ✅ Label (com asterisco para required)
- ✅ Checkbox (estilizado)

**Responsividade:**
- ✅ Desktop (> 1024px)
- ✅ Tablet (768px - 1024px)
- ✅ Mobile (< 768px)

**Temas de cores:**
- Primary: #0066CC (azul)
- Success: #10B981 (verde)
- Danger: #EF4444 (vermelho)
- Warning: #F59E0B (laranja)
- Info: #3B82F6 (azul claro)

**Fontes:**
- Body: Inter
- Data: JetBrains Mono

---

## 🐛 Problemas Conhecidos (Esperados)

### ⚠️ Erros ao Submeter Formulários
**Normal!** O backend ainda não existe.

**Erro esperado:**
```
Failed to fetch
TypeError: NetworkError when attempting to fetch resource
```

**Como contornar:**
- Use `window.mockLogin()` para simular autenticação
- Ou aguarde implementação do backend C# (.NET 8)

### ⚠️ Links Sem Destino
Alguns links ainda não têm páginas implementadas:
- "Esqueci minha senha"
- "Upgrade de Plano"
- "Adicionar Telefone"
- "Alterar Telefone"
- "Configurações"
- "Estratégias", "Análises", "Comunidade" (navbar)

**Planejado para Phase 2 e Phase 3**

---

## 📊 Checklist de Testes

### ✅ Funcionalidades Básicas
- [ ] Abrir /login → visualizar formulário
- [ ] Abrir /signup → visualizar formulário completo
- [ ] Testar validações de formulário
- [ ] Testar seletor de planos (mensal/anual)
- [ ] Executar `window.mockLogin()`
- [ ] Acessar /dashboard
- [ ] Visualizar navbar completa
- [ ] Acessar /dashboard/profile
- [ ] Acessar /dashboard/profile/edit
- [ ] Testar navegação entre páginas
- [ ] Testar logout

### ✅ Design e UX
- [ ] Verificar cores do design system
- [ ] Verificar fontes (Inter + JetBrains Mono)
- [ ] Testar responsividade (mobile, tablet, desktop)
- [ ] Verificar focus states (Tab navigation)
- [ ] Verificar hover states
- [ ] Verificar loading states (spinners)
- [ ] Verificar error states (mensagens de erro)

### ✅ Acessibilidade
- [ ] Navegação por teclado (Tab)
- [ ] ARIA labels nos inputs
- [ ] Error messages com aria-describedby
- [ ] Contraste de cores (WCAG 2.1 AA)
- [ ] Tamanhos de botões (mínimo 44px)

---

## 🔮 Próximos Passos

1. **Implementar Backend C# (.NET 8)**
   - Criar endpoints de autenticação
   - Criar endpoints de usuário
   - Integrar com frontend

2. **Phase 2: Core Features**
   - Upgrade Plan page
   - Add/Verify/Change Phone pages

3. **Phase 3: Enhanced UX**
   - OAuth (Google, Facebook)
   - 2FA
   - Password Reset
   - Email Verification

---

## 🆘 Comandos Úteis

```bash
# Rodar dev server
npm run dev

# Build para produção
npm run build

# Preview do build
npm run preview

# Type check
npm run type-check

# Testes unitários (quando implementados)
npm run test
```

---

## 🎯 Mock Login Rápido

**Console do navegador:**
```js
// Login
window.mockLogin()

// Ver usuário
console.log(window.MOCK_USER)

// Logout
window.mockLogout()
```

---

**Bons testes!** 🚀

Se encontrar bugs ou comportamentos inesperados, reporte no console ou documente para correção.
