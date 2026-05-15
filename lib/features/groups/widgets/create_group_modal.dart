import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_expense_tracker/core/models/group.dart';
import 'package:mobile_expense_tracker/core/providers/group_provider.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class CreateGroupModal extends ConsumerStatefulWidget {
  const CreateGroupModal({super.key});

  @override
  ConsumerState<CreateGroupModal> createState() => _CreateGroupModalState();
}

class _CreateGroupModalState extends ConsumerState<CreateGroupModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isCreating = false;
  Group? _createdGroup;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final uuid = const Uuid().v4();
    String code = '';
    for (int i = 0; i < 8; i++) {
      code += chars[uuid.codeUnitAt(i) % chars.length];
    }
    return code;
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final user = SupabaseService.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSignInForGroups)),
        );
      }
      setState(() => _isCreating = false);
      return;
    }

    final now = DateTime.now();
    final group = Group(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      createdBy: user.id,
      createdAt: now,
      inviteCode: _generateInviteCode(),
      isActive: true,
      updatedAt: now,
    );

    await ref.read(groupsProvider.notifier).addGroup(group);

    if (mounted) {
      setState(() {
        _isCreating = false;
        _createdGroup = group;
      });
    }
  }

  void _shareInviteCode() {
    if (_createdGroup == null) return;
    Share.share('Join my group "${_createdGroup!.name}" on SpendSmart!\n\nInvite code: ${_createdGroup!.inviteCode}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surfaceColor = Theme.of(context).colorScheme.surface;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final dividerColor = Theme.of(context).colorScheme.outline;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 16,
      ),
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
          const SizedBox(height: 24),
          Text(
            l10n.createGroup,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          if (_createdGroup == null) ...[
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.groupName,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterGroupName;
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createGroup,
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.create),
              ),
            ),
          ] else ...[
            Center(
              child: Column(
                children: [
                  Text(
                    '"${_createdGroup!.name}"',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  QrImageView(
                    data: _createdGroup!.inviteCode,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _createdGroup!.inviteCode,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _createdGroup!.inviteCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.copiedToClipboard)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _shareInviteCode,
                      icon: const Icon(Icons.share),
                      label: Text(l10n.shareInviteCode),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
