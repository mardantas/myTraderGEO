# myTraderGEO - Frontend (Vue 3)

Sistema de trading geolocalizado - Interface do usuário

## 🚀 Stack Tecnológica

### Core
- **Framework:** Vue 3.3+ (Composition API)
- **Build Tool:** Vite 4+
- **Language:** TypeScript
- **Styling:** Tailwind CSS

### State Management & Routing
- **State:** Pinia (oficial Vue store)
- **Router:** Vue Router 4
- **Forms:** VeeValidate + Zod

### UI Components
- **Base Components:** Custom components (Button, Input, Card, etc.)
- **Icons:** Heroicons Vue
- **Enterprise Components:** PrimeVue
- **Utilities:** @vueuse/core

### Testing
- **Unit Tests:** Vitest + Vue Test Utils
- **E2E Tests:** Playwright (futuro)

## 📁 Estrutura do Projeto

```
01-frontend/
├── src/
│   ├── assets/                    # Imagens, fontes, etc.
│   ├── components/
│   │   ├── ui/                    # Componentes base (Button, Input, Card, etc.)
│   │   ├── forms/                 # Componentes de formulários
│   │   └── layout/                # Componentes de layout (Navbar, etc.)
│   ├── views/
│   │   ├── auth/                  # Páginas de autenticação
│   │   └── dashboard/             # Páginas do dashboard
│   ├── stores/                    # Pinia stores
│   ├── router/                    # Vue Router config
│   ├── types/                     # TypeScript types
│   ├── lib/                       # Utilities e validations
│   ├── composables/               # Vue composables
│   ├── App.vue                    # Root component
│   ├── main.ts                    # Entry point
│   └── style.css                  # Global styles + Design System
├── public/                        # Static assets
├── .env.local                     # Environment variables
├── vite.config.ts                 # Vite configuration
├── tailwind.config.js             # Tailwind CSS config
├── tsconfig.json                  # TypeScript config
└── package.json                   # Dependencies
```

## ⚙️ Setup e Instalação

### Pré-requisitos
```bash
Node.js >= 18
npm ou yarn
```

### Instalação
```bash
cd 01-frontend
npm install
```

### Configuração de Ambiente

Crie o arquivo `.env.local`:

```env
VITE_API_URL=http://localhost:5000/api
VITE_APP_NAME=myTraderGEO
VITE_APP_URL=http://localhost:5173
VITE_ENV=development
```

### Executar em Desenvolvimento
```bash
npm run dev
```

