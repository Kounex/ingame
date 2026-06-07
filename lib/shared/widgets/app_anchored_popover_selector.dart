import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../services/app_haptics.dart';
import 'tappable.dart';

const _menuItemAnimationDuration = Duration(milliseconds: 220);
const _menuItemAnimationCurve = Curves.easeOutCubic;

class AppAnchoredPopoverOption<T> {
  const AppAnchoredPopoverOption({
    required this.value,
    required this.label,
    this.key,
    this.enabled = true,
  });

  final T value;
  final String label;
  final Key? key;
  final bool enabled;
}

typedef AppAnchoredPopoverTriggerBuilder =
    Widget Function(
      BuildContext context,
      VoidCallback togglePopover,
      bool isOpen,
    );

typedef AppAnchoredPopoverItemBuilder<T> =
    Widget Function(
      BuildContext context,
      AppAnchoredPopoverOption<T> option,
      bool selected,
    );

class AppAnchoredPopoverMenuItem extends StatelessWidget {
  const AppAnchoredPopoverMenuItem({
    super.key,
    required this.label,
    required this.selected,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _menuItemAnimationDuration,
      curve: _menuItemAnimationCurve,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.28)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (selected)
            const Icon(Icons.check_rounded, color: AppColors.primary, size: 18),
        ],
      ),
    );
  }
}

class AppAnchoredPopoverSelector<T> extends ConsumerStatefulWidget {
  const AppAnchoredPopoverSelector({
    super.key,
    required this.value,
    required this.options,
    required this.onSelected,
    required this.triggerBuilder,
    this.tooltip,
    this.panelKey,
    this.itemBuilder,
    this.maxHeightFactor = 1 / 3,
    this.itemExtent = 52,
    this.matchTriggerWidth = true,
    this.minPanelWidth = 0,
    this.verticalGap = AppSpacing.sm,
  });

  final T value;
  final List<AppAnchoredPopoverOption<T>> options;
  final ValueChanged<T> onSelected;
  final AppAnchoredPopoverTriggerBuilder triggerBuilder;
  final String? tooltip;
  final Key? panelKey;
  final AppAnchoredPopoverItemBuilder<T>? itemBuilder;
  final double maxHeightFactor;
  final double itemExtent;
  final bool matchTriggerWidth;
  final double minPanelWidth;
  final double verticalGap;

  @override
  ConsumerState<AppAnchoredPopoverSelector<T>> createState() =>
      _AppAnchoredPopoverSelectorState<T>();
}

