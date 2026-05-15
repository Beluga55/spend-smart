import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/core/models/group.dart';
import 'package:mobile_expense_tracker/core/models/group_member.dart';
import 'package:mobile_expense_tracker/core/models/group_expense.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_split.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_item.dart';

/// Current database schema version.
/// Increment this whenever you add a migration.
const int currentDbVersion = 2;

const String _dbVersionKey = 'dbVersion';

/// Runs all pending database migrations.
///
/// Call this after Hive is initialized but before any business logic runs.
/// It compares the stored [dbVersion] in the settings box with
/// [currentDbVersion] and executes every missing migration in order.
Future<void> runMigrations() async {
  final settings = Hive.box('settings');
  final storedVersion = settings.get(_dbVersionKey) as int?;

  developer.log(
    '[Migration] Stored DB version: $storedVersion, target: $currentDbVersion',
    name: 'DatabaseMigration',
  );

  if (storedVersion == null) {
    // Pre-versioning installs (before this system existed) are treated as v0.
    developer.log(
      '[Migration] No version found. Running all migrations from v0 → v$currentDbVersion.',
      name: 'DatabaseMigration',
    );
    await _migrateFromV0(settings);
  } else if (storedVersion < currentDbVersion) {
    for (int v = storedVersion; v < currentDbVersion; v++) {
      developer.log(
        '[Migration] Running migration v$v → v${v + 1}',
        name: 'DatabaseMigration',
      );
      await _runMigration(v + 1);
    }
  } else {
    developer.log(
      '[Migration] Database is up to date.',
      name: 'DatabaseMigration',
    );
  }

  await settings.put(_dbVersionKey, currentDbVersion);
  developer.log(
    '[Migration] Database version updated to $currentDbVersion',
    name: 'DatabaseMigration',
  );
}

/// Dispatch table for migrations.
///
/// Add a new case here every time you bump [currentDbVersion].
Future<void> _runMigration(int targetVersion) async {
  switch (targetVersion) {
    case 1:
      await _migrateV0toV1();
      break;
    case 2:
      await _migrateV1toV2();
      break;
    default:
      throw UnimplementedError(
        'Migration to version $targetVersion is not implemented.',
      );
  }
}

/// Migration from pre-versioning schema (v0) to v1.
///
/// v1 introduced:
/// - `categoryType` field on Category (default 'expense')
/// - `walletId` field on Expense and Income (nullable)
/// - WalletTransfer model and its box
/// - dbVersion tracking itself
///
/// Note: We access already-open typed boxes directly. The Map-patching
/// approach does not work with typed Hive boxes — values are deserialized
/// objects, not Maps. Missing fields are handled by defensive adapters
/// (nullable fields default to null) and the `effectiveType` getter.
Future<void> _migrateFromV0(Box<dynamic> settings) async {
  developer.log(
    '[Migration] v0 → v1: Running...',
    name: 'DatabaseMigration',
  );
  await _migrateV0toV1();
}

Future<void> _migrateV0toV1() async {
  // 1. Ensure Category objects without categoryType get a default.
  //    The adapter already reads missing field[5] as null, but rewriting
  //    ensures the on-disk bytes match the current schema for future proofing.
  final categoryBox = Hive.box<Category>('categories');
  for (final key in categoryBox.keys.toList()) {
    final cat = categoryBox.get(key);
    if (cat == null) continue;
    if (cat.categoryType == null) {
      final updated = cat.copyWith(categoryType: 'expense');
      await categoryBox.put(key, updated);
    }
  }

  // 2. Ensure wallet_transfers box exists (new in v1).
  //    Do NOT try to open it again if already open.
  if (!Hive.isBoxOpen('wallet_transfers')) {
    await Hive.openBox<dynamic>('wallet_transfers');
  }

  developer.log(
    '[Migration] v0 → v1 complete.',
    name: 'DatabaseMigration',
  );
}

Future<void> _migrateV1toV2() async {
  developer.log(
    '[Migration] v1 → v2: Adding group fields to Expense',
    name: 'DatabaseMigration',
  );

  final expenseBox = Hive.box<Expense>('expenses');
  for (final key in expenseBox.keys.toList()) {
    final exp = expenseBox.get(key);
    if (exp == null) continue;
    await expenseBox.put(key, exp);
  }

  if (!Hive.isBoxOpen('groups')) {
    await Hive.openBox<Group>('groups');
  }
  if (!Hive.isBoxOpen('group_members')) {
    await Hive.openBox<GroupMember>('group_members');
  }
  if (!Hive.isBoxOpen('group_expenses')) {
    await Hive.openBox<GroupExpense>('group_expenses');
  }
  if (!Hive.isBoxOpen('group_expense_splits')) {
    await Hive.openBox<GroupExpenseSplit>('group_expense_splits');
  }
  if (!Hive.isBoxOpen('group_expense_items')) {
    await Hive.openBox<GroupExpenseItem>('group_expense_items');
  }

  developer.log(
    '[Migration] v1 → v2 complete.',
    name: 'DatabaseMigration',
  );
}
