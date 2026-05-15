# Group Bill-Splitting Feature Design

**Date:** 2026-05-15
**Project:** SpendSmart
**Feature:** Group Bill-Splitting with Receipt OCR
**Status:** Approved

---

## 1. Overview

SpendSmart currently supports single-user personal finance tracking. This design adds **group bill-splitting**, allowing users to create groups, invite members via codes or QR, scan receipts, and split expenses equally, by custom amounts, or per receipt item. Each member's share is automatically recorded as a personal expense, while group-level balances and settlement state are tracked independently.

### Goals
- Enable shared expense tracking for groups (friends, roommates, travel, events).
- Integrate with existing receipt scanning (OCR + AI) for per-item assignment.
- Maintain offline-first behavior consistent with the rest of the app.
- Preserve personal budget accuracy by auto-creating personal expenses from group splits.

### Non-Goals
- In-app payment/settlement (users settle externally).
- Complex permission systems beyond admin/member.
- Partial settlement in MVP.

---

## 2. Data Model

### 2.1 New Hive Models

All new models use `@HiveType` with unique typeIds and live in `lib/core/models/`.

#### Group (typeId: 9)
| Field | Type | Notes |
|-------|------|-------|
| id | String | UUID v4 |
| name | String | Group display name |
| createdBy | String | Supabase user UUID of creator |
| createdAt | DateTime | |
| inviteCode | String | 8-character alphanumeric, uppercase |
| isActive | bool | Soft-delete flag |
| updatedAt | DateTime | For sync conflict resolution |

#### GroupMember (typeId: 10)
| Field | Type | Notes |
|-------|------|-------|
| id | String | UUID v4 |
| groupId | String | FK to Group |
| userId | String | Supabase auth UUID (null for placeholder members) |
| displayName | String | |
| joinedAt | DateTime | |
| role | String | 'admin' or 'member' |
| isActive | bool | Soft-delete flag |
| updatedAt | DateTime | |

#### GroupExpense (typeId: 11)
| Field | Type | Notes |
|-------|------|-------|
| id | String | UUID v4 |
| groupId | String | FK to Group |
| description | String | e.g. "Dinner at Marina Bay" |
| totalAmount | double | |
| date | DateTime | |
| paidByUserId | String | Supabase user UUID of payer |
| receiptImagePath | String? | Local path to receipt image |
| syncStatus | String | 'synced', 'pending', 'error' |
| supabaseId | String? | Remote row ID |
| createdAt | DateTime | |
| updatedAt | DateTime | |

#### GroupExpenseSplit (typeId: 12)
| Field | Type | Notes |
|-------|------|-------|
| id | String | UUID v4 |
| groupExpenseId | String | FK to GroupExpense |
| userId | String | Supabase user UUID |
| amount | double | This member's share |
| isSettled | bool | Default false |
| settledAt | DateTime? | |
| updatedAt | DateTime | |

#### GroupExpenseItem (typeId: 13)
| Field | Type | Notes |
|-------|------|-------|
| id | String | UUID v4 |
| groupExpenseId | String | FK to GroupExpense |
| description | String | e.g. "Burger" |
| amount | double | Item price |
| assignedToUserIds | List<String> | User IDs sharing this item |
| updatedAt | DateTime | |

### 2.2 Modified Existing Model

#### Expense (typeId: 0)
Two new nullable fields are added:
- `groupId` (String?) — links to the Group
- `groupExpenseId` (String?) — links to the GroupExpense

These are populated automatically when a GroupExpense is created.

### 2.3 Supabase Schema

Tables mirror the Hive models exactly, with `updated_at` triggers for realtime sync.

