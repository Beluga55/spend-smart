Build APK:
flutter build apk --release

Install to device:
adb -s 70a38c7c install -r build\app\outputs\flutter-apk\app-release.apk

Install to emulator:
adb -s emulator-5554 install -r build\app\outputs\flutter-apk\app-release.apk