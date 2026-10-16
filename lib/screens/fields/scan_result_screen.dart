import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger.dart';
import '../../widgets/ledger_parts.dart';
import '../auth/auth_ui.dart';
import '../tulip/tulip_chat_screen.dart';
import 'field_detail_screen.dart';
import 'field_service.dart';
import 'photo_check.dart';
import '../../l10n/tr.dart';

/// What the AI saw in the farmer's photo, as the design's "What the AI found":
/// the photo, a card with how worried to be and what it saw, what it found and
/// what to do, the reminder that AI can be wrong, then Scan again or Ask Tulip.
class ScanResultScreen extends StatelessWidget {
  final Field field;
  final Uint8List photo;
  final PhotoCheck check;

  const ScanResultScreen({super.key, required this.field, required this.photo, required this.check});

  static const _alert = '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/>';
  static const _info = '<circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/>';
  static const _eye = '<path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0"/><circle cx="12" cy="12" r="3"/>';
  static const _chat = '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/>';

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    // How worried to be: the tag, its colour and the card's heading.
    final (String tag, SlTone tone, String? icon, String headline) = switch (check.condition) {
      'healthy' => ('Looks healthy'.tr, SlTone.good, SlTag.check, 'Looks healthy'.tr),
      'act_now' => ('Act this week'.tr, SlTone.danger, _alert, 'Act this week'.tr),
      'watch' => ('Watch'.tr, SlTone.warn, _eye, 'Keep an eye on it'.tr),
      _ => ('Not sure'.tr, SlTone.info, _info, 'Photo not clear enough'.tr),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.scaffoldBackground,
        body: Stack(children: [
          CustomScrollView(
            slivers: [
              // The photo, rounded at the foot, with a frosted back button.
              // The verdict card overlaps the photo's foot by 40.
              SliverToBoxAdapter(
                child: Stack(children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                    child: SizedBox(
                      height: 230 + top,
                      width: double.infinity,
                      child: Stack(fit: StackFit.expand, children: [
                        Semantics(
                          image: true,
                          label: 'Your photo'.tr,
                          child: Image.memory(photo, fit: BoxFit.cover, gaplessPlayback: true),
                        ),
                        Positioned(left: 16, top: top + 20, child: _backButton(context, c)),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 230 + top - 40, 16, 0),
                    child: SlCard(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                            child: Text('{name} · TODAY'.trArgs({'name': field.name.toUpperCase()}),
                                maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.eyebrow.copyWith(color: c.textSecondary)),
                          ),
                          const SizedBox(width: 8),
                          SlTag(tag, tone: tone, icon: icon),
                        ]),
                        const SizedBox(height: 10),
                        Text(headline,
                            style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
                        if (check.summary.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(check.summary, style: AppType.bodyL.copyWith(color: c.textPrimary)),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          [if (check.subject.isNotEmpty) check.subject, '{level} confidence'.trArgs({'level': _confidence(check.confidence)})].join(' · '),
                          style: AppType.caption.copyWith(color: c.textSecondary),
                        ),
                      ]),
                    ),
                  ),
                ]),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 104 + bottom),
                sliver: SliverList.list(children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      if (!check.matchesField) ...[
                        _note(c, c.warnTint, c.warnInk, _alert,
                            "This doesn't look like {name}".trArgs({'name': field.name}) +
                                '. ' +
                                'Check you chose the right field, or take a closer photo.'.tr),
                        const SizedBox(height: 12),
                      ],
                      if (check.findings.isNotEmpty) ...[
                        SlLedger(title: 'What the AI found'.tr, children: [
                          for (final f in check.findings)
                            SlLedgerRow(
                              title: f.title,
                              meta: f.detail,
                              status: switch (f.severity) {
                                'good' => SlTag('Good'.tr, tone: SlTone.good),
                                'act' => SlTag('Act now'.tr, tone: SlTone.danger),
                                _ => SlTag('Watch'.tr, tone: SlTone.warn),
                              },
                            ),
                        ]),
                        const SizedBox(height: 12),
                      ],
                      if (check.actions.isNotEmpty) ...[
                        // Steps in order, the most urgent first.
                        SlLedger(title: 'What to do'.tr, children: [
                          for (final a in check.actions) SlLedgerRow(title: a),
                        ]),
                        const SizedBox(height: 12),
                      ],
                      _note(c, c.rainTint, c.rainInk, _info,
                          'AI can be wrong. For a sick animal, or anything spreading fast, call your vet or the county agriculture office.'.tr),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FieldDetailScreen(field: field))),
                          child: Text('Open {name}'.trArgs({'name': field.name}),
                              style: TextStyle(fontFamily: AppType.text, fontSize: 14, fontWeight: FontWeight.w700, color: c.brandText)),
                        ),
                      ),
                    ]),
                  ),
                ]),
              ),
            ],
          ),
          // Scan again, or ask Tulip about it.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 24 + bottom),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.3],
                  colors: [c.scaffoldBackground.withValues(alpha: 0), c.scaffoldBackground],
                ),
              ),
              child: Row(children: [
                Expanded(
                  child: LedgerButton(
                    label: 'Scan again'.tr,
                    kind: LedgerButtonKind.secondary,
                    large: false,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LedgerButton(
                    label: 'Ask Tulip'.tr,
                    large: false,
                    icon: const LineIcon(_chat, size: 20, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TulipChatScreen(draft: _question())),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  /// A question for Tulip about this photo, for the farmer to send or change.
  String _question() => 'About my {name}: {summary} What should I do?'.trArgs({
        'name': field.name,
        'summary': check.summary.trim().isEmpty ? '' : check.summary.trim(),
      });

  Widget _backButton(BuildContext context, AppColors c) => Semantics(
        button: true,
        label: 'Back'.tr,
        excludeSemantics: true,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Material(
              color: c.cardBackground.withValues(alpha: 0.86),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(child: LineIcon('<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>', size: 22, color: c.textPrimary)),
                ),
              ),
            ),
          ),
        ),
      );

  /// A tinted note with an icon: the AI warning, or a mismatch.
  static Widget _note(AppColors c, Color bg, Color ink, String icon, String text) => Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(24)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          LineIcon(icon, size: 20, color: ink),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppType.caption.copyWith(color: c.textPrimary))),
        ]),
      );

  static String _confidence(String level) => switch (level) {
        'high' => 'High'.tr,
        'medium' => 'Medium'.tr,
        _ => 'Low'.tr,
      };
}
