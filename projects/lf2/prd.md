# Luma Event Form Improvements - Product Requirements Document

**Version:** 1.0
**Date:** 2026-01-12
**Status:** Draft
**Author:** Claude

---

## 1. Executive Summary

This PRD covers four improvements to the Luma event import flow in Fluar. The goal is to streamline the user experience when creating projects from Luma events by:

1. Allowing users to copy column templates from existing Luma projects
2. Improving the connection flow UI to be more guided and sequential
3. Validating Luma API keys before saving and showing a connection name field
4. Displaying event preview images when an event is selected

These changes reduce friction for repeat Luma users and prevent errors from invalid API keys.

---

## 2. Goals & Success Metrics

### Goals
- Reduce time to create second+ Luma projects by enabling template reuse
- Eliminate failed imports due to invalid API keys
- Provide clearer guidance through the connection → event selection flow
- Improve visual feedback when selecting events

### Success Metrics (Future)
- Reduction in failed Luma connections due to invalid API keys
- Increased usage of template copying feature for repeat Luma users
- Reduced support requests related to Luma integration setup

---

## 3. User Personas

1. **Event Organizer (Primary)** - Runs multiple events on Luma, wants to quickly create Fluar projects with the same enrichment columns they've built before
2. **First-time Luma User** - Connecting Luma for the first time, needs clear guidance through the setup flow

---

## 4. Feature Scope

### 4.1 Phase 1 - MVP (Core Features)

**Priority: HIGHEST**

| Feature | Description | Priority |
|---------|-------------|----------|
| Template copying | Allow copying columns from existing Luma projects in the workspace | P0 |
| Sequential connection flow | Show connection UI "in front of" event selection; hide left panel when connected | P0 |
| API key validation | Call Luma get-self API to validate key before saving | P1 |
| Connection name field | Show connection name input on integrations page and pre-fill from API | P1 |

### 4.2 Phase 2 - Polish

**Priority: HIGH**

| Feature | Description | Priority |
|---------|-------------|----------|
| Event preview in trigger | Show event image next to name in dropdown trigger button | P2 |
| Template from saved templates | Include team's saved Luma templates (not just projects) in dropdown | P2 |

---

## 5. Data Model

### 5.1 No Database Changes Required

All features use existing database structures:
- `projects.columns` - JSONB field storing column definitions
- `projects.metadata` - JSONB with `integration: 'luma-event'` for Luma projects
- `integration_connections.connectionName` - Already exists, just needs UI exposure

### 5.2 Existing Types Used

```typescript
// Luma project metadata (packages/db/types/column.ts)
interface ProjectMetadata {
  integration?: 'luma-event'
  luma?: {
    eventId: string
    eventName: string
    webhookEnabled: boolean
    addApprovalColumn: boolean
  }
}

// Column type (packages/db/types/column.ts)
interface DbColumnType {
  id: string
  label: string
  type: 'manual' | 'ai' | 'api' | 'task' | 'reference'
  // ... other fields
}
```

---

## 6. Technical Architecture

### 6.1 External APIs Required

| Endpoint | Method | Use Case | Notes |
|----------|--------|----------|-------|
| `https://public-api.luma.com/v1/user/get-self` | GET | Validate API key and get user info | Header: `x-luma-api-key: {key}` |

### 6.2 New API Functions

```typescript
// packages/configs/src/luma/client.ts
export class LumaClient {
  // NEW: Validate API key and get user info
  async getSelf(): Promise<{ user: LumaUser }> {
    return await this.getJson<{ user: LumaUser }>(`${BASE_URL}/user/get-self`)
  }
}

interface LumaUser {
  api_id: string
  name: string
  first_name: string
  last_name: string
  email: string
  avatar_url: string
}
```

```typescript
// apps/web/src/trpc/router/data-sources.ts
// NEW: List Luma projects in workspace for template selection
listLumaProjects: protectedProcedure
  .query(async ({ ctx }) => {
    // Query projects where metadata->>'integration' = 'luma-event'
    // Return: { id, title, columnCount, createdAt }[]
  })
```

### 6.3 File Structure - Files to Modify

```
apps/web/src/components/project/create/components/
└── luma-event-form.tsx                    # Main form - all UI changes

apps/web/src/components/integrations/
├── integration-connect-dialog.tsx         # Add API key validation
└── integration-connect-inline.tsx         # No changes needed

apps/web/src/app/app/[teamSlug]/integrations/
└── integrations-content.tsx               # Show connection name field

apps/web/src/trpc/router/
├── integrations.ts                        # Add validateLumaApiKey procedure
└── data-sources.ts                        # Add listLumaProjects procedure

packages/configs/src/luma/
└── client.ts                              # Add getSelf() method
```

---

## 7. User Interface

### 7.1 Feature 1: Template Copying

**Location:** Luma Event Form, shown after event is selected

