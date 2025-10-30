<!--
FORMATTING REQUIREMENTS:
- Metadata lines must end with 2 spaces before line break for proper Markdown rendering
- Use arrow notation (→) for layouts to maintain alignment
- Keep component tables properly formatted with pipe separators
-->

# UXD-01 - [EpicName] - Wireframes

**Agent:** UXD (User Experience Designer)  
**Phase:** Iteration (per epic)  
**Epic:** [EPIC_NAME]  
**Version:** 3.0 (Simplified)  

---

## 📋 Metadata

- **Project Name:** [PROJECT_NAME]  
- **Epic:** [EPIC_NAME]  
- **Created:** [DATE]  
- **UX Designer:** [NAME]  
- **Works in Parallel with:** SE (Days 3-6)  
- **Used by:** FE (Days 7-9)  

---

## 🎯 Objetivo

Criar wireframes específicos para o épico **[EPIC_NAME]**, detalhando as telas e fluxos de usuário necessários para implementar a funcionalidade. Usa as design foundations de [UXD-00-Design-Foundations.md](UXD-00-Design-Foundations.md).

---

## 📚 Inputs Consumidos

### From SDA (Strategic Design)
- **Context Map:** [Path to SDA-02]
- **Bounded Contexts envolvidos:** [List BCs]
- **Ubiquitous Language:** [Path to SDA-03]

### From DE (Tactical Design)
- **Domain Model:** [Path to DE-01-[EpicName]-Domain-Model.md]
- **Use Cases:** [List use cases from DE-01]
- **Aggregates:** [List main aggregates]

### From UXD-00 (Design Foundations)
- **Colors, Typography, Components:** [Path to UXD-00-Design-Foundations.md]

---

## 👤 User Stories / Use Cases

### Use Case 1: [USE_CASE_NAME]

**Actor:** [User Role]  

**Goal:** [What the user wants to achieve]  

**Preconditions:**  
- [Condition 1]
- [Condition 2]

**Main Flow:**  
1. User [action 1]
2. System [response 1]
3. User [action 2]
4. System [response 2]
5. Success message displayed

**Alternative Flows:**  
- **Alt 1:** [Error scenario - e.g., validation failure]
- **Alt 2:** [Edge case - e.g., empty state]

**Postconditions:**  
- [Result 1]
- [Result 2]

### Use Case 2: [USE_CASE_NAME]

[Repeat structure above for each use case]

---

## 🗺️ User Flow Diagram

### High-Level Flow

```
[Entry Point] → [Screen 1] → [Screen 2] → [Screen 3] → [Success State]
                      ↓
                [Error State]
```

### Detailed Flow

```
Start
  ↓
[Screen 1: List View]
  ↓ (User clicks "Create")
[Screen 2: Creation Form]
  ↓ (User fills form and submits)
[Validation]
  ↓ (Success)
[Screen 3: Success Message + Redirect to Detail View]
  ↓ (Failure)
[Screen 2: Form with Error Messages]
```

**Flow Description:**  
1. **Entry:** User lands on [Screen 1]
2. **Action:** User clicks [Button/Link]
3. **Navigation:** System navigates to [Screen 2]
4. **Validation:** System validates input
5. **Success Path:** Navigate to [Screen 3]
6. **Error Path:** Stay on [Screen 2] with error messages

---

## 🖼️ Wireframes

### Screen 1: [SCREEN_NAME] - List View

**Purpose:** Display list of [entities] and allow filtering/searching  

**URL:** `/[path]` (e.g., `/strategies`)  

