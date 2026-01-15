# Waterfall Enrichment - Product Requirements Document

**Version:** 1.0  
**Date:** 2026-01-12  
**Status:** Draft  
**Author:** Kamil / Claude

---

## 1. Executive Summary

Waterfall Enrichment is a sequential data enrichment feature that allows users to try multiple providers in order until one succeeds. The primary use case is finding email addresses for contacts/leads, where users can configure multiple email-finding providers (e.g., Findymail, Hunter) in a specific order. The system runs providers sequentially—if the first provider returns a valid result, it stops; otherwise, it tries the next provider, and so on.

This feature is inspired by platforms like Clay.com and addresses the common need to maximize enrichment success rates by leveraging multiple data sources while minimizing unnecessary API calls and costs.

---

## 2. Goals & Success Metrics

### Goals
- Allow users to configure multiple enrichment providers in a preferred order
- Maximize email find rates by cascading through providers until success
- Minimize costs by stopping execution once a valid result is found
- Provide transparency into which provider succeeded and which were tried/skipped
- Create a generic waterfall system that can be extended to other enrichment types (LinkedIn URLs, tech stacks, etc.)

### Success Metrics (Future)
- Increase in overall email find rate compared to single-provider usage
- Reduction in average cost per successful enrichment
- User adoption rate of waterfall vs single-provider columns

---

## 3. User Personas

1. **Sales/Growth Teams** - Need to find verified emails for outreach campaigns; want high find rates without manually trying multiple tools
2. **Data Operations** - Building enrichment pipelines; need reliable, cost-effective data enrichment with fallback options

---

## 4. Feature Scope

### 4.1 MVP (Phase 1) - Email Waterfall

**Priority: HIGHEST**

Core waterfall functionality for email finding with existing providers.

| Feature | Description | Priority |
|---------|-------------|----------|
| Waterfall Task Type | New task type "Waterfall Email Finder" in the task registry | P0 |
| Provider Selection UI | Drag-and-drop interface to select and order providers | P0 |
| Standard Input Fields | Unified input mapping: `first_name`, `last_name`, `full_name`, `domain` | P0 |
| Sequential Execution | Run providers in order, stop on first success | P0 |
| Result Column | Parent column showing the final found email | P0 |
| Provider Child Columns | One child column per configured provider showing individual results | P0 |
| Mentionability Control | Only result column is mentionable by other columns | P0 |
| Provider Cost Display | Show cost/credits next to each provider in selection UI | P0 |

### 4.2 Phase 2 - Enhancements

**Priority: HIGH**

| Feature | Description | Priority |
|---------|-------------|----------|
| Provider Statistics | Show success rates per provider over time | P1 |
| Smart Ordering Suggestions | Suggest optimal provider order based on historical data | P1 |
| Conditional Provider Logic | Skip providers based on input data (e.g., skip if no domain) | P1 |

### 4.3 Phase 3 - Extended Waterfall Types

**Priority: MEDIUM**

| Feature | Description | Priority |
|---------|-------------|----------|
| LinkedIn URL Waterfall | Find LinkedIn profile URLs via multiple providers | P2 |
| Tech Stack Waterfall | Find company tech stack via multiple providers | P2 |
| Generic Waterfall Framework | Allow custom waterfall configurations for any provider category | P2 |

---

## 5. Data Model

### 5.1 Column Structure

Waterfall columns use the existing parent-child column structure:

```
Waterfall Column (Parent - dataShape: 'group')
├── Result (Child - the aggregated successful result)
├── Provider 1 (Child - e.g., Findymail result)
├── Provider 2 (Child - e.g., Hunter result)
└── Provider N (Child - additional providers)
```

### 5.2 New Types/Schemas

