# Integration Connection UI Consistency - Product Requirements Document

**Version:** 1.0
**Date:** 2026-01-12
**Status:** Draft
**Author:** Claude (with Kamil)

---

## 1. Executive Summary

This PRD addresses inconsistencies in how users connect third-party integrations across the Fluar application. Currently, the connection flow differs between the Luma Event Form, Column Settings, and Integrations Page. This creates a fragmented user experience and maintenance burden.

**Goals:**
1. Unify the "not connected" UI across all places using `IntegrationConnectInline`
2. Unify the connection form/dialog using `IntegrationConnectDialog`
3. Improve Luma API key validation with smarter trigger conditions
4. Ensure connection name is always captured and visible

---

## 2. Current State Analysis

### 2.1 Three Places Where Integration Connection Happens

| Location | Component | Current Behavior |
|----------|-----------|------------------|
| **Luma Event Form** (`luma-event-form.tsx`) | Custom inline form | Shows full form with API key + connection name fields directly in the UI |
| **Column Settings** (`task-field-settings-registry.tsx`) | `IntegrationConnectInline` + `IntegrationConnectDialog` | Shows "Link your {Provider} account" button → Opens dialog |
| **Integrations Page** (`integrations-content.tsx`) | `IntegrationAuthDialog` (different!) | Opens dialog with only API key field, no connection name, no Luma validation |

### 2.2 Problems

1. **Visual Inconsistency**: Luma Event Form shows a full inline form; Column Settings shows a button
2. **Form Inconsistency**: Integrations Page uses `IntegrationAuthDialog` which lacks:
   - Connection name field
   - Luma API key validation
   - Auto-population of connection name from API response
3. **Code Duplication**: Connection logic duplicated in `luma-event-form.tsx`
4. **Maintenance Burden**: Three different implementations to keep in sync

---

## 3. Target State

### 3.1 Unified Components

All integration connection flows will use:

| Component | Purpose |
|-----------|---------|
| `IntegrationConnectInline` | "Not connected" state UI - shows logos + connect button |
| `IntegrationConnectDialog` | Connection form dialog - API key + connection name + validation |

### 3.2 Component Usage Matrix

| Location | Not Connected State | Connection Form |
|----------|---------------------|-----------------|
| Luma Event Form | `IntegrationConnectInline` | `IntegrationConnectDialog` |
| Column Settings | `IntegrationConnectInline` ✓ (already) | `IntegrationConnectDialog` ✓ (already) |
| Integrations Page | N/A (shows "Connect" button in card) | `IntegrationConnectDialog` (replaces `IntegrationAuthDialog`) |

---

## 4. Detailed Requirements

### 4.1 Luma Event Form Changes

**File:** `apps/web/src/components/project/create/components/luma-event-form.tsx`

**Current Behavior:**
- When `!isConnected`, renders a custom 260-line inline form with API key and connection name fields

**New Behavior:**
- When `!isConnected`, render `IntegrationConnectInline` with a "Connect" button
- On button click, open `IntegrationConnectDialog`
- On successful connection, automatically transition to event selection UI (no manual refresh needed)
- Remove the custom inline form code (~90 lines of JSX)

**Visual Mockup - Not Connected State:**

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│              [Fluar logo] ⇄ [Luma logo]                    │
│                                                             │
│           Link your Luma account                            │
│     Connect to import event guests into your project        │
│                                                             │
│                  [Connect Luma]                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Note:** The text should be customized for the Luma Event Form context:
- Title: "Link your Luma account"
- Subtitle: "Connect to import event guests into your project" (not "Connect to configure this column")

**Implementation:**

```tsx
// When not connected
if (!isConnected) {
  return (
    <div className="flex min-h-[400px] items-center justify-center p-6">
      <IntegrationConnectInline
        integrationId="luma"
        onConnect={() => setConnectDialogOpen(true)}
        subtitle="Connect to import event guests into your project"
      />
      <IntegrationConnectDialog
        open={connectDialogOpen}
        onOpenChange={setConnectDialogOpen}
        integrationId="luma"
        onSuccess={() => {
          refetch() // Refresh connection state
        }}
      />
    </div>
  )
}
```

