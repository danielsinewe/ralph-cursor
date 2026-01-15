# Feature Name - Product Requirements Document

**Version:** 1.0  
**Date:** YYYY-MM-DD  
**Status:** Draft  
**Author:** Your Name

---

## 1. Executive Summary

Brief description of the feature and its purpose. What problem does it solve? Who benefits?

---

## 2. Goals & Success Metrics

### Goals
- Primary goal 1
- Primary goal 2
- Primary goal 3

### Success Metrics (Future)
- Metric 1: How will you measure success?
- Metric 2: What KPIs matter?

---

## 3. User Personas

1. **Primary User Type** - Description of who they are and what they need
2. **Secondary User Type** - Description of who they are and what they need

---

## 4. Feature Scope

### 4.1 MVP (Phase 1) - Core Feature

**Priority: HIGHEST**

Description of the core MVP functionality.

| Feature | Description | Priority |
|---------|-------------|----------|
| Feature 1 | What it does | P0 |
| Feature 2 | What it does | P0 |
| Feature 3 | What it does | P0 |

### 4.2 Phase 2 - Enhancements

**Priority: HIGH**

| Feature | Description | Priority |
|---------|-------------|----------|
| Feature 4 | What it does | P1 |
| Feature 5 | What it does | P1 |

### 4.3 Phase 3 - Nice to Have

**Priority: MEDIUM**

| Feature | Description | Priority |
|---------|-------------|----------|
| Feature 6 | What it does | P2 |
| Feature 7 | What it does | P2 |

---

## 5. Data Model

### 5.1 New Database Tables

```sql
-- Example table
CREATE TABLE my_table (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  team_id UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  
  -- Fields
  name VARCHAR(255) NOT NULL,
  config JSONB NOT NULL DEFAULT '{}',
  status VARCHAR(20) NOT NULL DEFAULT 'active',
  
  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 5.2 New Types/Schemas

Describe any new TypeScript types, enums, or Drizzle schemas needed.

### 5.3 Data Shape

If creating new data shapes for the data registry:

| Column | Data Shape | Description |
|--------|------------|-------------|
| Column 1 | `text` | Description |
| Column 2 | `url` | Description |
| Column 3 | `date` | Description |

---

## 6. Technical Architecture

### 6.1 External APIs Required

| Endpoint | Method | Use Case | Notes |
|----------|--------|----------|-------|
| `/api/endpoint` | GET | What it's for | Any notes |

### 6.2 New API Functions

```typescript
// Describe new functions needed
export async function myFunction(param: string): Promise<MyType>
```

### 6.3 Background Jobs

If background jobs are needed:

1. **`job:name`** - Description of what it does and when it runs

### 6.4 File Structure

```
apps/web/src/app/app/[teamSlug]/feature/
├── page.tsx                    # Main page
├── layout.tsx                  # Layout
├── [id]/
│   └── page.tsx               # Detail view
└── _components/
    ├── component-1.tsx
    └── component-2.tsx

apps/workers/src/
├── workers/
│   └── feature/               # New worker folder
│       ├── feature.worker.ts
│       └── process.ts
```

---

## 7. User Interface

### 7.1 Access Point

- URL: `/app/[teamSlug]/feature`
- Navigation: How users get here (sidebar, direct URL, etc.)

### 7.2 UI Wireframes

**Main Page:**
```
┌─────────────────────────────────────────────────────────┐
│ Page Title                              [+ New Button]  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Item 1                                              │ │
│ │ Description or metadata                             │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Item 2                                              │ │
│ │ Description or metadata                             │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Create/Edit Modal:**
```
┌─────────────────────────────────────────────────────────┐
│ Create New Item                                    [X]  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│ Field Label:                                            │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Input field                                         │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│              [Cancel]  [Create]                         │
└─────────────────────────────────────────────────────────┘
```

---

## 8. API Routes

### 8.1 tRPC Routes

```typescript
featureRouter = router({
  // List all items
  list: protectedProcedure
    .query(async ({ ctx }) => {...}),
  
  // Get single item
  get: protectedProcedure
    .input(z.object({ id: z.string().uuid() }))
    .query(async ({ ctx, input }) => {...}),
  
  // Create new item
  create: protectedProcedure
    .input(createSchema)
    .mutation(async ({ ctx, input }) => {...}),
  
  // Update item
  update: protectedProcedure
    .input(updateSchema)
    .mutation(async ({ ctx, input }) => {...}),
  
  // Delete item
  delete: protectedProcedure
    .input(z.object({ id: z.string().uuid() }))
    .mutation(async ({ ctx, input }) => {...}),
})
```

---

## 9. Edge Cases & Error Handling

| Scenario | Handling |
|----------|----------|
| Edge case 1 | How to handle it |
| Edge case 2 | How to handle it |
| Error condition 1 | How to handle it |

---

## 10. Security & Privacy

- Authentication: How is access controlled?
- Authorization: Who can do what?
- Data privacy: What data is sensitive?

---

## 11. Implementation Phases

### Phase 1: MVP (Target: X days)
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

### Phase 2: Enhancements
- [ ] Task 4
- [ ] Task 5

### Phase 3: Polish
- [ ] Task 6
- [ ] Task 7

---

## 12. Open Questions

1. Question that needs answering before/during implementation?
2. Decision that needs to be made?

---

## 13. References

- Link to related documentation
- Link to design files
- Link to competitor examples
- Link to existing code patterns to follow

---

## Appendix

### A. API Response Examples

```json
{
  "example": "response"
}
```

### B. Additional Technical Details

Any other technical details that help with implementation.