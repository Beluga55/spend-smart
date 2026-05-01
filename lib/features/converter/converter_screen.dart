import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:mobile_expense_tracker/core/constants/currency_constants.dart';
import 'package:mobile_expense_tracker/core/providers/currency_converter_provider.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class ConverterScreen extends ConsumerStatefulWidget {
  const ConverterScreen({super.key});

  @override
  ConsumerState<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends ConsumerState<ConverterScreen> {
  final _amountController = TextEditingController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currencyConverterProvider.notifier).init();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(currencyConverterProvider);
    final currencies = ref.watch(currencyListProvider);

    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    final fromCurrency = CurrencyConstants.getCurrency(state.fromCurrency);
    final toCurrency = CurrencyConstants.getCurrency(state.toCurrency);

    if (!_isInitialized && state.amount == 0) {
      _amountController.text = '';
      _isInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.currencyConverter),
        actions: [
          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(currencyConverterProvider.notifier).refreshRates(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withAlpha(76)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildCurrencySection(
                    label: l10n.from,
                    currency: fromCurrency,
                    selectedCode: state.fromCurrency,
                    currencies: currencies,
                    amount: state.amount.toStringAsFixed(2),
                    controller: _amountController,
                    onCurrencyChanged: (code) {
                      ref.read(currencyConverterProvider.notifier).setFromCurrency(code);
                    },
                    onAmountChanged: (value) {
                      final amount = double.tryParse(value) ?? 0;
                      ref.read(currencyConverterProvider.notifier).setAmount(amount);
                    },
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    backgroundColor: backgroundColor,
                    surfaceColor: surfaceColor,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: IconButton(
                      onPressed: () {
                        ref.read(currencyConverterProvider.notifier).swapCurrencies();
                      },
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white : AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.swap_vert,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCurrencySection(
                    label: l10n.to,
                    currency: toCurrency,
                    selectedCode: state.toCurrency,
                    currencies: currencies,
                    amount: state.result.toStringAsFixed(2),
                    controller: null,
                    isReadOnly: true,
                    onCurrencyChanged: (code) {
                      ref.read(currencyConverterProvider.notifier).setToCurrency(code);
                    },
                    onAmountChanged: (_) {},
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    backgroundColor: backgroundColor,
                    surfaceColor: surfaceColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.exchangeRate,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '1 ${fromCurrency.code} = ${_getExchangeRate(state, fromCurrency.code, toCurrency.code).toStringAsFixed(4)} ${toCurrency.code}',
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.lastUpdated,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        state.lastUpdated != null
                            ? _formatLastUpdated(state.lastUpdated!, l10n)
                            : '-',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildQuickAmounts(l10n, textPrimary, textSecondary, surfaceColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencySection({
    required String label,
    required Currency currency,
    required String selectedCode,
    required List<Currency> currencies,
    required String amount,
    required TextEditingController? controller,
    required Function(String) onCurrencyChanged,
    required Function(String) onAmountChanged,
    required Color textPrimary,
    required Color textSecondary,
    required Color backgroundColor,
    required Color surfaceColor,
    bool isReadOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: () => _showCurrencyPicker(
                  context,
                  currencies,
                  selectedCode,
                  onCurrencyChanged,
                  textPrimary,
                  textSecondary,
                  surfaceColor,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${currency.code} ${currency.symbol}',
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, color: textSecondary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: isReadOnly
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${currency.symbol}$amount',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        prefixText: '${currency.symbol} ',
                        prefixStyle: TextStyle(
                          color: textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        hintText: '0.00',
                        hintStyle: TextStyle(
                          color: textSecondary.withAlpha(128),
                          fontSize: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: onAmountChanged,
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAmounts(AppLocalizations l10n, Color textPrimary, Color textSecondary, Color surfaceColor) {
    final quickAmounts = [100, 500, 1000, 5000];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.quickAmounts,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: quickAmounts.map((amount) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton(
                    onPressed: () {
                      _amountController.text = amount.toString();
                      ref.read(currencyConverterProvider.notifier).setAmount(amount.toDouble());
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      amount >= 1000 ? '${amount ~/ 1000}K' : amount.toString(),
                      style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(
    BuildContext context,
    List<Currency> currencies,
    String selectedCode,
    Function(String) onCurrencyChanged,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
  ) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final dividerColor = Theme.of(context).colorScheme.outline;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select Currency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: currencies.length,
                itemBuilder: (context, index) {
                  final currency = currencies[index];
                  final isSelected = currency.code == selectedCode;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: InkWell(
                      onTap: () {
                        onCurrencyChanged(currency.code);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? textPrimary.withAlpha(13) : backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? textPrimary : dividerColor,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  currency.symbol,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                currency.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              currency.code,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.check, color: textPrimary, size: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(ctx).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  double _getExchangeRate(CurrencyConverterState state, String from, String to) {
    if (state.rates.isEmpty) return 0;
    final fromRate = state.rates[from] ?? 1.0;
    final toRate = state.rates[to] ?? 1.0;
    return toRate / fromRate;
  }

  String _formatLastUpdated(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} ${l10n.minutesAgo}';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ${l10n.hoursAgo}';
    } else {
      return '${diff.inDays} ${l10n.daysAgo}';
    }
  }
}


