# Technical Specifications - Luma Event Form Improvements

## 1. System Architecture

### Overview
This feature set enhances the existing Luma integration flow without requiring new database migrations. All changes leverage existing database structures and extend current API patterns.

### Component Diagram
```
┌─────────────────────────────────────────────────────────────────────┐
│                         Frontend (Next.js)                          │
├─────────────────────────────────────────────────────────────────────┤
│  luma-event-form.tsx          │  integration-connect-dialog.tsx     │
│  - Sequential flow UI         │  - API key validation               │
│  - Template selection         │  - Connection name field            │
│  - Event preview images       │                                     │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          tRPC Router                                │
├─────────────────────────────────────────────────────────────────────┤
│  integrations.ts              │  data-sources.ts                    │
│  - validateLumaApiKey()       │  - listLumaProjects()               │
└─────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────┐
│                          External APIs                              │
├─────────────────────────────────────────────────────────────────────┤
│  packages/configs/src/luma/client.ts                                │
│  - getSelf() → GET /user/get-self                                   │
└─────────────────────────────────────────────────────────────────────┘
```

## 2. Data Models

### Existing Types Used (No Changes Required)

```typescript
// packages/db/types/column.ts
interface ProjectMetadata {
  integration?: 'luma-event'
  luma?: {
    eventId: string
    eventName: string
    webhookEnabled: boolean
    addApprovalColumn: boolean
  }
}

interface DbColumnType {
  id: string
  label: string
  type: 'manual' | 'ai' | 'api' | 'task' | 'reference'
  // ... other configuration fields
}
```

### New Types to Add

```typescript
// packages/configs/src/luma/client.ts
interface LumaUser {
  api_id: string
  name: string
  first_name: string
  last_name: string
  email: string
  avatar_url: string
}

interface GetSelfResponse {
  user: LumaUser
}
```

## 3. API Specifications

### 3.1 LumaClient.getSelf()

**Location:** `packages/configs/src/luma/client.ts`

**HTTP Request:**
- Method: `GET`
- URL: `https://public-api.luma.com/v1/user/get-self`
- Headers: `x-luma-api-key: {apiKey}`

**Response (200 OK):**
```json
{
  "user": {
    "api_id": "usr-O7dC8EGjGEEHhEb",
    "avatar_url": "https://images.lumacdn.com/avatars/...",
    "email": "user@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "name": "John Doe"
  }
}
```

**Response (401 Unauthorized):**
- Thrown as error for invalid API keys

### 3.2 validateLumaApiKey tRPC Procedure

**Location:** `apps/web/src/trpc/router/integrations.ts`

**Input:**
```typescript
z.object({
  apiKey: z.string().min(8)
})
```

**Output (Success):**
```typescript
{
  valid: true,
  user: LumaUser,
  suggestedName: string // "{user.name}'s Luma"
}
```

**Output (Failure):**
```typescript
{
  valid: false,
  error: string // "Invalid API key"
}
```

### 3.3 listLumaProjects tRPC Procedure

**Location:** `apps/web/src/trpc/router/data-sources.ts`

**Input:** None (uses ctx.teamId)

**Output:**
```typescript
Array<{
  id: string
  title: string
  columnCount: number // Excludes _trigger column
  createdAt: Date
}>
```

**Database Query:**
```sql
SELECT id, title, columns, created_at
FROM projects
WHERE team_id = $teamId
  AND metadata->>'integration' = 'luma-event'
ORDER BY created_at DESC
```

## 4. User Interface Requirements

### 4.1 Sequential Flow Layout

**State: Not Connected**
- Full-width centered card layout
- Header: "Connect Luma" with link icon
- Description text explaining the connection
- API Key input field (required)
- Connection Name input field (pre-filled after validation)
- Help links: "Get API Key" and "Documentation"
- Connect button (disabled until validated)

**State: Connected**
- Full-width form layout
- Header: "Select your event"
- Description: "Search and pick one of your Luma events."
- Event dropdown with search
- Template selection dropdown (after event selected)
- Enrichment options checkboxes
- Create Project button

### 4.2 Template Selection Dropdown

**Structure:**
```
┌─────────────────────────────────────────┐
│ None - start fresh                      │  ← Default
├─────────────────────────────────────────┤
│ 📊 Project Title 1 (8 columns)          │
│ 📊 Project Title 2 (5 columns)          │
├─────────────────────────────────────────┤  ← Separator (Phase 2)
│ 📋 Template Name (12 columns)           │  ← Phase 2
└─────────────────────────────────────────┘
```

### 4.3 Event Preview Image

**Specifications:**
- Size: 48x48 pixels
- Border radius: rounded (8px)
- Position: Left of event name in dropdown trigger
- Fallback: No image shown (not a placeholder)
- Image source: `cover_url` from Luma event data

