# 

This is an app for many interesting demo for stereo vision learning, including hartly MVG, and VSLAM/VIO/VINS

now implement this feature:

1 a home page entrypoint for a lot features

2 the first feature:
LotusCam, a camera feature that supports focus distance (focus range from near to far, like the system camera’s manual focus: adjust at what distance the image is sharp, not where in the frame to focus). Value is set with a numeric input and a slider (synchronous); 0 = near, 1 = far.
make the value persistent, and auto load and set to camera
view the camera in realtime, and a press round button to take a photo and save to system image gallery
just mimic the system camera app is ok

show the realtime K matrix on the screen and a (small and maybe transparent) switch button to turn on/off of it


# flutter_webrtc

1 use https://pub.dev/packages/flutter_webrtc to support all platform
2 existing feature should be remained
3 remove uncessary code/3rdparty package after refacor
4 support camera switch (detect multiple cameras). with a button near the right side of "taking camera" button
5 support image size set (use the highest resolution as default). show the image size at left bottom
make the settings persistent
6 do not make toast after take picture, use a quick blink to indicate taking photo, just like the behevior of common camera app made by google and apple.
7 add a gallery button near the left side of "taking camera" button. show the thumbnail of the newest photo taken by this app

the UX and behavior and layout (of 4,5,6,7) could mimic any mature camera app make by google/apple, this is not a new thing. do not reinvent, just copy them

compile in windows/android to see if any building errors, after writing the code


# camera info

in flutter_webrtc
1 provide a function to return a dict of CameraCharacteristics to dart
2 in the app, add a camera info page to display all the data in a table. add a button in the appbar in the camera page to open this camera info page
3 if the characteristics.get(CameraCharacteristics.LENS_INTRINSIC_CALIBRATION) return null or less than 5 params or all near to zero, try estimzation K matrix from this second method:
availableFocalLengths (in mm), android.sensor.info.physicalSize (in mm), android.sensor.info.pixelArraySize
note: this should be done in dart, not in java. Java simply pass the original data to dart

If the second method fail. should show a warning when user tap it
The K ON button should not use ON OFF to show it state, just use text K and use white as OFF and blue as ON
default should be OFF

4 make the interface unified across platform. Currently we focus in android. in the future we will focus on other platform too
5 make the code clean and modular. Do not make a big single source code file

