import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/services/update_service.dart';

enum UpdateStatus {
  idle,
  checking,
  available,
  downloading,
  ready,
  upToDate,
  error,
}

class UpdateState {
  final UpdateStatus status;
  final double progress;
  final String? errorMessage;
  final String? apkPath;
  final UpdateInfo? latestUpdate;

  const UpdateState({
    this.status = UpdateStatus.idle,
    this.progress = 0,
    this.errorMessage,
    this.apkPath,
    this.latestUpdate,
  });

  UpdateState copyWith({
    UpdateStatus? status,
    double? progress,
    String? errorMessage,
    String? apkPath,
    UpdateInfo? latestUpdate,
    bool clearError = false,
    bool clearApkPath = false,
    bool clearLatestUpdate = false,
  }) {
    return UpdateState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      apkPath: clearApkPath ? null : (apkPath ?? this.apkPath),
      latestUpdate: clearLatestUpdate
          ? null
          : (latestUpdate ?? this.latestUpdate),
    );
  }
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  UpdateNotifier() : super(const UpdateState());

  Future<void> checkForUpdate(String currentVersion) async {
    state = state.copyWith(
      status: UpdateStatus.checking,
      clearError: true,
    );

    final info = await UpdateService.checkForUpdate(currentVersion);
    if (info != null) {
      state = state.copyWith(
        status: UpdateStatus.available,
        latestUpdate: info,
      );
    } else {
      state = state.copyWith(
        status: UpdateStatus.upToDate,
        clearLatestUpdate: true,
      );
    }
  }

  Future<void> downloadUpdate() async {
    if (state.latestUpdate == null) return;

    state = state.copyWith(
      status: UpdateStatus.downloading,
      progress: 0,
      clearError: true,
    );

    try {
      final file = await UpdateService.downloadApk(
        state.latestUpdate!.downloadUrl,
        (progress) {
          state = state.copyWith(progress: progress);
        },
      );
      state = state.copyWith(
        status: UpdateStatus.ready,
        apkPath: file.path,
      );
    } catch (e) {
      state = state.copyWith(
        status: UpdateStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const UpdateState();
  }
}

final updateProvider =
    StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  return UpdateNotifier();
});
