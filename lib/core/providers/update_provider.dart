import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_expense_tracker/core/services/update_service.dart';

enum UpdateState {
  idle,
  checking,
  available,
  downloading,
  ready,
  upToDate,
  error,
}

class UpdateNotifier extends StateNotifier<UpdateState> {
  UpdateInfo? latestUpdate;
  double downloadProgress = 0;
  String? errorMessage;
  String? apkPath;

  UpdateNotifier() : super(UpdateState.idle);

  Future<void> checkForUpdate(String currentVersion) async {
    state = UpdateState.checking;
    errorMessage = null;

    final info = await UpdateService.checkForUpdate(currentVersion);
    if (info != null) {
      latestUpdate = info;
      state = UpdateState.available;
    } else {
      state = UpdateState.upToDate;
    }
  }

  Future<void> downloadUpdate() async {
    if (latestUpdate == null) return;

    state = UpdateState.downloading;
    downloadProgress = 0;
    errorMessage = null;

    try {
      final file = await UpdateService.downloadApk(
        latestUpdate!.downloadUrl,
        (progress) {
          downloadProgress = progress;
          state = UpdateState.downloading;
        },
      );
      apkPath = file.path;
      state = UpdateState.ready;
    } catch (e) {
      errorMessage = e.toString();
      state = UpdateState.error;
    }
  }

  void reset() {
    state = UpdateState.idle;
    latestUpdate = null;
    downloadProgress = 0;
    errorMessage = null;
    apkPath = null;
  }
}

final updateProvider =
    StateNotifierProvider<UpdateNotifier, UpdateState>((ref) {
  return UpdateNotifier();
});
