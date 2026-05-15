import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/providers/group_provider.dart';
import 'package:mobile_expense_tracker/features/groups/groups_screen.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class GroupsCard extends ConsumerWidget {
  const GroupsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final groups = ref.watch(groupsProvider);
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final dividerColor = Theme.of(context).colorScheme.outline;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.group_outlined, color: textPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.groups,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              if (groups.isNotEmpty)
                Text(
                  '${groups.length} ${groups.length == 1 ? l10n.group : l10n.groups}',
                  style: TextStyle(color: textSecondary, fontSize: 14),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (groups.isEmpty) ...[
            Text(
              l10n.noGroupsYet,
              style: TextStyle(color: textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const GroupsScreen()),
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.createGroup,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ] else ...[
            ...groups.take(3).map((group) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          group.name,
                          style: TextStyle(color: textPrimary, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 16),
                    ],
                  ),
                )),
            if (groups.length > 3)
              Text(
                '+ ${groups.length - 3} ${l10n.more}',
                style: TextStyle(color: textSecondary, fontSize: 12),
              ),
          ],
        ],
      ),
    );
  }
}
