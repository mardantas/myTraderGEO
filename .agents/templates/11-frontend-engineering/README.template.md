<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# 01-frontend - {PROJECT_NAME} Frontend Application

**Projeto:** {PROJECT_NAME}  
**Stack:** {FRONTEND_STACK} (e.g., Vue 3 + TypeScript + Vite + Pinia + PrimeVue)  
**Architecture:** Component-based + State Management  
**Responsible Agent:** FE Agent  

---

## 📋 About This Document

This is a **quick reference guide** for building, running, and debugging the frontend application. For strategic UI/UX decisions, component design details, and architectural patterns, consult [FE-01-{EpicName}-Implementation-Report.md](../00-doc-ddd/06-frontend-design/FE-01-{EpicName}-Implementation-Report.md) and [UXD-01-{EpicName}-Wireframes.md](../00-doc-ddd/03-ux-design/UXD-01-{EpicName}-Wireframes.md).

**Document Separation:**  
- **This README:** Commands and checklists (HOW to execute)
- **FE-01 / UXD-01:** Design decisions, UI patterns, and trade-offs (WHY and WHAT)

**Principle:** README is an INDEX/QUICK-REFERENCE, not a duplicate.  

---

## 🎯 Technology Stack

- **Framework:** {FRAMEWORK} (e.g., Vue 3)
- **Language:** TypeScript
- **Build Tool:** {BUILD_TOOL} (e.g., Vite)
- **State Management:** {STATE_MGMT} (e.g., Pinia)
- **UI Library:** {UI_LIBRARY} (e.g., PrimeVue)
- **HTTP Client:** {HTTP_CLIENT} (e.g., Axios)
- **Form Validation:** {VALIDATION} (e.g., Zod)
- **Testing:** {TEST_FRAMEWORK} (e.g., Vitest + Vue Test Utils)

---

## 📁 Directory Structure

```
01-frontend/
├── src/
│   ├── assets/              # Static assets (images, fonts, styles)
│   ├── components/          # Reusable UI components
│   │   ├── common/          # Generic components (Button, Input, Modal)
│   │   └── {feature}/       # Feature-specific components
│   ├── views/               # Page components (routes)
│   │   └── {feature}/
│   ├── stores/              # State management (Pinia stores)
│   │   └── {feature}.ts
│   ├── services/            # API integration layer
│   │   ├── api.ts           # Axios instance + interceptors
│   │   └── {feature}.service.ts
│   ├── router/              # Vue Router configuration
│   │   └── index.ts
│   ├── composables/         # Reusable composition functions
│   │   └── use{Feature}.ts
│   ├── types/               # TypeScript interfaces/types
│   │   └── {feature}.types.ts
│   ├── utils/               # Utility functions
│   │   └── validators.ts
│   ├── App.vue              # Root component
│   └── main.ts              # Entry point
├── public/                  # Public assets (served as-is)
├── tests/
│   ├── unit/                # Unit tests (components, stores)
│   └── e2e/                 # E2E tests (Playwright/Cypress)
├── index.html               # HTML template
├── vite.config.ts           # Vite configuration
├── tsconfig.json            # TypeScript configuration
├── package.json             # Dependencies
└── README.md                # This file
```

---

## 🚀 Quick Start

### 1. Prerequisites

```bash
# Install Node.js (LTS version)
# Verify installation
node --version  # Should be ≥18.x
npm --version   # Should be ≥9.x
```

### 2. Install Dependencies

```bash
cd 01-frontend

# Install packages
npm install

# Or with specific package manager
# yarn install
# pnpm install
```

### 3. Configure Environment

```bash
# Copy .env example
cp .env.example .env

# Edit environment variables
nano .env
```

**Required Variables:**  
```bash
VITE_API_BASE_URL=http://localhost:5000
VITE_APP_TITLE={PROJECT_NAME}
VITE_ENV=development
```

### 4. Run Development Server

```bash
# Start dev server (hot reload enabled)
npm run dev

# Or via Docker
docker compose -f ../05-infra/docker/docker-compose.yml up web -d
```

**Access:**  
- Frontend: http://localhost:5173
- Hot Reload: Enabled (auto-refresh on code changes)

---

## 🔧 Common Commands

### Development

```bash
# Start dev server
npm run dev

# Start with specific port
npm run dev -- --port 3000

# Start with network access (accessible from other devices)
npm run dev -- --host
```

### Build

```bash
# Build for production
npm run build

# Preview production build locally
npm run preview

# Build with type checking
npm run type-check && npm run build
```

### Testing

```bash
# Run all tests
npm run test

# Run unit tests
npm run test:unit

# Run unit tests (watch mode)
npm run test:unit -- --watch

# Run E2E tests
npm run test:e2e

# Run E2E tests (headless)
npm run test:e2e:headless

# Generate coverage report
npm run test:coverage
```

### Code Quality

```bash
# Lint (ESLint)
npm run lint

# Lint and auto-fix
npm run lint:fix

# Format (Prettier)
npm run format

# Type check (TypeScript)
npm run type-check
```

---

