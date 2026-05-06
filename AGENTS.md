# AGENTS.md — SpendSmart

Flutter expense tracker. Local data via Hive. Cloud sync via Supabase. State management via Riverpod.

## Critical Commands

```bash
# Run app
flutter run

# Build release APK (CI does this on v* tags)
flutter build apk --release

# Lint
flutter analyze

# Regenerate Hive adapters after model changes
flutter pub run build_runner build --delete-conflicting-outputs

# Regenerate localization files (delete stale first!)
Remove-Item lib/l10n/app_localizations*.dart  # or rm
flutter gen-l10n

# Update launcher icons after changing icon.jpg
flutter pub run flutter_launcher_icons:main
```

## Release Workflow

1. Bump `version` in `pubspec.yaml` (format: `major.minor.patch+buildNumber`)
2. Commit, push
3. `git tag -a vX.Y.Z+N -m "..."`
4. `git push origin vX.Y.Z+N`
5. CI (`.github/workflows/release.yml`) builds signed APK, creates GitHub release, posts to Discord

CI requires secrets: `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`, `KEYSTORE_BASE64`, `DISCORD_WEBHOOK_URL`.

## Architecture Notes

- **Hive typed boxes** are opened eagerly in `main()`. Heavy boxes (`expenses`, `incomes`, `wallet_transfers`) have corruption recovery via `openBoxSafe()`.
- **Database migrations** run after box open via `DatabaseMigrationService` (`lib/core/database/`). Bump `currentDbVersion` and add a migration case when schema changes.
- **Localization** is generated from `lib/l10n/app_en.arb` and `app_zh.arb`. The `l10n.yaml` puts output in `lib/l10n/`. Stale `.dart` files **must** be deleted before `flutter gen-l10n` or `dart format` will fail on reserved keyword conflicts.
- **State**: Riverpod `StateNotifier` + `StateNotifierProvider` pattern. Box providers live in `lib/core/providers/`.
- **Models**: All Hive models have `@HiveType(typeId: N)` — typeIds must never conflict or be reused. Adapters are in `.g.dart` files.

## Testing

- `test/widget_test.dart` is a placeholder. Real widget tests need `Hive.initFlutter()` and adapter registration in `setUp()`.
- No integration tests exist.

## Style & Lint

- `analysis_options.yaml` uses `package:flutter_lints/flutter.yaml` — standard Flutter lints, no custom overrides.
- `avoid_print` is active but not enforced in `lib/core/services/` where `debugPrint` is used.

## Gotchas

- **Icon asset**: `flutter_launcher_icons` points to `android/app/src/main/res/icon.jpg`. This file must exist or icon generation fails.
- **Android label**: `SpendSmart` (not `mobile_expense_tracker`). Manifest is at `android/app/src/main/AndroidManifest.xml`.
- **Splash screen**: Custom Flutter widget at `lib/features/splash/splash_screen.dart`, shown during background init. The native Android splash (`LaunchTheme`) is a plain white background only.
- **Samsung-specific**: The app defers heavy init until after `runApp()` and adds `Future.delayed(Duration.zero)` yields between steps to avoid ANR on One UI's strict choreographer.
