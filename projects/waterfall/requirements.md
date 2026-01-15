# Technical Specifications

## System Architecture

### Overview
Waterfall Enrichment is a sequential data enrichment system that runs multiple providers in order until one succeeds. Built on existing task infrastructure with a new waterfall task type.

### Component Flow
```
User configures waterfall column
    → Column stored with WaterfallConfig in meta
    → Trigger execution enqueues job to worker
    → Worker runs waterfall-executor sequentially
    → Results distributed to child columns
    → UI reflects status per provider
```

### File Structure
```
packages/configs/src/
├── task-registry.ts              # Add waterfallEmail task
├── waterfall-registry.ts         # NEW: Provider definitions & field mappings

packages/db/types/
├── column.ts                     # Add mentionable field, WaterfallConfig types

apps/web/src/components/table/columns/
├── waterfall-settings.tsx        # NEW: Configuration UI
├── waterfall-provider-list.tsx   # NEW: Drag-drop provider list
├── task-field-settings-registry.tsx  # Add waterfallEmail case

apps/web/src/lib/table/
├── create-waterfall-column.ts    # NEW: Column creation logic

apps/workers/src/workers/row-run/
├── run-task.ts                   # Add waterfallEmail case
├── waterfall-executor.ts         # NEW: Execution logic
```

---

## Data Models

### WaterfallConfig
```typescript
interface WaterfallConfig {
  waterfallType: 'email' | 'linkedin' | 'techstack'
  providers: WaterfallProvider[]
  inputMapping: WaterfallInputMapping
}

interface WaterfallProvider {
  id: string                    // Unique ID for this provider instance
  taskType: string              // e.g., 'findymailFindByName', 'hunterFindEmail'
  enabled: boolean              // Toggle without removing
  order: number                 // Execution order (0 = first)
  fieldMapping: Record<string, string>  // Future: custom field overrides
}

interface WaterfallInputMapping {
  first_name?: string           // Column reference: '@{col_xyz}'
  last_name?: string
  full_name?: string
  domain?: string
}
```

### Column Meta Extension
```typescript
interface ColumnMeta {
  // Existing fields...
  mentionable?: boolean         // NEW: false = excluded from column references
  taskConfig?: {
    taskType: string
    waterfallEmail?: WaterfallConfig
  }
}
```

### Waterfall Result
```typescript
interface WaterfallResult {
  result: string | null           // Final email (goes to result child)
  successfulProvider: string | null
  providerResults: Record<string, ProviderResult>
  usage: { tokens: number }
}

interface ProviderResult {
  status: 'complete' | 'skipped' | 'error'
  value: any                      // Raw provider response
  success?: boolean               // True if email found
  message?: string                // Error or skip reason
}
```

---

## API Specifications

### No New tRPC Routes Required
Waterfall uses existing infrastructure:
- Column CRUD: Existing project column mutations
- Task execution: Existing row-run worker queue
- Configuration: Stored in column meta

### Worker Job Processing
Existing `RowRunJobData` structure is sufficient. Waterfall-specific logic handled in `run-task.ts` via `waterfallEmail` case.

---

## Provider Field Mapping

### Standard Fields → Provider Fields

| Standard Field | Findymail (findByName) | Hunter (findEmail) |
|---------------|------------------------|-------------------|
| `first_name` | Combined into `name` | `first_name` |
| `last_name` | Combined into `name` | `last_name` |
| `full_name` | `name` | Split to first/last |
| `domain` | `domain` | `domain` |

### Transformation Rules
- **full_name → first/last**: Split on first space. "John Doe" → first:"John", last:"Doe"
- **first/last → full_name**: Join with space. first:"John", last:"Doe" → "John Doe"

---

## User Interface Requirements

### Configuration Panel
- **Input Fields Section**: Column reference inputs for first_name, last_name, full_name, domain
- **Providers Section**: Drag-drop sortable list with enable/disable toggles
- **Cost Display**: Show estimated cost range based on selected providers

### Provider List Item
- Drag handle for reordering
- Checkbox for enable/disable
- Provider name and cost
- Connection status indicator (warning if API key not configured)

### Data Grid Display
- Parent column: "Email (Waterfall)" with expandable children
- Result child: Shows found email or empty
- Provider children: Show individual results, "(skipped)", or "(not found)"

---

## Execution Logic

### Waterfall Flow
1. Resolve input values from column references
2. Sort enabled providers by order
3. For each provider:
   - If previous provider succeeded: mark as 'skipped', continue
   - Map standard inputs to provider-specific fields
   - Execute provider task
   - Extract email from response
   - If valid email found: set as success, continue (remaining will be skipped)
   - If error: log error, continue to next provider
4. Return results distributed to child columns

### Success Criteria
Email is considered "found" if:
- Provider returns non-null email value
- Email passes basic format validation (contains @ and .)

---

## Error Handling

| Scenario | Handling |
|----------|----------|
| All providers return no email | Result: empty, status: complete |
| Provider API key missing | Provider errors with message, continues to next |
| Provider API error (rate limit, timeout) | Mark error, continue to next |
| All providers error | Result status: error with aggregated message |
| Missing required input (no domain) | Fail validation before execution |
| No enabled providers | Fail validation: "At least one provider required" |

---

## Security

- **API Keys**: Stored in team integrations, never exposed to client
- **Authorization**: Team-scoped, uses existing integration security model
- **Data Storage**: Results stored in project cells per existing data policies

---

## Performance

- **Sequential Execution**: Providers run one at a time (by design)
- **Early Termination**: Stops immediately on first success
- **Cost Optimization**: No unnecessary API calls after success
- **Provider Timeout**: Individual provider calls respect existing task timeouts

---

## Available Providers (MVP)

| Provider | Task Type | Cost | Required Input |
|----------|-----------|------|----------------|
| Findymail (Name) | findymailFindByName | 20,000 tokens | name, domain |
| Findymail (LinkedIn) | findymailFindByBusinessProfile | 20,000 tokens | linkedin_url |
| Hunter | hunterFindEmail | 0 (own key) | first_name, last_name, domain |
