import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

class CurrencyConverterService {
  static const String _ratesBoxName = 'currency_rates';
  static const String _lastFetchKey = 'last_fetch_timestamp';
  static const Duration _cacheValidDuration = Duration(hours: 24);

  Box? _ratesBox;

  Future<void> init() async {
    _ratesBox = await Hive.openBox(_ratesBoxName);
  }

  Future<Map<String, double>> fetchRates(String baseCurrency) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.frankfurter.app/latest?from=$baseCurrency'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = Map<String, double>.from(
          (data['rates'] as Map).map(
            (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
          ),
        );
        rates[baseCurrency] = 1.0;
        await _cacheRates(rates, baseCurrency);
        return rates;
      } else {
        throw Exception('Failed to fetch rates: ${response.statusCode}');
      }
    } catch (e) {
      final cached = getCachedRates(baseCurrency);
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }

  Future<void> _cacheRates(Map<String, double> rates, String baseCurrency) async {
    if (_ratesBox == null) await init();
    await _ratesBox!.put('rates_$baseCurrency', rates);
    await _ratesBox!.put('${_lastFetchKey}_$baseCurrency', DateTime.now().toIso8601String());
  }

  Map<String, double>? getCachedRates(String baseCurrency) {
    if (_ratesBox == null) return null;

    final rates = _ratesBox!.get('rates_$baseCurrency');
    if (rates == null) return null;

    final lastFetchStr = _ratesBox!.get('${_lastFetchKey}_$baseCurrency');
    if (lastFetchStr == null) return null;

    final lastFetch = DateTime.parse(lastFetchStr);
    if (DateTime.now().difference(lastFetch) > _cacheValidDuration) {
      return null;
    }

    return Map<String, double>.from(rates);
  }

  double convert(double amount, String from, String to, Map<String, double> rates) {
    if (from == to) return amount;

    final fromRate = rates[from] ?? 1.0;
    final toRate = rates[to] ?? 1.0;

    final amountInBase = amount / fromRate;
    return amountInBase * toRate;
  }

  bool isCacheValid(String baseCurrency) {
    if (_ratesBox == null) return false;

    final lastFetchStr = _ratesBox!.get('${_lastFetchKey}_$baseCurrency');
    if (lastFetchStr == null) return false;

    final lastFetch = DateTime.parse(lastFetchStr);
    return DateTime.now().difference(lastFetch) <= _cacheValidDuration;
  }
}