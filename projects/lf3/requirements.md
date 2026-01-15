# Technical Specifications

## Overview

Unify integration connection UI across three locations: Luma Event Form, Column Settings, and Integrations Page. All flows should use `IntegrationConnectInline` for the "not connected" state and `IntegrationConnectDialog` for the connection form.

## Files to Modify

| File | Purpose |
|------|---------|
| `apps/web/src/components/integrations/integration-connect-inline.tsx` | Add subtitle prop |
| `apps/web/src/components/integrations/integration-connect-dialog.tsx` | Add paste handler, 32-char trigger |
| `apps/web/src/app/app/[teamSlug]/integrations/integrations-content.tsx` | Replace IntegrationAuthDialog |
| `apps/web/src/components/project/create/components/luma-event-form.tsx` | Replace inline form |

## Component Changes

### IntegrationConnectInline

Add optional `subtitle` prop:

```typescript
interface IntegrationConnectInlineProps {
  integrationId: string
  onConnect: () => void
  subtitle?: string  // New prop
}
```

Default subtitle: `'Connect to configure this column'`

### IntegrationConnectDialog

#### New Constants
```typescript
const LUMA_API_KEY_LENGTH = 32
```

#### New Functions

**validateApiKey** - Extracted validation logic:
- Check if Luma integration
- Set validating state
- Call `validateLumaApiKey.mutateAsync`
- Update state based on result
- Auto-populate connection name on success

**handleApiKeyPaste** - Paste event handler:
- Extract pasted text from clipboard
- Trim whitespace
- If length >= 8, trigger validation after state update

**handleApiKeyChange** - Updated change handler:
- Set apiKey state
- If Luma and length changes: reset validation state to idle
- If Luma and length === 32: trigger validation

#### Validation Trigger Matrix

| Trigger | Condition | Action |
|---------|-----------|--------|
| onChange | length === 32 | Validate immediately |
| onChange | length !== 32 | Reset to idle |
| onBlur | length >= 8 | Validate |
| onPaste | length >= 8 | Validate after state update |

### Integrations Page (integrations-content.tsx)

**Remove:**
- `IntegrationAuthDialog` component definition (~100 lines)
- `apiKey` state
- `handleSaveConnection` function

**Add:**
- Import `IntegrationConnectDialog`
- Use `IntegrationConnectDialog` with props:
  - `open={dialogOpen}`
  - `onOpenChange` - handle close + clear activeIntegrationId
  - `integrationId={activeIntegrationId}`
  - `onSuccess` - call `integrationsQuery.refetch()`

### Luma Event Form (luma-event-form.tsx)

**Replace** the inline form (~90 lines JSX) with:

```tsx
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
        onSuccess={() => refetch()}
      />
    </div>
  )
}
```

**Add:**
- `connectDialogOpen` state variable

**Remove:**
- Custom inline form JSX
- Duplicate state variables if present

## Edge Cases

| Scenario | Handling |
|----------|----------|
| User types 32 chars then deletes | Reset validation to idle |
| User pastes partial key | Validate on blur |
| User pastes key > 32 chars | Validate trimmed paste |
| Dialog closed mid-validation | Ignore validation result |
| Luma API unreachable | Show error message |
| Non-Luma integration | Skip validation, use default name |

## Dependencies

No new dependencies required. All components exist.

## Testing

Manual testing required for:
1. Luma Event Form not-connected → connected flow
2. Integrations page connection dialog with connection name field
3. Luma API key validation on blur/paste/32-chars
4. Column Settings regression (no changes expected)