```
┌─────────────────────────────────────────────────────────────┐
│ Select your event                                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Event: [▼ AI Tinkerers Meetup - Jan 2026              ]     │
│                                                             │
│ ─────────────────────────────────────────────────────────── │
│                                                             │
│ Copy columns from:                                          │
│ [▼ None - start fresh                                  ]    │
│   ┌───────────────────────────────────────────────────┐     │
│   │ None - start fresh                                │     │
│   │ ─────────────────────────────────────────────────│     │
│   │ 📊 AI Tinkerers Dec 2025 (8 columns)              │     │
│   │ 📊 Founders Dinner Nov 2025 (5 columns)           │     │
│   │ ─────────────────────────────────────────────────│     │
│   │ 📋 My Luma Template (12 columns)                  │     │
│   └───────────────────────────────────────────────────┘     │
│                                                             │
│ ⚡ Add Enrichments                                          │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ ☑ Automatically pull new Luma submissions              │ │
│ │ ☑ Add approval/decline column                          │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│                                    [Create Project]         │
└─────────────────────────────────────────────────────────────┘
```

**Behavior:**
- Dropdown shows existing Luma projects (from `metadata.integration = 'luma-event'`)
- Shows column count for each project (excluding `_trigger`)
- "None - start fresh" is default selection
- When a project is selected, its columns (except `_trigger`) are copied to the new project
- Column configurations (prompts, dependencies, etc.) are copied exactly

### 7.2 Feature 2: Sequential Connection Flow

**State A: Not Connected (Connection Required)**

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                    🔗 Connect Luma                          │
│                                                             │
│   Connect your Luma calendar to sync event attendees       │
│   into your Fluar projects.                                │
│                                                             │
│   API Key:                                                  │
│   ┌───────────────────────────────────────────────────┐     │
│   │ luma-secret-...                                   │     │
│   └───────────────────────────────────────────────────┘     │
│                                                             │
│   Connection Name:                                          │
│   ┌───────────────────────────────────────────────────┐     │
│   │ Grzegorz Kossakowski's Luma                       │     │  ← Pre-filled after validation
│   └───────────────────────────────────────────────────┘     │
│                                                             │
│   [Get API Key ↗]  [Documentation ↗]                       │
│                                                             │
│                              [Connect]                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**State B: Connected (Event Selection)**

```
┌─────────────────────────────────────────────────────────────┐
│ Select your event                                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Search and pick one of your Luma events.                   │
│                                                             │
│ Event:                                                      │
│ ┌───────────────────────────────────────────────────────┐   │
│ │ [img] AI Tinkerers Meetup - Jan 2026              ▼ │   │  ← Image shown
│ └───────────────────────────────────────────────────────┘   │
│                                                             │
│ Copy columns from:                                          │
│ [▼ None - start fresh                                  ]    │
│                                                             │
│ ... enrichment options ...                                  │
│                                                             │
│                                    [Create Project]         │
└─────────────────────────────────────────────────────────────┘
```

**Key changes:**
- Remove the 2-column layout
- Show connection UI full-width when not connected
- Show event selection UI full-width when connected
- No left panel needed when already connected

### 7.3 Feature 3: API Key Validation

**Validation Flow:**
1. User enters API key
2. On blur or submit, call `validateLumaApiKey` procedure
3. If valid:
   - Pre-fill connection name with `"{user.name}'s Luma"` (editable)
   - Enable Connect button
4. If invalid:
   - Show error: "Invalid API key. Please check your key and try again."
   - Disable Connect button

**Integrations Page - Connection Name Field:**

```
┌─────────────────────────────────────────────────────────────┐
│ Connect Luma                                            [X] │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ API Key:                                                    │
│ ┌───────────────────────────────────────────────────────┐   │
│ │ luma-secret-...                                       │   │
│ └───────────────────────────────────────────────────────┘   │
│                                                             │
│ Connection Name:                                            │
│ ┌───────────────────────────────────────────────────────┐   │
│ │ Grzegorz Kossakowski's Luma                           │   │
│ └───────────────────────────────────────────────────────┘   │
│ A friendly name to identify this connection                 │
│                                                             │
│              [Cancel]  [Connect]                            │
└─────────────────────────────────────────────────────────────┘
```

### 7.4 Feature 4: Event Preview in Trigger

**Dropdown Trigger (when event selected):**

```
┌───────────────────────────────────────────────────────────┐
│ [48x48 img] AI Tinkerers Meetup - January 2026        ▼  │
└───────────────────────────────────────────────────────────┘
```

- Show event cover image (48x48, rounded) to the left of event name
- Use existing `cover_url` from event data
- Fallback: show no image if `cover_url` is null

---

## 8. API Routes

### 8.1 New tRPC Routes

