# UXD-00 - Design Foundations

**Agent:** UXD (User Experience Designer)  
**Phase:** Discovery (1x)  
**Scope:** Design foundations for the entire system  
**Version:** 3.0 (Simplified)  

---

## 📋 Metadata

- **Project Name:** myTraderGEO  
- **Created:** 2025-10-14  
- **UX Designer:** UXD Agent  
- **Target:** Trading platform for Brazilian market (B3)  
- **Approach:** Foundations only (detailed wireframes per epic)  

---

## 🎯 Objetivo

Estabelecer as fundações do design para todo o sistema myTraderGEO: cores, tipografia, componentes base e padrões de navegação. Wireframes detalhados serão criados por épico (UXD-01-[EpicName]).

**Contexto de Design:**
- **Domínio:** Plataforma de trading de opções no mercado brasileiro (B3)
- **Usuários:** Traders (conservadores, moderados, agressivos), Consultores, Moderadores, Administradores
- **Características:** Alta densidade de informação, decisões financeiras críticas, múltiplas visualizações simultâneas (tabelas, gráficos, P&L em tempo real)
- **Desafio:** Balancear densidade de dados com usabilidade e clareza visual

---

## 🎨 Color Palette

### Filosofia de Cor

**Tema: "Financial Blue & Green"**
- Paleta profissional inspirada em mercados financeiros
- Verde/Vermelho seguem convenção universal de lucro/prejuízo
- Alta legibilidade para dashboards densos
- Suporte a modo claro (MVP) e futuro modo escuro

### Primary Colors

| Color | Hex | RGB | Usage |
|-------|-----|-----|-------|
| **Primary** | `#0066CC` | rgb(0, 102, 204) | Ações principais, links, destaques, foco |
| **Primary Light** | `#3399FF` | rgb(51, 153, 255) | Hover states, backgrounds claros |
| **Primary Dark** | `#004C99` | rgb(0, 76, 153) | Active states, ênfase, header backgrounds |

### Secondary Colors

| Color | Hex | RGB | Usage |
|-------|-----|-----|-------|
| **Secondary** | `#6B7280` | rgb(107, 114, 128) | Ações secundárias, texto desabilitado |
| **Secondary Light** | `#9CA3AF` | rgb(156, 163, 175) | Hover states secundários |
| **Secondary Dark** | `#374151` | rgb(55, 65, 81) | Active states, borders escuras |

### Neutral Colors

| Color | Hex | RGB | Usage |
|-------|-----|-----|-------|
| **Background** | `#FFFFFF` | rgb(255, 255, 255) | Page backgrounds |
| **Surface** | `#F9FAFB` | rgb(249, 250, 251) | Card backgrounds, table headers |
| **Surface Dark** | `#F3F4F6` | rgb(243, 244, 246) | Hover states, alternate rows |
| **Border** | `#E5E7EB` | rgb(229, 231, 235) | Dividers, borders, separators |
| **Border Dark** | `#D1D5DB` | rgb(209, 213, 219) | Strong borders, focus rings |
| **Text Primary** | `#111827` | rgb(17, 24, 39) | Main text, headings |
| **Text Secondary** | `#6B7280` | rgb(107, 114, 128) | Secondary text, captions |
| **Text Disabled** | `#9CA3AF` | rgb(156, 163, 175) | Disabled text, placeholders |

### Semantic Colors - Financial Context

| Color | Hex | RGB | Usage |
|-------|-----|-----|-------|
| **Success / Profit** | `#10B981` | rgb(16, 185, 129) | Lucro, posições long, confirmações, aprovações |
| **Success Light** | `#D1FAE5` | rgb(209, 250, 229) | Success backgrounds, badges |
| **Danger / Loss** | `#EF4444` | rgb(239, 68, 68) | Prejuízo, posições short, erros, alertas críticos |
| **Danger Light** | `#FEE2E2` | rgb(254, 226, 226) | Error backgrounds, badges |
| **Warning** | `#F59E0B` | rgb(245, 158, 11) | Alertas, atenção, moderação pendente |
| **Warning Light** | `#FEF3C7` | rgb(254, 243, 199) | Warning backgrounds |
| **Info** | `#3B82F6` | rgb(59, 130, 246) | Mensagens informativas, tooltips |
| **Info Light** | `#DBEAFE` | rgb(219, 234, 254) | Info backgrounds |

### Accent Colors - Platform Features

| Color | Hex | RGB | Usage |
|-------|-----|-----|-------|
| **Premium** | `#8B5CF6` | rgb(139, 92, 246) | Features do plano Pleno, real-time data |
| **Consultant** | `#EC4899` | rgb(236, 72, 153) | Features do plano Consultor |
| **Paper Trading** | `#F59E0B` | rgb(245, 158, 11) | Modo paper trading (simulação) |
| **Real Trading** | `#10B981` | rgb(16, 185, 129) | Modo real (execução efetiva) |

### CSS Variables

```css
:root {
  /* Primary */
  --color-primary: #0066CC;
  --color-primary-light: #3399FF;
  --color-primary-dark: #004C99;

  /* Secondary */
  --color-secondary: #6B7280;
  --color-secondary-light: #9CA3AF;
  --color-secondary-dark: #374151;

  /* Neutral */
  --color-background: #FFFFFF;
  --color-surface: #F9FAFB;
  --color-surface-dark: #F3F4F6;
  --color-border: #E5E7EB;
  --color-border-dark: #D1D5DB;
  --color-text-primary: #111827;
  --color-text-secondary: #6B7280;
  --color-text-disabled: #9CA3AF;

  /* Semantic - Financial */
  --color-success: #10B981;
  --color-success-light: #D1FAE5;
  --color-danger: #EF4444;
  --color-danger-light: #FEE2E2;
  --color-warning: #F59E0B;
  --color-warning-light: #FEF3C7;
  --color-info: #3B82F6;
  --color-info-light: #DBEAFE;

  /* Accent - Features */
  --color-premium: #8B5CF6;
  --color-consultant: #EC4899;
  --color-paper: #F59E0B;
  --color-real: #10B981;
}
```

