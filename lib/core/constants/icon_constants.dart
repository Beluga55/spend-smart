import 'package:flutter/material.dart';

class AppIconData {
  final String name;
  final IconData icon;

  const AppIconData(this.name, this.icon);
}

class IconConstants {
  static const Map<String, IconData> iconMap = {
    'restaurant': Icons.restaurant,
    'directions_car': Icons.directions_car,
    'shopping_bag': Icons.shopping_bag,
    'receipt_long': Icons.receipt_long,
    'movie': Icons.movie,
    'medical_services': Icons.medical_services,
    'home': Icons.home,
    'flight': Icons.flight,
    'school': Icons.school,
    'sports': Icons.sports,
    'pets': Icons.pets,
    'more_horiz': Icons.more_horiz,
    'category': Icons.category,
    'checkroom': Icons.checkroom,
    'coffee': Icons.coffee,
    'local_grocery_store': Icons.local_grocery_store,
    'local_gas_station': Icons.local_gas_station,
    'local_hospital': Icons.local_hospital,
    'work': Icons.work,
    'games': Icons.games,
    'music_note': Icons.music_note,
    'sports_esports': Icons.sports_esports,
    'fitness_center': Icons.fitness_center,
    'spa': Icons.spa,
    'child_care': Icons.child_care,
    'credit_card': Icons.credit_card,
    'savings': Icons.savings,
    'account_balance': Icons.account_balance,
    'phone_android': Icons.phone_android,
    'computer': Icons.computer,
    'tv': Icons.tv,
    'headphones': Icons.headphones,
    'camera': Icons.camera,
    'book': Icons.book,
    'newspaper': Icons.newspaper,
    'beach_access': Icons.beach_access,
    'pool': Icons.pool,
    'golf_course': Icons.golf_course,
    'ice_skating': Icons.ice_skating,
    'surfing': Icons.surfing,
    'dock': Icons.dock,
    'airplanemode_active': Icons.airplanemode_active,
    'train': Icons.train,
    'directions_bus': Icons.directions_bus,
    'two_wheeler': Icons.two_wheeler,
    'electric_car': Icons.electric_car,
    'local_taxi': Icons.local_taxi,
    'hotel': Icons.hotel,
    'bakery_dining': Icons.bakery_dining,
    'fastfood': Icons.fastfood,
    'icecream': Icons.icecream,
    'local_bar': Icons.local_bar,
    'local_cafe': Icons.local_cafe,
    'local_pizza': Icons.local_pizza,
    'lunch_dining': Icons.lunch_dining,
    'dinner_dining': Icons.dinner_dining,
    'breakfast_dining': Icons.breakfast_dining,
    'add_shopping_cart': Icons.add_shopping_cart,
    'shopping_cart': Icons.shopping_cart,
    'local_mall': Icons.local_mall,
    'storefront': Icons.storefront,
    'add_business': Icons.add_business,
    'business_center': Icons.business_center,
  };

  static const List<String> iconNames = [
    'restaurant',
    'directions_car',
    'shopping_bag',
    'receipt_long',
    'movie',
    'medical_services',
    'home',
    'flight',
    'school',
    'sports',
    'pets',
    'more_horiz',
    'category',
  ];

  static IconData getIcon(String name) {
    return iconMap[name] ?? Icons.category;
  }

  static IconData getIconFromCode(int code) {
    for (final entry in iconMap.entries) {
      if (entry.value.codePoint == code) {
        return entry.value;
      }
    }
    return Icons.category;
  }
}