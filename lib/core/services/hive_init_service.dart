import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Safely opens a Hive box with automatic corruption recovery.
/// 
/// If the box fails to open (e.g., due to schema changes from an app update),
/// it deletes the corrupted box file from disk and reopens it empty.
/// This prevents the app from getting stuck on the splash screen forever.
Future<Box<T>> openBoxSafe<T>(
  String name, {
  bool deleteOnCorruption = true,
}) async {
  try {
    debugPrint('[Hive] Opening box: $name');
    final box = await Hive.openBox<T>(name);
    debugPrint('[Hive] Box "$name" opened successfully (${box.length} items)');
    return box;
  } catch (e, stack) {
    debugPrint('[Hive] ERROR opening box "$name": $e');
    debugPrint(stack.toString());

    if (deleteOnCorruption) {
      debugPrint('[Hive] Attempting to delete corrupted box "$name" and reopen...');
      try {
        await Hive.deleteBoxFromDisk(name);
        debugPrint('[Hive] Deleted corrupted box "$name"');
      } catch (deleteError) {
        debugPrint('[Hive] Failed to delete box from disk: $deleteError');
        // Fallback: try to delete the file manually
        try {
          final appDocDir = await getApplicationDocumentsDirectory();
          final boxFile = File('${appDocDir.path}/$name.hive');
          if (await boxFile.exists()) {
            await boxFile.delete();
            debugPrint('[Hive] Manually deleted box file: ${boxFile.path}');
          }
        } catch (_) {}
      }

      try {
        final box = await Hive.openBox<T>(name);
        debugPrint('[Hive] Box "$name" reopened successfully (empty)');
        return box;
      } catch (reopenError) {
        debugPrint('[Hive] CRITICAL: Failed to reopen box "$name": $reopenError');
        rethrow;
      }
    }
    rethrow;
  }
}

/// Safely opens an untyped Hive box with automatic corruption recovery.
Future<Box<dynamic>> openBoxSafeUntyped(
  String name, {
  bool deleteOnCorruption = true,
}) async {
  return openBoxSafe<dynamic>(name, deleteOnCorruption: deleteOnCorruption);
}
