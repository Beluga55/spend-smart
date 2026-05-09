import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/providers/ai_provider.dart';
import 'package:mobile_expense_tracker/core/utils/ai_formatter.dart';

class AIInsightsCard extends ConsumerWidget {
  const AIInsightsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiSettings = ref.watch(aiSettingsProvider);
    final insightsAsync = ref.watch(aiInsightsProvider);
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final bg = Theme.of(context).scaffoldBackgroundColor;

    if (!aiSettings.enabledFeatures.contains(AIFeature.monthlyInsights) ||
        !aiSettings.hasAnyKey) {
      return const SizedBox.shrink();
    }

    return insightsAsync.when(
      data: (insights) {
        if (insights == null) return const SizedBox.shrink();
        if (insights.isEmpty) {
          return _errorCard(
            'Could not generate insights. Check your API keys in Settings → AI Assistant.',
            textPrimary,
            textSecondary,
            bg,
            onRefresh: () => ref.read(aiInsightsProvider.notifier).refresh(),
          );
        }
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF6C63FF).withAlpha(25),
                const Color(0xFF42A5F5).withAlpha(15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6C63FF).withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome,
                        color: Color(0xFF6C63FF), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('AI Insights',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: textPrimary)),
                            const SizedBox(width: 8),
                            _ProviderChip(
                              provider: ref.read(aiInsightsProvider.notifier).lastProvider,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        RichText(
                          text: TextSpan(
                            children: AIFormatter.toSpans(
                              AIFormatter.format(insights),
                              baseStyle: TextStyle(
                                color: textSecondary,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  _DismissButton(
                    onDismiss: () => ref.read(aiInsightsProvider.notifier).dismiss(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        child: Row(
          children: [
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 12),
            Text('Generating insights…',
                style: TextStyle(color: textSecondary, fontSize: 13)),
          ],
        ),
      ),
      error: (e, _) => _errorCard(
        'AI error: ${e.toString().split('\n').first}',
        textPrimary,
        textSecondary,
        bg,
        onRefresh: () => ref.read(aiInsightsProvider.notifier).refresh(),
      ),
    );
  }

  Widget _errorCard(
    String msg,
    Color textPrimary,
    Color textSecondary,
    Color bg, {
    VoidCallback? onRefresh,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withAlpha(80)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(msg,
                style: TextStyle(
                    color: textSecondary, fontSize: 12, height: 1.3)),
          ),
          if (onRefresh != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 18, color: Colors.orange),
              onPressed: onRefresh,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Retry',
            ),
        ],
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  final VoidCallback onDismiss;

  const _DismissButton({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(20),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.close,
          size: 14,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
        ),
      ),
    );
  }
}

class _ProviderChip extends StatelessWidget {
  final String? provider;

  const _ProviderChip({this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider == null) return const SizedBox.shrink();
    final isGemini = provider == 'Gemini';
    final color = isGemini ? const Color(0xFF4285F4) : const Color(0xFF76B900);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        provider!,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
