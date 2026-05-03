import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/models/wallet_transfer.dart';
import 'package:mobile_expense_tracker/core/providers/wallet_provider.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/features/wallets/widgets/wallet_modal.dart';
import 'package:mobile_expense_tracker/features/wallets/widgets/transfer_modal.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final wallets = ref.watch(walletsProvider);
    final currency = ref.watch(currencyProvider);
    final totalBalance = ref.watch(totalBalanceProvider);
    final transfers = ref.watch(walletTransfersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wallets),
        automaticallyImplyLeading: false,
      ),
      body: wallets.isEmpty
          ? _buildEmptyState(context, l10n)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildTotalBalanceCard(context, totalBalance, currency, l10n),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.myWallets,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showTransferModal(context),
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: Text(l10n.transfer),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...wallets.map((wallet) {
                  final balance = ref.watch(walletBalanceProvider(wallet.id));
                  return _buildWalletCard(
                    context,
                    wallet,
                    balance,
                    currency,
                    ref,
                    l10n,
                  );
                }),
                if (transfers.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    l10n.recentTransfers,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...transfers.take(5).map((transfer) {
                    final fromWallet = wallets
                        .where((w) => w.id == transfer.fromWalletId)
                        .firstOrNull;
                    final toWallet = wallets
                        .where((w) => w.id == transfer.toWalletId)
                        .firstOrNull;
                    return _buildTransferCard(
                      context,
                      transfer,
                      fromWallet?.name ?? 'Unknown',
                      toWallet?.name ?? 'Unknown',
                      currency,
                      ref,
                      l10n,
                    );
                  }),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWalletModal(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withAlpha(102),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noWalletsYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tapToAddFirstWallet,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalBalanceCard(
    BuildContext context,
    double totalBalance,
    currency,
    AppLocalizations l10n,
  ) {
    final isPositive = totalBalance >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.totalBalance,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${currency.symbol}${totalBalance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isPositive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(
    BuildContext context,
    wallet,
    double balance,
    currency,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final isPositive = balance >= 0;
    final cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(wallet.color).withAlpha(26),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              IconConstants.getIcon(wallet.iconName),
              color: Color(wallet.color),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      wallet.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (wallet.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(26),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          l10n.defaultLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  wallet.type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(128),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${currency.symbol}${balance.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isPositive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    );

    if (wallet.isDefault) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: () => _showEditWalletModal(context, wallet),
          borderRadius: BorderRadius.circular(12),
          child: cardContent,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(wallet.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.deleteWallet),
              content: Text(l10n.areYouSureDeleteWallet),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) {
          ref.read(walletsProvider.notifier).deleteWallet(wallet.id);
        },
        child: InkWell(
          onTap: () => _showEditWalletModal(context, wallet),
          borderRadius: BorderRadius.circular(12),
          child: cardContent,
        ),
      ),
    );
  }

  Widget _buildTransferCard(
    BuildContext context,
    WalletTransfer transfer,
    String fromName,
    String toName,
    currency,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final errorColor = Theme.of(context).colorScheme.error;
    final onErrorColor = Theme.of(context).colorScheme.onError;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(transfer.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: errorColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete, color: onErrorColor),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.deleteTransfer),
              content: Text(l10n.areYouSureDeleteTransfer),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                    foregroundColor: onErrorColor,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.delete),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) {
          ref.read(walletTransfersProvider.notifier).deleteTransfer(transfer.id);
        },
        child: InkWell(
          onTap: () => _showEditTransferModal(context, transfer),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$fromName → $toName',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      if (transfer.note != null && transfer.note!.isNotEmpty)
                        Text(
                          transfer.note!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(128),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${currency.symbol}${transfer.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddWalletModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const WalletModal(),
    );
  }

  void _showEditWalletModal(BuildContext context, wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WalletModal(wallet: wallet),
    );
  }

  void _showTransferModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransferModal(),
    );
  }

  void _showEditTransferModal(BuildContext context, WalletTransfer transfer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransferModal(transfer: transfer),
    );
  }
}
