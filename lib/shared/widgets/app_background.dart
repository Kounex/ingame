import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme/app_theme.dart';
import 'debug_overlay_card.dart';

const _ambientBackgroundShaderAsset = 'shaders/ambient_background.frag';
const _productionAmbientIntensity = 0.8;
const _mobileShaderVisibilityBoost = 1.45;
const _mobileShaderBlobRadiusScale = 0.72;
const _mobileShaderBlobSoftnessScale = 0.58;
const _mobileShaderMotionScale = 1.45;
const _mobileShaderAccentStrength = 1.65;
const _mobileShaderGlowStrength = 1.5;
const _mobileShaderDistortionAmount = 0.075;
const _diagnosticShaderVisibilityBoost = 3.4;
const _diagnosticShaderBlobRadiusScale = 0.32;
const _diagnosticShaderBlobSoftnessScale = 0.22;
const _diagnosticShaderMotionScale = 2.2;
const _diagnosticShaderAccentStrength = 2.4;
const _diagnosticShaderGlowStrength = 2.1;
const _diagnosticShaderDistortionAmount = 0.11;
const _nativeShaderAmbientIntensity = 0.0;

enum AmbientRenderMode { loading, shader, fallback }

class AmbientShaderTuning {
  const AmbientShaderTuning({
    required this.visibilityBoost,
    required this.blobRadiusScale,
    required this.blobSoftnessScale,
    required this.motionScale,
    required this.accentStrength,
    required this.glowStrength,
    required this.distortionAmount,
  });

  final double visibilityBoost;
  final double blobRadiusScale;
  final double blobSoftnessScale;
  final double motionScale;
  final double accentStrength;
  final double glowStrength;
  final double distortionAmount;
}

@visibleForTesting
List<double> normalizedShaderColorChannels(Color color) {
  return [color.r, color.g, color.b];
}

@visibleForTesting
double normalizedAmbientLoopProgress(double progress) {
  final wrapped = progress % 1.0;
  if (wrapped < 0) {
    return wrapped + 1.0;
  }
  return wrapped;
}

@visibleForTesting
double productionAmbientIntensityForRenderMode({
  required bool isWeb,
  required TargetPlatform platform,
  required AmbientRenderMode renderMode,
}) {
  if (isWeb || renderMode == AmbientRenderMode.fallback) {
    return _productionAmbientIntensity;
  }

  return switch (platform) {
    TargetPlatform.iOS ||
    TargetPlatform.android => _nativeShaderAmbientIntensity,
    _ => _productionAmbientIntensity,
  };
}

double shaderVisibilityBoostForPlatform({
  required bool isWeb,
  required TargetPlatform platform,
}) {
  return shaderTuningForPlatform(
    isWeb: isWeb,
    platform: platform,
  ).visibilityBoost;
}

AmbientShaderTuning shaderTuningForPlatform({
  required bool isWeb,
  required TargetPlatform platform,
  bool diagnosticModeEnabled = false,
}) {
  if (diagnosticModeEnabled) {
    return const AmbientShaderTuning(
      visibilityBoost: _diagnosticShaderVisibilityBoost,
      blobRadiusScale: _diagnosticShaderBlobRadiusScale,
      blobSoftnessScale: _diagnosticShaderBlobSoftnessScale,
      motionScale: _diagnosticShaderMotionScale,
      accentStrength: _diagnosticShaderAccentStrength,
      glowStrength: _diagnosticShaderGlowStrength,
      distortionAmount: _diagnosticShaderDistortionAmount,
    );
  }

  if (isWeb) {
    return const AmbientShaderTuning(
      visibilityBoost: 1.0,
      blobRadiusScale: 1.0,
      blobSoftnessScale: 1.0,
      motionScale: 1.0,
      accentStrength: 1.0,
      glowStrength: 1.0,
      distortionAmount: 0.0,
    );
  }

  return switch (platform) {
    TargetPlatform.iOS || TargetPlatform.android => const AmbientShaderTuning(
      visibilityBoost: _mobileShaderVisibilityBoost,
      blobRadiusScale: _mobileShaderBlobRadiusScale,
      blobSoftnessScale: _mobileShaderBlobSoftnessScale,
      motionScale: _mobileShaderMotionScale,
      accentStrength: _mobileShaderAccentStrength,
      glowStrength: _mobileShaderGlowStrength,
      distortionAmount: _mobileShaderDistortionAmount,
    ),
    _ => const AmbientShaderTuning(
      visibilityBoost: 1.0,
      blobRadiusScale: 1.0,
      blobSoftnessScale: 1.0,
      motionScale: 1.0,
      accentStrength: 1.0,
      glowStrength: 1.0,
      distortionAmount: 0.0,
    ),
  };
}

