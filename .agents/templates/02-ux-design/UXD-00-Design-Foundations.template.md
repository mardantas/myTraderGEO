<!--
MARKDOWN FORMATTING:
- Use 2 spaces at end of line for compact line breaks (metadata)  
- Use blank lines between sections for readability (content)  
- Validate in Markdown preview before committing  
-->

# UXD-00 - Design Foundations

**Agent:** UXD (User Experience Designer)  
**Project:** [PROJECT_NAME]  
**Date:** [YYYY-MM-DD]  
**Phase:** Discovery (1x)  
**Scope:** Design foundations for the entire system  
**Version:** 3.0  
  
---  

## 📋 Metadata

- **Project Name:** [PROJECT_NAME]  
- **Created:** [DATE]  
- **UX Designer:** [NAME]  
- **Target:** Small/Medium Projects  
- **Approach:** Foundations only (detailed wireframes per epic)  

---

## 🎯 Objetivo

Estabelecer as fundações do design para todo o sistema: cores, tipografia, componentes base e padrões de navegação. Wireframes detalhados serão criados por épico (UXD-01-[EpicName]).

---

## 🎨 Color Palette

### Primary Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **Primary** | `#[HEX]` | Main actions, links, highlights |
| **Primary Light** | `#[HEX]` | Hover states, backgrounds |
| **Primary Dark** | `#[HEX]` | Active states, emphasis |

### Secondary Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **Secondary** | `#[HEX]` | Secondary actions, accents |
| **Secondary Light** | `#[HEX]` | Hover states |
| **Secondary Dark** | `#[HEX]` | Active states |

### Neutral Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **Background** | `#FFFFFF` | Page backgrounds |
| **Surface** | `#F5F5F5` | Card backgrounds |
| **Border** | `#E0E0E0` | Dividers, borders |
| **Text Primary** | `#212121` | Main text |
| **Text Secondary** | `#757575` | Secondary text |
| **Text Disabled** | `#BDBDBD` | Disabled text |

### Semantic Colors

| Color | Hex | Usage |
|-------|-----|-------|
| **Success** | `#4CAF50` | Success messages, confirmations |
| **Warning** | `#FF9800` | Warnings, alerts |
| **Error** | `#F44336` | Errors, validation failures |
| **Info** | `#2196F3` | Informational messages |

### Example Palette (customize for your project)

```css
:root {
  /* Primary */
  --color-primary: #1976D2;
  --color-primary-light: #42A5F5;
  --color-primary-dark: #1565C0;

  /* Secondary */
  --color-secondary: #424242;
  --color-secondary-light: #616161;
  --color-secondary-dark: #212121;

  /* Neutral */
  --color-background: #FFFFFF;
  --color-surface: #F5F5F5;
  --color-border: #E0E0E0;
  --color-text-primary: #212121;
  --color-text-secondary: #757575;
  --color-text-disabled: #BDBDBD;

  /* Semantic */
  --color-success: #4CAF50;
  --color-warning: #FF9800;
  --color-error: #F44336;
  --color-info: #2196F3;
}
```

---

## 📝 Typography

### Font Families

**Primary Font:** [Font Name] (e.g., Inter, Roboto, Open Sans)  
- **Usage:** Body text, UI elements  
- **Weights:** 400 (Regular), 500 (Medium), 700 (Bold)  
- **Source:** [Google Fonts / System Font]  

**Heading Font:** [Font Name] (e.g., Poppins, Montserrat)  
- **Usage:** Headings (H1-H6)  
- **Weights:** 600 (SemiBold), 700 (Bold)  
- **Source:** [Google Fonts / System Font]  

**Monospace Font:** [Font Name] (e.g., Fira Code, JetBrains Mono)  
- **Usage:** Code snippets, data displays  
- **Weights:** 400 (Regular)  
- **Source:** [Google Fonts / System Font]  

### Type Scale