### 4.4 Validation UI States

**API Key Field States:**
- Default: Empty input
- Validating: Input with loading spinner
- Valid: Input with green checkmark, connection name field appears
- Invalid: Input with red border, error message below

**Error Message:**
- Text: "Invalid API key. Please check your key and try again."
- Color: Destructive/red
- Position: Below API key input

## 5. Column Copying Logic

### Implementation Details

```typescript
async function copyColumnsFromTemplate(
  templateProjectId: string,
  baseColumns: DbColumnType[],
  addApprovalColumn: boolean
): Promise<DbColumnType[]> {
  // 1. Fetch source project
  const sourceProject = await getProjectById(templateProjectId)

  // 2. Filter and remap columns
  const columnIdMap = new Map<string, string>()
  const copiedColumns = (sourceProject.columns || [])
    .filter(col => col.id !== '_trigger')
    .map(col => {
      const newId = generateColumnId()
      columnIdMap.set(col.id, newId)
      return { ...col, id: newId }
    })

  // 3. Update dependencies to use new IDs
  const updatedColumns = copiedColumns.map(col => ({
    ...col,
    dependencies: col.dependencies?.map(dep =>
      columnIdMap.get(dep) || dep
    )
  }))

  // 4. Merge with base columns
  return [
    ...baseColumns, // Fresh _trigger column
    ...updatedColumns,
    ...(addApprovalColumn ? [buildApprovalColumn()] : [])
  ]
}
```

### Edge Cases
- Source project deleted: Filter out, show toast if selected
- Source has 0 columns: Show "(0 columns)" in dropdown
- Circular dependencies: Preserve original references for external deps

## 6. Performance Requirements

### API Call Latency
- validateLumaApiKey: < 2 seconds timeout
- listLumaProjects: < 500ms for typical workspace (< 100 projects)

### UI Responsiveness
- Validation spinner appears immediately on blur
- Dropdown opens within 100ms
- Image loading should not block dropdown interaction

### Caching
- listLumaProjects: Can be cached with staleTime of 30 seconds
- validateLumaApiKey: No caching (validation must be fresh)

## 7. Security Considerations

### API Key Handling
- API keys are only used in-memory during validation
- Keys are encrypted before database storage (existing behavior)
- Keys are never logged or exposed in error messages

### Access Control
- All procedures use `protectedProcedure` (requires authentication)
- listLumaProjects respects team boundaries via `ctx.teamId`
- Users can only copy from projects in their own workspace

### Input Validation
- API key minimum length: 8 characters
- Connection name: Sanitized before storage
- Project ID for template: Validated to exist and belong to team

## 8. Error Handling

### Network Errors
- Luma API unreachable: "Unable to validate. Please try again."
- Timeout: "Connection timed out. Please check your network."

### Business Logic Errors
- Invalid API key: "Invalid API key. Please check your key and try again."
- Project not found (for template): Silent filter, toast if directly selected
- Duplicate connection name: Append number, e.g., "John's Luma (2)"

### User Feedback
- All errors displayed inline near the relevant input
- Success states indicated with checkmarks
- Loading states use consistent spinner component

## 9. Files to Modify

### Backend
| File | Changes |
|------|---------|
| `packages/configs/src/luma/client.ts` | Add `LumaUser` interface, `getSelf()` method |
| `apps/web/src/trpc/router/integrations.ts` | Add `validateLumaApiKey` procedure |
| `apps/web/src/trpc/router/data-sources.ts` | Add `listLumaProjects` procedure |

### Frontend
| File | Changes |
|------|---------|
| `apps/web/src/components/project/create/components/luma-event-form.tsx` | Sequential flow, template dropdown, event preview |
| `apps/web/src/components/integrations/integration-connect-dialog.tsx` | API key validation, connection name field |
| `apps/web/src/app/app/[teamSlug]/integrations/integrations-content.tsx` | Display/edit connection name |

## 10. Testing Requirements

### Unit Tests
- `getSelf()` returns user data for valid key
- `getSelf()` throws for invalid key
- `validateLumaApiKey` returns correct structure
- `listLumaProjects` filters correctly and calculates column count
- Column copying logic handles edge cases

### Integration Tests
- Full connection flow with valid/invalid keys
- Project creation with template selection
- Template selection with empty project list

### Manual Testing Checklist
- [ ] Connect with valid Luma API key
- [ ] Reject invalid Luma API key with error message
- [ ] Connection name pre-fills correctly
- [ ] Sequential flow shows correct state
- [ ] Template dropdown loads projects
- [ ] Creating project copies columns correctly
- [ ] Event preview image displays (Phase 2)