**Layout:**  
```
┌─────────────────────────────────────────────────┐
│  [Logo]   Search [________] [+ Create New]      │ ← Header (Top Nav)
├─────────────────────────────────────────────────┤
│ [Breadcrumb: Home / Strategies]                 │
│                                                  │
│ ┌─────────────────────────────────────────────┐ │
│ │  Filters:                                   │ │
│ │  Status: [All ▼]  Type: [All ▼]  [Apply]   │ │
│ └─────────────────────────────────────────────┘ │
│                                                  │
│ ┌─────────────────────────────────────────────┐ │
│ │  Name         Type      Status     Actions  │ │ ← Table Header
│ ├─────────────────────────────────────────────┤ │
│ │  Strategy A   Long      Active     [Edit]   │ │ ← Data Row
│ │  Strategy B   Short     Draft      [Edit]   │ │
│ │  Strategy C   Neutral   Archived   [Edit]   │ │
│ └─────────────────────────────────────────────┘ │
│                                                  │
│ [Pagination: 1 2 3 ... 10 Next]                 │
└─────────────────────────────────────────────────┘
```

**Components Used:**  
- Top Navigation (from UXD-00)
- Breadcrumbs (from UXD-00)
- Filters (Select dropdowns)
- Table (from UXD-00)
- Primary Button: "Create New"
- Secondary Button: "Edit"
- Pagination

**States:**  
- **Empty State:** "No strategies found. Create your first strategy."
- **Loading State:** Skeleton table rows
- **Error State:** "Failed to load strategies. [Retry]"

**Interactions:**  
- **Search:** Filters table in real-time (debounced)
- **Filter dropdowns:** Applies on change or "Apply" button
- **[+ Create New] button:** Navigates to Screen 2
- **[Edit] button:** Navigates to Screen 4 (edit form)
- **Row click:** Navigates to Screen 3 (detail view)

---

### Screen 2: [SCREEN_NAME] - Creation Form

**Purpose:** Create new [entity]  

**URL:** `/[path]/new` (e.g., `/strategies/new`)  

**Layout:**  
```
┌─────────────────────────────────────────────────┐
│  [Logo]   [User Profile]                        │ ← Header
├─────────────────────────────────────────────────┤
│ [Breadcrumb: Home / Strategies / New]           │
│                                                  │
│  Create New Strategy                            │ ← H1 Title
│                                                  │
│ ┌─────────────────────────────────────────────┐ │
│ │  Name *                                     │ │
│ │  [_________________________________]        │ │
│ │                                             │ │
│ │  Type *                                     │ │
│ │  [Select type ▼]                            │ │
│ │                                             │ │
│ │  Description                                │ │
│ │  [_________________________________]        │ │
│ │  [_________________________________]        │ │
│ │  [_________________________________]        │ │
│ │                                             │ │
│ │  [Symbol, Quantity, etc. - form fields]    │ │
│ │                                             │ │
│ │  [Cancel]  [Create Strategy]                │ │ ← Buttons
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

**Components Used:**  
- Form (from UXD-00)
- Text Input (Name, Description)
- Select Dropdown (Type)
- Number Input (Quantity)
- Primary Button: "Create Strategy"
- Secondary Button: "Cancel"

**Validation:**  
- **Name:** Required, max 100 characters
- **Type:** Required
- **Quantity:** Required, > 0

**States:**  
- **Default:** Empty form
- **Validation Error:** Red border on invalid fields, error message below
- **Submitting:** Button disabled, loading spinner
- **Success:** Redirect to Screen 3 (detail view) with success toast

**Interactions:**  
- **[Cancel] button:** Navigates back to Screen 1 (with confirmation if form dirty)
- **[Create Strategy] button:** Validates → API call → Success/Error handling
- **Field blur:** Validates individual field (on blur)

---

### Screen 3: [SCREEN_NAME] - Detail View

**Purpose:** View details of [entity]  

**URL:** `/[path]/{id}` (e.g., `/strategies/123`)  

**Layout:**  
```
┌─────────────────────────────────────────────────┐
│  [Logo]   [User Profile]                        │ ← Header
├─────────────────────────────────────────────────┤
│ [Breadcrumb: Home / Strategies / Strategy A]    │
│                                                  │
│  Strategy A                    [Edit] [Delete]  │ ← H1 Title + Actions
│                                                  │
│ ┌─────────────────────────────────────────────┐ │
│ │  Status: Active (green badge)               │ │ ← Card
│ │  Type: Long                                 │ │
│ │  Created: 2025-01-15                        │ │
│ │  Updated: 2025-01-20                        │ │
│ └─────────────────────────────────────────────┘ │
│                                                  │
│  Description                                    │ ← H2 Section
│ ┌─────────────────────────────────────────────┐ │
│ │  [Full description text here...]            │ │
│ └─────────────────────────────────────────────┘ │
│                                                  │
│  Positions                                      │ ← H2 Section
│ ┌─────────────────────────────────────────────┐ │
│ │  Symbol    Qty    Price    P&L              │ │ ← Table
│ │  PETR4     100    28.50    +150.00          │ │
│ │  VALE3     200    65.30    -80.00           │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