```typescript
// Waterfall configuration stored in column meta
interface WaterfallConfig {
  waterfallType: 'email' | 'linkedin' | 'techstack' // extensible
  providers: WaterfallProvider[]
  inputMapping: WaterfallInputMapping
}

interface WaterfallProvider {
  id: string                    // e.g., 'findymailFindByName', 'hunterFindEmail'
  taskType: string              // Reference to task registry
  enabled: boolean              // Can toggle on/off without removing
  order: number                 // Execution order (0 = first)
  fieldMapping: Record<string, string>  // Maps standard fields to provider fields
}

interface WaterfallInputMapping {
  // Standard fields that user configures once
  first_name?: string    // Column reference or literal, e.g., '@{first_name_col}'
  last_name?: string     
  full_name?: string     // Alternative to first_name + last_name
  domain?: string        
}

// Standard field definitions for email waterfall
const EMAIL_WATERFALL_STANDARD_FIELDS = {
  first_name: { label: 'First Name', required: false },
  last_name: { label: 'Last Name', required: false },
  full_name: { label: 'Full Name', required: false, description: 'Used if first/last not provided' },
  domain: { label: 'Domain', required: true },
}
```

### 5.3 Provider Field Mapping

Each provider has different field requirements. The waterfall system maps standard fields to provider-specific fields:

| Standard Field | Findymail (findByName) | Hunter (findEmail) |
|---------------|------------------------|-------------------|
| `first_name` | (combined into `name`) | `first_name` |
| `last_name` | (combined into `name`) | `last_name` |
| `full_name` | `name` | (split into first/last) |
| `domain` | `domain` | `domain` |

**Mapping Logic:**
- If user provides `full_name` but provider needs `first_name`/`last_name`: auto-split on first space
- If user provides `first_name` + `last_name` but provider needs `full_name`: auto-join with space
- These transformations happen at execution time in the worker

### 5.4 Result Data Shape

```typescript
// Result column stores just the email (dataShape: 'email' or 'text')
type WaterfallResultValue = string  // e.g., "john@company.com"

// Provider columns store their native response format
// Status indicates outcome:
// - 'complete' with value: found email
// - 'complete' with empty: not found
// - 'skipped': earlier provider succeeded
// - 'error': provider failed (API error, not connected, etc.)
```

### 5.5 Column Meta Structure

```typescript
// Parent waterfall column meta
interface WaterfallColumnMeta {
  type: 'task'
  dataShape: 'group'
  taskConfig: {
    taskType: 'waterfallEmail'  // or future: 'waterfallLinkedin', etc.
    waterfallEmail: WaterfallConfig
  }
  children: WaterfallChildColumn[]
  // Dependencies point to INPUT fields, not provider columns
  dependencies: ColumnDependency[]  
}

// Child columns are auto-generated based on provider configuration
interface WaterfallChildColumn {
  id: string
  header: string
  meta: {
    type: 'task'
    dataShape: 'email' | 'text' | provider-specific-shape
    key: string  // 'result' | provider-id
    // Result column: mentionable = true (default)
    // Provider columns: mentionable = false
    mentionable?: boolean
  }
}
```

---

## 6. Technical Architecture

### 6.1 Task Registry Entry

```typescript
// packages/configs/src/task-registry.ts

waterfallEmail: defineTask({
  id: 'waterfallEmail',
  label: 'Waterfall Email Finder',
  description: 'Find emails using multiple providers in sequence until one succeeds.',
  provider: 'fluar',  // Internal task, not tied to single provider
  defaultHeader: 'Email (Waterfall)',
  fieldType: 'text',
  dataShape: 'group',  // Parent is a group with children
  configSchema: z.object({
    providers: z.array(z.object({
      id: z.string(),
      taskType: z.string(),
      enabled: z.boolean(),
      order: z.number(),
    })),
    inputMapping: z.object({
      first_name: z.string().optional(),
      last_name: z.string().optional(),
      full_name: z.string().optional(),
      domain: z.string().optional(),
    }),
  }),
  uiFields: [], // Custom UI component handles provider selection
  validate: (config) => {
    if (!config.providers?.length) {
      return { isValid: false, error: 'At least one provider must be selected.' }
    }
    if (!config.inputMapping?.domain) {
      return { isValid: false, error: 'Domain field is required.' }
    }
    // Must have either full_name OR (first_name AND last_name)
    const hasFullName = !!config.inputMapping?.full_name
    const hasFirstLast = !!config.inputMapping?.first_name && !!config.inputMapping?.last_name
    if (!hasFullName && !hasFirstLast) {
      return { isValid: false, error: 'Either full name or first + last name is required.' }
    }
    return { isValid: true }
  },
  getDefaultConfig: () => ({
    providers: [],
    inputMapping: {
      first_name: '',
      last_name: '',
      full_name: '',
      domain: '',
    },
  }),
  cost: {
    type: 'dynamic',
    range: { min: 0, max: 40000 },  // Depends on which providers run
    description: 'Cost varies based on which providers are called.',
  },
})
```

