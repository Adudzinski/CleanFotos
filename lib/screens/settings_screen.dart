import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../services/ad_service.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';
import '../l10n/strings.dart';

const String kPrivacyPolicyUrl =
    'https://crocodata.net/cleanpics/privacy-policy.html';

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
          _proCard(context, provider, s),

          const SizedBox(height: 24),

          // ── Reminders ─────────────────────────────────────────────────────
          _sectionHeader(s.reminders),
          _reminderCard(context, provider, s),

          const SizedBox(height: 24),

          // ── About ─────────────────────────────────────────────────────────
          _sectionHeader(s.about),
          _aboutCard(context, provider, s),
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
          fontSize: 16,
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
                        fontSize: 18,
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

  Widget _proCard(
      BuildContext context, AppProvider provider, AppStrings s) {
    // Already unlocked
    if (provider.isPro) {
      return _card(
        child: Row(
          children: [
            const Icon(Icons.workspace_premium,
                color: AppTheme.success, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Text(s.proUnlocked,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary)),
            ),
          ],
        ),
      );
    }

    final purchase = PurchaseService.instance;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium,
                  color: AppTheme.primary, size: 26),
              const SizedBox(width: 12),
              Text(s.proTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(s.proDesc,
              style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  height: 1.4)),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: purchase.isAvailable ? () => purchase.buyPro() : null,
            icon: const Icon(Icons.block, size: 20),
            // Google returns the price already localized to the user's currency;
            // show "Remove Ads" (no price) until it loads.
            label: Text(purchase.price != null
                ? s.proButton(purchase.price!)
                : s.proButtonNoPrice),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
          if (purchase.isAvailable)
            Center(
              child: TextButton(
                onPressed: () => purchase.restore(),
                child: Text(s.restorePurchase,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _reminderCard(
      BuildContext context, AppProvider provider, AppStrings s) {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.monthlyReminder,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(s.monthlyReminderDesc,
                    style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                        height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: provider.remindersEnabled,
            onChanged: provider.setReminders,
            activeColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _aboutCard(
      BuildContext context, AppProvider provider, AppStrings s) {
    // The "Ad privacy options" entry is only meaningful for non-Pro users in
    // regions (EEA/UK) where Google's consent platform requires it.
    final showPrivacyOptions =
        !provider.isPro && AdService.instance.isPrivacyOptionsRequired;

    return _card(
      child: Column(
        children: [
          _infoRow(s.appVersion, '1.0.0'),
          _divider(),
          InkWell(
            onTap: _openPrivacyPolicy,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Text(s.privacyPolicy,
                      style: const TextStyle(
                          fontSize: 17, color: AppTheme.textSecondary)),
                  const Spacer(),
                  const Icon(Icons.open_in_new,
                      size: 20, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
          if (showPrivacyOptions) ...[
            _divider(),
            InkWell(
              onTap: () => AdService.instance.showPrivacyOptionsForm(),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Text(s.privacyOptions,
                        style: const TextStyle(
                            fontSize: 17, color: AppTheme.textSecondary)),
                    const Spacer(),
                    const Icon(Icons.tune,
                        size: 20, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(kPrivacyPolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
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
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 17, color: AppTheme.textSecondary)),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
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
                  fontSize: 17, color: AppTheme.textSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600)),
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