| Element | Size | Weight | Line Height | Usage |
|---------|------|--------|-------------|-------|
| **H1** | 32px / 2rem | 700 | 1.2 | Page titles |
| **H2** | 24px / 1.5rem | 700 | 1.3 | Section titles |
| **H3** | 20px / 1.25rem | 600 | 1.4 | Subsection titles |
| **H4** | 18px / 1.125rem | 600 | 1.4 | Card titles |
| **H5** | 16px / 1rem | 600 | 1.5 | Small headings |
| **H6** | 14px / 0.875rem | 600 | 1.5 | Tiny headings |
| **Body Large** | 16px / 1rem | 400 | 1.5 | Large body text |
| **Body** | 14px / 0.875rem | 400 | 1.5 | Default body text |
| **Body Small** | 12px / 0.75rem | 400 | 1.5 | Small text, captions |
| **Button** | 14px / 0.875rem | 500 | 1.5 | Button labels |
| **Caption** | 12px / 0.75rem | 400 | 1.4 | Image captions, helper text |
| **Overline** | 10px / 0.625rem | 500 | 1.5 | Overline text (uppercase) |

### Example CSS

```css
:root {
  /* Font Families */
  --font-primary: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-heading: 'Poppins', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  --font-mono: 'Fira Code', 'Courier New', monospace;

  /* Font Sizes */
  --font-size-h1: 2rem;
  --font-size-h2: 1.5rem;
  --font-size-h3: 1.25rem;
  --font-size-h4: 1.125rem;
  --font-size-body: 0.875rem;
  --font-size-small: 0.75rem;
}

h1 { font-family: var(--font-heading); font-size: var(--font-size-h1); font-weight: 700; }
h2 { font-family: var(--font-heading); font-size: var(--font-size-h2); font-weight: 700; }
body { font-family: var(--font-primary); font-size: var(--font-size-body); }
```

---

## 🧩 Base Components

### Buttons

**Primary Button**
- Background: `var(--color-primary)`  
- Text: White  
- Border Radius: 4px (or 8px for rounded)  
- Padding: 10px 24px  
- Hover: `var(--color-primary-dark)`  
- Disabled: `var(--color-text-disabled)`, opacity 0.5  

**Secondary Button**
- Background: Transparent  
- Text: `var(--color-primary)`  
- Border: 1px solid `var(--color-primary)`  
- Border Radius: 4px  
- Padding: 10px 24px  
- Hover: Background `var(--color-primary-light)` 10% opacity  

**Danger Button**
- Background: `var(--color-error)`  
- Text: White  
- Border Radius: 4px  
- Padding: 10px 24px  

**Sizes:**  
- Small: padding 6px 16px, font-size 12px  
- Medium: padding 10px 24px, font-size 14px  
- Large: padding 14px 32px, font-size 16px  

### Input Fields

**Text Input**
- Border: 1px solid `var(--color-border)`  
- Border Radius: 4px  
- Padding: 10px 12px  
- Font Size: 14px  
- Focus: Border `var(--color-primary)`, box-shadow 0 0 0 2px rgba(primary, 0.2)  
- Error: Border `var(--color-error)`  
- Disabled: Background `var(--color-surface)`, cursor not-allowed  

**Select Dropdown**
- Same as text input  
- Dropdown icon: chevron-down (right side)  

**Checkbox / Radio**
- Size: 20px × 20px  
- Border: 2px solid `var(--color-border)`  
- Checked: Background `var(--color-primary)`, checkmark white  

**Label**
- Font Size: 14px  
- Font Weight: 500  
- Color: `var(--color-text-primary)`  
- Margin Bottom: 4px  

### Cards

**Standard Card**
- Background: White  
- Border: 1px solid `var(--color-border)` (or none for shadow only)  
- Border Radius: 8px  
- Padding: 16px (or 24px for larger cards)  
- Box Shadow: 0 1px 3px rgba(0,0,0,0.1)  
- Hover: Box shadow 0 4px 6px rgba(0,0,0,0.15)  

**Card Header**
- Font Size: 18px (H4)  
- Font Weight: 600  
- Margin Bottom: 12px  

**Card Content**
- Font Size: 14px  
- Line Height: 1.5  

### Tables

**Table Header**
- Background: `var(--color-surface)`  
- Font Weight: 600  
- Font Size: 14px  
- Padding: 12px 16px  
- Border Bottom: 2px solid `var(--color-border)`  

**Table Row**
- Padding: 12px 16px  
- Border Bottom: 1px solid `var(--color-border)`  
- Hover: Background `var(--color-surface)`  

**Table Cell**
- Font Size: 14px  
- Align: left (text), right (numbers)  

### Alerts / Notifications

**Success Alert**
- Background: `var(--color-success)` 10% opacity  
- Border Left: 4px solid `var(--color-success)`  
- Icon: checkmark-circle (success green)  