### 6.2 Worker Execution Logic

```typescript
// apps/workers/src/workers/row-run/run-task.ts

async function runWaterfallEmail(
  config: WaterfallConfig,
  columnValues: Record<string, any>,
  teamId: string,
  projectId: string
): Promise<WaterfallResult> {
  const { providers, inputMapping } = config
  
  // Resolve input values from column references
  const inputs = resolveInputMapping(inputMapping, columnValues)
  
  // Sort providers by order
  const sortedProviders = [...providers]
    .filter(p => p.enabled)
    .sort((a, b) => a.order - b.order)
  
  const results: Record<string, ProviderResult> = {}
  let successfulEmail: string | null = null
  let successfulProvider: string | null = null
  
  for (const provider of sortedProviders) {
    if (successfulEmail) {
      // Mark remaining providers as skipped
      results[provider.id] = { 
        status: 'skipped', 
        value: null,
        message: 'Skipped - earlier provider succeeded'
      }
      continue
    }
    
    try {
      // Map standard inputs to provider-specific fields
      const providerInputs = mapInputsToProvider(inputs, provider.taskType)
      
      // Run the provider's task
      const result = await runProviderTask(provider.taskType, providerInputs, teamId, projectId)
      
      // Check if we got a valid email
      const email = extractEmailFromResult(result, provider.taskType)
      
      if (email && isValidEmail(email)) {
        successfulEmail = email
        successfulProvider = provider.id
        results[provider.id] = {
          status: 'complete',
          value: result,
          success: true
        }
      } else {
        results[provider.id] = {
          status: 'complete',
          value: result,
          success: false,
          message: 'No email found'
        }
      }
    } catch (error) {
      results[provider.id] = {
        status: 'error',
        value: null,
        success: false,
        message: error.message
      }
    }
  }
  
  return {
    result: successfulEmail,  // Goes into result child column
    successfulProvider,
    providerResults: results,  // Goes into individual provider columns
    usage: { tokens: calculateTotalTokens(results) }
  }
}

// Helper to extract email from different provider response formats
function extractEmailFromResult(result: any, taskType: string): string | null {
  switch (taskType) {
    case 'findymailFindByName':
      return result?.contact?.email || result?.email || null
    case 'hunterFindEmail':
      return result?.data?.email || result?.email || null
    // Add more providers as needed
    default:
      return result?.email || null
  }
}
```

### 6.3 Column Creation Logic

When a user creates a waterfall column, child columns are auto-generated:

```typescript
// apps/web/src/lib/table/create-waterfall-column.ts

function createWaterfallColumn(config: WaterfallConfig): DbColumnType {
  const children: DbColumnType[] = []
  
  // Create result column (always first child)
  children.push({
    id: generateColumnId(),
    header: 'Email',
    meta: {
      type: 'task',
      dataShape: 'email',
      key: 'result',
      mentionable: true,  // Only this child is mentionable
    }
  })
  
  // Create provider columns
  for (const provider of config.providers) {
    const taskDef = getTaskConfig(provider.taskType)
    children.push({
      id: generateColumnId(),
      header: taskDef?.label || provider.taskType,
      meta: {
        type: 'task',
        dataShape: taskDef?.dataShape || 'text',
        key: provider.id,
        mentionable: false,  // Provider columns not mentionable
      }
    })
  }
  
  return {
    id: generateColumnId(),
    header: 'Email (Waterfall)',
    meta: {
      type: 'task',
      dataShape: 'group',
      taskConfig: {
        taskType: 'waterfallEmail',
        waterfallEmail: config,
      },
      children,
      dependencies: extractDependenciesFromInputMapping(config.inputMapping),
    }
  }
}
```