```sql
-- groups
CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  created_by UUID REFERENCES auth.users NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  invite_code TEXT UNIQUE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- group_members
CREATE TABLE group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users,
  display_name TEXT NOT NULL,
  joined_at TIMESTAMPTZ DEFAULT now(),
  role TEXT DEFAULT 'member',
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(group_id, user_id)
);

-- group_expenses
CREATE TABLE group_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  total_amount NUMERIC NOT NULL,
  date DATE NOT NULL,
  paid_by_user_id UUID REFERENCES auth.users NOT NULL,
  receipt_image_path TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- group_expense_splits
CREATE TABLE group_expense_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_expense_id UUID REFERENCES group_expenses(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users NOT NULL,
  amount NUMERIC NOT NULL,
  is_settled BOOLEAN DEFAULT false,
  settled_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- group_expense_items
CREATE TABLE group_expense_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_expense_id UUID REFERENCES group_expenses(id) ON DELETE CASCADE,
  description TEXT NOT NULL,
  amount NUMERIC NOT NULL,
  assigned_to_user_ids UUID[] NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

RLS policies ensure users can only read/write data for groups they are members of.

---

## 3. Architecture & Sync Strategy

### 3.1 Offline-First Pattern

Group data follows the same offline-first pattern as personal data:
1. All writes go to local Hive boxes immediately.
2. `syncStatus` is set to `'pending'`.
3. A background sync task (same worker as existing sync) pushes pending records to Supabase.
4. On success, `syncStatus` becomes `'synced'` and `supabaseId` is set.
5. On failure, `syncStatus` becomes `'error'` and retry happens with exponential backoff.

### 3.2 Sync Direction

| Direction | Trigger | Action |
|-----------|---------|--------|
| Up (local → remote) | Any local mutation on group data | Push changed rows to Supabase |
| Down (remote → local) | App foreground, periodic pull, or Supabase realtime | Fetch rows where `updated_at > local_last_sync` and merge |

### 3.3 Conflict Resolution

Last-write-wins based on `updated_at`. In the rare case of a true conflict (same row edited on two devices simultaneously), the later `updated_at` wins.

### 3.4 Auth Requirement

Groups require a Supabase authenticated user (not anonymous). If a user attempts to create or join a group while anonymous, they are prompted to sign in (Google Sign-In or existing auth flow).

---

## 4. UI/UX Flow

### 4.1 Navigation

Groups are accessible via **two entry points** (no bottom nav changes):

1. **Dashboard Card** — A "Groups" summary card on the Dashboard showing:
   - Number of active groups
   - Net balance ("You owe $45.20" or "You are owed $12.00")
   - Quick "Create Group" or "Join Group" buttons
   - Tapping the card navigates to the full GroupsListScreen

2. **Drawer Item** — A "Groups" item in the side drawer, alongside Recurring Expenses, Monthly Summary, etc.

The bottom navigation remains unchanged. AI Chat stays in place.

### 4.2 Screen Hierarchy

```
GroupsTab
├── GroupsListScreen
│   ├── CreateGroupScreen
│   ├── JoinGroupScreen (code input + QR scanner)
│   └── GroupDetailScreen
│       ├── GroupExpenseListScreen
│       ├── CreateGroupExpenseScreen
│       │   ├── ReceiptScannerSheet (reuse existing, extended)
│       │   └── SplitConfigurationScreen
│       │       └── PerItemAssignmentScreen
│       └── GroupBalancesScreen
```

### 4.3 Key Flows

#### Create a Group
1. Tap "+" on GroupsListScreen.
2. Enter group name.
3. App generates an 8-character invite code and a QR code.
4. User can copy the code or share the QR image.
5. Group is saved locally and synced to Supabase.

#### Join a Group
1. Tap "Join Group" on GroupsListScreen.
2. User can either:
   - Type an 8-character invite code.
   - Tap "Scan QR" to open the camera and scan a QR code.
3. App validates the code/QR against Supabase.
4. On success, a `GroupMember` record is created and synced.
5. The group's existing expenses are pulled down.

#### Create a Group Expense
1. Inside a group, tap "+" (FAB).
2. Choose **Scan Receipt** or **Manual Entry**.
3. If scanning: existing receipt scanner is used. After OCR/AI parsing, user lands on SplitConfigurationScreen.
4. If manual: user enters amount, description, date, and payer.
5. On SplitConfigurationScreen:
   - Default: **Equal split** among all members.
   - User can switch to **Custom amounts** or **Per-item** (if receipt was scanned).
   - For per-item: each line item shows assignee chips. Tapping cycles through members.
   - The app validates that assigned amounts sum to the total.
6. Tap "Save".
7. The app:
   - Saves the `GroupExpense`, `GroupExpenseSplit`s, and `GroupExpenseItem`s.
   - For each member, creates a personal `Expense` with `groupId` and `groupExpenseId`.
   - Marks all splits as `isSettled = false` except the payer's (payer auto-settled since they already paid).

#### Settle Up
1. Inside a group, tap "Balances".
2. Shows a card for each member: "You owe Alice $23.50" or "Bob owes you $12.00".
3. Tap "Mark as Settled" on a debt.
4. `GroupExpenseSplit.isSettled` becomes `true`, `settledAt` is set.
5. The personal `Expense` remains (real money was spent).

---

## 5. Receipt Scanning Integration

### 5.1 Extended AI Prompt

The existing prompt in `UnifiedAIService` is extended to request line items:

```
Extract receipt details. Respond ONLY with raw JSON containing:
- merchant (string)
- date (YYYY-MM-DD)
- total (number)
- currency (3-letter code)
- items (array of {description, amount})
```

If the AI fails to return items, the user can still proceed with equal/custom split.

### 5.2 Per-Item Assignment UI

After scanning, if items are present:
- Screen shows a list of receipt line items.
- Each item row shows: description, amount, and a row of circular avatar chips for group members.
- Tapping a member's chip toggles assignment (multi-select per item is allowed).
- A "remaining unassigned" indicator is shown at the bottom.
- A "Distribute remaining equally" button assigns unassigned amounts equally.

### 5.3 Calculation

For each member, their share is:
```
sum of (item.amount / item.assignedToUserIds.length)
for all items where they are assigned
```

If any amount is unassigned, the split screen prevents saving until resolved.

---

## 6. Error Handling & Edge Cases

### 6.1 Member Leaves Group
- If a member leaves, their `GroupMember` record is soft-deleted (`isActive = false`).
- Their unsettled splits remain visible in historical expenses.
- They cannot create new group expenses.
- An admin can remove a member (same effect).

### 6.2 Editing/Deleting Group Expenses
- **No edits allowed** after creation (to avoid settlement complexity).
- **Delete allowed only if all splits are settled.** Otherwise, show a warning: "Cannot delete an expense with unsettled splits."

### 6.3 Partial Settlement
- **Not supported in MVP.** A split is either fully settled or not.

### 6.4 Sync Failures
- Retry with exponential backoff (1s, 2s, 4s, 8s, max 60s).
- Show a sync status indicator on the Groups screen (same icon pattern as dashboard).
- If sync is consistently failing, show a persistent banner: "Some group data hasn't synced. Tap to retry."

### 6.5 Duplicate Invite Codes
- Invite codes are 8-character alphanumeric. The app checks Supabase for uniqueness before creating.
- Collision probability is low; on collision, regenerate.

### 6.6 Anonymous Users
- If an anonymous user tries to create/join a group, show a modal: "Sign in required to use groups." with a Google Sign-In button.

---

## 7. Testing Strategy

- **Unit tests:** Split calculation logic (equal, custom, per-item).
- **Widget tests:** Group creation flow, split configuration screen, QR scanner.
- **Integration tests:** End-to-end flow of create group → add expense → settle up.

---

## 8. Migration Plan

1. **Database migration:**
   - Add `groupId` and `groupExpenseId` to `Expense` model.
   - Bump `currentDbVersion` in `DatabaseMigrationService`.
   - Add migration case to populate new fields as null for existing expenses.

2. **Adapter registration:**
   - Register `Group`, `GroupMember`, `GroupExpense`, `GroupExpenseSplit`, `GroupExpenseItem` adapters in `main()`.
   - Run `flutter pub run build_runner build --delete-conflicting-outputs`.

3. **Dependencies:**
   - Add `qr_flutter` for QR code generation and display.
   - Add `mobile_scanner` for QR code scanning (if not already present).

4. **Supabase setup:**
   - Run schema SQL in Supabase dashboard.
   - Enable RLS policies.

---

## 9. Open Questions

None — all decisions are documented above.