class _AppAnchoredPopoverSelectorState<T>
    extends ConsumerState<AppAnchoredPopoverSelector<T>> {
  late final MenuController _menuController;
  late final ScrollController _scrollController;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _menuController = MenuController();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _togglePopover() {
    if (_isOpen) {
      _menuController.close();
      return;
    }
    ref.read(appHapticsProvider).selection();
    _menuController.open();
  }

  void _handleOpen() {
    setState(() => _isOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToSelected());
  }

  void _handleClose() {
    if (!mounted) return;
    setState(() => _isOpen = false);
  }

  void _jumpToSelected() {
    if (!_scrollController.hasClients) return;
    final selectedIndex = widget.options.indexWhere(
      (option) => option.value == widget.value,
    );
    if (selectedIndex < 0) return;
    final offset = selectedIndex * widget.itemExtent;
    final clampedOffset = math.min(
      offset,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(clampedOffset);
  }

  void _selectOption(AppAnchoredPopoverOption<T> option) {
    if (!option.enabled) return;
    ref.read(appHapticsProvider).selection();
    widget.onSelected(option.value);
    _menuController.close();
  }

  @override
  Widget build(BuildContext context) {
    final trigger = widget.triggerBuilder(context, _togglePopover, _isOpen);

    return RawMenuAnchor(
      controller: _menuController,
      consumeOutsideTaps: true,
      onOpen: _handleOpen,
      onClose: _handleClose,
      builder: (context, controller, child) {
        if (widget.tooltip == null || widget.tooltip!.isEmpty) {
          return child!;
        }
        return Tooltip(message: widget.tooltip!, child: child!);
      },
      child: trigger,
      overlayBuilder: (context, info) => _PopoverPanel<T>(
        panelKey: widget.panelKey,
        value: widget.value,
        options: widget.options,
        scrollController: _scrollController,
        itemBuilder: widget.itemBuilder,
        itemExtent: widget.itemExtent,
        maxHeightFactor: widget.maxHeightFactor,
        matchTriggerWidth: widget.matchTriggerWidth,
        minPanelWidth: widget.minPanelWidth,
        verticalGap: widget.verticalGap,
        onSelected: _selectOption,
        onClose: _menuController.close,
        info: info,
      ),
    );
  }
}

class _PopoverPanel<T> extends StatelessWidget {
  const _PopoverPanel({
    required this.value,
    required this.options,
    required this.scrollController,
    required this.itemBuilder,
    required this.itemExtent,
    required this.maxHeightFactor,
    required this.matchTriggerWidth,
    required this.minPanelWidth,
    required this.verticalGap,
    required this.onSelected,
    required this.onClose,
    required this.info,
    this.panelKey,
  });

  final T value;
  final List<AppAnchoredPopoverOption<T>> options;
  final ScrollController scrollController;
  final AppAnchoredPopoverItemBuilder<T>? itemBuilder;
  final double itemExtent;
  final double maxHeightFactor;
  final bool matchTriggerWidth;
  final double minPanelWidth;
  final double verticalGap;
  final ValueChanged<AppAnchoredPopoverOption<T>> onSelected;
  final VoidCallback onClose;
  final RawMenuOverlayInfo info;
  final Key? panelKey;

  @override
  Widget build(BuildContext context) {
    const screenPadding = AppSpacing.sm;
    final mediaPadding = MediaQuery.paddingOf(context);
    final maxPanelHeight = info.overlaySize.height * maxHeightFactor;
    final idealHeight = options.length * itemExtent;

    final belowTop = info.anchorRect.bottom + verticalGap;
    final aboveBottom = info.anchorRect.top - verticalGap;
    final availableBelow =
        info.overlaySize.height -
        belowTop -
        mediaPadding.bottom -
        screenPadding;
    final availableAbove = aboveBottom - mediaPadding.top - screenPadding;
    final desiredHeight = math.min(idealHeight, maxPanelHeight);
    final openBelow =
        availableBelow >= desiredHeight || availableBelow >= availableAbove;
    final availableHeight = math.max(
      0.0,
      openBelow ? availableBelow : availableAbove,
    );
    final panelHeight = math.min(desiredHeight, availableHeight);
    final isScrollable = idealHeight > panelHeight;

    final maxWidth =
        info.overlaySize.width -
        mediaPadding.left -
        mediaPadding.right -
        (screenPadding * 2);
    final double panelWidth = matchTriggerWidth
        ? math.min(info.anchorRect.width, maxWidth)
        : math.min(math.max(info.anchorRect.width, minPanelWidth), maxWidth);

    final left = _clampHorizontalOffset(
      preferredLeft: info.anchorRect.left,
      panelWidth: panelWidth,
      overlayWidth: info.overlaySize.width,
      mediaPadding: mediaPadding,
      screenPadding: screenPadding,
    );
    final top = openBelow
        ? belowTop
        : info.anchorRect.top - verticalGap - panelHeight;

    final listView = ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      shrinkWrap: true,
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final selected = option.value == value;
        final child =
            itemBuilder?.call(context, option, selected) ??
            AppAnchoredPopoverMenuItem(label: option.label, selected: selected);

        return Tappable(
          key: option.key,
          onTap: option.enabled ? () => onSelected(option) : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: itemExtent),
            child: child,
          ),
        );
      },
    );

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: panelWidth,
          child: TapRegion(
            groupId: info.tapRegionGroupId,
            onTapOutside: (_) => onClose(),
            child: Material(
              key: panelKey,
              color: AppColors.backgroundLight,
              elevation: 8,
              borderRadius: BorderRadius.circular(18),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: panelHeight,
                  minWidth: panelWidth,
                  maxWidth: panelWidth,
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    hoverColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    focusColor: Colors.transparent,
                    splashFactory: NoSplash.splashFactory,
                  ),
                  child: isScrollable
                      ? Scrollbar(
                          controller: scrollController,
                          thumbVisibility: true,
                          child: listView,
                        )
                      : listView,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _clampHorizontalOffset({
    required double preferredLeft,
    required double panelWidth,
    required double overlayWidth,
    required EdgeInsets mediaPadding,
    required double screenPadding,
  }) {
    final minLeft = mediaPadding.left + screenPadding;
    final maxLeft =
        overlayWidth - mediaPadding.right - screenPadding - panelWidth;
    return preferredLeft.clamp(minLeft, maxLeft);
  }
}
