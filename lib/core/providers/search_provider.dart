import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/core/models/category.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';

class SearchState {
  final String query;
  final double? minAmount;
  final double? maxAmount;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId;

  const SearchState({
    this.query = '',
    this.minAmount,
    this.maxAmount,
    this.startDate,
    this.endDate,
    this.categoryId,
  });

  bool get hasFilters =>
      minAmount != null ||
      maxAmount != null ||
      startDate != null ||
      endDate != null ||
      categoryId != null;

  SearchState copyWith({
    String? query,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearCategoryId = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
    );
  }

  SearchState clear() {
    return const SearchState();
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier() : super(const SearchState());

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }

  void setAmountRange(double? min, double? max) {
    state = state.copyWith(
      minAmount: min,
      maxAmount: max,
      clearMinAmount: min == null,
      clearMaxAmount: max == null,
    );
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDate: start,
      endDate: end,
      clearStartDate: start == null,
      clearEndDate: end == null,
    );
  }

  void setCategory(String? categoryId) {
    state = state.copyWith(
      categoryId: categoryId,
      clearCategoryId: categoryId == null,
    );
  }

  void clearFilters() {
    state = state.copyWith(
      query: '',
      clearMinAmount: true,
      clearMaxAmount: true,
      clearStartDate: true,
      clearEndDate: true,
      clearCategoryId: true,
    );
  }

  void clear() {
    state = const SearchState();
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier();
});

final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expensesProvider);
  final categories = ref.watch(categoriesProvider);
  final search = ref.watch(searchProvider);
  final selectedMonth = ref.watch(selectedMonthProvider);

  List<Expense> filtered = expenses.where((e) =>
    e.date.month == selectedMonth.month && e.date.year == selectedMonth.year
  ).toList();

  if (search.query.isNotEmpty) {
    final queryLower = search.query.toLowerCase();
    filtered = filtered.where((e) {
      Category category = categories.cast<Category>().firstWhere(
        (c) => c.id == e.categoryId,
        orElse: () => Category(id: '', name: '', iconName: '', color: 0),
      );
      final noteMatch = e.note?.toLowerCase().contains(queryLower) ?? false;
      final categoryMatch = category.name.toLowerCase().contains(queryLower);
      return noteMatch || categoryMatch;
    }).toList();
  }

  if (search.minAmount != null) {
    filtered = filtered.where((e) => e.amount >= search.minAmount!).toList();
  }

  if (search.maxAmount != null) {
    filtered = filtered.where((e) => e.amount <= search.maxAmount!).toList();
  }

  if (search.startDate != null) {
    filtered = filtered.where((e) =>
      e.date.isAfter(search.startDate!) || _isSameDay(e.date, search.startDate!)
    ).toList();
  }

  if (search.endDate != null) {
    filtered = filtered.where((e) =>
      e.date.isBefore(search.endDate!) || _isSameDay(e.date, search.endDate!)
    ).toList();
  }

  if (search.categoryId != null) {
    filtered = filtered.where((e) => e.categoryId == search.categoryId).toList();
  }

  filtered.sort((a, b) => b.date.compareTo(a.date));
  return filtered;
});

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}