Acesse: [http://localhost:5173](http://localhost:5173)

### Build para Produção
```bash
npm run build
npm run preview
```

### Type Check
```bash
npm run type-check
```

### Linting
```bash
npm run lint
```

### Testes
```bash
npm run test        # Run tests
npm run test:ui     # Run tests with UI
npm run coverage    # Generate coverage report
```

## 🎨 Design System

Baseado em [UXD-00-Design-Foundations.md](../00-doc-ddd/03-ux-design/UXD-00-Design-Foundations.md)

### Cores
- **Primary:** #0066CC
- **Success:** #10B981
- **Danger:** #EF4444
- **Warning:** #F59E0B
- **Info:** #3B82F6

### Tipografia
- **Body:** Inter (400, 500, 600, 700)
- **Data:** JetBrains Mono (400, 500)
- **Sizes:** xs (10px) → h1 (32px)

### Spacing (8px grid)
- xs: 4px
- sm: 8px
- md: 16px
- lg: 24px
- xl: 32px
- 2xl: 48px
- 3xl: 64px

## 📄 Páginas Implementadas (EPIC-01-A)

### Autenticação
- **[/login](src/views/auth/LoginPage.vue)** - Login com email/senha
- **[/signup](src/views/auth/SignUpPage.vue)** - Cadastro completo com seleção de plano

### Dashboard
- **[/dashboard](src/views/dashboard/DashboardHome.vue)** - Home do dashboard
- **[/dashboard/profile](src/views/dashboard/ProfilePage.vue)** - Visualizar perfil
- **[/dashboard/profile/edit](src/views/dashboard/EditProfilePage.vue)** - Editar perfil

## 🔐 Segurança

Conforme [SEC-00-Security-Architecture.md](../00-doc-ddd/09-security/SEC-00-Security-Architecture.md):

- ✅ JWT armazenado em **sessionStorage** (não localStorage)
- ✅ Tokens enviados via header `Authorization: Bearer {token}`
- ✅ Validação client-side com Zod
- ✅ CORS configurado
- ✅ Focus indicators WCAG 2.1 AA
- ✅ ARIA labels

## ♿ Acessibilidade (WCAG 2.1 AA)

- ✅ Keyboard navigation (Tab order lógico)
- ✅ Focus indicators (2px ring, offset 2px)
- ✅ ARIA labels em inputs
- ✅ Error messages com aria-describedby
- ✅ Color contrast > 4.5:1
- ✅ Button size mínimo 44px × 44px
- ✅ Headings hierarchy (H1 → H2 → H3)
- ✅ Required fields com asterisco + aria-required

## 🧪 Testes

```bash
# Unit tests
npm run test

# Unit tests (watch mode)
npm run test:watch

# Coverage
npm run coverage

# E2E tests (futuro)
npm run test:e2e
```

## 📚 Documentação Interna

- [UXD-00-Design-Foundations.md](../00-doc-ddd/03-ux-design/UXD-00-Design-Foundations.md) - Design System
- [UXD-01-EPIC-01-A-User-Flows-and-Wireframes.md](../00-doc-ddd/03-ux-design/UXD-01-EPIC-01-A-User-Flows-and-Wireframes.md) - User flows
- [DE-01-EPIC-01-A-User-Management-Domain-Model.md](../00-doc-ddd/04-tactical-design/DE-01-EPIC-01-A-User-Management-Domain-Model.md) - Domain model
- [PE-00-Environments-Setup.md](../00-doc-ddd/08-platform-engineering/PE-00-Environments-Setup.md) - Tech stack
- [IMPLEMENTATION.md](./IMPLEMENTATION.md) - Detalhes da implementação

## 🔄 Próximos Passos

### Phase 2: Core Features
- [ ] Upgrade Plan page (`/dashboard/profile/upgrade`)
- [ ] Add Phone page (`/dashboard/profile/phone/add`)
- [ ] Verify Phone page (`/dashboard/profile/phone/verify`)
- [ ] Change Phone page (`/dashboard/profile/phone/change`)

### Phase 3: Enhanced UX
- [ ] OAuth Login (Google, Facebook)
- [ ] Two-Factor Authentication (2FA)
- [ ] Password Reset Flow
- [ ] Email Verification Flow
- [ ] Dark Mode toggle

### Melhorias Futuras
- [ ] Integrar API real do backend
- [ ] Adicionar testes (Vitest + Vue Test Utils)
- [ ] Implementar PWA (Progressive Web App)
- [ ] Otimizar bundle size
- [ ] i18n (Internacionalização)
- [ ] Analytics (Google Analytics)

## 📝 Scripts Disponíveis

```json
{
  "dev": "vite",
  "build": "vue-tsc -b && vite build",
  "preview": "vite preview",
  "type-check": "vue-tsc --noEmit",
  "test": "vitest",
  "test:ui": "vitest --ui",
  "coverage": "vitest --coverage"
}
```

## 🤝 Contribuindo

1. Siga o style guide do Vue 3 (Composition API)
2. Use TypeScript strict mode
3. Escreva testes para novos componentes
4. Siga as convenções de commit (Conventional Commits)
5. Mantenha a documentação atualizada

## 📄 Licença

Proprietário - myTraderGEO © 2025

---

**Implementado por:** FE Agent
**Data:** 2025-11-14
**Framework:** Vue 3 + TypeScript + Vite
**Status:** ✅ Phase 1 (MVP) Completo
