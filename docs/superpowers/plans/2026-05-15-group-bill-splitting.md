# Group Bill-Splitting Implementation Plan

**Goal:** Add group bill-splitting with offline-first sync, invite codes, QR codes, equal/custom/per-item splits, and auto-created personal expenses.

**Architecture:** New Hive models (typeIds 9-13). Riverpod providers. Dashboard card + Drawer access. Supabase sync follows existing pattern.

**Tech Stack:** Flutter, Hive, Riverpod, Supabase, qr_flutter, mobile_scanner

---

## Phase 1: Dependencies & Models

### Task 1: Add dependencies
- Modify: `pubspec.yaml` — add `qr_flutter: ^4.1.0` and `mobile_scanner: ^6.0.7` under dependencies
- Run: `flutter pub get`
- Commit

### Task 2: Create Group model
- Create: `lib/core/models/group.dart`
- Code: `@HiveType(typeId: 9)` class with fields: id, name, createdBy, createdAt, inviteCode, isActive, updatedAt. Include copyWith.
- Run: `flutter pub run build_runner build --delete-conflicting-outputs`
- Commit

### Task 3: Create GroupMember model
- Create: `lib/core/models/group_member.dart`
- Code: `@HiveType(typeId: 10)` class with fields: id, groupId, userId, displayName, joinedAt, role, isActive, updatedAt. Include copyWith.
- Run build_runner
- Commit

### Task 4: Create GroupExpense model
- Create: `lib/core/models/group_expense.dart`
- Code: `@HiveType(typeId: 11)` class with fields: id, groupId, description, totalAmount, date, paidByUserId, receiptImagePath, syncStatus, supabaseId, createdAt, updatedAt. Include copyWith.
- Run build_runner
- Commit

### Task 5: Create GroupExpenseSplit model
- Create: `lib/core/models/group_expense_split.dart`
- Code: `@HiveType(typeId: 12)` class with fields: id, groupExpenseId, userId, amount, isSettled, settledAt, updatedAt. Include copyWith.
- Run build_runner
- Commit

### Task 6: Create GroupExpenseItem model
- Create: `lib/core/models/group_expense_item.dart`
- Code: `@HiveType(typeId: 13)` class with fields: id, groupExpenseId, description, amount, assignedToUserIds, updatedAt. Include copyWith.
- Run build_runner
- Commit

### Task 7: Modify Expense model
- Modify: `lib/core/models/expense.dart`
- Add `@HiveField(8) String? groupId` and `@HiveField(9) String? groupExpenseId`
- Add to constructor, copyWith
- Run build_runner
- Commit

---

## Phase 2: Migration & Main Setup

### Task 8: Database migration
- Modify: `lib/core/database/database_migration_service.dart`
- Bump `currentDbVersion` to 2
- Add `case 2: await _migrateV1toV2(); break;`
- Add `_migrateV1toV2()` that rewrites all expenses and opens new group boxes
- Commit

### Task 9: Register adapters and open boxes
- Modify: `lib/main.dart`
- Add imports for all 5 new models
- Add `_safeRegisterAdapter` calls for typeIds 9-13
- Add `openBoxSafe` calls for groups, group_members, group_expenses, group_expense_splits, group_expense_items
- Commit

---

## Phase 3: Providers

### Task 10: Create group provider
- Create: `lib/core/providers/group_provider.dart`
- Box provider + StateNotifierProvider for Groups
- Family StateNotifierProvider for GroupMembers
- Commit

### Task 11: Create group expense provider
- Create: `lib/core/providers/group_expense_provider.dart`
- Box providers + StateNotifierProviders for GroupExpenses, GroupExpenseSplits, GroupExpenseItems
- Provider for groupBalances calculation
- Commit

---

## Phase 4: Navigation Integration

### Task 12: Add Groups to Drawer
- Modify: `lib/features/home/widgets/drawer_content.dart`
- Add import for GroupsScreen
- Add drawer item with icon `Icons.group_outlined`, title `l10n.groups`
- Commit

### Task 13: Add GroupsCard to Dashboard
- Create: `lib/features/dashboard/widgets/groups_card.dart`
- ConsumerWidget showing group count and preview list
- Modify: `lib/features/dashboard/dashboard_screen.dart`
- Add import and place `const GroupsCard()` after AIInsightsCard
- Commit

---

## Phase 5: Group Screens

### Task 14: Create GroupsScreen
- Create: `lib/features/groups/groups_screen.dart`
- ConsumerWidget with list of groups, empty state, FABs for create/join
- Commit

### Task 15: Create CreateGroupModal
- Create: `lib/features/groups/widgets/create_group_modal.dart`
- Form for group name, generates 8-char invite code, shows QR with qr_flutter, share button
- Commit

### Task 16: Create JoinGroupModal
- Create: `lib/features/groups/widgets/join_group_modal.dart`
- Text field for invite code, QR scanner with mobile_scanner
- Commit

### Task 17: Create GroupDetailScreen
- Create: `lib/features/groups/group_detail_screen.dart`
- Shows member count, expense count, list of group expenses
- FAB to add group expense
- Commit

### Task 18: Create GroupExpenseModal
- Create: `lib/features/groups/widgets/group_expense_modal.dart`
- Manual entry: description, amount, date, payer dropdown
- Option to scan receipt (reuses existing scanner)
- Button to proceed to split configuration
- Commit

### Task 19: Create SplitConfigurationScreen
- Create: `lib/features/groups/widgets/split_configuration_screen.dart`
- Toggle between Equal / Custom / Per-item
- Equal: divide total by member count
- Custom: text fields per member
- Per-item: navigate to PerItemAssignmentScreen
- Validate sums match total
- On save: create GroupExpense, GroupExpenseSplits, GroupExpenseItems, and personal Expenses for each member
- Commit

### Task 20: Create PerItemAssignmentScreen
- Create: `lib/features/groups/widgets/per_item_assignment_screen.dart`
- List of receipt items with assignee chips
- Tapping chip toggles assignment
- Shows unassigned amount
- "Distribute remaining" button
- Commit

### Task 21: Create GroupBalancesScreen
- Create: `lib/features/groups/widgets/group_balances_screen.dart`
- Shows net balances per member
- "Mark as Settled" button for each unsettled split
- Commit

---

## Phase 6: Receipt Integration

### Task 22: Extend AI prompt for items
- Modify: `lib/core/services/unified_ai_service.dart` (or gemini/nvidia services)
- Update prompt to request `"items": [{"description", "amount"}]`
- Commit

### Task 23: Update receipt scanner flow
- Modify: `lib/features/expenses/widgets/receipt_scanner_sheet.dart`
- If items are present in parsed result, pass them to GroupExpenseModal
- Commit

---

## Phase 7: Sync & Polish

### Task 24: Add localization strings
- Modify: `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`
- Add all group-related strings
- Run: `flutter gen-l10n`
- Commit

### Task 25: Final verification
- Run: `flutter analyze`
- Fix any lint issues
- Run: `flutter build apk --debug` (smoke test)
- Commit

---

## Self-Review Checklist
- [ ] All 5 new models have unique typeIds (9-13)
- [ ] Expense model has groupId and groupExpenseId
- [ ] Migration bumps to version 2 and opens new boxes
- [ ] main.dart registers all adapters and opens boxes
- [ ] Drawer has Groups item
- [ ] Dashboard has GroupsCard
- [ ] All providers follow existing Riverpod patterns
- [ ] QR generation and scanning implemented
- [ ] Split calculation covers equal, custom, and per-item
- [ ] Personal expenses auto-created from splits
- [ ] Settlement updates split status only
