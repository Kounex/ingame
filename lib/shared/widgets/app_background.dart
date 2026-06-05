import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

const _ambientBackgroundShaderAsset = 'shaders/ambient_background.frag';

class AmbientMotionController extends ChangeNotifier {
  AmbientMotionController({double intensity = 0.8}) : _intensity = intensity;

  double _intensity;

  double get intensity => _intensity;

  void setIntensity(double value) {
    final next = value.clamp(0.0, 1.0).toDouble();
    if (next == _intensity) return;
    _intensity = next;
    notifyListeners();
  }
}

class AmbientMotionScope extends InheritedNotifier<AmbientMotionController> {
  const AmbientMotionScope({
    super.key,
    required AmbientMotionController controller,
    required super.child,
  }) : super(notifier: controller);

  static AmbientMotionController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AmbientMotionScope>()
        ?.notifier;
  }
}

class _AmbientSurfaceScope extends InheritedWidget {
  const _AmbientSurfaceScope({required super.child});

  static bool isPresent(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_AmbientSurfaceScope>() !=
        null;
  }

  @override
  bool updateShouldNotify(covariant _AmbientSurfaceScope oldWidget) => false;
}

class AmbientMotionDebugLayer extends StatefulWidget {
  const AmbientMotionDebugLayer({super.key, required this.child});

  final Widget child;

  @override
  State<AmbientMotionDebugLayer> createState() => _AmbientMotionDebugLayerState();
}

class _AmbientMotionDebugLayerState extends State<AmbientMotionDebugLayer> {
  late final AmbientMotionController _controller = AmbientMotionController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AmbientMotionScope(
      controller: _controller,
      child: Stack(
        children: [
          widget.child,
          const Positioned(
            top: 12,
            right: 12,
            child: SafeArea(child: AmbientMotionDebugPanel()),
          ),
        ],
      ),
    );
  }
}

class AmbientMotionDebugPanel extends StatelessWidget {
  const AmbientMotionDebugPanel({super.key});

  static const _presetValues = [0.15, 0.45, 0.8];
  static const _presetLabels = ['Subtle', 'Balanced', 'Expressive'];

