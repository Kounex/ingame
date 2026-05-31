import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/spacing.dart';
import '../../core/utils/extensions.dart';
import 'glass_bottom_nav.dart';
import 'ingame_logo.dart';
import 'tappable.dart';

class AdaptiveShell extends StatelessWidget {
  const AdaptiveShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useWideLayout = constraints.maxWidth >= AppBreakpoints.sidebar;

        if (useWideLayout) {
          return Scaffold(
            body: Row(
              children: [
                _GlassSidebar(
                  currentIndex: navigationShell.currentIndex,
                  onDestinationSelected: _onDestinationSelected,
                ),
                Expanded(child: navigationShell),
              ],
            ),
          );
        }

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: GlassBottomNav(
            currentIndex: navigationShell.currentIndex,
            onTap: _onDestinationSelected,
          ),
        );
      },
    );
  }
}

class _GlassSidebar extends StatelessWidget {
  const _GlassSidebar({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  static const double width = 220;

  final int currentIndex;
  final void Function(int) onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final destinations = [
      _SidebarDestination(
        icon: Icons.groups_outlined,
        activeIcon: Icons.groups,
        label: l10n.navigationGroups,
      ),
      _SidebarDestination(
        icon: Icons.explore_outlined,
        activeIcon: Icons.explore,
        label: l10n.navigationDiscover,
      ),
      _SidebarDestination(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: l10n.navigationProfile,
      ),
    ];
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          decoration: const BoxDecoration(
            color: Color(0x1A0A0E1A),
            border: Border(
              right: BorderSide(color: AppColors.glassBorder),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SidebarHeader(),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    itemCount: destinations.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (context, index) {
                      final dest = destinations[index];
                      final isSelected = index == currentIndex;

                      return _SidebarItem(
                        icon: isSelected ? dest.activeIcon : dest.icon,
                        label: dest.label,
                        isSelected: isSelected,
                        onTap: () => onDestinationSelected(index),
                      );
                    },
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

class _SidebarHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        0,
      ),
      child: InGameLogo(),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tappable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: TextStyle(
                color:
                    isSelected ? AppColors.primary : AppColors.textTertiary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarDestination {
  const _SidebarDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
