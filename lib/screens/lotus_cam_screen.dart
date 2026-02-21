import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kFocusPrefKey = 'lotus_cam_focus_distance';
const String _kShowKMatrixPrefKey = 'lotus_cam_show_k_matrix';
const double _kFocusMin = 0.0; // near
const double _kFocusMax = 1.0; // far
const int _kFocusSteps = 100;
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
  double _focusValue = 0.5;  // [0, 1]
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
      _focusValue = prefs.getDouble(_kFocusPrefKey) ?? 0.5;
      _showKMatrix = prefs.getBool(_kShowKMatrixPrefKey) ?? true;
    });
    _focusTextController.text = _formatFocus(_focusValue);
  }

  /// value: [0, 1]
  Future<void> _saveFocus(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kFocusPrefKey, value);
  }

  /// value: true/false
  Future<void> _saveShowKMatrix(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kShowKMatrixPrefKey, value);
  }

  /// [0, 1] -> [0, 100] e.g. 0: 0, 0.2: 20, 1.0: 100
  static String _formatFocus(double v) =>
      (v * _kFocusSteps).round().toString();

  /// [0, 100] -> [0, 1] e.g. 0: 0, 20: 0.2, 100: 1.0
  static double _parseFocus(String s) {
    final n = int.tryParse(s);
    if (n == null) return 0.5;
    final v = n / _kFocusSteps;
    return v.clamp(_kFocusMin, _kFocusMax);
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
      await _applyFocusDistance(_focusValue);

      if (!mounted) return;
      setState(() {
        _controller = controller;
        _error = null;
        _isInitialized = true;
      });
    } catch (e, st) {
      debugPrint('LotusCam init error: $e\n$st');
      setState(() {
        _error = e.toString();
        _isInitialized = false;
      });
    }
  }

  /// Sets focus distance (0 = near, 1 = far). Uses platform channel on Android;
  /// standard Flutter camera plugin does not expose LENS_FOCUS_DISTANCE.
  Future<void> _applyFocusDistance(double normalizedValue) async {
    if (!Platform.isAndroid) return;
    try {
      await const MethodChannel(_kCameraChannel).invokeMethod<void>(
        'setFocusDistance',
        normalizedValue,
      );
    } on MissingPluginException catch (_) {
      // Native side not implemented yet (requires camera plugin support)
    } on PlatformException catch (_) {
      // ignore if not supported
    }
  }

  void _onFocusSliderChanged(double value) {
    setState(() {
      _focusValue = value;
      _focusTextController.text = _formatFocus(value);
    });
    _saveFocus(value);
    _applyFocusDistance(value);
  }

  void _onFocusTextSubmitted(String text) {
    final value = _parseFocus(text);  // [0, 100] -> [0, 1]
    setState(() {
      _focusValue = value;
      _focusTextController.text = _formatFocus(value);
    });
    _saveFocus(value);
    _applyFocusDistance(value);
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
        Center(
          child: CameraPreview(_controller!),
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
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            'Near',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white70,
                inactiveTrackColor: Colors.white30,
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _focusValue,
                min: _kFocusMin,
                max: _kFocusMax,
                onChanged: _onFocusSliderChanged,
              ),
            ),
          ),
          Text(
            'Far',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            child: TextField(
              controller: _focusTextController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              keyboardType: TextInputType.number,
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