```typescript
// apps/web/src/trpc/router/integrations.ts
integrationRouter = router({
  // ... existing routes ...

  // NEW: Validate Luma API key and get user info
  validateLumaApiKey: protectedProcedure
    .input(z.object({ apiKey: z.string().min(8) }))
    .mutation(async ({ input }) => {
      const client = new LumaClient({ apiKey: input.apiKey })
      try {
        const result = await client.getSelf()
        return {
          valid: true,
          user: result.user,
          suggestedName: `${result.user.name}'s Luma`
        }
      } catch (error) {
        return { valid: false, error: 'Invalid API key' }
      }
    }),
})
```

```typescript
// apps/web/src/trpc/router/data-sources.ts
dataSourcesRouter = router({
  // ... existing routes ...

  // NEW: List Luma projects for template selection
  listLumaProjects: protectedProcedure
    .query(async ({ ctx }) => {
      const projects = await db.query.projects.findMany({
        where: and(
          eq(projects.teamId, ctx.teamId),
          sql`metadata->>'integration' = 'luma-event'`
        ),
        columns: {
          id: true,
          title: true,
          columns: true,
          createdAt: true,
        },
        orderBy: [desc(projects.createdAt)],
      })

      return projects.map(p => ({
        id: p.id,
        title: p.title,
        columnCount: (p.columns || []).filter(c => c.id !== '_trigger').length,
        createdAt: p.createdAt,
      }))
    }),
})
```

---

## 9. Edge Cases & Error Handling

| Scenario | Handling |
|----------|----------|
| Invalid Luma API key | Show error message, disable Connect button, don't save |
| Luma API unreachable during validation | Show "Unable to validate. Please try again." with retry option |
| Selected template project was deleted | Filter out non-existent projects, show "Project not found" if selected |
| Source project has 0 copyable columns | Show project in list but indicate "(0 columns)" |
| Connection name already exists | Append number: "Grzegorz Kossakowski's Luma (2)" |
| Event has no cover image | Show no image in trigger, just the event name |

---

## 10. Security & Privacy

- **API Key Validation:** Key is only used in memory during validation, then encrypted before storage
- **No new permissions needed:** Uses existing team membership checks
- **Template access:** Users can only copy from projects within their own workspace

---

## 11. Implementation Phases

### Phase 1: Core (P0-P1)
- [ ] Add `getSelf()` method to LumaClient
- [ ] Create `validateLumaApiKey` tRPC procedure
- [ ] Update `integration-connect-dialog.tsx` to validate before save
- [ ] Add connection name field to integrations page (`integrations-content.tsx`)
- [ ] Pre-fill connection name with user's name from Luma API
- [ ] Refactor `luma-event-form.tsx` to sequential flow (remove 2-column layout)
- [ ] Create `listLumaProjects` tRPC procedure
- [ ] Add template selection dropdown to Luma event form
- [ ] Implement column copying logic (exclude `_trigger`)

### Phase 2: Polish (P2)
- [ ] Add event preview image to dropdown trigger button
- [ ] Include saved Luma templates in template dropdown (not just projects)

---

## 12. Open Questions

1. ~~Should we validate API keys before saving?~~ **Resolved: Yes, reject invalid keys**
2. ~~What format for connection name?~~ **Resolved: "{User Name}'s Luma"**
3. Should we show a preview of which columns will be copied before creating the project?

---

## 13. References

- **Luma Event Form:** `apps/web/src/components/project/create/components/luma-event-form.tsx`
- **Integration Connect Dialog:** `apps/web/src/components/integrations/integration-connect-dialog.tsx`
- **Integrations Page:** `apps/web/src/app/app/[teamSlug]/integrations/integrations-content.tsx`
- **Luma Client:** `packages/configs/src/luma/client.ts`
- **Luma Import Logic:** `apps/web/src/lib/core/sources/luma.ts`
- **Data Sources Router:** `apps/web/src/trpc/router/data-sources.ts`
- **Integrations Router:** `apps/web/src/trpc/router/integrations.ts`

---

## Appendix

### A. Luma get-self API Response

```json
{
  "user": {
    "api_id": "usr-O7dC8EGjGEEHhEb",
    "avatar_url": "https://images.lumacdn.com/avatars/...",
    "email": "grzegorz.kossakowski@gmail.com",
    "first_name": "Grzegorz",
    "last_name": "Kossakowski",
    "name": "Grzegorz Kossakowski",
    "id": "usr-O7dC8EGjGEEHhEb"
  }
}
```

### B. Column Copying Logic

When copying columns from a source Luma project:

```typescript
const sourceProject = await getProjectById(templateProjectId)
const columnsToCopy = (sourceProject.columns || [])
  .filter(col => col.id !== '_trigger')  // Exclude trigger column
  .map(col => ({
    ...col,
    id: generateColumnId(),  // Generate new IDs to avoid conflicts
  }))

// Merge with base Luma columns
const finalColumns = [
  ...buildLumaColumns().columns,    // Fresh _trigger column
  ...columnsToCopy,                 // Copied enrichment columns
  ...(addApprovalColumn ? [buildLumaGuestStatusColumn(...)] : []),
]
```

### C. Priority Summary

| Priority | Feature |
|----------|---------|
| P0 | Sequential connection flow (remove 2-column layout) |
| P0 | Template copying from existing Luma projects |
| P1 | API key validation with get-self |
| P1 | Connection name field on integrations page |
| P2 | Event preview image in dropdown trigger |
| P2 | Include saved templates in dropdown |
