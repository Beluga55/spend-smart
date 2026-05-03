import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/models/wallet_transfer.dart';
import 'package:mobile_expense_tracker/core/providers/wallet_provider.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class TransferModal extends ConsumerStatefulWidget {
  final WalletTransfer? transfer;

  const TransferModal({super.key, this.transfer});

  @override
  ConsumerState<TransferModal> createState() => _TransferModalState();
}

class _TransferModalState extends ConsumerState<TransferModal> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  String? _fromWalletId;
  String? _toWalletId;
  late DateTime _selectedDate;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    final transfer = widget.transfer;
    _amountController = TextEditingController(
      text: transfer != null ? transfer.amount.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: transfer?.note ?? '');
    _fromWalletId = transfer?.fromWalletId;
    _toWalletId = transfer?.toWalletId;
    _selectedDate = transfer?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wallets = ref.watch(walletsProvider);
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = textPrimary.withAlpha(153);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final isEditing = widget.transfer != null;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEditing ? l10n.editTransfer : l10n.transferBetweenWallets,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _fromWalletId,
              decoration: _buildInputDecoration(l10n.fromWallet, backgroundColor, dividerColor, textSecondary),
              style: TextStyle(color: textPrimary),
              dropdownColor: surfaceColor,
              items: wallets.map((wallet) {
                return DropdownMenuItem(
                  value: wallet.id,
                  child: Text(wallet.name, style: TextStyle(color: textPrimary)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _fromWalletId = value;
                  if (_toWalletId == value) {
                    _toWalletId = null;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: IconButton(
                onPressed: () {
                  final temp = _fromWalletId;
                  setState(() {
                    _fromWalletId = _toWalletId;
                    _toWalletId = temp;
                  });
                },
                icon: Icon(Icons.swap_vert, size: 32, color: textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _toWalletId,
              decoration: _buildInputDecoration(l10n.toWallet, backgroundColor, dividerColor, textSecondary),
              style: TextStyle(color: textPrimary),
              dropdownColor: surfaceColor,
              items: wallets
                  .where((w) => w.id != _fromWalletId)
                  .map((wallet) {
                return DropdownMenuItem(
                  value: wallet.id,
                  child: Text(wallet.name, style: TextStyle(color: textPrimary)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _toWalletId = value);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: textPrimary),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) {
                if (_amountError != null) {
                  setState(() => _amountError = null);
                }
              },
              decoration: _buildInputDecoration(l10n.amount, backgroundColor, dividerColor, textSecondary,
                hintText: l10n.enterAmount,
                prefixText: '\$ ',
                errorText: _amountError,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              style: TextStyle(color: textPrimary),
              decoration: _buildInputDecoration(l10n.noteOptional, backgroundColor, dividerColor, textSecondary,
                hintText: l10n.addANote,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              child: InputDecorator(
                decoration: _buildInputDecoration(l10n.date, backgroundColor, dividerColor, textSecondary),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: TextStyle(color: textPrimary),
                    ),
                    Icon(Icons.calendar_today, size: 20, color: textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveTransfer,
                child: Text(isEditing ? l10n.update : l10n.transfer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    String labelText,
    Color backgroundColor,
    Color borderColor,
    Color textSecondary, {
    String? hintText,
    String? prefixText,
    String? errorText,
  }) {
    final errorColor = Theme.of(context).colorScheme.error;
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixText: prefixText,
      errorText: errorText,
      labelStyle: TextStyle(color: textSecondary),
      hintStyle: TextStyle(color: textSecondary),
      errorStyle: TextStyle(color: errorColor),
      filled: true,
      fillColor: backgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorText != null ? errorColor : borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _saveTransfer() {
    final l10n = AppLocalizations.of(context)!;
    if (_fromWalletId == null || _toWalletId == null) return;
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final balance = ref.read(walletBalanceProvider(_fromWalletId!));
    double available = balance;
    if (widget.transfer != null && widget.transfer!.fromWalletId == _fromWalletId) {
      available += widget.transfer!.amount;
    }

    if (amount > available) {
      setState(() => _amountError = l10n.insufficientBalance);
      return;
    }

    final notifier = ref.read(walletTransfersProvider.notifier);

    if (widget.transfer != null) {
      notifier.updateTransfer(
        widget.transfer!.copyWith(
          fromWalletId: _fromWalletId!,
          toWalletId: _toWalletId!,
          amount: amount,
          date: _selectedDate,
          note: _noteController.text.trim().isNotEmpty
              ? _noteController.text.trim()
              : null,
        ),
      );
    } else {
      notifier.addTransfer(
        fromWalletId: _fromWalletId!,
        toWalletId: _toWalletId!,
        amount: amount,
        date: _selectedDate,
        note: _noteController.text.trim().isNotEmpty
            ? _noteController.text.trim()
            : null,
      );
    }

    Navigator.pop(context);
  }
}
