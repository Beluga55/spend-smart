import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_expense_tracker/core/models/group.dart';
import 'package:mobile_expense_tracker/core/models/group_member.dart';
import 'package:mobile_expense_tracker/core/providers/group_provider.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class JoinGroupModal extends ConsumerStatefulWidget {
  const JoinGroupModal({super.key});

  @override
  ConsumerState<JoinGroupModal> createState() => _JoinGroupModalState();
}

class _JoinGroupModalState extends ConsumerState<JoinGroupModal> {
  final _codeController = TextEditingController();
  bool _isJoining = false;
  bool _showScanner = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinWithCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    await _joinGroup(code);
  }

  Future<void> _joinGroup(String code) async {
    setState(() => _isJoining = true);

    final user = SupabaseService.client.auth.currentUser;
    if (user == null || user.isAnonymous) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSignInForGroups)),
        );
      }
      setState(() => _isJoining = false);
      return;
    }

    final groupBox = ref.read(groupBoxProvider);
    Group? group;
    for (final g in groupBox.values) {
      if (g.inviteCode == code) {
        group = g;
        break;
      }
    }

    if (group == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group not found. Check the invite code.')),
        );
      }
      setState(() => _isJoining = false);
      return;
    }

    final now = DateTime.now();
    final member = GroupMember(
      id: const Uuid().v4(),
      groupId: group.id,
      userId: user.id,
      displayName: user.email ?? 'Member',
      joinedAt: now,
      role: 'member',
      isActive: true,
      updatedAt: now,
    );

    await ref.read(groupMembersProvider(group.id).notifier).addMember(member);

    if (mounted) {
      setState(() => _isJoining = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined "${group.name}"!')),
      );
    }
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null && code.length == 8) {
      _joinGroup(code.toUpperCase());
    }
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
            l10n.joinGroup,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          if (_showScanner) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 300,
                child: MobileScanner(
                  onDetect: _onQRCodeDetected,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _showScanner = false),
                child: Text(l10n.enterCodeInstead),
              ),
            ),
          ] else ...[
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.inviteCode,
                hintText: 'XXXXXXXX',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLength: 8,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isJoining ? null : _joinWithCode,
                child: _isJoining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.join),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _showScanner = true),
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(l10n.scanQRCode),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}