### 4.2 IntegrationConnectInline Enhancement

**File:** `apps/web/src/components/integrations/integration-connect-inline.tsx`

**Change:** Add optional `subtitle` prop to allow context-specific text.

**Current:**
```tsx
<p className="text-sm text-muted-foreground">Connect to configure this column</p>
```

**New:**
```tsx
interface IntegrationConnectInlineProps {
  integrationId: string
  onConnect: () => void
  subtitle?: string  // NEW
}

// In component:
<p className="text-sm text-muted-foreground">
  {subtitle ?? 'Connect to configure this column'}
</p>
```

### 4.3 Integrations Page Changes

**File:** `apps/web/src/app/app/[teamSlug]/integrations/integrations-content.tsx`

**Current Behavior:**
- Uses `IntegrationAuthDialog` component (defined inline in the same file)
- Dialog only has API key field
- No connection name input
- No Luma API key validation

**New Behavior:**
- Replace `IntegrationAuthDialog` with `IntegrationConnectDialog`
- Remove the inline `IntegrationAuthDialog` component (~100 lines)
- Connection name field will now be available
- Luma API key validation will work automatically

**Implementation:**

```diff
- import { IntegrationAuthDialog } from './IntegrationAuthDialog' // inline component
+ import { IntegrationConnectDialog } from '@/components/integrations/integration-connect-dialog'

// In render:
- <IntegrationAuthDialog
-   open={dialogOpen}
-   onOpenChange={...}
-   integration={activeIntegration}
-   provider={activeProvider}
-   apiKey={apiKey}
-   onApiKeyChange={setApiKey}
-   onSubmit={handleSaveConnection}
-   isSaving={saveConnection.isPending}
- />
+ <IntegrationConnectDialog
+   open={dialogOpen}
+   onOpenChange={(open) => {
+     setDialogOpen(open)
+     if (!open) setActiveIntegrationId(null)
+   }}
+   integrationId={activeIntegrationId}
+   onSuccess={() => {
+     integrationsQuery.refetch()
+   }}
+ />
```

**Cleanup:**
- Remove `handleSaveConnection` function (connection logic moves to dialog)
- Remove `apiKey` state (managed by dialog)
- Remove `IntegrationAuthDialog` component definition

### 4.4 Luma API Key Validation Improvements

**File:** `apps/web/src/components/integrations/integration-connect-dialog.tsx`

**Current Behavior:**
- Validates on blur only

**New Behavior:**
- Validate on blur (existing)
- Validate immediately when exactly 32 characters entered
- Validate on paste

**Implementation:**

```tsx
const LUMA_API_KEY_LENGTH = 32

// Handle API key change
const handleApiKeyChange = (value: string) => {
  setApiKey(value)
  
  if (isLuma) {
    // Reset validation state on change
    if (validationState !== 'idle') {
      setValidationState('idle')
      setValidationError(null)
    }
    
    // Trigger validation when exactly 32 chars
    if (value.trim().length === LUMA_API_KEY_LENGTH) {
      validateApiKey(value.trim())
    }
  }
}

// Handle paste event
const handleApiKeyPaste = (e: React.ClipboardEvent<HTMLInputElement>) => {
  if (!isLuma) return
  
  const pastedText = e.clipboardData.getData('text')
  const newValue = pastedText.trim()
  
  // If pasting a complete key, validate immediately
  if (newValue.length >= 8) {
    // Let the onChange handle the value update, then validate
    setTimeout(() => {
      validateApiKey(newValue)
    }, 0)
  }
}

// Extract validation logic to reusable function
const validateApiKey = async (key: string) => {
  if (!isLuma || key.length < 8) return
  
  setValidationState('validating')
  setValidationError(null)
  
  try {
    const result = await validateLumaApiKey.mutateAsync({ apiKey: key })
    if (result.valid) {
      setValidationState('valid')
      if (!connectionName || connectionName === `${provider?.name} Account`) {
        setConnectionName(result.suggestedName)
      }
    } else {
      setValidationState('invalid')
      setValidationError('Invalid API key. Please check your key and try again.')
    }
  } catch {
    setValidationState('invalid')
    setValidationError('Unable to validate. Please try again.')
  }
}

// In the Input component:
<Input
  ...
  onChange={(e) => handleApiKeyChange(e.target.value)}
  onBlur={handleApiKeyBlur}
  onPaste={handleApiKeyPaste}  // NEW
/>
```

