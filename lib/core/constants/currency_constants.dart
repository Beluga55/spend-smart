class Currency {
  final String code;
  final String symbol;
  final String name;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class CurrencyConstants {
  static const List<Currency> currencies = [
    Currency(code: 'USD', symbol: '\$', name: 'US Dollar'),
    Currency(code: 'EUR', symbol: '€', name: 'Euro'),
    Currency(code: 'GBP', symbol: '£', name: 'British Pound'),
    Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
    Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
    Currency(code: 'KRW', symbol: '₩', name: 'South Korean Won'),
    Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
    Currency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
    Currency(code: 'MYR', symbol: 'RM', name: 'Malaysian Ringgit'),
    Currency(code: 'THB', symbol: '฿', name: 'Thai Baht'),
    Currency(code: 'IDR', symbol: 'Rp', name: 'Indonesian Rupiah'),
    Currency(code: 'PHP', symbol: '₱', name: 'Philippine Peso'),
    Currency(code: 'VND', symbol: '₫', name: 'Vietnamese Dong'),
    Currency(code: 'TWD', symbol: 'NT\$', name: 'Taiwan Dollar'),
    Currency(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar'),
  ];

  static Currency getCurrency(String code) {
    return currencies.firstWhere(
      (c) => c.code == code,
      orElse: () => currencies.first,
    );
  }
}