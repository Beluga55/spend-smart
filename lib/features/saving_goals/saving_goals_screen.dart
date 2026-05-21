import 'package:mobile_expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/constants/icon_constants.dart';
import 'package:mobile_expense_tracker/core/providers/saving_goals_provider.dart';
import 'package:mobile_expense_tracker/core/providers/currency_provider.dart';
import 'package:mobile_expense_tracker/core/models/saving_goal.dart';
import 'package:mobile_expense_tracker/features/saving_goals/widgets/saving_goal_modal.dart';
import 'package:mobile_expense_tracker/features/saving_goals/widgets/goal_detail_modal.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class SavingGoalsScreen extends ConsumerWidget {
  const SavingGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final goals = ref.watch(savingGoalsProvider);
    final currency = ref.watch(currencyProvider);

    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(
      context,
    ).colorScheme.onSurface.withAlpha(153);
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.savingGoals)),
      body: goals.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.savings_outlined,
                    size: 64,
                    color: textSecondary.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noSavingGoalsYet,
                    style: TextStyle(color: textSecondary, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.tapToAddFirstGoal,
                    style: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return _buildGoalCard(
                  context,
                  ref,
                  goal,
                  currency.symbol,
                  l10n,
                  isDark,
                  textPrimary,
                  textSecondary,
                  surfaceColor,
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'saving_goals_fab',
        onPressed: () => _showAddGoalModal(context, ref, l10n),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGoalCard(
    BuildContext context,
    WidgetRef ref,
    SavingGoal goal,
    String currencySymbol,
    AppLocalizations l10n,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
  ) {
    final progressColor = _getProgressColor(goal.progress, isDark, context);

    return GestureDetector(
      onTap: () => _showGoalDetailModal(context, ref, goal, l10n),
      onLongPress: () => _showEditGoalModal(context, ref, goal, l10n),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: textSecondary.withAlpha(26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Color(goal.color).withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    IconConstants.getIcon(goal.iconName),
                    color: Color(goal.color),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: textPrimary,
                        ),
                      ),
                      if (goal.isCompleted)
                        Text(
                          l10n.goalCompleted,
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else if (goal.daysRemaining != null)
                        Text(
                          goal.daysRemaining! > 0
                              ? l10n.daysRemaining(goal.daysRemaining!)
                              : l10n.deadlinePassed,
                          style: TextStyle(
                            color: goal.daysRemaining! <= 7
                                ? Colors.orange
                                : textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currencySymbol${goal.currentAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      '$currencySymbol${goal.targetAmount.toStringAsFixed(0)}',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progress / 100,
                backgroundColor: textSecondary.withAlpha(26),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.progress.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: progressColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (goal.deadline != null && !goal.isCompleted)
                  Text(
                    '${l10n.deadline}: ${_formatDate(goal.deadline!)}',
                    style: TextStyle(color: textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progress, bool isDark, BuildContext context) {
    final semantic = Theme.of(context).extension<SemanticColors>();
    if (progress >= 100) return semantic?.success ?? Colors.green;
    if (progress >= 75) {
      return semantic?.success ??
          (isDark ? Colors.lightGreen : Colors.green.shade400);
    }
    if (progress >= 50) return Colors.orange;
    if (progress >= 25) {
      return isDark ? Colors.orange.shade300 : Colors.orange.shade400;
    }
    return isDark ? Colors.orange.shade200 : Colors.orange.shade300;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showAddGoalModal(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SavingGoalModal(
        onSave: (name, targetAmount, deadline, iconName, color) {
          ref
              .read(savingGoalsProvider.notifier)
              .addGoal(
                name: name,
                targetAmount: targetAmount,
                deadline: deadline,
                iconName: iconName,
                color: color,
              );
        },
      ),
    );
  }

  void _showEditGoalModal(
    BuildContext context,
    WidgetRef ref,
    SavingGoal goal,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SavingGoalModal(
        goal: goal,
        onSave: (name, targetAmount, deadline, iconName, color) {
          ref
              .read(savingGoalsProvider.notifier)
              .updateGoal(
                goal.copyWith(
                  name: name,
                  targetAmount: targetAmount,
                  deadline: deadline,
                  iconName: iconName,
                  color: color,
                  clearDeadline: deadline == null && goal.deadline != null,
                ),
              );
        },
        onDelete: () {
          ref.read(savingGoalsProvider.notifier).deleteGoal(goal.id);
        },
      ),
    );
  }

  void _showGoalDetailModal(
    BuildContext context,
    WidgetRef ref,
    SavingGoal goal,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoalDetailModal(
        goal: goal,
        onAddMoney: (amount) {
          ref.read(savingGoalsProvider.notifier).addToGoal(goal.id, amount);
        },
        onWithdraw: (amount) {
          ref
              .read(savingGoalsProvider.notifier)
              .withdrawFromGoal(goal.id, amount);
        },
      ),
    );
  }
}