class AmbientMotionController extends ChangeNotifier {
  AmbientMotionController({
    double intensity = _nativeShaderAmbientIntensity,
    AmbientRenderMode initialRenderMode = AmbientRenderMode.loading,
    this._diagnosticShaderModeEnabled = false,
    this._scrimBypassedForDebug = false,
  }) : _intensity = intensity.clamp(0.0, 1.0).toDouble(),
       _renderMode = initialRenderMode;

  double _intensity;
  AmbientRenderMode _renderMode;
  bool _diagnosticShaderModeEnabled;
  bool _scrimBypassedForDebug;
  bool _intensityManuallyOverridden = false;

  double get intensity => _intensity;
  AmbientRenderMode get renderMode => _renderMode;
  bool get diagnosticShaderModeEnabled => _diagnosticShaderModeEnabled;
  bool get scrimBypassedForDebug => _scrimBypassedForDebug;

  void setIntensity(double value) {
    final next = value.clamp(0.0, 1.0).toDouble();
    if (next == _intensity) return;
    _intensity = next;
    _intensityManuallyOverridden = true;
    notifyListeners();
  }

  void setRenderMode(AmbientRenderMode value) {
    if (value == _renderMode) return;
    _renderMode = value;
    notifyListeners();
  }

  void setDiagnosticShaderModeEnabled(bool value) {
    if (value == _diagnosticShaderModeEnabled) return;
    _diagnosticShaderModeEnabled = value;
    notifyListeners();
  }

  void setScrimBypassedForDebug(bool value) {
    if (value == _scrimBypassedForDebug) return;
    _scrimBypassedForDebug = value;
    notifyListeners();
  }