### 6.4 Mentionability Control

Modify `useUsableLeafColumns` to respect the `mentionable` flag:

```typescript
// In grid-store.ts or wherever usableLeafColumns is populated

// When building usableLeafColumns, filter out non-mentionable children
const usableLeafColumns = allLeafColumns.filter(col => {
  // If column has explicit mentionable: false, exclude it
  if (col.meta?.mentionable === false) {
    return false
  }
  return true
})
```

### 6.5 Available Email Providers (MVP)

| Provider ID | Task Type | Required Fields | Cost |
|------------|-----------|-----------------|------|
| findymail-name | `findymailFindByName` | `name`, `domain` | 20,000 tokens (fallback) / 0 (own key) |
| findymail-linkedin | `findymailFindByBusinessProfile` | `linkedin_url` | 20,000 tokens (fallback) / 0 (own key) |
| hunter | `hunterFindEmail` | `first_name`, `last_name`, `domain` | 0 (requires own key) |

### 6.6 File Structure

```
packages/configs/src/
├── task-registry.ts              # Add waterfallEmail task
├── waterfall-registry.ts         # NEW: Waterfall type definitions & provider mappings

apps/web/src/components/table/columns/
├── waterfall-settings.tsx        # NEW: Waterfall configuration UI
├── waterfall-provider-list.tsx   # NEW: Drag-drop provider list component
├── task-field-settings-registry.tsx  # Add waterfallEmail case

apps/workers/src/workers/row-run/
├── run-task.ts                   # Add runWaterfallEmail function
├── waterfall-executor.ts         # NEW: Waterfall execution logic

packages/db/types/
├── column.ts                     # Add mentionable field to meta schema
```

---

## 7. User Interface

### 7.1 Access Point

- **Task Type Selection**: User selects "Waterfall Email Finder" from the task type dropdown when creating/editing a column
- **Column Settings Panel**: Configuration UI appears in the existing column settings sidebar

### 7.2 UI Wireframes

**Task Type Selection:**
```
┌─────────────────────────────────────────────────────────────┐
│ Tool Type                                                   │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 🔍 Search tools...                                      │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ 📧 Waterfall Email Finder                    ★ NEW         │
│    Find emails using multiple providers in sequence         │
│                                                             │
│ 📧 Findymail Find From Name                                │
│ 📧 Hunter Find Email                                       │
│ 🔗 LinkedIn Profile Scraper                                │
│ ...                                                         │
└─────────────────────────────────────────────────────────────┘
```

**Waterfall Configuration Panel:**
```
┌─────────────────────────────────────────────────────────────┐
│ Waterfall Email Finder                                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ INPUT FIELDS                                                │
│ ─────────────────────────────────────────────────────────── │
│                                                             │
│ First Name                        Last Name                 │
│ ┌──────────────────────┐          ┌──────────────────────┐  │
│ │ @{first_name}        │          │ @{last_name}         │  │
│ └──────────────────────┘          └──────────────────────┘  │
│                                                             │
│ Full Name (alternative)                                     │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ @{full_name}                                            │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ℹ️ Used if first/last name not provided                     │
│                                                             │
│ Domain *                                                    │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ @{company_domain}                                       │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ PROVIDERS (drag to reorder)                                 │
│ ─────────────────────────────────────────────────────────── │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ ≡  ☑️ Findymail Find From Name          20,000 credits  │ │
│ │     Uses your key: ••••ABC                              │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ ≡  ☑️ Hunter Find Email                      0 credits  │ │
│ │     ⚠️ Not connected - will fail at runtime             │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ [+ Add Provider]                                            │
│                                                             │
│ ─────────────────────────────────────────────────────────── │
│ Estimated cost: 0 - 20,000 credits per row                  │
│ (stops after first successful find)                         │
└─────────────────────────────────────────────────────────────┘
```

