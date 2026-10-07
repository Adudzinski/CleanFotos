import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/strings.dart';
import '../providers/app_provider.dart';
import '../services/ad_service.dart';
import '../services/feedback_service.dart';
import '../services/purchase_service.dart';
import '../services/review_service.dart';
import '../theme/noir.dart';
import '../utils/format.dart';
import '../widgets/noir/noir_widgets.dart';
import 'milestones_screen.dart';

// The website path moved from /cleanpics/ to /cleanfotos/. The old paths are
// still served (Firebase rewrite, HTTP 200) so already-installed builds keep
// working, but new builds must use the real path — Google Play's Data safety
// checker requires a direct 200 and does not follow redirects.
const String kPrivacyPolicyUrl =
    'https://crocodata.net/cleanfotos/privacy-policy.html';
const String kDeleteDataUrl = 'https://crocodata.net/cleanfotos/delete-data.html';
const String kTermsUrl = 'https://crocodata.net/cleanfotos/terms.html';
const String kContactEmail = 'contact@crocodata.net';

/// Shown under About. Keep in step with `version:` in pubspec.yaml
/// (package_info_plus isn't a dependency).
const String kAppVersion = '1.3.0';

/// Settings (REDESIGN_1.3_PLAN.md §5.7): Feedback, Progress, Language,
/// Remove ads, About.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final s = AppStrings.of(provider.languageCode);
    final lang = provider.languageCode;

    return Scaffold(
      backgroundColor: Noir.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            NoirHeader(
              leading: NoirIconButton(
                icon: Icons.chevron_left_rounded,
                semanticLabel: s.back,
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: s.settings,
            ),

            // ── Feedback ──────────────────────────────────────────────────
            _Section(s.feedback),
            NoirCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _SwitchRow(
                    label: s.sounds,
                    value: provider.soundsEnabled,
                    onChanged: (v) {
                      provider.setSoundsEnabled(v);
                      FeedbackService.instance.play(Fx.tap);
                    },
                  ),
                  const _Divider(),
                  _SwitchRow(
                    label: s.haptics,
                    value: provider.hapticsEnabled,
                    onChanged: (v) {
                      provider.setHapticsEnabled(v);
                      FeedbackService.instance.play(Fx.tap);
                    },
                  ),
                ],
              ),
            ),

            // ── Progress ──────────────────────────────────────────────────
            _Section(s.progress),
            NoirCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _Row(
                    label: s.milestones,
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Noir.muted),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MilestonesScreen()),
                    ),
                  ),
                  const _Divider(),
                  _Row(
                    label: s.freedSpace,
                    value: formatBytes(provider.freedBytes, lang),
                  ),
                  const _Divider(),
                  _Row(
                    label: s.deletedPhotos,
                    value: formatCount(provider.deletedCount, lang),
                  ),
                ],
              ),
            ),

            // ── Language ──────────────────────────────────────────────────
            _Section(s.language),
            _languageCard(provider),

            // ── Remove ads ────────────────────────────────────────────────
            _Section(s.removeAds),
            _proCard(context, provider, s),

            // ── About ─────────────────────────────────────────────────────
            _Section(s.about),
            NoirCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                children: [
                  _Row(
                    label: s.rateApp,
                    trailing: const Icon(Icons.star_outline_rounded,
                        size: 20, color: Noir.muted),
                    onTap: () => ReviewService.instance.openStoreListing(),
                  ),
                  const _Divider(),
                  _Row(
                    label: s.privacyPolicy,
                    trailing: const Icon(Icons.open_in_new_rounded,
                        size: 18, color: Noir.muted),
                    onTap: _openPrivacyPolicy,
                  ),
                  // Always offered to non-Pro users so EEA users can change
                  // consent even if UMP hasn't flagged the form as required.
                  if (!provider.isPro) ...[
                    const _Divider(),
                    _Row(
                      label: s.privacyOptions,
                      trailing: const Icon(Icons.tune_rounded,
                          size: 18, color: Noir.muted),
                      onTap: () =>
                          AdService.instance.showPrivacyOptionsForm(),
                    ),
                  ],
                  const _Divider(),
                  _Row(label: s.appVersion, value: kAppVersion),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageCard(AppProvider provider) {
    const languages = [
      ('en', 'English'),
      ('es', 'Español'),
      ('de', 'Deutsch'),
      ('fr', 'Français'),
      ('pt', 'Português'),
      ('it', 'Italiano'),
      ('pl', 'Polski'),
    ];
    return NoirCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < languages.length; i++) ...[
            if (i > 0) const _Divider(),
            _Row(
              label: languages[i].$2,
              bold: provider.languageCode == languages[i].$1,
              trailing: provider.languageCode == languages[i].$1
                  ? const Icon(Icons.check_rounded,
                      size: 20, color: Noir.accent)
                  : null,
              onTap: () {
                FeedbackService.instance.play(Fx.tap);
                provider.setLanguage(languages[i].$1);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _proCard(BuildContext context, AppProvider provider, AppStrings s) {
    if (provider.isPro) {
      return NoirCard(
        child: Row(
          children: [
            const Icon(Icons.workspace_premium_outlined,
                color: Noir.text, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(s.proUnlocked,
                  style: NoirText.body.copyWith(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    final purchase = PurchaseService.instance;
    return NoirCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.proTitle, style: NoirText.h2),
          const SizedBox(height: 6),
          Text(s.proDesc, style: NoirText.secondary),
          const SizedBox(height: 16),
          NoirButton.primary(
            // Google/Apple return the price already localized; show
            // "Remove Ads" (no price) until it loads.
            label: purchase.price != null
                ? s.proButton(purchase.price!)
                : s.proButtonNoPrice,
            // Never disabled: a dead button looks broken (and App Review
            // flagged exactly that). If the product hasn't loaded we
            // re-query on tap, then explain if it's still unavailable.
            onPressed: () async {
              if (purchase.isAvailable) {
                await purchase.buyPro();
                return;
              }
              final ready = await purchase.refreshProduct();
              if (!context.mounted) return;
              if (ready) {
                await purchase.buyPro();
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(s.proUnavailable)),
              );
            },
          ),
          const SizedBox(height: 4),
          // Always offer Restore — Apple requires a restore path for
          // non-consumable purchases, and hiding it fails review.
          NoirButton.ghost(
            label: s.restorePurchase,
            height: 44,
            textStyle: NoirText.meta,
            onPressed: () => purchase.restore(),
          ),
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
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 4, 10),
      child: Semantics(
        header: true,
        child: Text(text.toUpperCase(), style: NoirText.label),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 1, color: Color(0x0FFFFFFF));
}

class _Row extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool bold;

  const _Row({
    required this.label,
    this.value,
    this.trailing,
    this.onTap,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(label,
                    style: NoirText.body.copyWith(
                        fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
              ),
              if (value != null) ...[
                const SizedBox(width: 12),
                Text(value!,
                    style: NoirText.body.copyWith(color: Noir.muted)),
              ],
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            Expanded(child: Text(label, style: NoirText.body)),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
