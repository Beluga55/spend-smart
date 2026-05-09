import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/providers/ai_provider.dart';

class AISettingsModal extends ConsumerWidget {
  const AISettingsModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final isActive = settings.hasAnyKey;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 4),
            _statusChip(isActive, textPrimary),
            const SizedBox(height: 16),
            Text(
              'AI helps you scan receipts, auto-categorize expenses, and get spending insights.',
              style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            _featureRow(Icons.receipt_long, 'Receipt Scanning', AIFeature.receiptParsing, settings, ref, textPrimary),
            _featureRow(Icons.auto_fix_high, 'Auto-Categorize', AIFeature.autoCategorize, settings, ref, textPrimary),
            _featureRow(Icons.insights, 'Monthly Insights', AIFeature.monthlyInsights, settings, ref, textPrimary),
            _featureRow(Icons.chat_bubble_outline, 'Spending Chat', AIFeature.chatQuery, settings, ref, textPrimary),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(aiInsightsProvider.notifier).refresh();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text('Regenerate Insights'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, AIFeature feature, AISettings settings, WidgetRef ref, Color textPrimary, {bool enabled = true}) {
    final isOn = settings.enabledFeatures.contains(feature);
    final color = enabled ? textPrimary : textPrimary.withAlpha(100);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: TextStyle(color: color, fontSize: 14))),
          Switch(
            value: enabled ? isOn : false,
            onChanged: enabled ? (val) => ref.read(aiSettingsProvider.notifier).toggleFeature(feature, val) : null,
          ),
        ],
      ),
    );
  }

  Widget _statusChip(bool isActive, Color textPrimary) {
    final color = isActive ? Colors.green : Colors.orange;
    final label = isActive ? 'Active' : 'Not configured';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isActive ? Icons.check_circle : Icons.info_outline, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
        ],
      ),
    );
  }
}