### 4.5 Connection Name Auto-Population

**Current Behavior (Luma only):**
- Luma validates API key and gets user profile
- Pre-fills connection name with `"{user.name}'s Luma"`

**New Behavior (All Integrations):**
- Luma: Keep current behavior (validate + auto-populate from API)
- Other integrations: Default connection name to `"{Provider} Account"`

This is already implemented in `IntegrationConnectDialog`:

```tsx
useEffect(() => {
  if (open && provider) {
    setConnectionName(`${provider.name} Account`)
  }
}, [open, provider])
```

No changes needed for this requirement.

---

## 5. Files to Modify

| File | Changes |
|------|---------|
| `apps/web/src/components/project/create/components/luma-event-form.tsx` | Replace inline form with `IntegrationConnectInline` + `IntegrationConnectDialog` |
| `apps/web/src/components/integrations/integration-connect-inline.tsx` | Add optional `subtitle` prop |
| `apps/web/src/components/integrations/integration-connect-dialog.tsx` | Add paste handler + exact 32-char trigger for Luma validation |
| `apps/web/src/app/app/[teamSlug]/integrations/integrations-content.tsx` | Replace `IntegrationAuthDialog` with `IntegrationConnectDialog`, remove inline component |

---

## 6. Edge Cases & Error Handling

| Scenario | Handling |
|----------|----------|
| User types 32 chars then deletes some | Reset validation state to idle, don't re-validate until 32 chars again or blur |
| User pastes partial key | Still validate on blur |
| User pastes key longer than 32 chars | Validate the trimmed paste |
| Connection dialog closed mid-validation | Cancel/ignore validation result |
| Luma API unreachable | Show "Unable to validate. Please try again." |
| Other integration selected (non-Luma) | Skip all validation, just save with default name |

---

## 7. Testing Scenarios

### 7.1 Luma Event Form

- [ ] When not connected, shows `IntegrationConnectInline` with correct subtitle
- [ ] Clicking "Connect Luma" opens `IntegrationConnectDialog`
- [ ] After successful connection, automatically shows event selection UI
- [ ] No page refresh needed after connecting

### 7.2 Integrations Page

- [ ] Clicking "Connect" opens `IntegrationConnectDialog`
- [ ] Dialog shows connection name field
- [ ] For Luma: API key is validated on blur/paste/32-chars
- [ ] For Luma: Connection name is auto-populated from API
- [ ] For other integrations: Connection name defaults to "{Provider} Account"
- [ ] After connection, list refreshes with new connection

### 7.3 Column Settings

- [ ] Existing behavior unchanged (already uses correct components)
- [ ] Luma validation improvements apply here too

### 7.4 Luma API Key Validation

- [ ] Validates on blur when key is ≥8 chars
- [ ] Validates immediately when exactly 32 chars entered
- [ ] Validates on paste
- [ ] Does NOT validate when 33 chars (only at exactly 32)
- [ ] Shows spinner during validation
- [ ] Shows checkmark when valid
- [ ] Shows error when invalid
- [ ] Pre-fills connection name on successful validation

---

## 8. Implementation Order

