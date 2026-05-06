import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final int size;

  UpdateInfo({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.size,
  });
}

class UpdateService {
  static const _repoOwner = 'Beluga55';
  static const _repoName = 'spend-smart';
  static const _apiUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  static Future<UpdateInfo?> checkForUpdate(String currentVersion) async {
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final tagName = (data['tag_name'] as String?)?.replaceFirst('v', '') ?? '';
      if (tagName.isEmpty) return null;

      if (!_isNewer(tagName, currentVersion)) return null;

      final assets = data['assets'] as List<dynamic>? ?? [];
      final apk = assets.cast<Map<String, dynamic>>().firstWhere(
        (a) => (a['name'] as String).endsWith('.apk'),
        orElse: () => <String, dynamic>{},
      );

      if (apk.isEmpty) return null;

      return UpdateInfo(
        version: tagName,
        downloadUrl: apk['browser_download_url'] as String,
        releaseNotes: (data['body'] as String?) ?? '',
        size: (apk['size'] as int?) ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<File> downloadApk(
    String url,
    void Function(double progress) onProgress,
  ) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      final totalBytes = response.contentLength ?? 0;
      var receivedBytes = 0;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/update.apk');
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }

      await sink.close();
      return file;
    } finally {
      client.close();
    }
  }

  static bool _isNewer(String remote, String local) {
    final remoteParts = _parseVersion(remote);
    final localParts = _parseVersion(local);

    for (var i = 0; i < 3; i++) {
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      final l = i < localParts.length ? localParts[i] : 0;
      if (r > l) return true;
      if (r < l) return false;
    }

    final rBuild = remoteParts.length > 3 ? remoteParts[3] : 0;
    final lBuild = localParts.length > 3 ? localParts[3] : 0;
    return rBuild > lBuild;
  }

  static List<int> _parseVersion(String version) {
    final main = version.split('+');
    final components = main[0]
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    if (main.length > 1) {
      components.add(int.tryParse(main[1]) ?? 0);
    }
    return components;
  }
}
