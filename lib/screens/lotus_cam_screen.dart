import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kFocusPrefKey = 'lotus_cam_focus_diopters';
const String _kShowKMatrixPrefKey = 'lotus_cam_show_k_matrix';
const double _kFocusMinDiopters = 0.0; // infinity
const double _kDefaultMaxDiopters = 10.0; // until we get LENS_INFO_MINIMUM_FOCUS_DISTANCE
const String _kCameraChannel = 'com.example.camlotus/camera';

class LotusCamScreen extends StatefulWidget {
  const LotusCamScreen({super.key});

  @override
  State<LotusCamScreen> createState() => _LotusCamScreenState();
}

class _LotusCamScreenState extends State<LotusCamScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  String? _error;
  double _focusDiopters = 0.0; // diopters (0 = infinity)
  double _focusMaxDiopters = _kDefaultMaxDiopters;
  final TextEditingController _focusTextController = TextEditingController();
  bool _showKMatrix = true;
  bool _isCapturing = false;
  Size? _previewSize;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _initCamera();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _focusDiopters = prefs.getDouble(_kFocusPrefKey) ?? 0.0;
      _showKMatrix = prefs.getBool(_kShowKMatrixPrefKey) ?? true;
    });
    _focusTextController.text = _formatDiopters(_focusDiopters);
  }

  Future<void> _saveFocusDiopters(double diopters) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFocusPrefKey, diopters);
  }

  /// value: true/false
  Future<void> _saveShowKMatrix(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowKMatrixPrefKey, value);
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

  /// Human-readable focus distance in metric for display only (from current diopters).
  /// diopter 0 → "∞"; < 0.1 m → cm; >= 1 m → m.
  String _formatFocusDistanceDisplay() {
    if (_focusDiopters <= 0) return '∞';
    final distanceM = 1.0 / _focusDiopters;
    if (distanceM >= 1.0) {
      return '${distanceM.toStringAsFixed(1)} m';
    } else {
      final distanceCm = distanceM * 100;
      return '${distanceCm.toStringAsFixed(1)} cm';
    }
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
      if (Platform.isIOS || Platform.isAndroid) {
        final ph = await Permission.photos.request();
        if (!ph.isGranted && !ph.isLimited) {
          // Continue anyway; saving may fail with a message
        }
      }

      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _error = 'No camera found';
          _isInitialized = false;
        });
        return;
      }

      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      _previewSize = controller.value.previewSize;

      double maxD = _kDefaultMaxDiopters;
      if (Platform.isAndroid) {
        try {
          final r = await const MethodChannel(_kCameraChannel)
              .invokeMethod<double>('getMaxFocusDistanceDiopters');
          if (r != null && r > 0) maxD = r;
        } catch (_) {}
      }

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _error = null;
        _isInitialized = true;
        _focusMaxDiopters = maxD;
        _focusDiopters = _focusDiopters.clamp(_kFocusMinDiopters, maxD);
        _focusTextController.text = _formatDiopters(_focusDiopters);
      });
      await _applyFocusDistance(_focusDiopters);
    } catch (e, st) {
      debugPrint('LotusCam init error: $e\n$st');
      setState(() {
        _error = e.toString();
        _isInitialized = false;
      });
    }
  }

  /// Sets focus distance in diopters (0 = infinity). Platform channel on Android.
  Future<void> _applyFocusDistance(double diopters) async {
    if (!Platform.isAndroid) return;
    try {
      await const MethodChannel(_kCameraChannel).invokeMethod<void>(
        'setFocusDistance',
        diopters,
      );
    } on MissingPluginException catch (_) {
    } on PlatformException catch (_) {}
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

  void _toggleKMatrix() {
    setState(() => _showKMatrix = !_showKMatrix);
    _saveShowKMatrix(_showKMatrix);
  }

  Future<void> _captureAndSave() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final file = await c.takePicture();
      await Gal.putImage(file.path, album: 'Camlotus');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo saved to gallery')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  void dispose() {
    _focusTextController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('LotusCam'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleKMatrix,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _showKMatrix
                          ? Colors.white24
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'K ${_showKMatrix ? 'ON' : 'OFF'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
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
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
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

    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        InteractiveViewer(
          minScale: 1.0,
          maxScale: 10.0,
          child: Center(
            child: CameraPreview(_controller!),
          ),
        ),
        if (_showKMatrix) _buildKMatrixOverlay(),
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
                _buildCaptureButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKMatrixOverlay() {
    final size = _previewSize ?? const Size(1920, 1080);
    final k = _computeKMatrix(size);
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
                'K (approx)',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'fx=${k.fx.toStringAsFixed(1)} fy=${k.fy.toStringAsFixed(1)}\n'
                'cx=${k.cx.toStringAsFixed(1)} cy=${k.cy.toStringAsFixed(1)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  ({double fx, double fy, double cx, double cy}) _computeKMatrix(Size size) {
    final w = size.width;
    final h = size.height;
    const double fovDeg = 60.0;
    const fovRad = fovDeg * (3.14159265359 / 180);
    final fx = w / (2 * math.tan(fovRad / 2));
    final fy = h / (2 * math.tan(fovRad / 2));
    return (fx: fx, fy: fy, cx: w / 2, cy: h / 2);
  }

  Widget _buildFocusControls() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
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
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
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
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                filled: true,
                fillColor: Colors.white12,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: ' D',
                suffixStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              onSubmitted: _onFocusTextSubmitted,
            ),
          ),
        ],
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
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 36),
        ),
      ),
    );
  }
}