## 🏗️ Build & Deploy

### Build for Production

```bash
# Build optimized bundle
npm run build

# Output: dist/ directory (ready to deploy)
```

**Build Optimizations:**  
- Code splitting (lazy loading)
- Tree shaking (remove unused code)
- Minification (smaller bundle size)
- Asset optimization (images, fonts)

### Docker Build

```bash
# Build Docker image
docker build -f ../05-infra/dockerfiles/frontend/Dockerfile -t {project}-web:latest .

# Run container
docker run -p 80:80 {project}-web:latest
```

### Deploy to Nginx (Production)

```bash
# Copy dist/ to Nginx root
cp -r dist/* /var/www/html/

# Or use Docker Compose
docker compose -f ../05-infra/docker/docker-compose.prod.yml up -d web
```

---

## 🧪 Testing

### Unit Tests (Components, Stores)

**Coverage Target:** ≥60% on critical components  

```bash
# Run all unit tests
npm run test:unit

# Run specific test file
npm run test:unit -- src/components/Button.spec.ts

# Run tests with coverage
npm run test:coverage

# Open coverage report
open coverage/index.html  # macOS
start coverage/index.html # Windows
```

### E2E Tests (User Flows)

```bash
# Run E2E tests (interactive)
npm run test:e2e

# Run E2E tests (headless - CI)
npm run test:e2e:headless

# Run specific E2E test
npm run test:e2e -- --spec tests/e2e/login.spec.ts
```

### Manual Testing (Browser)

```bash
# Start dev server
npm run dev

# Open browser: http://localhost:5173

# Test features:
# - Authentication (login, logout)
# - Navigation (routes, breadcrumbs)
# - Forms (validation, submission)
# - Responsive (mobile, tablet, desktop)
```

---

## 🐛 Debugging

### VS Code

**Launch Configuration (`.vscode/launch.json`):**  

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "chrome",
      "request": "launch",
      "name": "Launch Chrome (Vue)",
      "url": "http://localhost:5173",
      "webRoot": "${workspaceFolder}/01-frontend/src",
      "sourceMaps": true
    }
  ]
}
```

**Steps:**  
1. Start dev server: `npm run dev`
2. Press F5 in VS Code
3. Set breakpoints in `.vue` or `.ts` files
4. Debug in VS Code (no need for browser DevTools)

### Browser DevTools

```bash
# Vue DevTools extension (Chrome/Firefox)
# Install: https://devtools.vuejs.org/

# Enable sourcemaps (already enabled in Vite dev mode)
# Open DevTools → Sources tab → See original TypeScript code
```

### Common Debug Techniques

```typescript
// 1. Console logging
console.log('State:', state.user);

// 2. Vue DevTools (inspect component state, Pinia stores)
// Open browser → Vue DevTools panel

// 3. Network tab (inspect API requests/responses)
// DevTools → Network → Filter: XHR

// 4. Reactive debugging
import { watchEffect } from 'vue';
watchEffect(() => {
  console.log('User changed:', user.value);
});
```

---

## 📦 Component Library

### Using PrimeVue Components

```vue
<script setup lang="ts">
import Button from 'primevue/button';
import InputText from 'primevue/inputtext';
</script>

<template>
  <Button label="Click Me" @click="handleClick" />
  <InputText v-model="username" placeholder="Username" />
</template>
```

### Creating Custom Components

```vue
<!-- src/components/common/CustomButton.vue -->
<script setup lang="ts">
interface Props {
  label: string;
  variant?: 'primary' | 'secondary';
}

defineProps<Props>();
defineEmits<{
  click: [];
}>();
</script>

<template>
  <button :class="['btn', `btn-${variant}`]" @click="$emit('click')">
    {{ label }}
  </button>
</template>

<style scoped>
.btn {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}
.btn-primary {
  background: #007bff;
  color: white;
}
</style>
```

---

## 🔄 State Management (Pinia)

### Define Store

```typescript
// src/stores/user.ts
import { defineStore } from 'pinia';

export const useUserStore = defineStore('user', () => {
  const user = ref<User | null>(null);
  const isAuthenticated = computed(() => user.value !== null);

  async function login(credentials: Credentials) {
    const response = await authService.login(credentials);
    user.value = response.user;
  }

  function logout() {
    user.value = null;
  }

  return { user, isAuthenticated, login, logout };
});
```

### Use Store in Component

```vue
<script setup lang="ts">
import { useUserStore } from '@/stores/user';

const userStore = useUserStore();

async function handleLogin() {
  await userStore.login({ username: '...', password: '...' });
}
</script>

<template>
  <div v-if="userStore.isAuthenticated">
    Welcome, {{ userStore.user?.name }}!
  </div>
</template>
```

---

## 🌐 API Integration

### Configure Axios

```typescript
// src/services/api.ts
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  timeout: 10000,
});

// Request interceptor (add auth token)
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor (handle errors)
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      // Logout user
    }
    return Promise.reject(error);
  }
);

export default api;
```

### Create Service

```typescript
// src/services/user.service.ts
import api from './api';
import type { User, Credentials } from '@/types/user.types';

