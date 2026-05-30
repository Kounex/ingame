import 'package:cue/cue.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum UserStatus { ready, online, away, offline }

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 12,
    this.showPulse = true,
  });

  final UserStatus status;
  final double size;
  final bool showPulse;

  Color get _color => switch (status) {
    UserStatus.ready => AppColors.success,
    UserStatus.online => AppColors.success,
    UserStatus.away => AppColors.warning,
    UserStatus.offline => AppColors.textTertiary,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 4,
      height: size + 4,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (status == UserStatus.ready && showPulse)
            _ReadyPulseRing(size: size, color: _color),
          _StatusDot(status: status, size: size, color: _color),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.status,
    required this.size,
    required this.color,
  });

  final UserStatus status;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: AppColors.background, width: 2),
        boxShadow: status == UserStatus.ready
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }
}

class _ReadyPulseRing extends StatelessWidget {
  const _ReadyPulseRing({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxScale = (size + 6) / size;

    return Cue.onMount(
      debugLabel: 'StatusIndicatorPulse',
      motion: .easeInOut(1500.ms),
      repeat: true,
      reverseOnRepeat: false,
      child: Actor(
        acts: [
          ScaleAct.keyframed(
            frames: .fractional([
              const .key(1.0, at: 0.0),
              .key(maxScale, at: 0.5),
              const .key(1.0, at: 1.0),
            ]),
          ),
          const OpacityAct.keyframed(
            frames: .fractional([
              .key(1.0, at: 0.0),
              .key(0.0, at: 0.5),
              .key(1.0, at: 1.0),
            ]),
          ),
        ],
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
