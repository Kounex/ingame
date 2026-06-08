import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/glass_components.dart';
import '../../core/theme/spacing.dart';
import 'provider_visuals.dart';

class SocialIdentityCardEntry {
  const SocialIdentityCardEntry({
    required this.provider,
    required this.label,
    required this.subtitle,
    required this.connected,
    this.subtitleColor,
    this.trailing,
    this.onTap,
  });

  final String provider;
  final String label;
  final String subtitle;
  final bool connected;
  final Color? subtitleColor;
  final Widget? trailing;
  final VoidCallback? onTap;
}

class SocialIdentitiesCard extends StatelessWidget {
  const SocialIdentitiesCard({
    super.key,
    required this.entries,
    this.title,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final List<SocialIdentityCardEntry> entries;
  final String? title;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            _SocialCardSectionHeader(title: title!),
            const SizedBox(height: AppSpacing.md),
          ],
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _SocialIdentityRow(entry: entries[i]),
          ],
        ],
      ),
    );
  }
}

class _SocialCardSectionHeader extends StatelessWidget {
  const _SocialCardSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: AppColors.textTertiary.withValues(alpha: 0.8),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SocialIdentityRow extends StatelessWidget {
  const _SocialIdentityRow({required this.entry});

  final SocialIdentityCardEntry entry;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: entry.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ProviderVisuals.rowIconBackground(
                  entry.provider,
                  connected: entry.connected,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                ProviderVisuals.forProvider(entry.provider).icon,
                color: ProviderVisuals.rowIconColor(
                  entry.provider,
                  connected: entry.connected,
                ),
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.subtitle,
                    style: TextStyle(
                      color:
                          entry.subtitleColor ??
                          (entry.connected
                              ? AppColors.textSecondary
                              : AppColors.textTertiary),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (entry.trailing != null)
              entry.trailing!
            else if (entry.onTap != null)
              Icon(
                Icons.chevron_right,
                color: AppColors.textTertiary.withValues(alpha: 0.5),
                size: 20,
              )
            else if (entry.connected)
              const Icon(Icons.check_circle, color: AppColors.success, size: 20)
            else
              const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
