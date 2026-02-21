# Local override: camera_android_camerax

This is a clone of [camera_android_camerax](https://pub.dev/packages/camera_android_camerax) (0.6.17) used via `dependency_overrides` in the camlotus app.

## Changes from upstream

1. **FocusDistanceBridge.java**  
   Static bridge so app code (MainActivity) can set **LENS_FOCUS_DISTANCE** (focus range: near ↔ far) via Camera2 `CaptureRequestOptions`. The stock Flutter camera plugin does not expose this.

2. **ProcessCameraProviderProxyApi.java**  
   - In `bindToLifecycle`: after binding the camera, registers `Camera2CameraControl` with `FocusDistanceBridge` so the app can apply focus distance.
   - In `unbindAll`: calls `FocusDistanceBridge.clear()`.

## Updating from upstream

To refresh from pub.dev (and re-apply the above changes):

1. Replace this folder with a fresh copy of `camera_android_camerax-0.6.17` from the pub cache.
2. Re-add `FocusDistanceBridge.java` and the edits to `ProcessCameraProviderProxyApi.java` as described above.

## Why not patch the pub cache?

Patching the pub cache is fragile (e.g. `flutter pub get` can overwrite it). Keeping a local clone under `packages/` keeps the project self-contained and version-controlled.
