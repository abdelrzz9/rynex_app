# Rynex App

A Flutter drawing app with username-based email OTP verification.

## Secure OTP verification flow

1. A user logs in with a username and password, or registers with a username, password, display name, and account email.
2. Account emails are stored in the local auth database and are not rendered back in account switchers, titles, success states, or OTP hints.
3. When an OTP is requested, the OTP repository looks up the stored email by username through `AuthRepository.emailForUsername`.
4. The OTP is sent only to the email returned by that database lookup.
5. SMTP credentials and sender address come from environment variables; there are no hardcoded recipient or sender addresses in the app code.
6. OTP values are held only in memory by `InMemoryOtpRepository` and are cleared after successful verification.

## SMTP environment variables

Set these before running a build that needs to send OTP email:

```sh
export SMTP_HOST="your-smtp-host"
export SMTP_PORT="587"
export SMTP_USERNAME="smtp-user"
export SMTP_PASSWORD="smtp-password"
export SMTP_SENDER_EMAIL="your-sender-address"
export SMTP_SENDER_NAME="Rynex"
export SMTP_USE_STARTTLS="true"
export SMTP_USE_SSL="false"
```

Use `SMTP_USE_SSL=true` for implicit TLS providers, commonly on port `465`. Use `SMTP_USE_STARTTLS=true` for STARTTLS providers, commonly on port `587`.

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
