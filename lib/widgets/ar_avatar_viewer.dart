import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import '../services/ultimate_ai_features_service.dart';
import '../core/constants/themes/utils/akel_design_system.dart';

/// ==================== AR AVATAR VIEWER ====================
///
/// AR experience for Doctor Annie 3D avatar:
/// - Camera preview with AR overlay
/// - 3D avatar visualization (simplified without ARCore)
/// - Avatar skin selector
/// - Gesture controls
///
/// ==============================================================

class ARAvatarViewer extends StatefulWidget {
  const ARAvatarViewer({super.key});

  @override
  State<ARAvatarViewer> createState() => _ARAvatarViewerState();
}

class _ARAvatarViewerState extends State<ARAvatarViewer> {
  final UltimateAIFeaturesService _service = UltimateAIFeaturesService();

  CameraController? _cameraController;
  bool _isARActive = false;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('⚠️ No cameras available');
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Camera init error: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
// Camera preview
          if (_isCameraInitialized && _cameraController != null)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            )
          else
            _buildCameraPlaceholder(),

// AR overlay
          if (_isARActive) _buildAROverlay(),

// Controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildCameraPlaceholder() {
    return Container(
      color: AkelDesign.deepBlack,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF00BFA5),
            ),
            const SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAROverlay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
// 3D Avatar placeholder (simplified without ARCore)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF00BFA5).withOpacity(0.8),
                  const Color(0xFF00E5FF).withOpacity(0.6),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Icon(
              Icons.psychology,
              size: 100,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

// Speech bubble
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Text(
              "Hi! I'm Annie in AR! 👋",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return SafeArea(
      child: Column(
        children: [
// Top bar
          _buildTopBar(),

          const Spacer(),

// Bottom controls
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.7),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _isARActive
                  ? const Color(0xFF00BFA5)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isARActive ? 'AR Active' : 'AR Inactive',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            Icons.cameraswitch,
            'Switch',
                () async {
              if (_cameraController != null) {
                final cameras = await availableCameras();
                if (cameras.length > 1) {
// Switch camera logic
                  HapticFeedback.mediumImpact();
                }
              }
            },
          ),
          GestureDetector(
            onTap: () {
              setState(() => _isARActive = !_isARActive);
              HapticFeedback.mediumImpact();
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00BFA5), Color(0xFF00E5FF)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00BFA5).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                _isARActive ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
          _buildControlButton(
            Icons.settings,
            'Skins',
                () => _showAvatarSkinSelector(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showAvatarSkinSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AkelDesign.carbonFiber,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final skins = _service.getAvailableAvatarSkins();

        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Avatar Skins',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...skins.map((skin) {
                final isSelected = _service.currentAvatarSkin == skin.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00BFA5).withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00BFA5)
                          : Colors.white30,
                    ),
                  ),
                  child: ListTile(
                    leading: Text(skin.emoji, style: const TextStyle(fontSize: 32)),
                    title: Text(
                      skin.name,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF00BFA5) : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      skin.description,
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Color(0xFF00BFA5))
                        : null,
                    onTap: () async {
                      await _service.setAvatarSkin(skin.id);
                      Navigator.pop(context);
                      setState(() {});

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Avatar: ${skin.name}'),
                            backgroundColor: const Color(0xFF00BFA5),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}