**Provider Selection Dropdown:**
```
┌─────────────────────────────────────────────────────────────┐
│ Add Provider                                           [X]  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ EMAIL PROVIDERS                                             │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 📧 Findymail Find From Name              20,000 cr      │ │
│ │    Find email from full name + domain                   │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 📧 Findymail From LinkedIn               20,000 cr      │ │
│ │    Find email from LinkedIn profile URL                 │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 📧 Hunter Find Email                          0 cr      │ │
│ │    Find email from first/last name + domain             │ │
│ │    ⚠️ Requires Hunter integration                       │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Data Grid - Column Headers:**
```
┌──────────────────────────────────────────────────────────────────────────────┐
│ ... │ Email (Waterfall)                                                      │
│     ├──────────────────┬──────────────────────┬──────────────────────────────┤
│     │ Email            │ Findymail            │ Hunter                       │
│     │ (Result)         │                      │                              │
├─────┼──────────────────┼──────────────────────┼──────────────────────────────┤
│  1  │ john@acme.com    │ john@acme.com        │ (skipped)                    │
│  2  │ jane@corp.io     │ (not found)          │ jane@corp.io                 │
│  3  │ —                │ (not found)          │ (not found)                  │
│  4  │ ⏳               │ ⏳ running...        │                              │
└─────┴──────────────────┴──────────────────────┴──────────────────────────────┘
```

---

## 8. API Routes

### 8.1 No New tRPC Routes Required

The waterfall execution uses existing task infrastructure:
- Column creation/update via existing project column mutations
- Task execution via existing row-run worker
- Provider configuration stored in column meta

### 8.2 Worker Job Data

```typescript
// Existing RowRunJobData structure is sufficient
// Waterfall logic is handled within run-task.ts
```

---

## 9. Edge Cases & Error Handling

| Scenario | Handling |
|----------|----------|
| All providers fail to find email | Result column shows empty, status: 'complete'. Individual provider columns show their respective "not found" messages |
| Provider integration not connected | Provider runs and fails with error message "Missing X API key. Please add it in Integrations." |
| Provider API error (rate limit, timeout) | Mark that provider as 'error', continue to next provider |
| All providers error (no "not found", all errors) | Result column status: 'error' with aggregated error message |
| Missing required input (no domain) | Fail at validation, don't run any providers |
| Only full_name provided but provider needs first/last | Auto-split full_name on first space |
| Only first/last provided but provider needs full_name | Auto-join with space |
| User disables all providers | Validation error: "At least one provider must be enabled" |
| Duplicate provider added | Allow it (user might want same provider with different field mappings in future) |
| Column depending on waterfall result | Normal dependency handling - waits for waterfall to complete |

---

## 10. Security & Privacy

- **Authentication**: Uses existing team-based API key storage for providers
- **Authorization**: Provider credentials are team-scoped, same as existing integrations
- **Data Privacy**: Email results stored in project cells, subject to existing data retention policies
- **API Key Security**: Provider API keys never exposed to client, only used server-side in workers

---

## 11. Implementation Phases

### Phase 1: MVP (Target: 3-5 days)
- [ ] Add `waterfallEmail` task to task registry
- [ ] Create waterfall configuration schema and types
- [ ] Implement waterfall settings UI component
- [ ] Implement provider list with drag-drop reordering
- [ ] Add `mentionable` field to column meta schema
- [ ] Filter non-mentionable columns from `usableLeafColumns`
- [ ] Implement waterfall execution logic in worker
- [ ] Implement input field mapping (standard → provider-specific)
- [ ] Implement success detection (check if email returned)
- [ ] Handle result distribution to child columns
- [ ] Add provider cost display in UI
- [ ] Test with Findymail + Hunter providers

### Phase 2: Polish
- [ ] Add provider connection status indicators
- [ ] Improve error messages for common failures
- [ ] Add execution summary in cell metadata
- [ ] Documentation

### Phase 3: Extensions (Future)
- [ ] LinkedIn URL waterfall
- [ ] Tech stack waterfall
- [ ] Provider success rate analytics
- [ ] Smart provider ordering suggestions

---

## 12. Open Questions

1. ~~What constitutes a "successful" provider result?~~ **Answered: Valid email returned**
2. ~~How should standard fields map to provider-specific fields?~~ **Answered: Auto-transform names**
3. ~~Should provider columns be mentionable?~~ **Answered: No, only result column**
4. Should we persist which provider succeeded in cell metadata for analytics?
5. Should we support "best of" mode (run all providers, pick best result by confidence)?
6. Should waterfall support conditional provider selection based on input data?

---

## 13. References

- [Clay.com Waterfall Feature](https://www.clay.com/) - Competitor reference
- [Task Registry](../../../packages/configs/src/task-registry.ts) - Existing task definitions
- [Provider Registry](../../../packages/configs/src/provider-registry.ts) - Provider configurations
- [Row Run Worker](../../../apps/workers/src/workers/row-run/row-run.worker.ts) - Execution engine
- [Column Types](../../../packages/db/types/column.ts) - Column meta schema

---

## Appendix

### A. Provider Response Examples

**Findymail Find By Name - Success:**
```json
{
  "contact": {
    "email": "john.doe@acme.com",
    "first_name": "John",
    "last_name": "Doe",
    "confidence": 95
  }
}
```

**Findymail Find By Name - Not Found:**
```json
{
  "contact": null,
  "message": "No email found for this contact"
}
```

**Hunter Find Email - Success:**
```json
{
  "data": {
    "email": "john.doe@acme.com",
    "score": 85,
    "first_name": "John",
    "last_name": "Doe",
    "position": "CEO"
  }
}
```

**Hunter Find Email - Not Found:**
```json
{
  "data": null,
  "errors": [
    { "details": "No email found for this person" }
  ]
}
```

### B. Standard Fields for Different Waterfall Types

**Email Waterfall (MVP):**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `first_name` | string | conditional | First name (required if no full_name) |
| `last_name` | string | conditional | Last name (required if no full_name) |
| `full_name` | string | conditional | Full name (required if no first/last) |
| `domain` | string | required | Company email domain |

**LinkedIn URL Waterfall (Future):**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `first_name` | string | conditional | First name |
| `last_name` | string | conditional | Last name |
| `full_name` | string | conditional | Full name |
| `company_name` | string | optional | Company name for disambiguation |

**Tech Stack Waterfall (Future):**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `domain` | string | required | Company website domain |
| `company_name` | string | optional | Company name |

### C. Waterfall Execution Flowchart

```
                    ┌─────────────────┐
                    │  Start Waterfall │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Resolve Inputs   │
                    │ (column values)  │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │ Get Sorted       │
                    │ Enabled Providers│
                    └────────┬────────┘
                             │
              ┌──────────────▼──────────────┐
              │     For each provider        │
              └──────────────┬──────────────┘
                             │
                    ┌────────▼────────┐
         ┌─────────│ Already have     │──────────┐
         │   No    │ successful email?│   Yes    │
         │         └─────────────────┘          │
         │                                       │
