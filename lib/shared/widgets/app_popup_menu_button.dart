import 'package:flutter/material.dart';

class AppPopupMenuButton<T> extends StatelessWidget {
  const AppPopupMenuButton({
    super.key,
    required this.itemBuilder,
    this.initialValue,
    this.onOpened,
    this.onSelected,
    this.onCanceled,
    this.tooltip,
    this.elevation,
    this.padding = const EdgeInsets.all(8),
    this.menuPadding,
    this.child,
    this.icon,
    this.iconSize,
    this.offset = Offset.zero,
    this.enabled = true,
    this.shape,
    this.color,
    this.position,
    this.clipBehavior = Clip.none,
    this.borderRadius,
    this.splashRadius,
    this.constraints,
    this.enableFeedback,
    this.popUpAnimationStyle,
    this.routeSettings,
    this.style,
  }) : assert(
         child != null || icon != null,
         'Provide either an icon or a child for AppPopupMenuButton.',
       );

  final PopupMenuItemBuilder<T> itemBuilder;
  final T? initialValue;
  final VoidCallback? onOpened;
  final PopupMenuItemSelected<T>? onSelected;
  final PopupMenuCanceled? onCanceled;
  final String? tooltip;
  final double? elevation;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? menuPadding;
  final Widget? child;
  final Widget? icon;
  final double? iconSize;
  final Offset offset;
  final bool enabled;
  final ShapeBorder? shape;
  final Color? color;
  final PopupMenuPosition? position;
  final Clip clipBehavior;
  final BorderRadius? borderRadius;
  final double? splashRadius;
  final BoxConstraints? constraints;
  final bool? enableFeedback;
  final AnimationStyle? popUpAnimationStyle;
  final RouteSettings? routeSettings;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transparentInkTheme = theme.copyWith(
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
    );

    return Theme(
      data: transparentInkTheme,
      child: PopupMenuButton<T>(
        itemBuilder: itemBuilder,
        initialValue: initialValue,
        onOpened: onOpened,
        onSelected: onSelected,
        onCanceled: onCanceled,
        tooltip: tooltip,
        elevation: elevation,
        padding: padding,
        menuPadding: menuPadding,
        icon: icon,
        iconSize: iconSize,
        offset: offset,
        enabled: enabled,
        shape: shape,
        color: color,
        position: position,
        clipBehavior: clipBehavior,
        borderRadius: borderRadius,
        splashRadius: splashRadius,
        constraints: constraints,
        enableFeedback: enableFeedback,
        popUpAnimationStyle: popUpAnimationStyle,
        routeSettings: routeSettings,
        style: style,
        child: child,
      ),
    );
  }
}