**Components Used:**  
- Card (from UXD-00)
- Badge (status indicator)
- Table (positions)
- Secondary Button: "Edit"
- Danger Button: "Delete"

**States:**  
- **Loading:** Skeleton for card + table
- **Error:** "Failed to load strategy. [Retry]"
- **Empty Positions:** "No positions yet. [Add Position]"

**Interactions:**  
- **[Edit] button:** Navigates to Screen 4 (edit form)
- **[Delete] button:** Opens confirmation modal → API call → Navigate to Screen 1
- **Position row click:** Navigate to position detail (if applicable)

---

### Screen 4: [SCREEN_NAME] - Edit Form

**Purpose:** Edit existing [entity]  

**URL:** `/[path]/{id}/edit` (e.g., `/strategies/123/edit`)  

**Layout:**  
```
[Similar to Screen 2, but with pre-filled values]

┌─────────────────────────────────────────────────┐
│  Edit Strategy: Strategy A                      │ ← H1 Title
│                                                  │
│ ┌─────────────────────────────────────────────┐ │
│ │  Name *                                     │ │
│ │  [Strategy A__________________]             │ │ ← Pre-filled
│ │                                             │ │
│ │  Type *                                     │ │
│ │  [Long ▼]                                   │ │ ← Pre-filled
│ │                                             │ │
│ │  [Cancel]  [Save Changes]                   │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

**Components Used:**  
- Same as Screen 2 (form components)
- Primary Button: "Save Changes"

**Interactions:**  
- **[Cancel] button:** Navigate back to Screen 3 (with confirmation if dirty)
- **[Save Changes] button:** Validates → API call → Navigate to Screen 3 with success toast

---

### Screen 5: [SCREEN_NAME] - Delete Confirmation Modal

**Purpose:** Confirm deletion of [entity]  

**Triggered by:** Delete button on Screen 3  

**Layout:**  
```
┌─────────────────────────────────────────┐
│  Delete Strategy?                       │ ← Modal Header
│                                         │
│  Are you sure you want to delete        │
│  "Strategy A"? This action cannot be    │
│  undone.                                │
│                                         │
│  [Cancel]  [Delete]                     │ ← Buttons
└─────────────────────────────────────────┘
```

**Components Used:**  
- Modal (from UXD-00)
- Danger Button: "Delete"
- Secondary Button: "Cancel"

**Interactions:**  
- **[Cancel] button:** Close modal
- **[Delete] button:** API call → Navigate to Screen 1 with success toast
- **Click outside modal:** Close modal
- **ESC key:** Close modal

---

## 📊 Component Inventory

List all UI components used in this epic's wireframes:

| Component | Source | Screens Used |
|-----------|--------|--------------|
| Top Navigation | UXD-00 | All screens |
| Breadcrumbs | UXD-00 | All screens |
| Primary Button | UXD-00 | Screens 2, 3, 4 |
| Secondary Button | UXD-00 | Screens 1, 2, 3, 4, 5 |
| Danger Button | UXD-00 | Screens 3, 5 |
| Text Input | UXD-00 | Screens 2, 4 |
| Select Dropdown | UXD-00 | Screens 1, 2, 4 |
| Table | UXD-00 | Screens 1, 3 |
| Card | UXD-00 | Screen 3 |
| Modal | UXD-00 | Screen 5 |
| Badge | UXD-00 | Screen 3 |
| Alert/Toast | UXD-00 | Success/Error messages |

---

## 📱 Responsive Behavior

### Mobile Adaptations (< 600px)

**Screen 1 (List View):**  
- Table becomes card list (vertical stack)
- Filters collapse into drawer
- Search bar full width

**Screen 2 (Form):**  
- Form fields full width
- Buttons stack vertically

**Screen 3 (Detail View):**  
- Positions table scrolls horizontally
- Edit/Delete buttons stack vertically

**Screen 4 (Edit Form):**  
- Same as Screen 2

**Screen 5 (Modal):**  
- Modal full width (90% of screen)

---

## ♿ Accessibility Considerations

### Keyboard Navigation
- All interactive elements accessible via Tab
- Modal: Focus trapped inside, ESC to close
- Form: Tab order follows visual order

### Screen Reader Support
- Form labels associated with inputs (`<label for="...">`)
- Error messages announced (`aria-live="polite"`)
- Modal: `role="dialog"`, `aria-labelledby`, `aria-describedby`

### Color Contrast
- All text meets WCAG AA (4.5:1 for normal text)
- Error messages use icon + color (not color alone)

---

## 🎨 Visual Design Notes

### Color Usage
- **Primary color:** Call-to-action buttons, links, active states
- **Success green:** Active status badge, success toasts
- **Error red:** Validation errors, delete button, error toasts
- **Neutral gray:** Borders, secondary text, disabled states

### Spacing
- Form field spacing: 16px between fields
- Section spacing: 32px between sections
- Card padding: 24px

### Icons (from UXD-00 icon library)
- **Search icon:** magnifying-glass
- **Add icon:** plus-circle
- **Edit icon:** pencil
- **Delete icon:** trash
- **Success icon:** check-circle
- **Error icon:** x-circle

---

## ✅ Wireframes Checklist

- [ ] All use cases mapped to screens
- [ ] User flow diagram created
- [ ] Screen 1 wireframe (List View)
- [ ] Screen 2 wireframe (Creation Form)
- [ ] Screen 3 wireframe (Detail View)
- [ ] Screen 4 wireframe (Edit Form)
- [ ] Screen 5 wireframe (Delete Modal)
- [ ] Component inventory completed
- [ ] Responsive behavior documented
- [ ] Accessibility considerations documented
- [ ] Visual design notes completed
- [ ] Validation rules specified per field
- [ ] Error states defined per screen
- [ ] Loading states defined per screen
- [ ] Empty states defined per screen

---

## 🚀 Handoff to Frontend Engineer (FE)

**What FE receives (Day 7):**  
- ✅ This wireframes document (UXD-01)
- ✅ Design foundations (UXD-00)
- ✅ APIs from SE (backend endpoints ready)

**FE Implementation (Days 7-9):**  
- Implement screens based on wireframes
- Use components from design foundations
- Integrate with backend APIs
- Implement validation, error handling, loading states

**Collaboration Points:**  
- FE can ask UXD clarification questions
- If wireframe is ambiguous, FE creates feedback: `FEEDBACK-[ID]`

---

## 📚 References

- **Design Foundations:** [UXD-00-Design-Foundations.md](../UXD-00-Design-Foundations.md)
- **Domain Model:** [DE-01-[EpicName]-Domain-Model.md](../../04-tactical-design/DE-01-[EpicName]-Domain-Model.md)
- **Context Map:** [SDA-02-Context-Map.md](../../02-strategic-design/SDA-02-Context-Map.md)
- **Agent XML:** `.agents/20-UXD - User Experience Designer.xml`

---

**Template Version:** 3.0  
**Last Updated:** 2025-10-08  
**Parallel Work:** SE implements backend (Days 3-6) while UXD creates wireframes  
**Next:** FE implements UI (Days 7-9) based on these wireframes  
