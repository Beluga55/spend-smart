import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mobile_expense_tracker/core/models/group.dart';
import 'package:mobile_expense_tracker/core/models/group_member.dart';
import 'package:mobile_expense_tracker/core/models/group_expense.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_split.dart';
import 'package:mobile_expense_tracker/core/models/group_expense_item.dart';
import 'package:mobile_expense_tracker/core/models/expense.dart';
import 'package:mobile_expense_tracker/core/models/income.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:mobile_expense_tracker/core/providers/group_provider.dart';
import 'package:mobile_expense_tracker/core/utils/design_utils.dart';
import 'package:mobile_expense_tracker/core/services/group_realtime_service.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  final Group group;

  const GroupSettingsScreen({super.key, required this.group});

  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  late TextEditingController _nameController;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final members = ref.watch(groupMembersProvider(widget.group.id));
    final currentUserId = SupabaseService.currentUser?.id;

    final currentMember = members.firstWhere(
      (m) => m.userId == currentUserId,
      orElse: () => GroupMember(
        id: '',
        groupId: widget.group.id,
        displayName: '',
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    final isAdmin = currentMember.role == 'admin';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.groupSettings,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Group Info Card
            _buildGroupInfoCard(context, l10n, theme),
            const SizedBox(height: 24),

            // Admin Actions Section (only for admins)
            if (isAdmin) ...[
              _buildSectionHeader(context, l10n, 'Admin Actions'),
              const SizedBox(height: 8),
              _buildEditNameTile(context, l10n, theme),
              _buildDivider(),
              _buildDeleteGroupTile(context, l10n, theme),
              const SizedBox(height: 32),
            ],

            // Member Management Section (admins see all members with actions, members see read-only list)
            _buildSectionHeader(context, l10n, l10n.members),
            const SizedBox(height: 8),
            _buildMembersList(
              context,
              l10n,
              theme,
              members,
              currentUserId,
              isAdmin,
            ),
            const SizedBox(height: 32),

            // Danger Zone - Leave Group (available to all)
            _buildSectionHeader(context, l10n, 'Danger Zone'),
            const SizedBox(height: 8),
            _buildLeaveGroupTile(context, l10n, theme, currentMember),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    AppLocalizations l10n,
    String title,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildGroupInfoCard(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: DesignUtils.getColorFromId(
                    widget.group.id,
                  ).withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.groups_rounded,
                  color: DesignUtils.getColorFromId(widget.group.id),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.group.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created ${DateFormat('MMM d, yyyy').format(widget.group.createdAt)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.qr_code,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.group.inviteCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: widget.group.inviteCode),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.copiedToClipboard),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditNameTile(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    if (_isEditingName) {
      return ListTile(
        leading: Icon(Icons.edit, color: theme.colorScheme.primary),
        title: TextField(
          controller: _nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Group name',
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _saveGroupName(),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.close, color: theme.colorScheme.error),
              onPressed: () {
                setState(() {
                  _isEditingName = false;
                  _nameController.text = widget.group.name;
                });
              },
            ),
            IconButton(
              icon: Icon(Icons.check, color: theme.colorScheme.primary),
              onPressed: _saveGroupName,
            ),
          ],
        ),
      );
    }

    return ListTile(
      leading: Icon(Icons.edit, color: theme.colorScheme.primary),
      title: const Text('Edit Group Name'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => setState(() => _isEditingName = true),
    );
  }

  Future<void> _saveGroupName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || newName == widget.group.name) {
      setState(() => _isEditingName = false);
      return;
    }

    try {
      final updatedGroup = widget.group.copyWith(
        name: newName,
        updatedAt: DateTime.now(),
        syncStatus: 'pending',
      );

      await ref.read(groupsProvider.notifier).updateGroup(updatedGroup);

      // Sync to Supabase
      await SupabaseService.client
          .from('groups')
          .update({
            'name': newName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.group.id);

      if (mounted) {
        setState(() => _isEditingName = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group name updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildDeleteGroupTile(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return ListTile(
      leading: Icon(Icons.delete_forever, color: theme.colorScheme.error),
      title: Text(
        l10n.deleteGroup,
        style: TextStyle(color: theme.colorScheme.error),
      ),
      onTap: () => _showDeleteGroupDialog(context, l10n),
    );
  }

  void _showDeleteGroupDialog(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.delete_forever,
          color: theme.colorScheme.error,
          size: 32,
        ),
        title: Text(l10n.deleteGroup),
        content: Text(l10n.deleteGroupConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteGroup();
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteGroup() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // Delete from Supabase first
      await SupabaseService.client
          .from('groups')
          .delete()
          .eq('id', widget.group.id);

      // Delete related local data
      final membersBox = Hive.box<GroupMember>('group_members');
      final expensesBox = Hive.box<GroupExpense>('group_expenses');
      final splitsBox = Hive.box<GroupExpenseSplit>('group_expense_splits');
      final itemsBox = Hive.box<GroupExpenseItem>('group_expense_items');
      final expensesBoxPersonal = Hive.box<Expense>('expenses');
      final incomesBox = Hive.box<Income>('incomes');

      // Get all expenses in this group
      final groupExpenses = expensesBox.values
          .where((e) => e.groupId == widget.group.id)
          .toList();

      // Delete related personal transactions (settlements)
      for (final expense in groupExpenses) {
        // Delete settlement expenses
        final settlementExpenses = expensesBoxPersonal.values
            .where(
              (e) =>
                  e.groupExpenseId == expense.id &&
                  e.note?.startsWith('[Settlement]') == true,
            )
            .toList();
        for (final se in settlementExpenses) {
          await expensesBoxPersonal.delete(se.id);
        }

        // Delete settlement incomes
        final settlementIncomes = incomesBox.values
            .where(
              (i) =>
                  i.groupExpenseId == expense.id &&
                  i.note?.startsWith('[Settlement') == true,
            )
            .toList();
        for (final si in settlementIncomes) {
          await incomesBox.delete(si.id);
        }

        // Delete splits
        final splits = splitsBox.values
            .where((s) => s.groupExpenseId == expense.id)
            .toList();
        for (final split in splits) {
          await splitsBox.delete(split.id);
        }

        // Delete items
        final items = itemsBox.values
            .where((i) => i.groupExpenseId == expense.id)
            .toList();
        for (final item in items) {
          await itemsBox.delete(item.id);
        }

        // Delete expense
        await expensesBox.delete(expense.id);
      }

      // Delete members
      final members = membersBox.values
          .where((m) => m.groupId == widget.group.id)
          .toList();
      for (final member in members) {
        await membersBox.delete(member.id);
      }

      // Finally delete the group
      await ref.read(groupsProvider.notifier).deleteGroup(widget.group.id);

      // Refresh realtime
      GroupRealtimeService.instance.refreshGroupList();

      if (mounted) {
        // Navigate back twice (settings -> detail -> groups list)
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.group.name} deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.syncFailed}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildMembersList(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    List<GroupMember> members,
    String? currentUserId,
    bool isAdmin,
  ) {
    if (members.isEmpty) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('No members')),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        children: members.map((member) {
          final isYou = member.userId == currentUserId;
          final memberIsAdmin = member.role == 'admin';
          final memberColor = DesignUtils.getColorFromId(
            member.userId ?? member.id,
          );

          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: memberColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  member.displayName.isNotEmpty
                      ? member.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: memberColor,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Text(member.displayName),
                if (isYou)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.you,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              memberIsAdmin ? 'Administrator' : 'Member',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: isAdmin && !isYou
                ? PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'remove':
                          _showRemoveMemberDialog(context, l10n, member);
                          break;
                        case 'promote':
                          if (!memberIsAdmin) {
                            _showPromoteMemberDialog(context, l10n, member);
                          }
                          break;
                        case 'demote':
                          if (memberIsAdmin) {
                            _showDemoteMemberDialog(context, l10n, member);
                          }
                          break;
                      }
                    },
                    itemBuilder: (ctx) => [
                      if (!memberIsAdmin)
                        const PopupMenuItem(
                          value: 'promote',
                          child: Row(
                            children: [
                              Icon(Icons.arrow_upward, size: 20),
                              SizedBox(width: 8),
                              Text('Promote to Admin'),
                            ],
                          ),
                        ),
                      if (memberIsAdmin)
                        const PopupMenuItem(
                          value: 'demote',
                          child: Row(
                            children: [
                              Icon(Icons.arrow_downward, size: 20),
                              SizedBox(width: 8),
                              Text('Demote to Member'),
                            ],
                          ),
                        ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            Icon(
                              Icons.remove_circle,
                              color: theme.colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Remove',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : memberIsAdmin
                ? Icon(
                    Icons.verified_user,
                    color: theme.colorScheme.primary,
                    size: 20,
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }

  void _showRemoveMemberDialog(
    BuildContext context,
    AppLocalizations l10n,
    GroupMember member,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove ${member.displayName} from the group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _removeMember(member);
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  Future<void> _removeMember(GroupMember member) async {
    try {
      await ref
          .read(groupMembersProvider(widget.group.id).notifier)
          .removeMember(member.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.displayName} removed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPromoteMemberDialog(
    BuildContext context,
    AppLocalizations l10n,
    GroupMember member,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Promote to Admin'),
        content: Text(
          'Make ${member.displayName} an admin? They will have full control over the group.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateMemberRole(member, 'admin');
            },
            child: const Text('Promote'),
          ),
        ],
      ),
    );
  }

  void _showDemoteMemberDialog(
    BuildContext context,
    AppLocalizations l10n,
    GroupMember member,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demote to Member'),
        content: Text('Remove admin privileges from ${member.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _updateMemberRole(member, 'member');
            },
            child: const Text('Demote'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMemberRole(GroupMember member, String newRole) async {
    try {
      final updatedMember = member.copyWith(
        role: newRole,
        updatedAt: DateTime.now(),
        syncStatus: 'pending',
      );

      await ref
          .read(groupMembersProvider(widget.group.id).notifier)
          .updateMember(updatedMember);

      // Sync to Supabase
      await SupabaseService.client
          .from('group_members')
          .update({
            'role': newRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', member.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${member.displayName} is now ${newRole == 'admin' ? 'an admin' : 'a member'}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update role: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildLeaveGroupTile(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    GroupMember currentMember,
  ) {
    return ListTile(
      leading: Icon(Icons.logout, color: theme.colorScheme.error),
      title: Text(
        l10n.leaveGroup,
        style: TextStyle(color: theme.colorScheme.error),
      ),
      onTap: () => _showLeaveGroupDialog(context, l10n, currentMember),
    );
  }

  void _showLeaveGroupDialog(
    BuildContext context,
    AppLocalizations l10n,
    GroupMember member,
  ) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.logout, color: theme.colorScheme.error, size: 32),
        title: Text(l10n.leaveGroup),
        content: Text(l10n.leaveGroupConfirm(widget.group.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _leaveGroup(member);
            },
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            child: Text(l10n.leave),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup(GroupMember member) async {
    final l10n = AppLocalizations.of(context)!;
    final members = ref.read(groupMembersProvider(widget.group.id));
    final activeMembersCount = members.where((m) => m.isActive).length;
    final isLastMember = activeMembersCount <= 1;

    try {
      if (isLastMember) {
        // Delete the group entirely if last member
        await SupabaseService.client
            .from('groups')
            .delete()
            .eq('id', widget.group.id);
      } else {
        // Just remove this member
        await ref
            .read(groupMembersProvider(widget.group.id).notifier)
            .removeMember(member.id);
      }

      // Remove from local groups
      await ref.read(groupsProvider.notifier).deleteGroup(widget.group.id);
      GroupRealtimeService.instance.refreshGroupList();

      if (mounted) {
        // Navigate back twice (settings -> detail -> groups list)
        Navigator.pop(context);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLastMember ? 'Group deleted' : 'You left the group',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.syncFailed}: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 56);
  }
}
