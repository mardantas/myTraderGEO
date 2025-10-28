<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)
- Use blank lines between sections for readability (content)
- Validate in Markdown preview before committing
-->

# UXD-03-Component-Library.md

**Projeto:** [PROJECT_NAME]  
**Data:** [YYYY-MM-DD]  
**Designer:** UXD Agent  

---

## 🎯 Objetivo

Definir biblioteca de componentes reutilizáveis para garantir consistência visual e funcional em todo o sistema.

---

## 🧩 Componentes Base

### 1. Buttons

**Variantes:**  

| Variante | Uso | Aparência |
|----------|-----|-----------|
| **Primary** | Ação principal | Background colorido, texto branco |
| **Secondary** | Ação secundária | Outline, sem background |
| **Danger** | Ações destrutivas | Background vermelho |
| **Ghost** | Ações terciárias | Apenas texto, sem borda |
| **Link** | Navegação | Estilo de link |

**Tamanhos:** Small, Medium, Large  
**Estados:** Default, Hover, Active, Disabled, Loading  

**Props/Atributos:**  
```typescript
{
  variant: 'primary' | 'secondary' | 'danger' | 'ghost' | 'link'
  size: 'sm' | 'md' | 'lg'
  disabled: boolean
  loading: boolean
  icon?: IconName
  onClick: () => void
}
```

---

### 2. Input Fields

**Tipos:**  
- Text input
- Number input
- Email input
- Password input
- Textarea
- Date picker
- Time picker

**Estados:**  
- Default
- Focus
- Error (com mensagem)
- Disabled
- Read-only

**Props:**  
```typescript
{
  type: 'text' | 'number' | 'email' | 'password'
  label: string
  placeholder?: string
  error?: string
  disabled?: boolean
  required?: boolean
  onChange: (value) => void
}
```

---

### 3. Select/Dropdown

**Variantes:**  
- Single select
- Multi select
- Searchable select
- Grouped options

**Props:**  
```typescript
{
  options: Array<{label: string, value: any}>
  multiple?: boolean
  searchable?: boolean
  placeholder?: string
  onChange: (value) => void
}
```

---

### 4. Cards

**Tipos:**  
- Basic card (título + conteúdo)
- Interactive card (clicável)
- Status card (com badge)
- Metric card (número + label)

**Estrutura:**  
```
+---------------------------+
| [Header com título]       |
+---------------------------+
| Conteúdo principal        |
|                           |
+---------------------------+
| [Footer com ações]        |
+---------------------------+
```

---

### 5. Tables/Data Grids

**Funcionalidades:**  
- Sorting (ordenação por coluna)
- Filtering (filtro por coluna)
- Pagination
- Row selection
- Row actions
- Responsive (card view em mobile)

**Props:**  
```typescript
{
  columns: Array<{key, label, sortable, filterable}>
  data: Array<any>
  pagination?: {pageSize, total}
  onSort?: (column, direction) => void
  onRowClick?: (row) => void
}
```

---

### 6. Modals/Dialogs

**Tipos:**  
- Confirmation dialog
- Form modal
- Info modal
- Full screen modal

**Tamanhos:** Small (400px), Medium (600px), Large (800px), Full screen  

**Props:**  
```typescript
{
  title: string
  size: 'sm' | 'md' | 'lg' | 'full'
  open: boolean
  onClose: () => void
  footer?: ReactNode
}
```

---

### 7. Alerts/Notifications

**Tipos:**  
- Success (verde)
- Warning (amarelo)
- Error (vermelho)
- Info (azul)

**Positions:** Top-right, Top-center, Bottom-right  
**Auto-dismiss:** Sim/Não (timeout configurável)  

---

### 8. Loading States

**Componentes:**  
- Spinner (circular)
- Linear progress bar
- Skeleton loader (para conteúdo)
- Overlay loading (fullscreen)

---

## 🎨 Design Tokens

### Colors

```javascript
{
  primary: {
    50: '#...',
    100: '#...',
    // ... até 900
  },
  secondary: {...},
  success: {...},
  warning: {...},
  error: {...},
  neutral: {...}
}
```

### Typography

```javascript
{
  fontFamily: {
    sans: ['Inter', 'sans-serif'],
    mono: ['Fira Code', 'monospace']
  },
  fontSize: {
    xs: '0.75rem',
    sm: '0.875rem',
    base: '1rem',
    lg: '1.125rem',
    xl: '1.25rem',
    // ...
  },
  fontWeight: {
    normal: 400,
    medium: 500,
    semibold: 600,
    bold: 700
  }
}
```

### Spacing

```javascript
{
  spacing: {
    0: '0',
    1: '0.25rem',  // 4px
    2: '0.5rem',   // 8px
    3: '0.75rem',  // 12px
    4: '1rem',     // 16px
    // ...
  }
}
```

### Borders

```javascript
{
  borderRadius: {
    none: '0',
    sm: '0.25rem',
    md: '0.375rem',
    lg: '0.5rem',
    full: '9999px'
  }
}
```

---

## 📐 Layout Components

### Grid System

**Breakpoints:**  
- xs: 0-640px
- sm: 640px-768px
- md: 768px-1024px
- lg: 1024px-1280px
- xl: 1280px+

**Columns:** 12-column grid  

---

### Containers

- Container (max-width com breakpoints)
- Fluid container (100% width)
- Section (com padding vertical)

---

## 🔄 Contextos Específicos

### [BC Name] - Componentes Customizados

**Componente:** [Nome do Componente Específico]  

**Uso:** [Quando usar]  
**Props:** [Listagem]  
**Exemplo:** [Visual ou código]  

---

## ✅ Validação

- [ ] Todos componentes base definidos
- [ ] Props/atributos documentados
- [ ] Variantes e estados especificados
- [ ] Design tokens definidos
- [ ] Grid system documentado
- [ ] Componentes contexto-específicos identificados
- [ ] Responsividade considerada
- [ ] Acessibilidade (ARIA labels, keyboard nav)
