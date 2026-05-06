import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/models/wallet.dart';
import 'package:mobile_expense_tracker/core/providers/wallet_provider.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class WalletModal extends ConsumerStatefulWidget {
  final Wallet? wallet;

  const WalletModal({super.key, this.wallet});

  @override
  ConsumerState<WalletModal> createState() => _WalletModalState();
}

class _WalletModalState extends ConsumerState<WalletModal> {
  late TextEditingController _nameController;
  late String _selectedIcon;
  late int _selectedColor;
  late String _selectedType;
  late bool _isDefault;
  String? _nameError;

  final List<String> _walletTypes = ['cash', 'bank', 'credit', 'ewallet'];
  final List<int> _colors = [
    0xFF4CAF50,
    0xFF2196F3,
    0xFFFF9800,
    0xFFE91E63,
    0xFF9C27B0,
    0xFF00BCD4,
    0xFFFF5722,
    0xFF795548,
    0xFF607D8B,
    0xFF3F51B5,
  ];

  final List<String> _walletIcons = [
    'wallet',
    'account_balance',
    'credit_card',
    'savings',
    'phone_android',
    'home',
    'work',
    'business_center',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wallet?.name ?? '');
    _selectedIcon = widget.wallet?.iconName ?? 'wallet';
    _selectedColor = widget.wallet?.color ?? 0xFF4CAF50;
    _selectedType = widget.wallet?.type ?? 'cash';
    _isDefault = widget.wallet?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.wallet != null;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = textPrimary.withAlpha(153);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final dividerColor = Theme.of(context).colorScheme.outline;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: dividerColor, width: 1)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: textSecondary, size: 24),
                ),
                const Spacer(),
                Text(
                  isEditing ? l10n.editWallet : l10n.addWallet,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                if (isEditing && !widget.wallet!.isDefault)
                  GestureDetector(
                    onTap: () => _deleteWallet(context, l10n),
                    child: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error, size: 24),
                  )
                else
                  const SizedBox(width: 24),
              ],
            ),
          ),
          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: 20 + MediaQuery.of(context).padding.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name field
                  _buildSectionTitle(l10n.walletName, textPrimary),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: textPrimary),
                    onChanged: (_) {
                      if (_nameError != null) {
                        setState(() => _nameError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: l10n.enterWalletName,
                      errorText: _nameError,
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: dividerColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _nameError != null ? Theme.of(context).colorScheme.error : dividerColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: textPrimary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Wallet type
                  _buildSectionTitle(l10n.walletType, textPrimary),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _walletTypes.map((type) {
                      final isSelected = _selectedType == type;
                      final primaryColor = Theme.of(context).colorScheme.primary;
                      final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedType = type),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? primaryColor : dividerColor,
                            ),
                          ),
                          child: Text(
                            _getTypeName(type, l10n),
                            style: TextStyle(
                              color: isSelected ? onPrimaryColor : textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Icon picker
                  _buildSectionTitle(l10n.icon, textPrimary),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: dividerColor),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _walletIcons.map((iconName) {
                        final isSelected = _selectedIcon == iconName;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIcon = iconName),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(_selectedColor).withAlpha(30)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Color(_selectedColor)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              IconConstants.getIcon(iconName),
                              color: isSelected
                                  ? Color(_selectedColor)
                                  : textSecondary,
                              size: 24,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Color picker
                  _buildSectionTitle(l10n.color, textPrimary),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: dividerColor),
                    ),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _colors.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedColor = color),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Color(color),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? textPrimary : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Color(color).withAlpha(80),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      )
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: color == 0xFFFFFFFF
                                        ? Colors.black
                                        : Colors.white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Default wallet toggle
                  GestureDetector(
                    onTap: () => setState(() => _isDefault = !_isDefault),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: dividerColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _isDefault ? textPrimary : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: _isDefault ? textPrimary : textSecondary,
                                width: 2,
                              ),
                            ),
                            child: _isDefault
                                ? Icon(
                                    Icons.check,
                                    color: surfaceColor,
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.setAsDefault,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Pre-select this wallet for new transactions',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saveWallet,
                      child: Text(
                        isEditing ? l10n.update : l10n.save,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textPrimary) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    );
  }

  String _getTypeName(String type, AppLocalizations l10n) {
    switch (type) {
      case 'cash':
        return l10n.cash;
      case 'bank':
        return l10n.bankAccount;
      case 'credit':
        return l10n.creditCard;
      case 'ewallet':
        return l10n.eWallet;
      default:
        return type;
    }
  }

  void _saveWallet() {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = l10n.walletNameRequired);
      return;
    }

    final notifier = ref.read(walletsProvider.notifier);

    if (widget.wallet != null) {
      notifier.updateWallet(
        widget.wallet!.copyWith(
          name: name,
          iconName: _selectedIcon,
          color: _selectedColor,
          type: _selectedType,
          isDefault: _isDefault,
        ),
      );
    } else {
      notifier.addWallet(
        name: name,
        iconName: _selectedIcon,
        color: _selectedColor,
        type: _selectedType,
        isDefault: _isDefault,
      );
    }

    Navigator.pop(context);
  }

  void _deleteWallet(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
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
    if (confirmed == true) {
      ref.read(walletsProvider.notifier).deleteWallet(widget.wallet!.id);
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }
}
