import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/models/wallet.dart';
import 'package:mobile_expense_tracker/core/models/wallet_transfer.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';
import 'package:uuid/uuid.dart';

final walletBoxProvider = Provider<Box<Wallet>>((ref) {
  return Hive.box<Wallet>('wallets');
});

final walletTransferBoxProvider = Provider<Box<WalletTransfer>>((ref) {
  return Hive.box<WalletTransfer>('wallet_transfers');
});

final walletsProvider =
    StateNotifierProvider<WalletsNotifier, List<Wallet>>((ref) {
  final box = ref.watch(walletBoxProvider);
  return WalletsNotifier(box);
});

class WalletsNotifier extends StateNotifier<List<Wallet>> {
  final Box<Wallet> _box;

  WalletsNotifier(this._box) : super(_box.values.toList()) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() {
    state = _box.values.toList();
  }

  Future<void> addWallet({
    required String name,
    required String iconName,
    required int color,
    required String type,
    bool isDefault = false,
  }) async {
    const uuid = Uuid();
    if (isDefault) {
      for (final wallet in _box.values) {
        if (wallet.isDefault) {
          final updated = wallet.copyWith(isDefault: false);
          await _box.put(wallet.id, updated);
        }
      }
    }
    final wallet = Wallet(
      id: uuid.v4(),
      name: name,
      iconName: iconName,
      color: color,
      type: type,
      isDefault: isDefault,
      createdAt: DateTime.now(),
    );
    await _box.put(wallet.id, wallet);
    _refresh();
  }

  Future<void> updateWallet(Wallet wallet) async {
    if (wallet.isDefault) {
      for (final w in _box.values) {
        if (w.isDefault && w.id != wallet.id) {
          final updated = w.copyWith(isDefault: false);
          await _box.put(w.id, updated);
        }
      }
    }
    await _box.put(wallet.id, wallet);
    _refresh();
  }

  Future<void> deleteWallet(String id) async {
    final wallet = _box.get(id);
    if (wallet != null && !wallet.isDefault) {
      await _box.delete(id);
      _refresh();
    }
  }
}

final walletTransfersProvider =
    StateNotifierProvider<WalletTransfersNotifier, List<WalletTransfer>>((ref) {
  final box = ref.watch(walletTransferBoxProvider);
  return WalletTransfersNotifier(box);
});

class WalletTransfersNotifier extends StateNotifier<List<WalletTransfer>> {
  final Box<WalletTransfer> _box;

  WalletTransfersNotifier(this._box) : super(_box.values.toList()) {
    _box.listenable().addListener(_refresh);
  }

  void _refresh() {
    state = _box.values.toList();
  }

  Future<void> addTransfer({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    const uuid = Uuid();
    final transfer = WalletTransfer(
      id: uuid.v4(),
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount,
      date: date,
      note: note,
      createdAt: DateTime.now(),
    );
    await _box.put(transfer.id, transfer);
    _refresh();
  }

  Future<void> updateTransfer(WalletTransfer transfer) async {
    await _box.put(transfer.id, transfer);
    _refresh();
  }

  Future<void> deleteTransfer(String id) async {
    await _box.delete(id);
    _refresh();
  }
}

final walletBalanceProvider = Provider.family<double, String>((ref, walletId) {
  final expenses = ref.watch(expensesProvider);
  final incomes = ref.watch(incomesProvider);
  final transfers = ref.watch(walletTransfersProvider);

  double balance = 0;

  for (final income in incomes) {
    if (income.walletId == walletId) {
      balance += income.amount;
    }
  }

  for (final expense in expenses) {
    if (expense.walletId == walletId) {
      balance -= expense.amount;
    }
  }

  for (final transfer in transfers) {
    if (transfer.fromWalletId == walletId) {
      balance -= transfer.amount;
    }
    if (transfer.toWalletId == walletId) {
      balance += transfer.amount;
    }
  }

  return balance;
});

final defaultWalletProvider = Provider<Wallet?>((ref) {
  final wallets = ref.watch(walletsProvider);
  return wallets.where((w) => w.isDefault).firstOrNull;
});

final totalBalanceProvider = Provider<double>((ref) {
  final wallets = ref.watch(walletsProvider);
  double total = 0;
  for (final wallet in wallets) {
    total += ref.watch(walletBalanceProvider(wallet.id));
  }
  return total;
});
