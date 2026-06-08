# Rynex App

A Flutter drawing app with a device-local OTP verification entry flow.

## Local OTP verification flow

The app starts with a phone number verification experience when no local drawing account is signed in:

1. Enter a phone number on the verification screen.
2. The app generates a random six-digit OTP locally on the device.
3. The OTP is kept only in memory through `InMemoryOtpRepository`; it is not written to a database, file, or backend service.
4. The app navigates to a six-field OTP entry screen.
5. In debug builds only, the generated OTP is displayed on the verification screen for testing.
6. Entering the matching OTP shows a success state; entering a wrong OTP shows an error message.
7. The resend button stays disabled during the countdown, then generates a fresh in-memory OTP when tapped.

## Running locally

Use the standard Flutter tooling from the repository root:

```sh
flutter pub get
flutter run
```

If `flutter run` builds successfully but fails while installing with `adb: device offline`, the APK build has completed and the failure is in the Android emulator/device connection rather than the Flutter code. Try the following:

```sh
adb devices
adb kill-server
adb start-server
```

Then restart the emulator from Android Studio or cold boot it from Device Manager and run:

```sh
flutter run
```

If the emulator still appears as `offline`, wipe the emulator data or select a different emulator/device before retrying.

## Getting Started

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