  @override
  Widget build(BuildContext context) {
    final controller = AmbientMotionScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final intensity = controller.intensity;
        return Material(
          color: Colors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 24,
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints.tightFor(width: 248),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.waves_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Ambient motion',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${(intensity * 100).round()}%',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _IntensityStepButton(
                          icon: Icons.remove,
                          onPressed: () => controller.setIntensity(
                            (intensity - 0.1).clamp(0.0, 1.0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (var i = 0; i < _presetValues.length; i++)
                                _IntensityPresetChip(
                                  label: _presetLabels[i],
                                  isSelected:
                                      (intensity - _presetValues[i]).abs() < 0.01,
                                  onTap: () =>
                                      controller.setIntensity(_presetValues[i]),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _IntensityStepButton(
                          icon: Icons.add,
                          onPressed: () => controller.setIntensity(
                            (intensity + 0.1).clamp(0.0, 1.0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: intensity,
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(999),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      backgroundColor: AppColors.glassBorder,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _IntensityStepButton extends StatelessWidget {
  const _IntensityStepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onPressed,
      radius: 18,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.glassSurfaceLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

class _IntensityPresetChip extends StatelessWidget {
  const _IntensityPresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 28,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.glassSurfaceLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class SharedAnimatedBackground extends StatefulWidget {
  const SharedAnimatedBackground({
    super.key,
    this.forceFallback = false,
  });

  final bool forceFallback;

  @override
  State<SharedAnimatedBackground> createState() => _SharedAnimatedBackgroundState();
}

class _SharedAnimatedBackgroundState extends State<SharedAnimatedBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _cycleDuration = Duration(seconds: 20);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _cycleDuration,
  );

  ui.FragmentProgram? _program;
  bool _shaderLoadFailed = false;

  bool get _reduceMotion => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.repeat();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        _ambientBackgroundShaderAsset,
      );
      if (!mounted) return;
      setState(() {
        _program = program;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _shaderLoadFailed = true;
      });
    }
  }

  void _syncAnimationState() {
    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = 0;
      return;
    }

    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_reduceMotion) return;

    if (state == AppLifecycleState.resumed) {
      _syncAnimationState();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final intensity =
                AmbientMotionScope.maybeOf(context)?.intensity ?? 0.3;
            final progress = _reduceMotion ? 0.0 : _controller.value;
            final useFallback =
                widget.forceFallback ||
                kIsWeb ||
                _program == null ||
                _shaderLoadFailed;

            if (useFallback) {
              return _FallbackAmbientBackground(
                progress: progress,
                intensity: intensity,
              );
            }

            return SizedBox.expand(
              child: CustomPaint(
                painter: _AmbientShaderPainter(
                  program: _program!,
                  progress: progress,
                  intensity: intensity,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AppBackgroundSurface extends StatelessWidget {
  const AppBackgroundSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (_AmbientSurfaceScope.isPresent(context)) {
      return child;
    }

    final intensity = AmbientMotionScope.maybeOf(context)?.intensity ?? 0.3;
    final topAlpha = ui.lerpDouble(0.8, 0.34, intensity)!;
    final bottomAlpha = ui.lerpDouble(0.88, 0.5, intensity)!;

    return _AmbientSurfaceScope(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background.withValues(alpha: topAlpha),
              AppColors.backgroundLight.withValues(alpha: bottomAlpha),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _AmbientShaderPainter extends CustomPainter {
  const _AmbientShaderPainter({
    required this.program,
    required this.progress,
    required this.intensity,
  });

  final ui.FragmentProgram program;
  final double progress;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();
    final accent = Color.lerp(AppColors.primary, AppColors.secondary, 0.55)!;
    final glow = Color.lerp(AppColors.backgroundLight, AppColors.primary, 0.35)!;

    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, progress * _SharedAnimatedBackgroundState._cycleDuration.inSeconds)
      ..setFloat(3, AppColors.background.r / 255)
      ..setFloat(4, AppColors.background.g / 255)
      ..setFloat(5, AppColors.background.b / 255)
      ..setFloat(6, AppColors.backgroundLight.r / 255)
      ..setFloat(7, AppColors.backgroundLight.g / 255)
      ..setFloat(8, AppColors.backgroundLight.b / 255)
      ..setFloat(9, accent.r / 255)
      ..setFloat(10, accent.g / 255)
      ..setFloat(11, accent.b / 255)
      ..setFloat(12, glow.r / 255)
      ..setFloat(13, glow.g / 255)
      ..setFloat(14, glow.b / 255)
      ..setFloat(15, intensity);

    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientShaderPainter oldDelegate) {
    return oldDelegate.program != program ||
        oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity;
  }
}

class _FallbackAmbientBackground extends StatelessWidget {
  const _FallbackAmbientBackground({
    required this.progress,
    required this.intensity,
  });

  final double progress;
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final drift = progress * math.pi * 2;

    return SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final shortestSide = size.shortestSide;

          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.background, AppColors.backgroundLight],
                  ),
                ),
              ),
              _AmbientOrb(
                key: const ValueKey('ambient-orb-primary'),
                size: shortestSide * (0.72 + intensity * 0.22),
                center: Offset(
                  size.width * (0.22 + 0.12 * math.sin(drift + 0.35)),
                  size.height * (0.2 + 0.08 * math.cos(drift * 2 - 0.4)),
                ),
                color: AppColors.primary,
                opacity: 0.08 + intensity * 0.26,
              ),
              _AmbientOrb(
                key: const ValueKey('ambient-orb-secondary'),
                size: shortestSide * (0.6 + intensity * 0.2),
                center: Offset(
                  size.width * (0.84 + 0.1 * math.cos(drift - 0.55)),
                  size.height * (0.3 + 0.09 * math.sin(drift * 2 + 0.6)),
                ),
                color: AppColors.secondary,
                opacity: 0.06 + intensity * 0.24,
              ),
              _AmbientOrb(
                key: const ValueKey('ambient-orb-tertiary'),
                size: shortestSide * (0.86 + intensity * 0.24),
                center: Offset(
                  size.width * (0.54 + 0.08 * math.sin(drift * 2 + 0.8)),
                  size.height * (0.8 + 0.07 * math.cos(drift - 0.7)),
                ),
                color: Color.lerp(
                  AppColors.primary,
                  AppColors.secondary,
                  0.25,
                )!,
                opacity: 0.05 + intensity * 0.18,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({
    super.key,
    required this.size,
    required this.center,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Offset center;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: center.dx - size / 2,
      top: center.dy - size / 2,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 1),
                  color.withValues(alpha: 0.7),
                  color.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.24, 0.62, 1.0],
              ),
            ),
            child: SizedBox.square(dimension: size),
          ),
        ),
      ),
    );
  }
}
