import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';

/// Current database schema version.
/// Increment this whenever you add a migration.
const int currentDbVersion = 1;

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
    // case 2:
    //   await _migrateV1toV2();
    //   break;
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
Future<void> _migrateFromV0(Box<dynamic> settings) async {
  developer.log(
    '[Migration] v0 → v1: Ensuring new fields have sensible defaults...',
    name: 'DatabaseMigration',
  );
  await _migrateV0toV1();
}

Future<void> _migrateV0toV1() async {
  // 1. Ensure every Category has a categoryType.
  final categoryBox = Hive.box<dynamic>('categories');
  for (final key in categoryBox.keys.toList()) {
    final cat = categoryBox.get(key);
    if (cat is! Map) continue;
    if (cat['categoryType'] == null) {
      cat['categoryType'] = 'expense';
      await categoryBox.put(key, cat);
    }
  }

  // 2. Ensure expense/note and income/note fields exist as null if missing.
  //    (Defensive only — generated adapters already handle missing nullable fields.)
  final expenseBox = Hive.box<dynamic>('expenses');
  for (final key in expenseBox.keys.toList()) {
    final e = expenseBox.get(key);
    if (e is! Map) continue;
    if (!e.containsKey('walletId')) {
      e['walletId'] = null;
      await expenseBox.put(key, e);
    }
  }

  final incomeBox = Hive.box<dynamic>('incomes');
  for (final key in incomeBox.keys.toList()) {
    final i = incomeBox.get(key);
    if (i is! Map) continue;
    if (!i.containsKey('walletId')) {
      i['walletId'] = null;
      await incomeBox.put(key, i);
    }
  }

  // 3. Create empty wallet_transfers box if missing (new in v1).
  if (!Hive.isBoxOpen('wallet_transfers')) {
    await Hive.openBox<dynamic>('wallet_transfers');
  }

  developer.log(
    '[Migration] v0 → v1 complete.',
    name: 'DatabaseMigration',
  );
}