this is a debug log from android for reference
```
D/CameraUtils(12824): ========== CameraCharacteristics camera=0 ==========
D/CameraUtils(12824):   CameraCharacteristics.Key(android.colorCorrection.availableAberrationModes) = [0]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.aeAvailableAntibandingModes) = [0, 1, 2, 3]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.aeAvailableModes) = [0, 1, 2, 3]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.aeAvailableTargetFpsRanges) = [[10, 10], [15, 15], [15, 20], [20, 20], [5, 30], [30, 30]]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.aeCompensationRange) = [-4, 4]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.aeCompensationStep) = 1/2
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.aeLockAvailable) = true
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.afAvailableModes) = [0, 1, 2, 3, 4]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.availableEffects) = [0]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.availableModes) = [0, 1, 2, 3]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.availableSceneModes) = [1]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.availableVideoStabilizationModes) = [0]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.awbAvailableModes) = [0, 1, 2, 3, 4, 5, 6, 7, 8]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.awbLockAvailable) = true
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.maxRegionsAe) = 1
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.maxRegionsAf) = 1
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.maxRegionsAwb) = 1
D/CameraUtils(12824):   CameraCharacteristics.Key(android.control.zoomRatioRange) = [1.0, 4.0]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.edge.availableEdgeModes) = [0, 1, 2, 3]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.flash.info.available) = true
D/CameraUtils(12824):   CameraCharacteristics.Key(android.hotPixel.availableHotPixelModes) = [0, 1, 2]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.info.supportedHardwareLevel) = 1
D/CameraUtils(12824):   CameraCharacteristics.Key(android.jpeg.availableThumbnailSizes) = [0x0, 176x144, 240x144, 256x144, 240x160, 256x154, 320x144, 320x154, 320x160, 240x240, 320x240, 384x288]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.lens.facing) = 1
D/CameraUtils(12824):   CameraCharacteristics.Key(android.lens.info.availableApertures) = [1.8]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.lens.info.availableFilterDensities) = [0.0]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.lens.info.availableFocalLengths) = [3.57]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.lens.info.availableOpticalStabilization) = [0]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.lens.info.focusDistanceCalibration) = 0
D/CameraUtils(12824):   CameraCharacteristics.Key(android.lens.info.hyperfocalDistance) = 0.1
D/CameraUtils(12824):   CameraCharacteristics.Key(android.lens.info.minimumFocusDistance) = 14.285714
D/CameraUtils(12824):   CameraCharacteristics.Key(android.noiseReduction.availableNoiseReductionModes) = [0, 1, 2, 3, 4]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.reprocess.maxCaptureStall) = 4
D/CameraUtils(12824):   CameraCharacteristics.Key(android.request.availableCapabilities) = [0, 1, 2, 5, 6, 4, 7]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.request.maxNumInputStreams) = 1
D/CameraUtils(12824):   CameraCharacteristics.Key(android.request.maxNumOutputProc) = 3
D/CameraUtils(12824):   CameraCharacteristics.Key(android.request.maxNumOutputProcStalling) = 1
D/CameraUtils(12824):   CameraCharacteristics.Key(android.request.maxNumOutputRaw) = 1
D/CameraUtils(12824):   CameraCharacteristics.Key(android.request.partialResultCount) = 10
D/CameraUtils(12824):   CameraCharacteristics.Key(android.request.pipelineMaxDepth) = 8
D/CameraUtils(12824):   CameraCharacteristics.Key(android.scaler.availableMaxDigitalZoom) = 4.0
D/CameraUtils(12824):   CameraCharacteristics.Key(android.scaler.croppingType) = 0
D/CameraUtils(12824):   CameraCharacteristics.Key(android.scaler.mandatoryStreamCombinations) = [android.hardware.camera2.params.MandatoryStreamCombination@1245bc2f, android.hardware.camera2.params.MandatoryStreamCombination@2c743958, android.hardware.camera2.params.MandatoryStreamCombination@cd02c71d, android.hardware.camera2.params.MandatoryStreamCombination@920f3088, android.hardware.camera2.params.MandatoryStreamCombination@8fd7370a, android.hardware.camera2.params.MandatoryStreamCombination@9e6a7849, android.hardware.camera2.params.MandatoryStreamCombination@470ebb5a, android.hardware.camera2.params.MandatoryStreamCombination@3622b3e7, android.hardware.camera2.params.MandatoryStreamCombination@c811c18, android.hardware.camera2.params.MandatoryStreamCombination@5949366c, android.hardware.camera2.params.MandatoryStreamCombination@f68d2a1, android.hardware.camera2.params.MandatoryStreamCombination@5d1b42f1, android.hardware.camera2.params.MandatoryStreamCombination@f12a8b91, android.hardware.camera2.params.MandatoryStreamCombination@e2dce88b, android.hardware.camera2.params.MandatoryStreamCombination@9ffafd8c, android.hardware.camera2.params.MandatoryStreamCombination@c6b89fce, android.hardware.camera2.params.MandatoryStreamCombination@63824e40, android.hardware.camera2.params.MandatoryStreamCombination@b60e8841, android.hardware.camera2.params.MandatoryStreamCombination@9f8e6868, android.hardware.camera2.params.MandatoryStreamCombination@f3d277aa, android.hardware.camera2.params.MandatoryStreamCombination@56e7a6e4, android.hardware.camera2.params.MandatoryStreamCombination@da585a5, android.hardware.camera2.params.MandatoryStreamCombination@56d80971, android.hardware.camera2.params.MandatoryStreamCombination@8a252acd, android.hardware.camera2.params.MandatoryStreamCombination@215393e, android.hardware.camera2.params.MandatoryStreamCombination@b1f054eb, android.hardware.camera2.params.MandatoryStreamCombination@6d0d1c57, android.hardware.camera2.params.MandatoryStreamCombination@e531289c, android.hardware.camera2.params.MandatoryStreamCombination@9dc2a48f, android.hardware.camera2.params.MandatoryStreamCombination@72122668, android.hardware.camera2.params.MandatoryStreamCombination@7103179b, android.hardware.camera2.params.MandatoryStreamCombination@514d2387, android.hardware.camera2.params.MandatoryStreamCombination@606dc3a4, android.hardware.camera2.params.MandatoryStreamCombination@70c9e08c, android.hardware.camera2.params.MandatoryStreamCombination@b9f9fff3, android.hardware.camera2.params.MandatoryStreamCombination@87e053a7, android.hardware.camera2.params.MandatoryStreamCombination@737424fd, android.hardware.camera2.params.MandatoryStreamCombination@4e70cb2b, android.hardware.camera2.params.MandatoryStreamCombination@1400a8f]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.scaler.streamConfigurationMap) = StreamConfiguration(Outputs([w:4160, h:3120, format:JPEG(256), min_duration:50000000, stall:50000000], [w:4160, h:1872, format:JPEG(256), min_duration:50000000, stall:50000000], [w:3840, h:2160, format:JPEG(256), min_duration:33333333, stall:33333333], [w:3264, h:2448, format:JPEG(256), min_duration:50000000, stall:50000000], [w:3120, h:3120, format:JPEG(256), min_duration:50000000, stall:50000000], [w:2560, h:1920, format:JPEG(256), min_duration:33333333, stall:33333333], [w:1920, h:1440, format:JPEG(256), min_duration:33333333, stall:33333333], [w:1920, h:1088, format:JPEG(256), min_duration:33333333, stall:33333333], [w:1920, h:1080, format:JPEG(256), min_duration:33333333, stall:33333333], [w:1680, h:720, format:JPEG(256), min_duration:33333333, stall:33333333], [w:1600, h:720, format:JPEG(256), min_duration:33333333, stall:33333333], [w:1560, h:720, format:JPEG(256), min_duration:33333333, stall:33333333], [w:1552, h:720, format:JPEG(256), min_duration:33333333, stall:33333333], [w:1520, h:720, format:JPEG(256), min_duration:33333333, stall:33333333], [w:1440, h:1088, format:JPEG(256), min_duration:33333333, stall:33333333], [w:1440, h:720, format:JPEG(256), min_duration:33333333, stall:33333333], [w:1280, h:960, format:JPEG(256), min_duration:33333333, stall:33333333], [w:1280, h:720, format:JPEG(256), min_duration:33333333, stall:33333333], [w:1280, h:576, format:JPEG(256), min_duration:33333333, stall:33333333], [w:1080, h:720, format:JPEG(256), min_duration:33333333, stall:33333333], [w:1024, h:768, format:JPEG(256), min_duration:33333333, stall:33333333], [w:960, h:720, format:JPEG(256), min_duration:33333333, stall:33333333], [w:960, h:540, format:JPEG(256), min_duration:33333333, stall:33333333], [w:800, h:600, format:JPEG(256), min_duration:33333333, stall:33333333], [w:720, h:720, format:JPEG(256), min_duration:33333333, stall:33333333], [w:640, h:480, format:JPEG(256), min_duration:33333333, stall:33333333], [w:640, h:360, format:JPEG(256), min_duration:33333333, stall:33333333], [w:384, h:288, format:JPEG(256), min_duration:33333333, stall:33333333], [w:320, h:240, format:JPEG(256), min_duration:33333333, stall:33333333], [w:320, h:180, format:JPEG(256), min_duration:33333333, stall:33333333], [w:320, h:144, format:JPEG(256), min_duration:33333333, stall:33333333], [w:240, h:240, format:JPEG(256), min_duration:33333333, stall:33333333], [w:176, h:144, format:JPEG(256), min_duration:33333333, stall:33333333], [w:4160, h:3120, format:PRIVATE(34), min_duration:50000000, stall:0], [w:4160, h:1872, format:PRIVATE(34), min_duration:50000000, stall:0], [w:3840, h:2160, format:PRIVATE(34), min_duration:33333333, stall:0], [w:3264, h:2448, format:PRIVATE(34), min_duration:50000000, stall:0], [w:3120, h:3120, format:PRIVATE(34), min_duration:50000000, stall:0], [w:2560, h:1920, format:PRIVATE(34), min_duration:33333333, stall:0], [w:2560, h:1440, format:PRIVATE(34), min_duration:33333333, stall:0], [w:1920, h:1440, format:PRIVATE(34), min_duration:33333333, stall:0], [w:1920, h:1088, format:PRIVATE(34), min_duration:33333333, stall:0], [w:1920, h:1080, format:PRIVATE(34), min_duration:33333333, stall:0], [w:1680, h:720, format:PRIVATE(34), min_duration:33333333, stall:0], [w:1600, h:720, format:PRIVATE(34), min_duration:33333333, stall:0], [w:1560, h:720, format:PRIVATE(34), min_duration:33333333, stall:0], [w:1552, h:720, format:PRIVATE(34), min_duration:33333333, stall:0], [w:1520, h:720, format:PRIVATE(34), min_duration:33333333, stall:0], [w:1440, h:1088, format:PRIVATE(34), min_duration:33333333, stall:0], [w:1440, h:1080, format:PRIVATE(34), min_duration:33333333, stall:0], [w:1440, h:720, format:PRIVATE(34), min_duration:33333333, stall:0], [w:1280, h:960, format:PRIVATE(34), min_duration:33333333, stall:0], [w:1280, h:720, format:PRIVATE(34), min_duration:33333333, stall:0], [w:1280, h:576, format:PRIVATE(34), min_duration:33333333, stall:0], [w:1080, h:720, format:PRIVATE(34), min_duration:3333333
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.availableTestPatternModes) = [0]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.blackLevelPattern) = BlackLevelPattern([64, 64], [64, 64])
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.calibrationTransform1) = ColorSpaceTransform([65536/65536, 0/65536, 0/65536], [0/65536, 65536/65536, 0/65536], [0/65536, 0/65536, 65536/65536])
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.calibrationTransform2) = ColorSpaceTransform([65536/65536, 0/65536, 0/65536], [0/65536, 65536/65536, 0/65536], [0/65536, 0/65536, 65536/65536])
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.colorTransform1) = ColorSpaceTransform([43699/65536, -10413/65536, -5619/65536], [-37614/65536, 91081/65536, 9373/65536], [-9036/65536, 17377/65536, 39559/65536])
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.colorTransform2) = ColorSpaceTransform([100366/65536, -30776/65536, -14094/65536], [-31210/65536, 94721/65536, 439/65536], [-4702/65536, 15645/65536, 15267/65536])
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.forwardMatrix1) = ColorSpaceTransform([44115/65536, 12782/65536, 6293/65536], [18100/65536, 53622/65536, -6187/65536], [1419/65536, -15234/65536, 67896/65536])
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.forwardMatrix2) = ColorSpaceTransform([37650/65536, 12059/65536, 13481/65536], [12702/65536, 48849/65536, 3984/65536], [-950/65536, -34648/65536, 89680/65536])
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.info.activeArraySize) = Rect(0, 0 - 4208, 3120)
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.info.colorFilterArrangement) = 2
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.info.exposureTimeRange) = [100000, 667847000]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.info.maxFrameDuration) = 667981000
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.info.physicalSize) = 4.71x3.49
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.info.pixelArraySize) = 4208x3120
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.info.preCorrectionActiveArraySize) = Rect(0, 0 - 4208, 3120)
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.info.sensitivityRange) = [100, 16000]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.info.timestampSource) = 0
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.info.whiteLevel) = 1023
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.maxAnalogSensitivity) = 1600
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.orientation) = 90
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.referenceIlluminant1) = 21
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sensor.referenceIlluminant2) = 17
D/CameraUtils(12824):   CameraCharacteristics.Key(android.shading.availableModes) = [0, 1, 2]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.statistics.info.availableFaceDetectModes) = [0, 1]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.statistics.info.availableHotPixelMapModes) = [Z@b68962e
D/CameraUtils(12824):   CameraCharacteristics.Key(android.statistics.info.availableLensShadingMapModes) = [0]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.statistics.info.maxFaceCount) = 15
D/CameraUtils(12824):   CameraCharacteristics.Key(android.sync.maxLatency) = 0
D/CameraUtils(12824):   CameraCharacteristics.Key(android.tonemap.availableToneMapModes) = [0, 1, 2]
D/CameraUtils(12824):   CameraCharacteristics.Key(android.tonemap.maxCurvePoints) = 257
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.facefeature.availableasdmodes) = [0, 1]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.facefeature.availableforceface3a) = [0, 1]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.facefeature.availableregionface3a) = [1]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.nrfeature.available3dnrmodes) = [0, 1]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.hdrfeature.availableHdrModesPhoto) = [0, 1]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.hdrfeature.availableHdrModesVideo) = [0]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.hdrfeature.availableMStreamHdrModes) = [0]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.hdrfeature.availableStaggerHdrModes) = [0]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.mfnrfeature.availablemfbmodes) = [0, 1, 2, 255]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.mfnrfeature.availableaismodes) = [0, 1]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.cshotfeature.availableCShotModes) = [0, 1]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.streamingfeature.availableRecordStates) = [0, 1]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.streamingfeature.cropOuterLinesEnable) = [0]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.multicamfeature.availableMultiCamFeatureSensorManualUpdated) = [983040, 983050, 983046, 983042, 983051, 983058, 917518, 524293, 65559, 65564]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.control.capture.early.notification.support) = [0, 1]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.control.capture.availablepostviewmodes) = [0, 1]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.control.capture.available.zsl.modes) = [0, 1]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.control.capture.default.zsl.mode) = [1]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.control.capture.ispMetaSizeForRaw) = [2560, 1920]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.control.capture.ispMetaSizeForYuv) = [1280, 720]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.bgservicefeature.availableprereleasemodes) = [0, 1]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.flashfeature.calibration.available) = [1]
D/CameraUtils(12824):   CameraCharacteristics.Key(com.mediatek.flashfeature.customization.available) = [1]
D/CameraUtils(12824): ========== end CameraCharacteristics ==========
```


# info screen
1 add a top list, currently with these keys
make physicalSize, availableFocalLengths, pixelArraySize, minimumFocusDistance
make items in this list be on the top of the table

2 rename lib\screens\camera_info_screen.dart and related class name it to appropriate name, if it only support android

3 could the enum(s) of the value show the enum name? the 0, 1, 2, ..., is not readable for human (we have to query the api document when see the numbers)

