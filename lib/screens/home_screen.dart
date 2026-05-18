import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../services/history_service.dart';
import 'history_screen.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  File? _image;
  AnalysisType _type = AnalysisType.plantPest;
  bool _loading = false;

  late final AnimationController _pulseCtrl;
  late final AnimationController _scanCtrl;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _analyze() async {
    if (_image == null || _loading) return;
    setState(() => _loading = true);
    _scanCtrl.repeat();

    try {
      final result = await ApiService.analyze(
        imageFile: _image!,
        analysisType: _type,
      );
      await HistoryService.save(HistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        analysisType: _type,
        response: result,
        imagePath: _image!.path,
      ));
      if (!mounted) return;
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => ResultScreen(response: result),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
          transitionDuration: const Duration(milliseconds: 420),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.userFriendlyMessage);
    } catch (e) {
      if (!mounted) return;
      _showError('Network error. Check your internet connection.');
    } finally {
      _scanCtrl
        ..stop()
        ..reset();
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── Header ──────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            backgroundColor: cs.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white),
                tooltip: 'History',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 18, bottom: 14),
              title: const Row(children: [
                Icon(Icons.eco_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'GblackAI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ]),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primary, const Color(0xFF1B5E20)],
                  ),
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Icon(
                      Icons.grass_rounded,
                      size: 72,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Content ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image preview card
                  _ImageCard(
                    image: _image,
                    loading: _loading,
                    pulseAnim: _pulseCtrl,
                    scanAnim: _scanCtrl,
                    onCamera: () => _pick(ImageSource.camera),
                    onGallery: () => _pick(ImageSource.gallery),
                  ),
                  const SizedBox(height: 24),

                  // Analysis type selector
                  _SectionLabel(label: 'Analysis type'),
                  const SizedBox(height: 10),
                  _TypeSelector(
                    selected: _type,
                    enabled: !_loading,
                    onChanged: (t) => setState(() => _type = t),
                  ),
                  const SizedBox(height: 28),

                  // Analyze button
                  _AnalyzeButton(
                    enabled: _image != null && !_loading,
                    loading: _loading,
                    onTap: _analyze,
                  ),

                  if (_image == null) ...[
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'Select or take a photo to get started',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: cs.outline),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
    );
  }
}

// ─── Image Card ───────────────────────────────────────────────────────────────

class _ImageCard extends StatelessWidget {
  final File? image;
  final bool loading;
  final Animation<double> pulseAnim;
  final Animation<double> scanAnim;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _ImageCard({
    required this.image,
    required this.loading,
    required this.pulseAnim,
    required this.scanAnim,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (context, _) {
        final glowOpacity = image != null ? 0.12 + 0.08 * pulseAnim.value : 0.0;
        final borderOpacity = image != null ? 0.5 + 0.3 * pulseAnim.value : 1.0;

        return Container(
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: image != null
                  ? cs.primary.withOpacity(borderOpacity)
                  : cs.outlineVariant,
              width: image != null ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(glowOpacity),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image != null)
                  Image.file(image!, fit: BoxFit.cover)
                else
                  _EmptySlot(onCamera: onCamera, onGallery: onGallery),

                if (loading) _ScanOverlay(animation: scanAnim),

                if (image != null && !loading)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black54, Colors.transparent],
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _GlassButton(
                            icon: Icons.camera_alt_rounded,
                            label: 'Camera',
                            onTap: onCamera,
                          ),
                          const SizedBox(width: 8),
                          _GlassButton(
                            icon: Icons.photo_library_rounded,
                            label: 'Gallery',
                            onTap: onGallery,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GlassButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _EmptySlot extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _EmptySlot({required this.onCamera, required this.onGallery});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceVariant.withOpacity(0.4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 70,
            color: cs.primary.withOpacity(0.45),
          ),
          const SizedBox(height: 14),
          Text(
            'Add a photo',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SlotButton(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                onTap: onCamera,
              ),
              const SizedBox(width: 12),
              _SlotButton(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: onGallery,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SlotButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─── Scan Overlay ─────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  final Animation<double> animation;
  const _ScanOverlay({required this.animation});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.55),
      child: AnimatedBuilder(
        animation: animation,
        builder: (_, __) => Stack(children: [
          Positioned(
            top: animation.value * 280 - 2,
            left: 0,
            right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  Colors.greenAccent,
                  Colors.greenAccent,
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.document_scanner_rounded,
                  color: Colors.white,
                  size: 52,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Analyzing…',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'AI is running',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Type Selector ────────────────────────────────────────────────────────────

class _TypeSelector extends StatelessWidget {
  final AnalysisType selected;
  final bool enabled;
  final ValueChanged<AnalysisType> onChanged;

  const _TypeSelector({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  static String _icon(AnalysisType t) => switch (t) {
        AnalysisType.plantPest => '🌿',
        AnalysisType.satellite => '🛰️',
        AnalysisType.drone => '🚁',
      };

  static String _short(AnalysisType t) => switch (t) {
        AnalysisType.plantPest => 'Plant',
        AnalysisType.satellite => 'Satellite',
        AnalysisType.drone => 'Drone',
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final types = AnalysisType.values;

    return Row(
      children: types.asMap().entries.map((e) {
        final i = e.key;
        final type = e.value;
        final isSelected = type == selected;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < types.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: enabled ? () => onChanged(type) : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary : cs.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: cs.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_icon(type), style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 5),
                    Text(
                      _short(type),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : cs.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Analyze Button ───────────────────────────────────────────────────────────

class _AnalyzeButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _AnalyzeButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: enabled
            ? LinearGradient(
                colors: [cs.primary, const Color(0xFF1B5E20)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: enabled ? null : cs.onSurface.withOpacity(0.08),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: cs.primary.withOpacity(0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                )
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Center(
            child: loading
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Analyzing…',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: enabled
                            ? Colors.white
                            : cs.onSurface.withOpacity(0.35),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Analyze',
                        style: TextStyle(
                          color: enabled
                              ? Colors.white
                              : cs.onSurface.withOpacity(0.35),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