**Warning Alert**
- Background: `var(--color-warning)` 10% opacity  
- Border Left: 4px solid `var(--color-warning)`  
- Icon: alert-triangle (warning orange)  

**Error Alert**
- Background: `var(--color-error)` 10% opacity  
- Border Left: 4px solid `var(--color-error)`  
- Icon: alert-circle (error red)  

**Info Alert**
- Background: `var(--color-info)` 10% opacity  
- Border Left: 4px solid `var(--color-info)`  
- Icon: info-circle (info blue)  

### Modals

**Modal Overlay**
- Background: rgba(0,0,0,0.5)  
- Position: fixed, full screen  
- Z-index: 1000  

**Modal Container**
- Background: White  
- Border Radius: 8px  
- Max Width: 600px (or 90% on mobile)  
- Padding: 24px  
- Box Shadow: 0 10px 25px rgba(0,0,0,0.3)  

**Modal Header**
- Font Size: 20px (H3)  
- Font Weight: 600  
- Margin Bottom: 16px  

**Modal Footer**
- Margin Top: 24px  
- Text Align: right  
- Buttons: Cancel (secondary) + Confirm (primary)  

### Loading States

**Spinner**
- Size: 24px × 24px (small), 48px × 48px (large)  
- Color: `var(--color-primary)`  
- Animation: rotate 1s linear infinite  

**Skeleton**
- Background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%)  
- Animation: shimmer 1.5s infinite  

---

## 🗺️ Navigation Patterns

### Top Navigation Bar

**Desktop:**  
- Height: 64px  
- Logo: Left (max height 40px)  
- Menu Items: Center or Left after logo  
- User Profile: Right (avatar + dropdown)  
- Background: White  
- Box Shadow: 0 1px 3px rgba(0,0,0,0.1)  

**Mobile:**  
- Height: 56px  
- Hamburger menu: Left  
- Logo: Center  
- User profile icon: Right  

### Sidebar Navigation (if applicable)

**Desktop:**  
- Width: 240px (collapsed: 64px)  
- Position: Fixed left  
- Menu items: Icon + Label  
- Active item: Background `var(--color-primary)` 10%, border-left `var(--color-primary)` 4px  

**Mobile:**  
- Drawer: slides from left  
- Overlay: background rgba(0,0,0,0.5)  

### Breadcrumbs

- Font Size: 14px  
- Separator: "/" or ">" (color: `var(--color-text-secondary)`)  
- Current page: Font Weight 500, no link  
- Example: Home / Dashboard / Orders / Order #123  

### Tabs

- Border Bottom: 2px solid `var(--color-border)`  
- Active Tab: Border Bottom 2px solid `var(--color-primary)`, font weight 500  
- Inactive Tab: Color `var(--color-text-secondary)`  
- Hover: Color `var(--color-primary)`  

---

## 📐 Spacing System

### Spacing Scale (based on 8px grid)

| Variable | Size | Usage |
|----------|------|-------|
| `--spacing-xs` | 4px | Tiny gaps |
| `--spacing-sm` | 8px | Small gaps |
| `--spacing-md` | 16px | Default gaps |
| `--spacing-lg` | 24px | Large gaps |
| `--spacing-xl` | 32px | Extra large gaps |
| `--spacing-2xl` | 48px | Section gaps |
| `--spacing-3xl` | 64px | Page gaps |

### Layout Grid

- **Desktop:** 12 columns, 24px gutter  
- **Tablet:** 8 columns, 16px gutter  
- **Mobile:** 4 columns, 16px gutter  

---

## 📱 Responsive Breakpoints

| Breakpoint | Size | Target |
|------------|------|--------|
| **xs** | 0-599px | Mobile portrait |
| **sm** | 600-959px | Mobile landscape, small tablets |
| **md** | 960-1279px | Tablets, small desktops |
| **lg** | 1280-1919px | Desktops |
| **xl** | 1920px+ | Large desktops |

### Example CSS

```css
/* Mobile first approach */
.container {
  padding: 16px;
}

@media (min-width: 600px) {
  .container { padding: 24px; }
}

@media (min-width: 960px) {
  .container { padding: 32px; }
}

@media (min-width: 1280px) {
  .container { padding: 48px; }
}
```

---

## ♿ Accessibility Guidelines

### Color Contrast

- **Normal text:** Minimum 4.5:1 contrast ratio (WCAG AA)  
- **Large text (18px+):** Minimum 3:1 contrast ratio  
- **UI components:** Minimum 3:1 contrast ratio  