  void syncProductionIntensityForRenderMode({
    required bool isWeb,
    required TargetPlatform platform,
    required AmbientRenderMode renderMode,
  }) {
    if (_intensityManuallyOverridden) return;
    final next = productionAmbientIntensityForRenderMode(
      isWeb: isWeb,
      platform: platform,
      renderMode: renderMode,
    );
    if ((next - _intensity).abs() < 0.001) return;
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

class AmbientMotionLayer extends StatefulWidget {
  const AmbientMotionLayer({
    super.key,
    required this.child,
    this.showDebugOverlay = false,
    this.initialIntensity,
  });

  final Widget child;
  final bool showDebugOverlay;
  final double? initialIntensity;

  @override
  State<AmbientMotionLayer> createState() => _AmbientMotionLayerState();
}

class _AmbientMotionLayerState extends State<AmbientMotionLayer> {
  late final AmbientMotionController _controller = AmbientMotionController(
    intensity:
        widget.initialIntensity ??
        productionAmbientIntensityForRenderMode(
          isWeb: kIsWeb,
          platform: defaultTargetPlatform,
          renderMode: kIsWeb
              ? AmbientRenderMode.fallback
              : AmbientRenderMode.loading,
        ),
  );

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
          if (widget.showDebugOverlay)
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

class AmbientMotionDebugLayer extends StatelessWidget {
  const AmbientMotionDebugLayer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AmbientMotionLayer(showDebugOverlay: true, child: child);
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

  bool _isCollapsed = true;
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
        final renderMode = controller.renderMode;
        final diagnosticShaderModeEnabled =
            controller.diagnosticShaderModeEnabled;
        final scrimBypassedForDebug = controller.scrimBypassedForDebug;
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
              trailing: DebugOverlayStatusBadge(
                label: switch (renderMode) {
                  AmbientRenderMode.loading => 'Loading',
                  AmbientRenderMode.shader => 'Shader',
                  AmbientRenderMode.fallback => 'Fallback',
                },
                highlighted: renderMode == AmbientRenderMode.shader,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DebugOverlayInfoPanel(
                    children: [
                      _DebugInfoRow(
                        label: 'Renderer',
                        value: switch (renderMode) {
                          AmbientRenderMode.loading => 'Loading shader asset',
                          AmbientRenderMode.shader => 'Fragment shader',
                          AmbientRenderMode.fallback =>
                            kIsWeb ? 'Fallback orbs (web)' : 'Fallback orbs',
                        },
                      ),
                      const SizedBox(height: 8),
                      const _DebugInfoRow(
                        label: 'Asset',
                        value: _ambientBackgroundShaderAsset,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    switch (renderMode) {
                      AmbientRenderMode.loading =>
                        'Waiting for the shader asset to load.',
                      AmbientRenderMode.shader =>
                        diagnosticShaderModeEnabled
                            ? 'Using the fragment shader renderer in diagnostic mode.'
                            : 'Using the fragment shader renderer.',
                      AmbientRenderMode.fallback =>
                        'Using animated orbs because the shader is unavailable or disabled.',
                    },
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DebugOverlayMetricBlock(
                    label: 'Diagnostic',
                    value: diagnosticShaderModeEnabled ? 'On' : 'Off',
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _IntensityPresetChip(
                          label: 'Normal',
                          isSelected: !diagnosticShaderModeEnabled,
                          onTap: () =>
                              controller.setDiagnosticShaderModeEnabled(false),
                        ),
                        _IntensityPresetChip(
                          label: 'Diagnostic',
                          isSelected: diagnosticShaderModeEnabled,
                          onTap: () =>
                              controller.setDiagnosticShaderModeEnabled(true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  DebugOverlayMetricBlock(
                    label: 'Scrim',
                    value: scrimBypassedForDebug ? 'Bypassed' : 'Normal',
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _IntensityPresetChip(
                          label: 'Normal',
                          isSelected: !scrimBypassedForDebug,
                          onTap: () =>
                              controller.setScrimBypassedForDebug(false),
                        ),
                        _IntensityPresetChip(
                          label: 'Bypass',
                          isSelected: scrimBypassedForDebug,
                          onTap: () =>
                              controller.setScrimBypassedForDebug(true),
                        ),
                      ],
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
    } catch (error, stackTrace) {
      debugPrint('Ambient shader load failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() {
        _shaderLoadFailed = true;
      });
    }
  }

  AmbientRenderMode _currentRenderMode() {
    if (widget.forceFallback || kIsWeb || _shaderLoadFailed) {
      return AmbientRenderMode.fallback;
    }
    if (_program == null) {
      return AmbientRenderMode.loading;
    }
    return AmbientRenderMode.shader;
  }

  void _publishRenderMode(AmbientRenderMode mode) {
    final controller = AmbientMotionScope.maybeOf(context);
    if (controller == null || controller.renderMode == mode) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      controller.setRenderMode(mode);
      controller.syncProductionIntensityForRenderMode(
        isWeb: kIsWeb,
        platform: defaultTargetPlatform,
        renderMode: mode,
      );
    });
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
                AmbientMotionScope.maybeOf(context)?.intensity ??
                _productionAmbientIntensity;
            final progress = _reduceMotion ? 0.0 : _controller.value;
            final useFallback =
                widget.forceFallback ||
                kIsWeb ||
                _program == null ||
                _shaderLoadFailed;
            _publishRenderMode(_currentRenderMode());

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
                  tuning: shaderTuningForPlatform(
                    isWeb: kIsWeb,
                    platform: defaultTargetPlatform,
                    diagnosticModeEnabled:
                        AmbientMotionScope.maybeOf(
                          context,
                        )?.diagnosticShaderModeEnabled ??
                        false,
                  ),
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

    final intensity =
        AmbientMotionScope.maybeOf(context)?.intensity ??
        _productionAmbientIntensity;
    final scrimBypassedForDebug =
        AmbientMotionScope.maybeOf(context)?.scrimBypassedForDebug ?? false;
    final topAlpha = scrimBypassedForDebug
        ? 0.0
        : ui.lerpDouble(0.8, 0.34, intensity)!;
    final bottomAlpha = scrimBypassedForDebug
        ? 0.0
        : ui.lerpDouble(0.88, 0.5, intensity)!;

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
    required this.tuning,
  });

  final ui.FragmentProgram program;
  final double progress;
  final double intensity;
  final AmbientShaderTuning tuning;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();
    const accent = AppColors.primary;
    final glow = Color.lerp(
      AppColors.secondary,
      AppColors.secondaryDark,
      0.35,
    )!;
    final baseA = normalizedShaderColorChannels(AppColors.background);
    final baseB = normalizedShaderColorChannels(AppColors.backgroundLight);
    final accentChannels = normalizedShaderColorChannels(accent);
    final glowChannels = normalizedShaderColorChannels(glow);

    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, normalizedAmbientLoopProgress(progress))
      ..setFloat(3, baseA[0])
      ..setFloat(4, baseA[1])
      ..setFloat(5, baseA[2])
      ..setFloat(6, baseB[0])
      ..setFloat(7, baseB[1])
      ..setFloat(8, baseB[2])
      ..setFloat(9, accentChannels[0])
      ..setFloat(10, accentChannels[1])
      ..setFloat(11, accentChannels[2])
      ..setFloat(12, glowChannels[0])
      ..setFloat(13, glowChannels[1])
      ..setFloat(14, glowChannels[2])
      ..setFloat(15, intensity)
      ..setFloat(16, tuning.visibilityBoost)
      ..setFloat(17, tuning.blobRadiusScale)
      ..setFloat(18, tuning.blobSoftnessScale)
      ..setFloat(19, tuning.motionScale)
      ..setFloat(20, tuning.accentStrength)
      ..setFloat(21, tuning.glowStrength)
      ..setFloat(22, tuning.distortionAmount);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _AmbientShaderPainter oldDelegate) {
    return oldDelegate.program != program ||
        oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity ||
        oldDelegate.tuning != tuning;
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
