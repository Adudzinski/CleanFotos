import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/strings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s = AppStrings.of(provider.languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Stats Card ────────────────────────────────────────────────────
          _sectionHeader(s.statistics),
          _statsCard(context, provider, s),

          const SizedBox(height: 24),

          // ── Language ─────────────────────────────────────────────────────
          _sectionHeader(s.language),
          _languageCard(context, provider, s),

          const SizedBox(height: 24),

          // ── Monetization / Ads ───────────────────────────────────────────
          _sectionHeader(s.monetization),
          _adsCard(context, provider, s),

          const SizedBox(height: 24),

          // ── About ─────────────────────────────────────────────────────────
          _sectionHeader(s.about),
          _aboutCard(context, s),
        ],
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _statsCard(
      BuildContext context, AppProvider provider, AppStrings s) {
    final stats = provider.stats;
    return _card(
      child: Column(
        children: [
          _statRow(
            context,
            icon: Icons.photo_library_outlined,
            label: s.totalPhotos,
            value: '${stats.totalPhotos}',
            color: AppTheme.primary,
          ),
          _divider(),
          _statRow(
            context,
            icon: Icons.storage_outlined,
            label: s.librarySize,
            value: stats.totalSizeFormatted,
            color: const Color(0xFF43A8D0),
          ),
          _divider(),
          _statRow(
            context,
            icon: Icons.content_copy_outlined,
            label: s.similarGroups,
            value: '${stats.duplicateGroups}',
            color: AppTheme.secondary,
          ),
          _divider(),
          _statRow(
            context,
            icon: Icons.savings_outlined,
            label: s.couldSave,
            value: stats.savingsFormatted,
            color: AppTheme.success,
          ),
          _divider(),
          _statRow(
            context,
            icon: Icons.delete_forever_outlined,
            label: s.freedSpace,
            value: provider.freedFormatted,
            color: AppTheme.success,
          ),
          _divider(),
          _statRow(
            context,
            icon: Icons.check_circle_outline,
            label: s.deletedPhotos,
            value: '${provider.deletedCount}',
            color: AppTheme.success,
          ),
        ],
      ),
    );
  }

  Widget _languageCard(
      BuildContext context, AppProvider provider, AppStrings s) {
    final languages = [
      {'code': 'en', 'name': '🇬🇧 English'},
      {'code': 'es', 'name': '🇪🇸 Español'},
      {'code': 'de', 'name': '🇩🇪 Deutsch'},
      {'code': 'fr', 'name': '🇫🇷 Français'},
      {'code': 'pt', 'name': '🇧🇷 Português'},
      {'code': 'it', 'name': '🇮🇹 Italiano'},
    ];

    return _card(
      child: Column(
        children: languages.map((lang) {
          final selected = provider.languageCode == lang['code'];
          return InkWell(
            onTap: () => provider.setLanguage(lang['code']!),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Row(
                children: [
                  Text(lang['name']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                      )),
                  const Spacer(),
                  if (selected)
                    const Icon(Icons.check_circle,
                        color: AppTheme.primary, size: 22),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _adsCard(
      BuildContext context, AppProvider provider, AppStrings s) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.enableAds,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(s.adsDesc,
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: provider.showAds,
                onChanged: provider.setShowAds,
                activeColor: AppTheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Text(s.monetizationTips,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          _tipRow('📱', s.tip1),
          _tipRow('⭐', s.tip2),
          _tipRow('🌟', s.tip3),
          _tipRow('📊', s.tip4),
        ],
      ),
    );
  }

  Widget _tipRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _aboutCard(BuildContext context, AppStrings s) {
    return _card(
      child: Column(
        children: [
          _infoRow(s.appVersion, '1.0.0'),
          _divider(),
          _infoRow(s.buildWith, 'Flutter 3.x'),
          _divider(),
          _infoRow(s.developerTip, s.developerTipValue),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context,
      {required IconData icon,
      required String label,
      required String value,
      required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 14),
          Text(label,
              style: const TextStyle(
                  fontSize: 15, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 15, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, color: Color(0xFFF0F0F4));

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
