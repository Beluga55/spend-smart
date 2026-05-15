import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/providers/group_provider.dart';
import 'package:mobile_expense_tracker/features/groups/widgets/create_group_modal.dart';
import 'package:mobile_expense_tracker/features/groups/widgets/join_group_modal.dart';
import 'package:mobile_expense_tracker/features/groups/group_detail_screen.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final groups = ref.watch(groupsProvider);
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withAlpha(153);
    final dividerColor = Theme.of(context).colorScheme.outline;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.groups)),
      body: groups.isEmpty
          ? _buildEmptyState(context, l10n, textSecondary)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupDetailScreen(group: group),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: dividerColor),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Icon(Icons.group, color: Theme.of(context).colorScheme.onPrimaryContainer),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Invite: ${group.inviteCode}',
                                style: TextStyle(color: textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: textPrimary.withAlpha(128)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'join_group_fab',
            onPressed: () => _showJoinGroupModal(context),
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'create_group_fab',
            onPressed: () => _showCreateGroupModal(context),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 64, color: textSecondary),
          const SizedBox(height: 16),
          Text(
            l10n.noGroupsYet,
            style: TextStyle(fontSize: 16, color: textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showCreateGroupModal(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.createGroup),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateGroupModal(),
    );
  }

  void _showJoinGroupModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const JoinGroupModal(),
    );
  }
}
