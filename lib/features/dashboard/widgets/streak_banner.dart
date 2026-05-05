import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mobile_expense_tracker/core/providers/providers.dart';

class StreakBanner extends ConsumerStatefulWidget {
  const StreakBanner({super.key});

  @override
  ConsumerState<StreakBanner> createState() => _StreakBannerState();
}

class _StreakBannerState extends ConsumerState<StreakBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final showBanner = Hive.box('settings').get('showStreakBanner', defaultValue: true) as bool;
    if (!showBanner) return const SizedBox.shrink();

    final streak = ref.watch(spendingStreakProvider)['streak'] ?? 0;
    if (streak < 2 || _dismissed) return const SizedBox.shrink();

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dismissedDate = Hive.box('settings').get('streakDismissedDate');
    if (dismissedDate == today) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Text('\u{1F525}', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$streak-day streak \u2014 keep it up!',
              style: TextStyle(fontWeight: FontWeight.w600, color: cs.onPrimaryContainer),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: cs.onPrimaryContainer),
            onPressed: () {
              Hive.box('settings').put('streakDismissedDate', today);
              setState(() => _dismissed = true);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