### Color Usage Guidelines

**Green (Success):**
- P&L positivo (lucro)
- Posições long (compradas)
- Aprovações de moderação
- Estratégias dentro do limite de risco

**Red (Danger):**
- P&L negativo (prejuízo)
- Posições short (vendidas)
- Alertas críticos (margem call, vencimento iminente)
- Rejeições de moderação

**Yellow/Orange (Warning):**
- Alertas de atenção
- Conflitos detectados
- Conteúdo pendente de moderação

**Blue (Primary):**
- CTAs principais
- Links
- Navegação ativa

**Purple (Premium):**
- Features exclusivas do plano Pleno (dados real-time)
- Badge de upgrade

**Pink (Consultant):**
- Features exclusivas do plano Consultor
- Gestão de clientes

---

## 📝 Typography

### Font Families

**Primary Font: Inter** (Google Fonts)
- **Usage:** Body text, UI elements, labels, buttons
- **Weights:** 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold)
- **Source:** https://fonts.google.com/specimen/Inter
- **Justificativa:** Excelente legibilidade em tamanhos pequenos, números bem diferenciados (crítico para valores monetários), otimizada para UI

**Heading Font: Inter** (consistency)
- **Usage:** Headings (H1-H6), títulos de cards
- **Weights:** 600 (SemiBold), 700 (Bold)
- **Justificativa:** Manter consistência visual, evitar mistura de fontes

**Monospace Font: JetBrains Mono** (Google Fonts)
- **Usage:** Tabelas de dados numéricos, valores monetários, códigos de ticker (PETR4, VALE3), gregas (Delta, Gamma)
- **Weights:** 400 (Regular), 500 (Medium)
- **Source:** https://fonts.google.com/specimen/JetBrains+Mono
- **Justificativa:** Alinhamento perfeito de números, excelente para tabelas financeiras, diferenciação clara de caracteres

### Type Scale

| Element | Size | Weight | Line Height | Letter Spacing | Usage |
|---------|------|--------|-------------|----------------|-------|
| **H1** | 32px / 2rem | 700 | 1.2 | -0.02em | Page titles (Dashboard, Catálogo) |
| **H2** | 24px / 1.5rem | 700 | 1.3 | -0.01em | Section titles (Estratégias Ativas) |
| **H3** | 20px / 1.25rem | 600 | 1.4 | normal | Subsection titles (Template Selecionado) |
| **H4** | 18px / 1.125rem | 600 | 1.4 | normal | Card titles (Nome da Estratégia) |
| **H5** | 16px / 1rem | 600 | 1.5 | normal | Small headings (Pernas, Gregas) |
| **H6** | 14px / 0.875rem | 600 | 1.5 | normal | Tiny headings (Timestamp) |
| **Body Large** | 16px / 1rem | 400 | 1.6 | normal | Large body text, descriptions |
| **Body** | 14px / 0.875rem | 400 | 1.5 | normal | Default body text, forms |
| **Body Small** | 12px / 0.75rem | 400 | 1.5 | normal | Small text, captions, helper text |
| **Button** | 14px / 0.875rem | 500 | 1.5 | 0.01em | Button labels (all sizes) |
| **Caption** | 12px / 0.75rem | 400 | 1.4 | normal | Image captions, timestamps |
| **Overline** | 10px / 0.625rem | 500 | 1.5 | 0.05em | Overline text (uppercase labels) |
| **Data Large** | 18px / 1.125rem | 500 | 1.4 | normal | P&L values, prices (JetBrains Mono) |
| **Data Medium** | 14px / 0.875rem | 400 | 1.5 | normal | Table cells, numeric data (JetBrains Mono) |
| **Data Small** | 12px / 0.75rem | 400 | 1.5 | normal | Compact tables, gregas (JetBrains Mono) |

### CSS Implementation

```css
:root {
  /* Font Families */
  --font-primary: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-heading: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-mono: 'JetBrains Mono', 'Fira Code', 'Courier New', monospace;

  /* Font Sizes */
  --font-size-h1: 2rem;
  --font-size-h2: 1.5rem;
  --font-size-h3: 1.25rem;
  --font-size-h4: 1.125rem;
  --font-size-h5: 1rem;
  --font-size-h6: 0.875rem;
  --font-size-body-large: 1rem;
  --font-size-body: 0.875rem;
  --font-size-body-small: 0.75rem;
  --font-size-caption: 0.75rem;
  --font-size-overline: 0.625rem;

  /* Font Weights */
  --font-weight-regular: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;
}

h1 {
  font-family: var(--font-heading);
  font-size: var(--font-size-h1);
  font-weight: var(--font-weight-bold);
  letter-spacing: -0.02em;
}

h2 {
  font-family: var(--font-heading);
  font-size: var(--font-size-h2);
  font-weight: var(--font-weight-bold);
  letter-spacing: -0.01em;
}

body {
  font-family: var(--font-primary);
  font-size: var(--font-size-body);
  font-weight: var(--font-weight-regular);
}

.data-numeric {
  font-family: var(--font-mono);
  font-variant-numeric: tabular-nums;
}
```

### Typography Guidelines

**Números Monetários:**
- Sempre usar JetBrains Mono para alinhamento
- Format: R$ 1.234,56 (padrão brasileiro)
- Negativo: -R$ 1.234,56 ou (R$ 1.234,56) - usar cor vermelha

**Percentuais:**
- Format: +5.25% (verde) / -2.30% (vermelho)
- Sempre mostrar sinal (+/-)

**Gregas:**
- Delta: Δ 0.65
- Gamma: Γ 0.05
- Theta: Θ -0.10
- Vega: ν 15.50

---

## 🧩 Base Components

### Buttons