### Keyboard Navigation

- All interactive elements must be keyboard accessible (Tab, Enter, Space)  
- Focus state visible: outline 2px solid `var(--color-primary)`  
- Skip to main content link (for screen readers)  

### ARIA Labels

- Buttons: `aria-label` if no visible text  
- Icons: `aria-hidden="true"` if decorative, `aria-label` if functional  
- Forms: `aria-describedby` for error messages  

### Screen Reader Support

- Semantic HTML: `<header>`, `<nav>`, `<main>`, `<footer>`  
- Headings hierarchy: H1 → H2 → H3 (no skipping levels)  
- Alt text for images (empty alt="" if decorative)  

---

## 🎭 Iconography

### Icon Library

**Selected Library:** [Choose one]  
- [ ] Material Icons (Google)  
- [ ] Heroicons (Tailwind)  
- [ ] Feather Icons  
- [ ] Font Awesome  
- [ ] Custom SVG icons  

**Icon Sizes:**  
- Small: 16px × 16px  
- Medium: 24px × 24px (default)  
- Large: 32px × 32px  

**Common Icons:**  
- Navigation: home, search, menu, close, chevron-down, chevron-right  
- Actions: edit, delete, add, save, cancel, refresh  
- Status: check-circle (success), alert-triangle (warning), x-circle (error), info-circle (info)  
- User: user, settings, logout, profile  

---

## 🖼️ Imagery Guidelines

### Photos

- **Aspect Ratios:** 16:9 (hero), 4:3 (cards), 1:1 (avatars)  
- **Quality:** High resolution, optimized for web (WebP format preferred)  
- **Placeholder:** Skeleton or solid color background during load  

### Avatars

- **Size:** 32px (small), 40px (default), 64px (large), 120px (profile)  
- **Shape:** Circle (users), rounded square (teams/organizations)  
- **Fallback:** Initials on colored background (use user ID hash for color)  

### Illustrations (optional)

- **Style:** [Describe style - flat, outlined, 3D, etc.]  
- **Usage:** Empty states, onboarding, error pages  

---

## 📋 Forms Guidelines

### Form Layout

- **Label position:** Top (mobile-friendly) or Left (desktop, if space allows)  
- **Field width:** Full width on mobile, max 400px on desktop  
- **Field spacing:** 16px between fields  
- **Required fields:** Asterisk (*) after label OR "Required" text  

### Validation

- **Timing:** On blur (after user leaves field) OR on submit  
- **Error display:** Below field, red text, with error icon  
- **Success display:** Green checkmark icon (optional)  

### Error Messages

- **Format:** Clear, actionable (e.g., "Email is required" not "Invalid input")  
- **Position:** Below field  
- **Style:** Color `var(--color-error)`, font size 12px  

---

## ✅ Design Foundations Checklist

- [ ] Color palette defined (primary, secondary, neutral, semantic)  
- [ ] Typography scale defined (font families, sizes, weights)  
- [ ] Base components specified (buttons, inputs, cards, tables, alerts, modals)  
- [ ] Navigation patterns defined (top nav, sidebar, breadcrumbs, tabs)  
- [ ] Spacing system defined (8px grid)  
- [ ] Responsive breakpoints defined  
- [ ] Accessibility guidelines documented  
- [ ] Icon library selected  
- [ ] Imagery guidelines defined  
- [ ] Forms guidelines defined  

---

## 🚀 Next Steps

1. **Implement Design System** (FE team)
   - Create reusable components based on this spec  
   - Set up CSS variables / Tailwind config  

2. **Create Wireframes per Epic** (UXD per epic)
   - Use these foundations consistently  
   - Create UXD-01-[EpicName]-Wireframes for each epic  

3. **Validation**
   - Review with stakeholders  
   - Test components across breakpoints  
   - Validate accessibility (contrast, keyboard nav)  

---

## 📚 References

- **Workflow Guide:** `.agents/00-Workflow-Guide.md`  
- **Agent XML:** `.agents/20-UXD - User Experience Designer.xml`  
- **Design Resources:**  
  - Material Design: https://material.io/design  
  - Tailwind UI: https://tailwindui.com  
  - Refactoring UI: https://refactoringui.com  

---

**Template Version:** 3.0  
**Last Updated:** 2025-10-08  
**Next Document:** UXD-01-[EpicName]-Wireframes (per epic)  
