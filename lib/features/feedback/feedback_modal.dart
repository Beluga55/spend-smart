import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum FeedbackCategory { bugReport, featureRequest }

class FeedbackModal extends ConsumerStatefulWidget {
  const FeedbackModal({super.key});

  @override
  ConsumerState<FeedbackModal> createState() => _FeedbackModalState();
}

class _FeedbackModalState extends ConsumerState<FeedbackModal> {
  FeedbackCategory _selectedCategory = FeedbackCategory.bugReport;
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final dividerColor = Theme.of(context).colorScheme.outline;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(
      context,
    ).colorScheme.onSurface.withAlpha(153);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.sendFeedback,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.feedbackCategory,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCategoryChip(
                    label: l10n.bugReport,
                    isSelected: _selectedCategory == FeedbackCategory.bugReport,
                    onTap: () => setState(
                      () => _selectedCategory = FeedbackCategory.bugReport,
                    ),
                    textPrimary: textPrimary,
                    surfaceColor: surfaceColor,
                    dividerColor: dividerColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildCategoryChip(
                    label: l10n.featureRequest,
                    isSelected:
                        _selectedCategory == FeedbackCategory.featureRequest,
                    onTap: () => setState(
                      () => _selectedCategory = FeedbackCategory.featureRequest,
                    ),
                    textPrimary: textPrimary,
                    surfaceColor: surfaceColor,
                    dividerColor: dividerColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              l10n.feedbackMessage,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              maxLength: 1000,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                hintText: l10n.feedbackMessage,
                hintStyle: TextStyle(color: textSecondary),
                filled: true,
                fillColor: backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: textPrimary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              buildCounter:
                  (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) {
                    return Text(
                      '$currentLength / $maxLength',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    );
                  },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                child: _isSubmitting
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      )
                    : Text(l10n.submit),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color surfaceColor,
    required Color dividerColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? textPrimary.withAlpha(13) : surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? textPrimary : dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final userId = SupabaseService.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final category = _selectedCategory == FeedbackCategory.bugReport
          ? 'bug_report'
          : 'feature_request';

      await SupabaseService.client.from('feedback').insert({
        'user_id': userId,
        'category': category,
        'message': message,
        'app_version': '${packageInfo.version}+${packageInfo.buildNumber}',
      });

      if (mounted) {
        Navigator.pop(context);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.feedbackSent),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Feedback submission error: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.feedbackError),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