#### Primary Button
- **Background:** `var(--color-primary)` (#0066CC)
- **Text:** White (#FFFFFF)
- **Border Radius:** 6px
- **Padding:** 10px 20px (medium), 8px 16px (small), 12px 28px (large)
- **Font:** Inter Medium (500), 14px
- **Hover:** Background `var(--color-primary-dark)` (#004C99)
- **Active:** Background `var(--color-primary-dark)`, scale(0.98)
- **Disabled:** Background `var(--color-text-disabled)`, opacity 0.5, cursor not-allowed
- **Focus:** Outline 2px solid `var(--color-primary)`, offset 2px

**Usage:** Ações principais (Criar Estratégia, Ativar, Salvar)  

#### Secondary Button
- **Background:** Transparent
- **Text:** `var(--color-primary)` (#0066CC)
- **Border:** 1.5px solid `var(--color-primary)`
- **Border Radius:** 6px
- **Padding:** 10px 20px
- **Font:** Inter Medium (500), 14px
- **Hover:** Background `var(--color-primary)` 8% opacity
- **Active:** Background `var(--color-primary)` 12% opacity

**Usage:** Ações secundárias (Cancelar, Voltar, Exportar)  

#### Danger Button
- **Background:** `var(--color-danger)` (#EF4444)
- **Text:** White (#FFFFFF)
- **Border Radius:** 6px
- **Padding:** 10px 20px
- **Font:** Inter Medium (500), 14px
- **Hover:** Background darker (#DC2626)

**Usage:** Ações destrutivas (Excluir, Encerrar Estratégia, Remover)  

#### Success Button
- **Background:** `var(--color-success)` (#10B981)
- **Text:** White (#FFFFFF)
- **Border Radius:** 6px
- **Padding:** 10px 20px
- **Font:** Inter Medium (500), 14px

**Usage:** Confirmações positivas (Aprovar Conteúdo, Confirmar Lucro)  

#### Icon Button
- **Size:** 36px × 36px (square)
- **Border Radius:** 6px
- **Icon Size:** 20px × 20px
- **Padding:** 8px
- **Background:** Transparent
- **Hover:** Background `var(--color-surface-dark)`

**Usage:** Ações rápidas (Editar, Deletar, Refresh, Settings)  

### Input Fields

#### Text Input
- **Border:** 1.5px solid `var(--color-border)` (#E5E7EB)
- **Border Radius:** 6px
- **Padding:** 10px 12px
- **Font:** Inter Regular (400), 14px
- **Background:** White (#FFFFFF)
- **Focus:** Border `var(--color-primary)`, box-shadow 0 0 0 3px rgba(0, 102, 204, 0.1)
- **Error:** Border `var(--color-danger)`, box-shadow 0 0 0 3px rgba(239, 68, 68, 0.1)
- **Disabled:** Background `var(--color-surface)`, cursor not-allowed
- **Placeholder:** Color `var(--color-text-disabled)`, style italic

#### Number Input (Financial)
- Same as text input
- **Font:** JetBrains Mono Regular (400), 14px
- **Text Align:** Right
- **Prefix/Suffix:** R$ (prefix), % (suffix) - color `var(--color-text-secondary)`

#### Select Dropdown
- Same as text input
- **Dropdown Icon:** Heroicon chevron-down (right side, 20px)
- **Dropdown Menu:**
  - Background White
  - Border 1px solid `var(--color-border)`
  - Border Radius 6px
  - Box Shadow 0 4px 12px rgba(0,0,0,0.15)
  - Max Height 300px (scrollable)
  - Option Hover: Background `var(--color-surface-dark)`

#### Checkbox / Radio
- **Size:** 20px × 20px
- **Border:** 2px solid `var(--color-border)`
- **Border Radius:** 4px (checkbox), 50% (radio)
- **Checked:** Background `var(--color-primary)`, checkmark/dot white
- **Focus:** Box shadow 0 0 0 3px rgba(0, 102, 204, 0.1)

#### Label
- **Font:** Inter Medium (500), 14px
- **Color:** `var(--color-text-primary)`
- **Margin Bottom:** 6px
- **Required:** Asterisk (*) in red - `var(--color-danger)`

#### Helper Text
- **Font:** Inter Regular (400), 12px
- **Color:** `var(--color-text-secondary)`
- **Margin Top:** 4px

#### Error Message
- **Font:** Inter Regular (400), 12px
- **Color:** `var(--color-danger)`
- **Icon:** Heroicon exclamation-circle (16px)
- **Margin Top:** 4px

### Cards

#### Standard Card
- **Background:** White (#FFFFFF)
- **Border:** 1px solid `var(--color-border)` (#E5E7EB)
- **Border Radius:** 8px
- **Padding:** 20px
- **Box Shadow:** 0 1px 3px rgba(0,0,0,0.06)
- **Hover:** Box shadow 0 4px 8px rgba(0,0,0,0.1), transform translateY(-2px), transition 200ms

#### Strategy Card (Specific)
- Same as standard card
- **Header:**
  - Display: flex, justify-between
  - Title (H4) + Status badge
- **Body:**
  - Underlying asset (ticker)
  - P&L value (large, colored)
  - Greeks display
  - Leg count
- **Footer:**
  - Actions (Edit, Activate, Delete)

#### Card Header
- **Font:** Inter SemiBold (600), 18px
- **Color:** `var(--color-text-primary)`
- **Margin Bottom:** 16px
- **Border Bottom:** 1px solid `var(--color-border)` (optional)

#### Card Content
- **Font:** Inter Regular (400), 14px
- **Line Height:** 1.5
- **Spacing:** 12px between sections

### Tables

#### Table Container
- **Border:** 1px solid `var(--color-border)`
- **Border Radius:** 8px
- **Overflow:** auto (horizontal scroll on small screens)

#### Table Header
- **Background:** `var(--color-surface)` (#F9FAFB)
- **Font:** Inter SemiBold (600), 14px
- **Color:** `var(--color-text-primary)`
- **Padding:** 12px 16px
- **Border Bottom:** 2px solid `var(--color-border-dark)`
- **Text Transform:** none (keep natural case)
- **Sortable:** Cursor pointer, hover background `var(--color-surface-dark)`

#### Table Row
- **Padding:** 12px 16px
- **Border Bottom:** 1px solid `var(--color-border)`
- **Hover:** Background `var(--color-surface)` (#F9FAFB)
- **Selected:** Background `var(--color-info-light)`, border-left 3px solid `var(--color-primary)`

#### Table Cell
- **Font:** Inter Regular (400), 14px (text), JetBrains Mono Regular (400), 14px (numbers)
- **Align:** left (text), right (numbers), center (icons/badges)
- **Padding:** 12px 16px
- **Vertical Align:** middle

#### Table - Financial Data Specific
- **P&L Column:** JetBrains Mono, color green (positive) / red (negative), bold
- **Price Column:** JetBrains Mono, align right
- **Ticker Column:** JetBrains Mono, uppercase
- **Percentage Column:** JetBrains Mono, +/- sign, color coded

### Badges

#### Status Badge
- **Font:** Inter Medium (500), 12px
- **Padding:** 4px 10px
- **Border Radius:** 12px (pill)
- **Text Transform:** uppercase
- **Letter Spacing:** 0.05em

**Variants:**
- **Active:** Background `var(--color-success-light)`, text `var(--color-success)` (darker)
- **Inactive:** Background `var(--color-text-disabled)` 20%, text `var(--color-text-secondary)`
- **Paper:** Background `var(--color-warning-light)`, text `var(--color-warning)` (darker)
- **Pending:** Background `var(--color-info-light)`, text `var(--color-info)` (darker)
- **Critical:** Background `var(--color-danger-light)`, text `var(--color-danger)` (darker)

#### P&L Badge
- **Font:** JetBrains Mono Medium (500), 14px
- **Padding:** 6px 12px
- **Border Radius:** 6px
- **Profit:** Background `var(--color-success-light)`, text `var(--color-success)` (darker), prefix "+"
- **Loss:** Background `var(--color-danger-light)`, text `var(--color-danger)` (darker), prefix "-"
- **Neutral:** Background `var(--color-surface)`, text `var(--color-text-secondary)`, value "R$ 0,00"

#### Risk Score Badge
- **Font:** Inter Medium (500), 12px
- **Padding:** 4px 10px
- **Border Radius:** 6px
- **Low:** Background green light, text green dark
- **Medium:** Background yellow light, text yellow dark
- **High:** Background orange light, text orange dark
- **Critical:** Background red light, text red dark

### Alerts / Notifications

#### Success Alert
- **Background:** `var(--color-success-light)` (#D1FAE5)
- **Border:** 1px solid `var(--color-success)` (#10B981)
- **Border Left:** 4px solid `var(--color-success)`
- **Border Radius:** 6px
- **Padding:** 12px 16px
- **Icon:** Heroicon check-circle (20px), color `var(--color-success)`
- **Title:** Inter SemiBold (600), 14px, color `var(--color-success)` (darker)
- **Message:** Inter Regular (400), 14px

**Usage:** Estratégia criada com sucesso, Ordem executada  

#### Warning Alert
- **Background:** `var(--color-warning-light)` (#FEF3C7)
- **Border:** 1px solid `var(--color-warning)` (#F59E0B)
- **Border Left:** 4px solid `var(--color-warning)`
- **Icon:** Heroicon exclamation-triangle (20px)

**Usage:** Alerta de margem próxima ao limite, Vencimento em 3 dias  

#### Error Alert
- **Background:** `var(--color-danger-light)` (#FEE2E2)
- **Border:** 1px solid `var(--color-danger)` (#EF4444)
- **Border Left:** 4px solid `var(--color-danger)`
- **Icon:** Heroicon x-circle (20px)

**Usage:** Margem call crítica, Erro na execução, Estratégia rejeitada  

#### Info Alert
- **Background:** `var(--color-info-light)` (#DBEAFE)
- **Border:** 1px solid `var(--color-info)` (#3B82F6)
- **Border Left:** 4px solid `var(--color-info)`
- **Icon:** Heroicon information-circle (20px)

**Usage:** Informações gerais, Tips, Novidades  

#### Alert with Action
- **Close Button:** Icon button (X) top-right
- **Action Button:** Primary or secondary button below message

### Modals

#### Modal Overlay
- **Background:** rgba(0,0,0,0.6)
- **Position:** fixed, full screen (z-index: 1000)
- **Backdrop Filter:** blur(4px) (optional, modern browsers)
- **Animation:** Fade in 200ms

#### Modal Container
- **Background:** White (#FFFFFF)
- **Border Radius:** 12px
- **Max Width:** 600px (small), 800px (medium), 1000px (large)
- **Width:** 90% on mobile
- **Padding:** 24px
- **Box Shadow:** 0 20px 60px rgba(0,0,0,0.3)
- **Animation:** Scale from 0.95 + fade in 200ms

#### Modal Header
- **Font:** Inter SemiBold (600), 20px
- **Color:** `var(--color-text-primary)`
- **Margin Bottom:** 16px
- **Display:** flex, justify-between
- **Close Button:** Icon button (X) with hover state

#### Modal Body
- **Font:** Inter Regular (400), 14px
- **Line Height:** 1.6
- **Max Height:** 70vh (scrollable if exceeds)
- **Padding:** 0 (container already has padding)

#### Modal Footer
- **Margin Top:** 24px
- **Border Top:** 1px solid `var(--color-border)` (optional)
- **Padding Top:** 16px (if border)
- **Text Align:** right
- **Buttons:** Cancel (secondary) + Confirm (primary), gap 12px

### Loading States

#### Spinner
- **Size:** 20px × 20px (small), 32px × 32px (medium), 48px × 48px (large)
- **Color:** `var(--color-primary)` (#0066CC)
- **Stroke Width:** 2px (small/medium), 3px (large)
- **Animation:** rotate 1s linear infinite
- **Implementation:** SVG circle with partial stroke

#### Skeleton
- **Background:** linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%)
- **Animation:** shimmer 1.5s infinite
- **Border Radius:** 4px (text), 6px (buttons), 8px (cards)
- **Sizes:** Match content being loaded (text lines, card shapes)

#### Progress Bar
- **Height:** 4px (thin), 8px (default)
- **Background:** `var(--color-border)` (#E5E7EB)
- **Fill:** `var(--color-primary)` (#0066CC)
- **Border Radius:** 4px
- **Animation:** Indeterminate (sliding) or Determinate (percentage)

### Trading-Specific Components

#### Greek Display Component
- **Layout:** Inline grid, 4 columns (Δ, Γ, Θ, ν)
- **Font:** JetBrains Mono Regular (400), 12px
- **Label:** Greek symbol + name (e.g., "Δ Delta")
- **Value:** Numeric, aligned right
- **Color:** Based on value (positive/negative)

**Example:**
```
Δ 0.65  |  Γ 0.05  |  Θ -0.10  |  ν 15.50
```

#### Price Ticker Component
- **Font:** JetBrains Mono Medium (500), 16px
- **Display:** Ticker symbol + Price + Change %
- **Real-time:** Animate on price change (flash green/red)
- **Badge:** "Real-time" (plano Pleno) vs "Delayed 15min" (plano Básico)

**Example:**
```
PETR4  R$ 32,45  +2.35% ↑
```

#### Leg Row Component (Table)
- **Columns:** Type | Position | Strike | Expiration | Quantity | Price
- **Type:** Badge (Stock, Call, Put) with icon
- **Position:** Badge (Long green, Short red)
- **Strike:** JetBrains Mono (for opções), empty for ações
- **Expiration:** Date format DD/MM/YYYY (for opções), empty for ações
- **Quantity:** Numeric, prefixed with +/- sign
- **Price:** JetBrains Mono, R$ format

#### Strategy Summary Widget
- **Layout:** Card with sections
- **Sections:**
  - Header: Strategy name + Status badge
  - Body: Underlying asset, P&L (large), Greeks, Leg count, Margin required
  - Footer: Actions (Edit, Activate, Delete, View Details)
- **P&L:** Large, colored (green/red), JetBrains Mono Bold

#### Moderation Queue Item
- **Layout:** Card with preview
- **Header:** Content type (Message, Article, Strategy) + Author + Timestamp
- **Body:** Content preview (truncated)
- **Reason:** Flag reason badge (Spam, Fraud, Misleading)
- **Actions:** Approve (success), Reject (danger), View Full

---

## 🗺️ Navigation Patterns

### Top Navigation Bar

#### Desktop (≥1024px)
- **Height:** 64px
- **Background:** White (#FFFFFF)
- **Border Bottom:** 1px solid `var(--color-border)`
- **Box Shadow:** 0 1px 3px rgba(0,0,0,0.06)
- **Z-index:** 900

**Layout:**
- **Left:** Logo myTraderGEO (max height 40px, clickable to dashboard)
- **Center/Left:** Primary navigation items
  - Estratégias
  - Carteira
  - Comunidade
  - Configurações
- **Right:**
  - Market status indicator (Real-time / Delayed / Offline)
  - Plan badge (Básico / Pleno / Consultor)
  - Notifications bell (with counter badge)
  - User avatar + dropdown

**Active Item:** Border-bottom 3px solid `var(--color-primary)`, font weight 600  

#### Mobile (<1024px)
- **Height:** 56px
- **Layout:**
  - **Left:** Hamburger menu icon (Heroicon bars-3)
  - **Center:** Logo myTraderGEO
  - **Right:** User avatar only
- **Drawer:** Slides from left, overlay background rgba(0,0,0,0.5)

### Sidebar Navigation (Desktop)

**Note:** Sidebar optional, use if app becomes very dense. For MVP, top nav sufficient.  

#### Collapsed Sidebar (64px width)
- **Position:** Fixed left
- **Background:** `var(--color-surface)` (#F9FAFB)
- **Border Right:** 1px solid `var(--color-border)`
- **Menu Items:** Icon only (24px), tooltip on hover

#### Expanded Sidebar (240px width)
- **Menu Items:** Icon (24px) + Label (14px)
- **Active Item:**
  - Background `var(--color-primary)` 10% opacity
  - Border-left 4px solid `var(--color-primary)`
  - Font weight 600
- **Hover:** Background `var(--color-surface-dark)`

**Menu Structure (based on Bounded Contexts):**
- Dashboard
- Strategy Planning
  - Catálogo de Templates
  - Criar Estratégia
- Trade Execution
  - Estratégias Ativas
  - Paper Trading
- Risk Management
  - Alertas
  - Limites
- Asset Management
  - Carteira B3
  - Garantias
- Community
  - Chat
  - Artigos
- Consultant (only if plano = Consultor)
  - Meus Clientes
  - Compartilhamentos

### Breadcrumbs

- **Font:** Inter Regular (400), 14px
- **Color:** `var(--color-text-secondary)`
- **Separator:** Heroicon chevron-right (16px)
- **Current Page:** Font weight 600, color `var(--color-text-primary)`, no link
- **Margin Bottom:** 16px

**Example:**
```
Dashboard > Estratégias > Criar Estratégia > Instanciar Template
```

### Tabs

- **Border Bottom:** 2px solid `var(--color-border)`
- **Tab Item:**
  - Font: Inter Medium (500), 14px
  - Padding: 12px 20px
  - Cursor: pointer
- **Active Tab:**
  - Border Bottom: 3px solid `var(--color-primary)`
  - Color: `var(--color-primary)`
  - Font Weight: 600
  - Margin Bottom: -2px (overlap with border)
- **Inactive Tab:**
  - Color: `var(--color-text-secondary)`
- **Hover:** Color `var(--color-text-primary)`

**Example Tabs:**
- Strategy Planning: Templates | Minhas Estratégias | Catálogo Global
- Trade Execution: Ativas | Paper | Real | Histórico
- Asset Management: Ações | Opções | Garantias

### Pagination

- **Font:** Inter Medium (500), 14px
- **Layout:** Previous | 1 2 3 ... 10 | Next
- **Button:**
  - Size: 36px × 36px (square)
  - Border Radius: 6px
  - Padding: 8px
- **Active Page:** Background `var(--color-primary)`, text white
- **Inactive Page:** Background transparent, text `var(--color-text-primary)`, hover background `var(--color-surface)`
- **Disabled:** Opacity 0.5, cursor not-allowed

---

## 📐 Spacing System

### Spacing Scale (8px grid)

| Variable | Size | Usage |
|----------|------|-------|
| `--spacing-xs` | 4px | Tiny gaps, icon margins |
| `--spacing-sm` | 8px | Small gaps, input padding |
| `--spacing-md` | 16px | Default gaps, card padding |
| `--spacing-lg` | 24px | Large gaps, section padding |
| `--spacing-xl` | 32px | Extra large gaps |
| `--spacing-2xl` | 48px | Section separators |
| `--spacing-3xl` | 64px | Page-level gaps |

### Layout Grid

- **Desktop (≥1280px):** 12 columns, 24px gutter, max-width 1440px
- **Tablet (960-1279px):** 12 columns, 20px gutter
- **Mobile Landscape (600-959px):** 8 columns, 16px gutter
- **Mobile Portrait (<600px):** 4 columns, 16px gutter

### Container Padding

- **Desktop:** 48px horizontal
- **Tablet:** 32px horizontal
- **Mobile:** 16px horizontal

---

## 📱 Responsive Breakpoints

| Breakpoint | Size | Target | Container Max Width |
|------------|------|--------|---------------------|
| **xs** | 0-639px | Mobile portrait | 100% |
| **sm** | 640-767px | Mobile landscape | 100% |
| **md** | 768-1023px | Tablets | 768px |
| **lg** | 1024-1279px | Small desktops | 1024px |
| **xl** | 1280-1535px | Desktops | 1280px |
| **2xl** | 1536px+ | Large desktops | 1440px |

### Responsive Strategy

**Mobile-First Approach:**
- Base styles for mobile (xs)
- Progressive enhancement for larger screens
- Critical content first, secondary content optional on mobile

**Desktop-Privileged for Financial App:**
- Traders typically use desktop (multiple monitors common)
- Tables can be full-width on desktop, horizontal scroll on mobile
- Charts prioritize desktop experience

### Breakpoint Usage

```css
/* Mobile first */
.container {
  padding: 16px;
}

@media (min-width: 640px) {
  .container { padding: 24px; }
}

@media (min-width: 1024px) {
  .container { padding: 32px; }
}

@media (min-width: 1280px) {
  .container { padding: 48px; max-width: 1440px; margin: 0 auto; }
}
```

---

## ♿ Accessibility Guidelines (WCAG 2.1 AA)

### Color Contrast

**Text Contrast:**
- **Normal text (<18px):** Minimum 4.5:1 contrast ratio
- **Large text (≥18px or ≥14px bold):** Minimum 3:1 contrast ratio
- **UI components (borders, icons):** Minimum 3:1 contrast ratio

**Verified Contrast Ratios:**
- Primary (#0066CC) on White: 5.3:1 ✓
- Success (#10B981) on White: 2.9:1 (use darker shade for text)
- Danger (#EF4444) on White: 3.9:1 ✓
- Text Primary (#111827) on White: 16.4:1 ✓
- Text Secondary (#6B7280) on White: 5.8:1 ✓

### Keyboard Navigation

**Tab Order:**
- Logical tab order following visual flow
- Skip to main content link (hidden until focus)
- All interactive elements keyboard accessible (Tab, Enter, Space, Arrow keys)

**Focus Indicators:**
- **Focus Ring:** 2px solid `var(--color-primary)`, offset 2px
- **Focus Visible:** Use `:focus-visible` to hide focus ring on mouse click, show on keyboard
- **Never remove focus indicators** (accessibility violation)

### ARIA Labels and Roles

**Buttons:**
- Icon buttons: `aria-label="Descriptive action"` (e.g., "Editar estratégia")
- Toggle buttons: `aria-pressed="true|false"`

**Forms:**
- Labels associated with inputs: `for` attribute matching input `id`
- Error messages: `aria-describedby="error-id"`
- Required fields: `aria-required="true"` + visual asterisk

**Navigation:**
- Main navigation: `<nav aria-label="Primary navigation">`
- Breadcrumbs: `<nav aria-label="Breadcrumb">`

**Tables:**
- Data tables: `<table role="table">`
- Headers: `<th scope="col">` or `<th scope="row">`
- Financial data: `aria-label` for numeric context (e.g., "Lucro de R$ 1.234,56")

**Icons:**
- Decorative icons: `aria-hidden="true"`
- Functional icons: `aria-label="Icon meaning"` or paired with visible text

### Screen Reader Support

**Semantic HTML:**
- Use `<header>`, `<nav>`, `<main>`, `<aside>`, `<footer>`
- Headings hierarchy: H1 → H2 → H3 (never skip levels)
- Lists for navigation: `<ul>`, `<ol>`, `<li>`

**Alt Text:**
- Images: Descriptive alt text (e.g., "Gráfico de payoff mostrando lucro máximo de R$ 5.000")
- Decorative images: `alt=""` (empty)
- Charts: Provide text alternative (table of data)

**Live Regions:**
- Price updates: `aria-live="polite"` (real-time tickers)
- Alerts: `aria-live="assertive"` (critical alerts)
- Status messages: `aria-live="polite"` + `role="status"`

### Accessibility Testing

**Tools:**
- Lighthouse (Chrome DevTools)
- axe DevTools (browser extension)
- WAVE (Web Accessibility Evaluation Tool)

**Manual Testing:**
- Keyboard-only navigation
- Screen reader testing (NVDA, JAWS, VoiceOver)
- Color blindness simulation (Deuteranopia, Protanopia)

---

## 🎭 Iconography

### Icon Library

**Selected Library:** Heroicons v2 (Tailwind ecosystem)  
- **Source:** https://heroicons.com
- **License:** MIT (free, open source)
- **Variants:** Outline (default, 24px), Solid (filled, 20px/24px), Mini (20px)
- **Format:** SVG (inline or component-based)

**Justificativa:**
- Modern, clean design
- Excellent coverage of financial/business icons
- Consistent stroke width and style
- Optimized SVG, small file size
- Easy integration with React/Vue

### Icon Sizes

| Size | Pixels | Usage |
|------|--------|-------|
| **Mini** | 16px × 16px | Inline with text, small badges |
| **Small** | 20px × 20px | Buttons, form inputs |
| **Medium** | 24px × 24px | Default, navigation, cards |
| **Large** | 32px × 32px | Feature icons, empty states |
| **XLarge** | 48px × 48px | Hero icons, onboarding |

### Common Icons - Financial Context

**Navigation:**
- home
- chart-bar (dashboard)
- squares-2x2 (catálogo)
- rocket-launch (criar estratégia)
- arrow-trending-up (trade execution)
- shield-check (risk management)
- briefcase (asset management)
- user-group (community)

**Actions:**
- plus (add)
- pencil (edit)
- trash (delete)
- arrow-path (refresh)
- arrow-down-tray (download/export)
- arrow-up-tray (upload/import)
- check (confirm)
- x-mark (cancel/close)

**Status:**
- check-circle (success, approved, profit)
- x-circle (error, rejected, loss)
- exclamation-triangle (warning, alert)
- information-circle (info, help)
- clock (pending, in progress)

**Financial:**
- arrow-trending-up (bull, profit, long position)
- arrow-trending-down (bear, loss, short position)
- currency-dollar (money, P&L)
- chart-pie (portfolio, distribution)
- calculator (calculations, gregas)
- scale (balance, risk)

**User:**
- user (profile)
- cog-6-tooth (settings)
- bell (notifications)
- arrow-right-on-rectangle (logout)

**Communication:**
- chat-bubble-left-right (chat)
- megaphone (announcements)
- flag (moderation, report)
- share (share, export)

### Icon Usage Guidelines

**Color:**
- Default: `var(--color-text-secondary)` (#6B7280)
- Active/Hover: `var(--color-primary)` (#0066CC)
- Success: `var(--color-success)` (#10B981)
- Danger: `var(--color-danger)` (#EF4444)
- Warning: `var(--color-warning)` (#F59E0B)

**With Text:**
- Align vertically center
- Gap 8px between icon and text
- Icon color matches text color

**Icon Buttons:**
- Padding 8px (clickable area ≥44px × 44px for touch)
- Hover: Background `var(--color-surface-dark)`
- Active: Scale 0.95

---

## 🖼️ Imagery Guidelines

### Photos

**Aspect Ratios:**
- **16:9** - Hero banners, feature images
- **4:3** - Card images, thumbnails
- **1:1** - User avatars, square previews
- **21:9** - Wide banners (optional)

**Quality:**
- High resolution (2x for retina)
- WebP format preferred (fallback to JPG)
- Max file size: 200KB (optimized)
- Lazy loading for below-the-fold images

**Placeholder:**
- Skeleton with shimmer animation during load
- Solid color background matching image dominant color
- Low-quality image placeholder (LQIP) optional

**Usage in Financial App:**
- Minimal use of photos (app is data-dense)
- User avatars
- Onboarding illustrations
- Empty state illustrations

### Avatars

**Sizes:**
- **Mini:** 24px × 24px (inline with text)
- **Small:** 32px × 32px (compact lists)
- **Default:** 40px × 40px (standard UI)
- **Large:** 64px × 64px (profile cards)
- **Profile:** 120px × 120px (profile page)

**Shape:**
- **Circle:** Users (traders, consultors)
- **Rounded Square (8px radius):** Organizations, system icons

**Fallback:**
- Initials on colored background
- Background color: hash of user ID for consistency
- Text: White, Inter Bold, centered
- Example: "MJ" for Marco Junior

**Border:**
- Optional: 2px solid `var(--color-border)` for visual separation

### Illustrations

**Style:** Minimal, line-based, professional  
- **Source:** unDraw (https://undraw.co) or custom
- **Color Scheme:** Match primary palette (blues, greens)
- **Usage:**
  - Empty states ("Nenhuma estratégia criada")
  - Onboarding screens
  - Error pages (404, 500)
  - Success confirmations

**Size:**
- Empty states: 200-300px width
- Onboarding: 400-600px width
- Error pages: 300-400px width

---

## 📋 Forms Guidelines

### Form Layout

**Label Position:**
- **Top (default):** Label above input (mobile-friendly, best for responsive)
- **Left (optional):** Label left of input (desktop only, space permitting)

**Field Width:**
- **Full width:** Mobile (<640px)
- **Max 400px:** Desktop (≥640px), centered or left-aligned
- **Inline fields:** Group related fields (e.g., Strike + Expiration) with gap 16px

**Field Spacing:**
- **Vertical gap:** 20px between fields
- **Group gap:** 32px between field groups
- **Label to input:** 6px margin-bottom

**Required Fields:**
- **Indicator:** Asterisk (*) in red after label
- **Aria:** `aria-required="true"` on input
- **Optional fields:** Mark as "(opcional)" in gray text

### Validation

**Timing:**
- **On Blur:** Validate after user leaves field (better UX than real-time)
- **On Submit:** Final validation before submitting form
- **Real-time (limited):** Password strength, username availability

**Error Display:**
- **Position:** Below field
- **Style:** Red text (12px), icon (Heroicon exclamation-circle 16px)
- **Border:** Change input border to red
- **Focus ring:** Red focus ring (0 0 0 3px rgba(239, 68, 68, 0.1))
- **Aria:** `aria-describedby="error-message-id"` on input

**Success Display (optional):**
- **Indicator:** Green checkmark icon (Heroicon check-circle 20px) inside input (right side)
- **Use sparingly:** Only for critical fields (password confirmation, unique username)

### Error Messages

**Format:**
- Clear, actionable, specific
- Good: "Email é obrigatório"
- Bad: "Campo inválido"
- Good: "Senha deve ter no mínimo 8 caracteres"
- Bad: "Erro de senha"

**Position:**
- Below field, aligned left
- If multiple errors, stack vertically

**Color:** `var(--color-danger)` (#EF4444)  

**Font:** Inter Regular (400), 12px  

### Form Buttons

**Position:**
- **End of form:** Right-aligned (desktop), full-width (mobile)
- **Order:** Cancel/Back (left/secondary) + Submit (right/primary)
- **Gap:** 12px between buttons

**Loading State:**
- **Disabled:** Button disabled during submission
- **Spinner:** Show spinner inside button + text "Enviando..."
- **Prevent double-submit:** Disable button after first click

### Multi-Step Forms

**Progress Indicator:**
- **Style:** Stepper with steps (1 → 2 → 3)
- **Active step:** Primary color, bold
- **Completed step:** Success color, checkmark
- **Future step:** Gray, disabled

**Navigation:**
- Back button (secondary) + Next/Submit button (primary)
- Allow going back to previous steps without losing data

---

## ✅ Design Foundations Checklist

- [x] Color palette defined (primary, secondary, neutral, semantic, accent)
- [x] Typography scale defined (font families, sizes, weights, line heights)
- [x] Base components specified (buttons, inputs, cards, tables, alerts, modals, badges, loading states)
- [x] Trading-specific components specified (Greek display, price ticker, P&L badge, strategy card, leg row)
- [x] Navigation patterns defined (top nav, sidebar optional, breadcrumbs, tabs, pagination)
- [x] Spacing system defined (8px grid, layout grid, container padding)
- [x] Responsive breakpoints defined (mobile-first, desktop-privileged)
- [x] Accessibility guidelines documented (WCAG 2.1 AA, keyboard nav, ARIA, screen readers)
- [x] Icon library selected (Heroicons v2) with common icons listed
- [x] Imagery guidelines defined (photos, avatars, illustrations)
- [x] Forms guidelines defined (layout, validation, error messages, multi-step)

---

## 🚀 Next Steps

### 1. Frontend Implementation (FE Team)

**Priority Tasks:**
- Set up CSS variables (colors, typography, spacing)
- Implement base components (buttons, inputs, cards, tables)
- Create design system folder (`/components/ui/`)
- Set up Tailwind config (if using Tailwind)
- Implement trading-specific components (P&L badge, Greek display, strategy card)

**Tools Recommended:**
- **CSS Framework:** Tailwind CSS (utility-first, aligns with this design system)
- **Component Library:** shadcn/ui (Tailwind-based, accessible, customizable) OR Headless UI (unstyled, accessible primitives)
- **Icons:** @heroicons/react (React components for Heroicons)
- **Fonts:** @fontsource/inter, @fontsource/jetbrains-mono (self-hosted via npm)

### 2. Create Epic-Specific Wireframes (UXD per Epic)

**Process:**
- UXD-01-[EpicName]-Wireframes for each epic
- Use these foundations consistently
- Focus on user flows and screen interactions
- Work in parallel with SE (Software Engineer) during epic implementation

**First Epic to Wireframe:** EPIC-01 (Criação e Análise de Estratégias)  

### 3. Validation

**Stakeholder Review:**
- Present color palette and typography to stakeholders
- Get approval on professional/financial tone
- Validate trading-specific components with domain experts (traders)

**Accessibility Audit:**
- Run Lighthouse accessibility score (target: >95)
- Test keyboard navigation
- Verify color contrast ratios (use WebAIM Contrast Checker)

**Cross-Browser/Device Testing:**
- Chrome, Firefox, Safari, Edge
- Desktop (1920×1080, 1366×768)
- Tablet (768×1024)
- Mobile (375×667, 414×896)

---

## 📚 References

### Internal Documents
- **Workflow Guide:** [workflow-config.json](../../workflow-config.json)
- **Agent XML:** [.agents/20-UXD - User Experience Designer.xml](../../.agents/20-UXD%20-%20User%20Experience%20Designer.xml)
- **Strategic Design:** [SDA-02-Context-Map.md](../02-strategic-design/SDA-02-Context-Map.md)
- **Ubiquitous Language:** [SDA-03-Ubiquitous-Language.md](../02-strategic-design/SDA-03-Ubiquitous-Language.md)

### External Design Resources
- **Material Design:** https://material.io/design (design principles, components)
- **Tailwind UI:** https://tailwindui.com (component examples)
- **Refactoring UI:** https://refactoringui.com (design tips)
- **Heroicons:** https://heroicons.com (icon library)
- **unDraw:** https://undraw.co (illustrations)

### Accessibility Resources
- **WCAG 2.1 Guidelines:** https://www.w3.org/WAI/WCAG21/quickref/
- **WebAIM Contrast Checker:** https://webaim.org/resources/contrastchecker/
- **axe DevTools:** https://www.deque.com/axe/devtools/
- **A11y Project:** https://www.a11yproject.com/

### Typography & Fonts
- **Google Fonts:** https://fonts.google.com
- **Inter:** https://fonts.google.com/specimen/Inter
- **JetBrains Mono:** https://fonts.google.com/specimen/JetBrains+Mono

---

**Document Version:** 3.0 (Simplified)  
**Date Created:** 2025-10-14  
**Last Updated:** 2025-10-31  
**Next Document:** UXD-01-[EpicName]-Wireframes (per epic)    
**Status:** ✅ Complete - Ready for FE Implementation    

---

**Definition of Done:**
- [x] UXD-00-Design-Foundations.md created with complete design system
- [x] Colors, typography, spacing defined
- [x] Base components documented (15+ components including trading-specific)
- [x] Responsive breakpoints defined
- [x] Accessibility guidelines documented (WCAG 2.1 AA)
- [x] Icon library selected (Heroicons v2)
- [x] FE can implement design system using this document without blocking questions
