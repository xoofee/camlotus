// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Bridge for apps (e.g. camlotus) to set LENS_FOCUS_DISTANCE when the camera
// is bound. Register via setCamera2CameraControl() from ProcessCameraProviderProxyApi.

package io.flutter.plugins.camerax;

import android.hardware.camera2.CaptureRequest;
import androidx.annotation.Nullable;
import androidx.annotation.OptIn;
import androidx.camera.camera2.interop.Camera2CameraControl;
import androidx.camera.camera2.interop.CaptureRequestOptions;
import androidx.camera.camera2.interop.ExperimentalCamera2Interop;
import androidx.core.content.ContextCompat;
import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import com.google.common.util.concurrent.ListenableFuture;

/**
 * Holds the current Camera2CameraControl so that app code (e.g. MainActivity) can apply focus
 * distance (LENS_FOCUS_DISTANCE) without the camera plugin exposing this API. Set when the camera
 * is bound; clear when unbound.
 * 
 * Focus distance:
 * Desired distance to plane of sharpest focus, measured from frontmost surface of the lens.
 * 
 * Unit: diopters (1/meter)
 */
@OptIn(markerClass = ExperimentalCamera2Interop.class)
public final class FocusDistanceBridge {
  private static final float MAX_DIOPTERS = 10f; // ~10 cm; device may clamp, 

  @Nullable private static Camera2CameraControl camera2CameraControl;
  @Nullable private static android.content.Context context;

  /** Called by the plugin when a camera is bound. */
  public static void setCamera2CameraControl(
      @Nullable Camera2CameraControl control, @Nullable android.content.Context ctx) {
    camera2CameraControl = control;
    context = ctx;
  }

  /** Called by the plugin when the camera is unbound. */
  public static void clear() {
    camera2CameraControl = null;
    context = null;
  }

  /**
   * Applies focus distance. Called from app (e.g. MainActivity) when it receives setFocusDistance.
   *
   * @param normalized 0 = near (max diopters), 1 = far (0 diopters / infinity).
   * see https://developer.android.com/reference/android/hardware/camera2/CaptureRequest#LENS_FOCUS_DISTANCE
   */
  public static void applyFocusDistance(double normalized) {
    final Camera2CameraControl control = camera2CameraControl;
    final android.content.Context ctx = context;
    if (control == null || ctx == null) {
      return;
    }
    float diopters = (float) ((1.0 - normalized) * MAX_DIOPTERS);
    CaptureRequestOptions requestOptions =
        new CaptureRequestOptions.Builder()
            .setCaptureRequestOption(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_OFF)
            .setCaptureRequestOption(CaptureRequest.LENS_FOCUS_DISTANCE, diopters)
            .build();
    ListenableFuture<Void> future = control.addCaptureRequestOptions(requestOptions);
    Futures.addCallback(
        future,
        new FutureCallback<Void>() {
          @Override
          public void onSuccess(Void unused) {}

          @Override
          public void onFailure(Throwable t) {
            android.util.Log.w("FocusDistanceBridge", "setFocusDistance failed", t);
          }
        },
        ContextCompat.getMainExecutor(ctx));
  }
}
