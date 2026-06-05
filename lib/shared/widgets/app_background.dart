import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/app_theme.dart';
import 'debug_overlay_card.dart';

const _ambientBackgroundShaderAsset = 'shaders/ambient_background.frag';

class AmbientMotionController extends ChangeNotifier {
  AmbientMotionController({double intensity = 0.8})
    : _intensity = intensity.clamp(0.0, 1.0).toDouble();

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
    return context.dependOnInheritedWidgetOfExactType<_AmbientSurfaceScope>() !=
        null;
  }

  @override
  bool updateShouldNotify(covariant _AmbientSurfaceScope oldWidget) => false;
}

class AmbientMotionDebugLayer extends StatefulWidget {
  const AmbientMotionDebugLayer({super.key, required this.child});

  final Widget child;

  @override
  State<AmbientMotionDebugLayer> createState() =>
      _AmbientMotionDebugLayerState();
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

  @override
  Widget build(BuildContext context) {
    return const _AmbientDebugOverlay();
  }
}

class _AmbientDebugOverlay extends StatefulWidget {
  const _AmbientDebugOverlay();

  @override
  State<_AmbientDebugOverlay> createState() => _AmbientDebugOverlayState();
}

class _AmbientDebugOverlayState extends State<_AmbientDebugOverlay> {
  static const _intensityPresetValues = [0.15, 0.45, 0.8];
  static const _intensityPresetLabels = ['Subtle', 'Balanced', 'Expressive'];
  static const _timeDilationPresetValues = [1.0, 5.0, 20.0];
  static const _timeDilationPresetLabels = ['1x', '5x', '20x'];
  static const _defaultDebugTimeDilation = 1.0;

  bool _isCollapsed = false;
  bool _motionExpanded = true;
  bool _shaderExpanded = false;
  late double _timeDilationValue;

  @override
  void initState() {
    super.initState();
    _timeDilationValue = timeDilation <= 1.0
        ? _defaultDebugTimeDilation
        : timeDilation;
    timeDilation = _timeDilationValue;
  }

  @override
  void dispose() {
    timeDilation = 1.0;
    super.dispose();
  }

  void _setTimeDilation(double value) {
    final next = value.clamp(1.0, 40.0).toDouble();
    if ((_timeDilationValue - next).abs() < 0.001) return;
    setState(() => _timeDilationValue = next);
    timeDilation = next;
  }

  @override
  Widget build(BuildContext context) {
    final controller = AmbientMotionScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final intensity = controller.intensity;
        return DebugOverlayCard(
          title: 'Debug',
          icon: Icons.bug_report_outlined,
          isCollapsed: _isCollapsed,
          onToggleCollapsed: () => setState(() => _isCollapsed = !_isCollapsed),
          children: [
            DebugOverlaySection(
              title: 'Motion',
              icon: Icons.waves_rounded,
              isExpanded: _motionExpanded,
              onToggle: () =>
                  setState(() => _motionExpanded = !_motionExpanded),
              trailing: Text(
                '${(intensity * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DebugOverlayMetricBlock(
                    label: 'Ambient intensity',
                    value: '${(intensity * 100).round()}%',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                  for (
                                    var i = 0;
                                    i < _intensityPresetValues.length;
                                    i++
                                  )
                                    _IntensityPresetChip(
                                      label: _intensityPresetLabels[i],
                                      isSelected:
                                          (intensity -
                                                  _intensityPresetValues[i])
                                              .abs() <
                                          0.01,
                                      onTap: () => controller.setIntensity(
                                        _intensityPresetValues[i],
                                      ),
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
                  const SizedBox(height: 10),
                  DebugOverlayMetricBlock(
                    label: 'Time dilation',
                    value:
                        '${_timeDilationValue.toStringAsFixed(_timeDilationValue < 10 ? 1 : 0)}x',
                    child: Row(
                      children: [
                        _IntensityStepButton(
                          icon: Icons.remove,
                          onPressed: () =>
                              _setTimeDilation(_timeDilationValue - 1),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (
                                var i = 0;
                                i < _timeDilationPresetValues.length;
                                i++
                              )
                                _IntensityPresetChip(
                                  label: _timeDilationPresetLabels[i],
                                  isSelected:
                                      (_timeDilationValue -
                                              _timeDilationPresetValues[i])
                                          .abs() <
                                      0.01,
                                  onTap: () => _setTimeDilation(
                                    _timeDilationPresetValues[i],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _IntensityStepButton(
                          icon: Icons.add,
                          onPressed: () =>
                              _setTimeDilation(_timeDilationValue + 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            DebugOverlaySection(
              title: 'Shader',
              icon: Icons.auto_awesome_outlined,
              isExpanded: _shaderExpanded,
              onToggle: () =>
                  setState(() => _shaderExpanded = !_shaderExpanded),
              trailing: const DebugOverlayStatusBadge(
                label: kIsWeb ? 'Fallback' : 'Auto',
                highlighted: !kIsWeb,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DebugOverlayInfoPanel(
                    children: [
                      _DebugInfoRow(
                        label: 'Renderer',
                        value: kIsWeb
                            ? 'Fallback orbs (web)'
                            : 'Automatic shader',
                      ),
                      SizedBox(height: 8),
                      _DebugInfoRow(
                        label: 'Asset',
                        value: _ambientBackgroundShaderAsset,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Falls back to animated orbs automatically if shader loading fails.',
                    style: TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DebugInfoRow extends StatelessWidget {
  const _DebugInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 10),
          ),
        ),
      ],
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
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, size: 15, color: AppColors.textPrimary),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.background.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class SharedAnimatedBackground extends StatefulWidget {
  const SharedAnimatedBackground({super.key, this.forceFallback = false});

  final bool forceFallback;

  @override
  State<SharedAnimatedBackground> createState() =>
      _SharedAnimatedBackgroundState();
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

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

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
    final glow = Color.lerp(
      AppColors.backgroundLight,
      AppColors.primary,
      0.35,
    )!;

    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(
        2,
        progress * _SharedAnimatedBackgroundState._cycleDuration.inSeconds,
      )
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

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
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
