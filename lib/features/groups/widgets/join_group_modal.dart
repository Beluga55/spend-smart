import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:mobile_expense_tracker/core/models/group.dart';
import 'package:mobile_expense_tracker/core/models/group_member.dart';
import 'package:mobile_expense_tracker/core/providers/group_provider.dart';
import 'package:mobile_expense_tracker/core/services/group_realtime_service.dart';
import 'package:mobile_expense_tracker/core/services/group_sync_service.dart';
import 'package:mobile_expense_tracker/core/services/supabase_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_expense_tracker/l10n/app_localizations.dart';

class JoinGroupModal extends ConsumerStatefulWidget {
  const JoinGroupModal({super.key});

  @override
  ConsumerState<JoinGroupModal> createState() => _JoinGroupModalState();
}

class _JoinGroupModalState extends ConsumerState<JoinGroupModal> {
  final _codeController = TextEditingController();
  bool _isJoining = false;
  bool _showScanner = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinWithCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 8) return;
    await _performJoin(code);
  }

  Future<void> _performJoin(String code) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isJoining = true;
      _error = null;
    });

    Group? group;

    final groupBox = ref.read(groupBoxProvider);
    for (final g in groupBox.values) {
      if (g.inviteCode == code) {
        group = g;
        break;
      }
    }

    if (group == null) {
      try {
        final groupResult = await SupabaseService.client
            .from('groups')
            .select()
            .eq('invite_code', code)
            .eq('is_active', true)
            .maybeSingle();

        if (groupResult != null) {
          group = Group(
            id: groupResult['id'],
            name: groupResult['name'],
            createdBy: groupResult['created_by'],
            createdAt: DateTime.parse(groupResult['created_at']),
            inviteCode: groupResult['invite_code'],
            isActive: groupResult['is_active'] ?? true,
            updatedAt: DateTime.parse(groupResult['updated_at']),
            syncStatus: 'synced',
          );
          await groupBox.put(group.id, group);
        }
      } catch (e) {
        debugPrint('Supabase group lookup failed: $e');
      }
    }

    if (group == null) {
      if (mounted) {
        setState(() {
          _isJoining = false;
          _error = l10n.groupNotFound;
        });
      }
      return;
    }

    final memberBox = ref.read(groupMemberBoxProvider);
    final alreadyMember = memberBox.values.any(
      (m) => m.groupId == group!.id && m.userId == user.id && m.isActive,
    );

    if (alreadyMember) {
      if (mounted) {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.alreadyMember)));
      }
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

    final sync = ref.read(groupSyncServiceProvider);
    sync.pullGroupHistory(group.id).catchError((e) {
      debugPrint('[JoinGroup] History pull failed: $e');
    });

    // Navigate immediately - local data is saved
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.joinedGroup(group.name))));
    }

    // Immediately subscribe to this group's realtime updates
    await GroupRealtimeService.instance.forceRefreshForGroup(group.id);
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code != null && code.length == 8) {
      setState(() => _showScanner = false);
      _performJoin(code.toUpperCase());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;
    final textPrimary = theme.colorScheme.onSurface;
    final dividerColor = theme.colorScheme.outline;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dividerColor.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.joinGroup,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            if (_showScanner) ...[
              Container(
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: MobileScanner(onDetect: _onQRCodeDetected),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showScanner = false),
                  icon: const Icon(Icons.keyboard_outlined),
                  label: Text(l10n.enterCodeInstead),
                ),
              ),
            ] else ...[
              TextField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  labelText: l10n.inviteCode,
                  hintText: 'XXXXXXXX',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.qr_code_rounded),
                  errorText: _error,
                ),
                maxLength: 8,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isJoining ? null : _joinWithCode,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          l10n.join,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showScanner = true),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(
                    l10n.scanQRCode,
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
