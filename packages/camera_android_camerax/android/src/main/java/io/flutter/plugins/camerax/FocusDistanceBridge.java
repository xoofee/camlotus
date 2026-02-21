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
 * <p>Focus distance unit: diopters (1/meter). 0 = infinity; max = LENS_INFO_MINIMUM_FOCUS_DISTANCE.
 */
@OptIn(markerClass = ExperimentalCamera2Interop.class)
public final class FocusDistanceBridge {
  /** Fallback when LENS_INFO_MINIMUM_FOCUS_DISTANCE is 0 (fixed-focus) or unavailable. */
  private static final float FALLBACK_MAX_DIOPTERS = 10f;

  @Nullable private static Camera2CameraControl camera2CameraControl;
  @Nullable private static android.content.Context context;
  private static float maxDiopters = FALLBACK_MAX_DIOPTERS;

  /**
   * Called by the plugin when a camera is bound.
   *
   * @param maxDioptersValue LENS_INFO_MINIMUM_FOCUS_DISTANCE from the lens (max diopter for this device).
   */
  public static void setCamera2CameraControl(
      @Nullable Camera2CameraControl control,
      @Nullable android.content.Context ctx,
      float maxDioptersValue) {
    camera2CameraControl = control;
    context = ctx;
    maxDiopters = (maxDioptersValue > 0f) ? maxDioptersValue : FALLBACK_MAX_DIOPTERS;
  }

  /** Called by the plugin when the camera is unbound. */
  public static void clear() {
    camera2CameraControl = null;
    context = null;
    maxDiopters = FALLBACK_MAX_DIOPTERS;
  }

  /** Returns the maximum focus distance in diopters (for this lens). */
  public static float getMaxDiopters() {
    return maxDiopters;
  }

  /**
   * Applies focus distance in diopters. Called from app (e.g. MainActivity) when it receives
   * setFocusDistance. Value is in diopters (0 = infinity, positive = nearer).
   */
  public static void applyFocusDistance(double diopters) {
    final Camera2CameraControl control = camera2CameraControl;
    final android.content.Context ctx = context;
    if (control == null || ctx == null) {
      return;
    }
    float d = (float) diopters;
    CaptureRequestOptions requestOptions =
        new CaptureRequestOptions.Builder()
            .setCaptureRequestOption(CaptureRequest.CONTROL_AF_MODE, CaptureRequest.CONTROL_AF_MODE_OFF)
            .setCaptureRequestOption(CaptureRequest.LENS_FOCUS_DISTANCE, d)
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
