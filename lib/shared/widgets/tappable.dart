import 'package:flutter/material.dart';

/// Wraps [MouseRegion] + [GestureDetector] so every tappable surface
/// automatically shows a pointer cursor on desktop/web.
///
/// Use this instead of raw [GestureDetector] for any clickable widget.
/// When [onTap] is null the cursor stays default and the tap is ignored.
class Tappable extends StatelessWidget {
  const Tappable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.behavior = HitTestBehavior.opaque,
    this.cursor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final HitTestBehavior behavior;

  /// Override the hover cursor. Defaults to [SystemMouseCursors.click]
  /// when [onTap] or [onLongPress] is set, [SystemMouseCursors.basic] otherwise.
  final MouseCursor? cursor;

  @override
  Widget build(BuildContext context) {
    final isInteractive = onTap != null || onLongPress != null;

    return MouseRegion(
      cursor: cursor ?? (isInteractive ? SystemMouseCursors.click : SystemMouseCursors.basic),
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: behavior,
        child: child,
      ),
    );
  }
}
