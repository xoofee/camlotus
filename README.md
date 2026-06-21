# Camlotus

Camlotus is a Flutter reference app for camera and computer-vision experiments.
The current code is centered on the `LotusCam` Android camera demo.

## Current Status

- `LotusCam` is the implemented feature.
- MVG, VSLAM, VIO, and VINS demos are placeholders on the home screen.
- Android is the actively exercised target.
- Desktop and other Flutter targets are still scaffolded, but the camera feature depends on mobile camera behavior and a local `flutter_webrtc` patch.

## Implemented Features

- Live camera preview through `flutter_webrtc`.
- Camera switching when multiple video inputs are available.
- Resolution cycling across predefined camera sizes.
- Manual focus-distance control in diopters on Android.
- Camera intrinsic matrix display when Android camera metadata is available.
- Android Camera2 characteristics inspection.
- Still-frame capture to the app documents directory and the `Camlotus` gallery album.
- Persistence for focus distance, resolution choice, and K-matrix overlay visibility.

## Important Code Paths

```text
lib/main.dart
lib/screens/home_page.dart
lib/screens/lotus_cam_screen.dart
lib/screens/android_camera_characteristics_screen.dart
lib/camera/k_matrix_estimator.dart
third_party/flutter_webrtc/
```

## Requirements

- Flutter SDK compatible with Dart `^3.5.4`.
- Android SDK and an attached Android device for the primary camera workflow.
- Camera and photo/gallery permissions on the device.

## Run On Android

```sh
flutter pub get
flutter run -d <android-device-id>
```

For the Xiaomi device currently used in local smoke checks:

```sh
flutter run -d dyzluokvron7hazl
```

## Notes

This is reference/prototype code under `references/`, not a production app.
Treat the current behavior as an experimental camera capability sample rather
than a finished VSLAM product.
