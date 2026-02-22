import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../camera/k_matrix_estimator.dart';
import 'camera_info_screen.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Resolution options: (width, height); first = highest = default.
const List<(int, int)> _kResolutions = [
  (1920, 1080),
  (1280, 720),
  (640, 480),
];

const String _kFocusPrefKey = 'lotus_cam_focus_diopters';
const String _kShowKMatrixPrefKey = 'lotus_cam_show_k_matrix';
const String _kResolutionIndexKey = 'lotus_cam_resolution_index';
const String _kLastPhotoPathKey = 'lotus_cam_last_photo_path';
const double _kFocusMinDiopters = 0.0;
const double _kDefaultMaxDiopters = 10.0;

class LotusCamScreen extends StatefulWidget {
  const LotusCamScreen({super.key});

  @override
  State<LotusCamScreen> createState() => _LotusCamScreenState();
}

class _LotusCamScreenState extends State<LotusCamScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  bool _isInitialized = false;
  String? _error;
  double _focusDiopters = 0.0;
  double _focusMaxDiopters = _kDefaultMaxDiopters;
  final TextEditingController _focusTextController = TextEditingController();
  bool _showKMatrix = false;
  bool _isCapturing = false;
  bool _showCaptureBlink = false;
  List<MediaDeviceInfo> _videoDevices = [];
  int _currentDeviceIndex = 0;
  int _resolutionIndex = 0;
  String? _lastPhotoPath;
  Uint8List? _lastPhotoBytes; // in-memory thumbnail after capture; null after restart
  List<double>? _kMatrixIntrinsics; // from platform (Android LENS_INTRINSIC_CALIBRATION); null = feature disabled

  @override
  void initState() {
    super.initState();
    _initRenderer();
    _loadPrefs().then((_) => _initCamera());
  }

  Future<void> _initRenderer() async {
    await _localRenderer.initialize();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastPath = prefs.getString(_kLastPhotoPathKey);
    if (lastPath != null && !File(lastPath).existsSync()) {
      lastPath = null;
      await _saveLastPhotoPath(null);
    }
    if (!mounted) return;
    setState(() {
      _focusDiopters = prefs.getDouble(_kFocusPrefKey) ?? 0.0;
      _showKMatrix = prefs.getBool(_kShowKMatrixPrefKey) ?? false;
      _resolutionIndex = prefs.getInt(_kResolutionIndexKey) ?? 0;
      _resolutionIndex = _resolutionIndex.clamp(0, _kResolutions.length - 1);
      _lastPhotoPath = lastPath;
    });
    _focusTextController.text = _formatDiopters(_focusDiopters);
  }

  Future<void> _saveFocusDiopters(double diopters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFocusPrefKey, diopters);
  }

  Future<void> _saveShowKMatrix(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowKMatrixPrefKey, value);
  }

  Future<void> _saveResolutionIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kResolutionIndexKey, index);
  }

  Future<void> _saveLastPhotoPath(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_kLastPhotoPathKey, path);
    } else {
      await prefs.remove(_kLastPhotoPathKey);
    }
  }

  static String _formatDiopters(double d) {
    if (d == d.roundToDouble()) return d.round().toString();
    return d.toStringAsFixed(2);
  }

  static double _parseDiopters(String s, double maxD) {
    final v = double.tryParse(s);
    if (v == null) return 0.0;
    return v.clamp(_kFocusMinDiopters, maxD);
  }

  String _formatFocusDistanceDisplay() {
    if (_focusDiopters <= 0) return '∞';
    final distanceM = 1.0 / _focusDiopters;
    if (distanceM >= 1.0) {
      return '${distanceM.toStringAsFixed(1)} m';
    }
    final distanceCm = distanceM * 100;
    return '${distanceCm.toStringAsFixed(1)} cm';
  }

  Map<String, dynamic> _mediaConstraints() {
    final (w, h) = _kResolutions[_resolutionIndex];
    return {
      'audio': false,
      'video': {
        'mandatory': {
          'minWidth': w.toString(),
          'minHeight': h.toString(),
          'minFrameRate': '24',
        },
        'optional': [
          {'deviceId': _videoDevices.isNotEmpty && _currentDeviceIndex < _videoDevices.length
              ? _videoDevices[_currentDeviceIndex].deviceId
              : null},
        ],
      },
    };
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _error = 'Camera permission denied';
          _isInitialized = false;
        });
        return;
      }
      if (Platform.isAndroid || Platform.isIOS) {
        final ph = await Permission.photos.request();
        if (!ph.isGranted && !ph.isLimited) {}
      }

      _videoDevices = await navigator.mediaDevices.enumerateDevices();
      final videoOnly = _videoDevices.where((d) => d.kind == 'videoinput' || d.kind == 'video').toList();
      if (videoOnly.isEmpty) {
        _videoDevices = [];
      } else {
        _videoDevices = videoOnly;
      }

      final constraints = _mediaConstraints();
      if (_videoDevices.isNotEmpty && _currentDeviceIndex < _videoDevices.length) {
        constraints['video']!['optional'] = [
          {'sourceId': _videoDevices[_currentDeviceIndex].deviceId},
        ];
      }
      var stream = await navigator.mediaDevices.getUserMedia(constraints);
      _localStream = stream;
      _localRenderer.srcObject = _localStream;

      if (!mounted) return;
      double maxD = _focusMaxDiopters;
      List<double>? kResolved;
      if (Platform.isAndroid && _localStream != null) {
        try {
          final track = _localStream!.getVideoTracks().firstWhere((t) => t.kind == 'video');
          maxD = await Helper.getMaxFocusDistanceDiopters(track);
          if (maxD <= 0) maxD = _kDefaultMaxDiopters;
          final intrinsics = await Helper.getCameraIntrinsics(track);
          final characteristics = await Helper.getCameraCharacteristics(track);
          kResolved = resolveKMatrix(intrinsics, characteristics);
        } catch (_) {}
      }
      final maxDiopters = maxD;
      setState(() {
        _error = null;
        _isInitialized = true;
        _focusMaxDiopters = maxDiopters;
        _focusDiopters = _focusDiopters.clamp(_kFocusMinDiopters, _focusMaxDiopters);
        _focusTextController.text = _formatDiopters(_focusDiopters);
        _kMatrixIntrinsics = kResolved;
      });
      if (Platform.isAndroid && _localStream != null) {
        _applyFocusDistance(_focusDiopters);
      }
    } catch (e, st) {
      debugPrint('LotusCam init error: $e\n$st');
      setState(() {
        _error = e.toString();
        _isInitialized = false;
      });
    }
  }

  Future<void> _replaceStream() async {
    await _localStream?.dispose();
    _localStream = null;
    final constraints = _mediaConstraints();
    if (_videoDevices.isNotEmpty && _currentDeviceIndex < _videoDevices.length) {
      constraints['video']!['optional'] = [
        {'sourceId': _videoDevices[_currentDeviceIndex].deviceId},
      ];
    }
    final stream = await navigator.mediaDevices.getUserMedia(constraints);
    _localStream = stream;
    _localRenderer.srcObject = _localStream;
    if (mounted) {
      setState(() {});
      if (Platform.isAndroid && _localStream != null) {
        _applyFocusDistance(_focusDiopters);
        final track = _localStream!.getVideoTracks().firstWhere((t) => t.kind == 'video');
        Helper.getMaxFocusDistanceDiopters(track).then((double maxD) {
          if (maxD > 0 && mounted) setState(() => _focusMaxDiopters = maxD);
        });
        Helper.getCameraIntrinsics(track).then((List<double>? intrinsics) async {
          final characteristics = await Helper.getCameraCharacteristics(track);
          final kResolved = resolveKMatrix(intrinsics, characteristics);
          if (mounted) setState(() => _kMatrixIntrinsics = kResolved);
        });
      }
    }
  }

  void _onSwitchCamera() {
    if (_videoDevices.isEmpty) return;
    setState(() {
      _currentDeviceIndex = (_currentDeviceIndex + 1) % _videoDevices.length;
    });
    _replaceStream();
  }

  void _onResolutionTap() {
    setState(() {
      _resolutionIndex = (_resolutionIndex + 1) % _kResolutions.length;
    });
    _saveResolutionIndex(_resolutionIndex);
    _replaceStream();
  }

  Future<void> _applyFocusDistance(double diopters) async {
    if (!Platform.isAndroid || _localStream == null) return;
    try {
      final track = _localStream!.getVideoTracks().firstWhere((t) => t.kind == 'video');
      await Helper.setFocusDistance(track, diopters);
    } catch (e) {
      debugPrint('setFocusDistance: $e');
    }
  }

  void _onFocusSliderChanged(double diopters) {
    setState(() {
      _focusDiopters = diopters;
      _focusTextController.text = _formatDiopters(diopters);
    });
    _saveFocusDiopters(diopters);
    _applyFocusDistance(diopters);
  }

  void _onFocusTextSubmitted(String text) {
    final diopters = _parseDiopters(text, _focusMaxDiopters);
    setState(() {
      _focusDiopters = diopters;
      _focusTextController.text = _formatDiopters(diopters);
    });
    _saveFocusDiopters(diopters);
    _applyFocusDistance(diopters);
  }

  void _onKTap() {
    if (_kMatrixIntrinsics == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('K matrix not available (no intrinsics or estimation failed)'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() => _showKMatrix = !_showKMatrix);
    _saveShowKMatrix(_showKMatrix);
  }

  Future<void> _openCameraInfo() async {
    if (_localStream == null) return;
    try {
      final track = _localStream!.getVideoTracks().firstWhere((t) => t.kind == 'video');
      final characteristics = await Helper.getCameraCharacteristics(track);
      if (!mounted) return;
      if (characteristics == null || characteristics.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera info not available')),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (context) => CameraInfoScreen(characteristics: characteristics),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera info: $e')),
        );
      }
    }
  }

  Future<void> _captureAndSave() async {
    if (_localStream == null || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final videoTrack = _localStream!.getVideoTracks().firstWhere((t) => t.kind == 'video');
      final frame = await videoTrack.captureFrame();
      final bytes = frame.asUint8List();
      if (bytes.isEmpty) return;
      final appDir = await getApplicationDocumentsDirectory();
      final camlotusDir = Directory('${appDir.path}/Camlotus');
      if (!await camlotusDir.exists()) await camlotusDir.create(recursive: true);
      const lastCaptureName = 'last_capture.jpg';
      final path = '${camlotusDir.path}/$lastCaptureName';
      final file = File(path);
      await file.writeAsBytes(bytes);
      await Gal.putImage(path, album: 'Camlotus');
      await _saveLastPhotoPath(path);
      if (mounted) {
        setState(() {
          _lastPhotoPath = path;
          _lastPhotoBytes = Uint8List.fromList(bytes);
          _showCaptureBlink = true;
        });
        Future.delayed(const Duration(milliseconds: 120), () {
          if (mounted) setState(() => _showCaptureBlink = false);
        });
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _openGallery() {
    Gal.open();
  }

  @override
  void dispose() {
    _focusTextController.dispose();
    _localStream?.dispose();
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          if (Platform.isAndroid && _isInitialized)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: _openCameraInfo,
              tooltip: 'Camera info',
            ),
          if (Platform.isAndroid && _isInitialized)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _onKTap,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _showKMatrix ? Colors.blue : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'K',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _showKMatrix ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() => _error = null);
                  _initCamera();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _localStream == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          minScale: 1.0,
          maxScale: 10.0,
          child: Center(child: RTCVideoView(_localRenderer)),
        ),
        if (_showCaptureBlink)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(color: Colors.white.withValues(alpha: 0.4)),
            ),
          ),
        if (_kMatrixIntrinsics != null && _showKMatrix) _buildKMatrixOverlay(),
        Positioned(
          left: 12,
          bottom: MediaQuery.of(context).padding.bottom + 24 + 72 + 16 + 60,
          child: GestureDetector(
            onTap: _onResolutionTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_kResolutions[_resolutionIndex].$1}×${_kResolutions[_resolutionIndex].$2}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFocusControls(),
                const SizedBox(height: 16),
                _buildBottomControls(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKMatrixOverlay() {
    final k = _kMatrixIntrinsics!;
    final fx = k.isNotEmpty ? k[0] : 0.0;
    final fy = k.length > 1 ? k[1] : 0.0;
    final cx = k.length > 2 ? k[2] : 0.0;
    final cy = k.length > 3 ? k[3] : 0.0;
    return Positioned(
      left: 12,
      top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
      child: Material(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'K (camera)',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'fx=${fx.toStringAsFixed(1)} fy=${fy.toStringAsFixed(1)}\n'
                'cx=${cx.toStringAsFixed(1)} cy=${cy.toStringAsFixed(1)}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFocusControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white70,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _focusDiopters,
                min: _kFocusMinDiopters,
                max: _focusMaxDiopters,
                onChanged: _onFocusSliderChanged,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              _formatFocusDistanceDisplay(),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 56,
            child: TextField(
              controller: _focusTextController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: ' D',
                suffixStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
              ),
              onSubmitted: _onFocusTextSubmitted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 24),
        _buildGalleryButton(),
        const SizedBox(width: 24),
        _buildCaptureButton(),
        const SizedBox(width: 24),
        _buildSwitchCameraButton(),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _buildGalleryButton() {
    final hasThumbnail = _lastPhotoBytes != null ||
        (_lastPhotoPath != null && File(_lastPhotoPath!).existsSync());
    return GestureDetector(
      onTap: _openGallery,
      child: SizedBox(
        width: 56,
        height: 56,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: hasThumbnail
              ? (_lastPhotoBytes != null
                  ? Image.memory(_lastPhotoBytes!, fit: BoxFit.cover)
                  : Image.file(File(_lastPhotoPath!), fit: BoxFit.cover))
              : Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white54),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: Colors.white54, size: 32),
                ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isCapturing ? null : _captureAndSave,
      child: AnimatedOpacity(
        opacity: _isCapturing ? 0.6 : 1,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            color: Colors.white24,
          ),
          child: _isCapturing
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 36),
        ),
      ),
    );
  }

  Widget _buildSwitchCameraButton() {
    return IconButton(
      onPressed: _videoDevices.length > 1 ? _onSwitchCamera : null,
      icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white, size: 28),
      style: IconButton.styleFrom(
        backgroundColor: _videoDevices.length > 1 ? Colors.white24 : Colors.white12,
      ),
    );
  }
}