export const userService = {
  async login(credentials: Credentials): Promise<{ user: User; token: string }> {
    const response = await api.post('/auth/login', credentials);
    return response.data;
  },

  async getProfile(): Promise<User> {
    const response = await api.get('/users/me');
    return response.data;
  },
};
```

---

## 🔗 Related Artifacts

This section connects operational README with strategic documentation.

| Artifact | Purpose | When to Consult |
|----------|---------|------------------|
| **[FE-01-{EpicName}-Implementation-Report.md](../00-doc-ddd/06-frontend-design/FE-01-{EpicName}-Implementation-Report.md)** | Frontend implementation decisions, patterns used, component architecture | To understand **WHY** components are structured this way, patterns chosen |
| **[UXD-01-{EpicName}-Wireframes.md](../00-doc-ddd/03-ux-design/UXD-01-{EpicName}-Wireframes.md)** | Wireframes, UI/UX specifications, user flows, component library | To understand UI design, user interactions, accessibility requirements |
| **[SE-01-{EpicName}-Implementation-Report.md](../00-doc-ddd/04-tactical-design/SE-01-{EpicName}-Implementation-Report.md)** | Backend API specification, endpoints, DTOs | To understand API contracts, request/response formats |
| **[Security Baseline](../00-doc-ddd/09-security/SEC-00-Security-Baseline.md)** | Frontend security (XSS, CSRF, input validation) | To implement security best practices |

---

## 📚 References

### Internal Documentation

- **Frontend Implementation:** [00-doc-ddd/06-frontend-design/FE-01-{EpicName}-Implementation-Report.md](../00-doc-ddd/06-frontend-design/FE-01-{EpicName}-Implementation-Report.md)
- **UX Design:** [00-doc-ddd/03-ux-design/UXD-01-{EpicName}-Wireframes.md](../00-doc-ddd/03-ux-design/UXD-01-{EpicName}-Wireframes.md)
- **Security Baseline:** [00-doc-ddd/09-security/SEC-00-Security-Baseline.md](../00-doc-ddd/09-security/SEC-00-Security-Baseline.md)

### External Documentation

- **{FRAMEWORK} Documentation:** {DOCS_URL} (e.g., https://vuejs.org/)
- **TypeScript Documentation:** https://www.typescriptlang.org/docs/
- **{BUILD_TOOL} Documentation:** {BUILD_DOCS_URL} (e.g., https://vitejs.dev/)
- **{STATE_MGMT} Documentation:** {STATE_DOCS_URL} (e.g., https://pinia.vuejs.org/)
- **{UI_LIBRARY} Documentation:** {UI_DOCS_URL} (e.g., https://primevue.org/)

---

## 🛠️ Troubleshooting

### Problem: Dev server fails to start

**Symptom:** `npm run dev` fails with error  

**Solution:**  
```bash
# 1. Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# 2. Check if port 5173 is already in use
netstat -ano | findstr :5173  # Windows
lsof -i :5173                 # Linux/Mac

# 3. Try different port
npm run dev -- --port 3000
```

### Problem: Build fails with TypeScript errors

**Symptom:** `npm run build` fails with type errors  

**Solution:**  
```bash
# 1. Run type check
npm run type-check

# 2. Fix type errors in code
# 3. Ensure tsconfig.json is correct

# 4. Clear cache and rebuild
rm -rf node_modules/.vite
npm run build
```

### Problem: API requests fail with CORS error

**Symptom:** Console shows `CORS policy: No 'Access-Control-Allow-Origin' header`  

**Solution:**  
```bash
# 1. Verify API is running
curl http://localhost:5000/health

# 2. Check CORS configuration in backend
# Backend should allow origin: http://localhost:5173

# 3. Use proxy in vite.config.ts (development only)
export default defineConfig({
  server: {
    proxy: {
      '/api': 'http://localhost:5000'
    }
  }
});
```

### Problem: Components not hot-reloading

**Symptom:** Code changes not reflected in browser  

**Solution:**  
```bash
# 1. Check if dev server is running in watch mode
npm run dev

# 2. Hard refresh browser (Ctrl+Shift+R)

# 3. Check file watcher limits (Linux)
cat /proc/sys/fs/inotify/max_user_watches
sudo sysctl fs.inotify.max_user_watches=524288

# 4. Restart dev server
# Ctrl+C and npm run dev
```

### Problem: Large bundle size

**Symptom:** `npm run build` generates large dist/ files (>1MB)  

**Solution:**  
```bash
# 1. Analyze bundle
npm run build -- --mode analyze

# 2. Implement code splitting
# Use dynamic imports: const Component = () => import('./Component.vue')

# 3. Lazy load routes
const routes = [
  {
    path: '/dashboard',
    component: () => import('@/views/Dashboard.vue')
  }
];

# 4. Use PrimeVue tree-shaking
# Import only needed components, not entire library
```

---

**FE Agent** - {PROJECT_NAME} Frontend Engineering
**Last Updated:** {YYYY-MM-DD}  
**Status:** ⏳ {Status}  
