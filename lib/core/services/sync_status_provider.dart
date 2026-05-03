import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum SyncStatus {
  synced,
  pending,
  syncing,
  offline,
  error,
}

class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncedAt;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.synced,
    this.lastSyncedAt,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncedAt,
    String? errorMessage,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(const SyncState());

  void setSynced() {
    state = state.copyWith(
      status: SyncStatus.synced,
      lastSyncedAt: DateTime.now(),
    );
  }

  void setPending() {
    state = state.copyWith(status: SyncStatus.pending);
  }

  void setSyncing() {
    state = state.copyWith(status: SyncStatus.syncing);
  }

  void setOffline() {
    state = state.copyWith(status: SyncStatus.offline);
  }

  void setError(String message) {
    state = state.copyWith(
      status: SyncStatus.error,
      errorMessage: message,
    );
  }
}

final syncNotifierProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier();
});

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.maybeWhen(
    data: (results) => !results.contains(ConnectivityResult.none),
    orElse: () => true,
  );
});

final autoBackupProvider = StateProvider<bool>((ref) => true);