┌────────▼────────┐                    ┌────────▼────────┐
│ Map inputs to    │                    │ Mark provider    │
│ provider format  │                    │ as 'skipped'     │
└────────┬────────┘                    └────────┬────────┘
         │                                       │
┌────────▼────────┐                              │
│ Run provider     │                              │
│ task             │                              │
└────────┬────────┘                              │
         │                                       │
┌────────▼────────┐                              │
│ Extract email    │                              │
│ from response    │                              │
└────────┬────────┘                              │
         │                                       │
    ┌────▼────┐                                  │
    │ Valid    │                                  │
    │ email?   │                                  │
    └────┬────┘                                  │
    Yes  │  No                                   │
    ┌────┘  └────┐                               │
    │            │                               │
┌───▼───┐  ┌────▼────┐                           │
│Set as  │  │Mark as   │                          │
│success │  │not found │                          │
└───┬───┘  └────┬────┘                           │
    │           │                                │
    └─────┬─────┘                                │
          │                                      │
          └──────────────┬───────────────────────┘
                         │
              ┌──────────▼──────────┐
              │   More providers?    │
              └──────────┬──────────┘
                    No   │   Yes
                    ┌────┘   └────────────┐
                    │                      │
           ┌────────▼────────┐            │
           │ Return results   │     (loop back)
           │ to child columns │
           └─────────────────┘
```
