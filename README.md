# Rynex App

A Flutter drawing and notes app that runs entirely on the user's device.

## Offline authentication model

Rynex does **not** send OTP emails from the Flutter client. Because this app has
no backend server, email OTP verification was replaced with a device-local
account unlock flow:

1. Create a local profile with a display name, email identifier, and local
   password.
2. The password is hashed on the device with PBKDF2-SHA256 and a per-account
   random salt before being written to local app storage.
3. Returning users unlock the local profile with the same email identifier and
   password after app startup or logout.
4. The unlocked session is not restored automatically across app restarts.

The email field is only a local profile identifier. It is not verified, sent to a
mail provider, or treated as proof that the user controls an inbox.

## Why client-side OTP email is not supported

Sending OTP email directly from a mobile, desktop, or web client is not secure:

- SMTP/API credentials embedded in a client binary can be extracted and abused.
- Attackers can replay the exposed credentials to send spam, phishing, or OTPs
  outside the app.
- Client-side OTP generation/validation can be bypassed by patching the app,
  inspecting memory, or altering local state.
- A client cannot reliably enforce rate limits, abuse detection, IP reputation,
  mailbox ownership, or delivery auditing.
- Hardcoded recipient addresses leak personal data and force every install to
  verify the same inbox.

If real email verification is required, add a backend service or serverless
function. The client should request a challenge over HTTPS, the backend should
generate and store a short-lived hashed OTP with rate limits, the backend should
send the email using server-held mail provider credentials, and the client should
submit the code to the backend for verification. Mail credentials and OTP truth
must never live in the app bundle.

## Running locally

Use the standard Flutter tooling from the repository root:

```sh
flutter pub get
flutter run
```

If `flutter run` builds successfully but fails while installing with
`adb: device offline`, the APK build has completed and the failure is in the
Android emulator/device connection rather than the Flutter code. Try restarting
ADB and cold booting the emulator before retrying.
