import 'package:flutter/material.dart';
import 'icon_constants.dart';

class AppConstants {
  static const String appName = 'Expense Tracker';

  // Supabase Configuration
  static const String supabaseUrl = 'https://gvjqpsyypiyathjhjkrz.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_CNz49j_lu7pC1zjm6i_9Zg_Vj5wQe8j';

  // Google OAuth Web Client ID (from Google Cloud Console → Credentials)
  // This is the *web* client ID, NOT the Android client ID
  static const String googleWebClientId =
      '370726002669-du5eg8hhhk2laj8nt1eqove9vfufkt8c.apps.googleusercontent.com';

  static const List<DefaultCategory> defaultCategories = [
    DefaultCategory(name: 'Food', iconName: 'restaurant', color: 0xFFFF6B6B),
    DefaultCategory(
      name: 'Transport',
      iconName: 'directions_car',
      color: 0xFF4ECDC4,
    ),
    DefaultCategory(
      name: 'Shopping',
      iconName: 'shopping_bag',
      color: 0xFFFFE66D,
    ),
    DefaultCategory(name: 'Bills', iconName: 'receipt_long', color: 0xFF95E1D3),
    DefaultCategory(
      name: 'Entertainment',
      iconName: 'movie',
      color: 0xFFA8E6CF,
    ),
    DefaultCategory(
      name: 'Health',
      iconName: 'medical_services',
      color: 0xFFDDA0DD,
    ),
    DefaultCategory(name: 'Other', iconName: 'more_horiz', color: 0xFFB8B8B8),
  ];

  static const List<DefaultCategory> defaultIncomeCategories = [
    DefaultCategory(name: 'Salary', iconName: 'work', color: 0xFF4CAF50),
    DefaultCategory(name: 'Freelance', iconName: 'computer', color: 0xFF2196F3),
    DefaultCategory(name: 'Investment', iconName: 'savings', color: 0xFFFF9800),
    DefaultCategory(
      name: 'Business',
      iconName: 'storefront',
      color: 0xFF9C27B0,
    ),
    DefaultCategory(name: 'Rental', iconName: 'home', color: 0xFF795548),
    DefaultCategory(name: 'Gift', iconName: 'credit_card', color: 0xFFE91E63),
    DefaultCategory(name: 'Other', iconName: 'more_horiz', color: 0xFF9E9E9E),
  ];

  static const int budgetWarningThreshold = 80;
  static const int budgetCriticalThreshold = 100;
}

class DefaultCategory {
  final String name;
  final String iconName;
  final int color;

  const DefaultCategory({
    required this.name,
    required this.iconName,
    required this.color,
  });

  IconData get iconData => IconConstants.getIcon(iconName);
  Color get colorValue => Color(color);
}