1. **Phase 1: IntegrationConnectInline Enhancement**
   - Add `subtitle` prop to `IntegrationConnectInline`
   - Low risk, quick change

2. **Phase 2: Integrations Page Migration**
   - Replace `IntegrationAuthDialog` with `IntegrationConnectDialog`
   - Remove inline `IntegrationAuthDialog` component
   - Test all integrations work correctly

3. **Phase 3: Luma Validation Improvements**
   - Add paste handler to `IntegrationConnectDialog`
   - Add exact 32-char trigger
   - Test validation triggers correctly

4. **Phase 4: Luma Event Form Migration**
   - Replace inline form with `IntegrationConnectInline` + `IntegrationConnectDialog`
   - Test connection → event selection flow
   - Remove old inline form code

---

## 9. Success Criteria

- [ ] All three locations (Luma Event Form, Column Settings, Integrations Page) use the same visual pattern for "not connected" state
- [ ] All three locations use `IntegrationConnectDialog` for the connection form
- [ ] Connection name field is present in all connection flows
- [ ] Luma API key validation triggers on blur, paste, and exactly 32 chars
- [ ] No regression in existing functionality
- [ ] Code duplication reduced (removed inline form from luma-event-form.tsx, removed IntegrationAuthDialog)

---

## 10. Out of Scope

- Adding API key validation for integrations other than Luma
- Changing the connection selector UI (where users pick from multiple connections)
- OAuth-based integrations (not applicable to current integrations)
- Mobile-specific UI considerations

---

## 11. Open Questions

1. ~~Should the subtitle in `IntegrationConnectInline` be customizable?~~ **Resolved: Yes, add optional `subtitle` prop**
2. ~~Should validation trigger at exactly 32 chars or ≥32 chars?~~ **Resolved: Exactly 32 chars only**
3. Should we add analytics events for connection success/failure? (Future consideration)

---

## 12. References

- **IntegrationConnectInline:** `apps/web/src/components/integrations/integration-connect-inline.tsx`
- **IntegrationConnectDialog:** `apps/web/src/components/integrations/integration-connect-dialog.tsx`
- **Luma Event Form:** `apps/web/src/components/project/create/components/luma-event-form.tsx`
- **Integrations Page:** `apps/web/src/app/app/[teamSlug]/integrations/integrations-content.tsx`
- **Column Settings (Task Fields):** `apps/web/src/components/table/columns/task-field-settings-registry.tsx`
- **Luma API Key Validation:** `apps/web/src/trpc/router/integrations.ts` → `validateLumaApiKey`

---

## Appendix A: Component Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     User Sees "Not Connected"                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   IntegrationConnectInline                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  [Fluar] ⇄ [Provider]                                   │    │
│  │  Link your {Provider} account                           │    │
│  │  {subtitle}                                             │    │
│  │  [Connect {Provider}]                                   │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                        User clicks
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   IntegrationConnectDialog                       │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  Add {Provider} key                                     │    │
│  │  ─────────────────────────────────────────────────────  │    │
│  │  API Key: [________________] [✓/spinner]                │    │
│  │  [Get API Key ↗]                                        │    │
│  │                                                         │    │
│  │  Connection Name: [________________]                    │    │
│  │  A friendly name to identify this connection            │    │
│  │                                                         │    │
│  │              [Cancel]  [Save]                           │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                              │
                        onSuccess()
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Main UI (Connected State)                    │
│  - Luma Event Form: Shows event selection                       │
│  - Column Settings: Shows task configuration                    │
│  - Integrations Page: Shows connection in list                  │
└─────────────────────────────────────────────────────────────────┘
```

## Appendix B: Validation Trigger Matrix (Luma Only)

| Trigger | Condition | Action |
|---------|-----------|--------|
| On Change | `key.length === 32` | Validate immediately |
| On Change | `key.length !== 32` | Reset to idle (if was validating) |
| On Blur | `key.length >= 8` | Validate |
| On Paste | `pastedKey.length >= 8` | Validate after state update |
