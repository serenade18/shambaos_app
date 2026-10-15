import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger.dart';
import '../../widgets/phosphor_icons.dart';
import 'field_detail_screen.dart';
import 'field_service.dart';
import 'field_widgets.dart';
import 'photo_check.dart';

/// What the AI saw in the farmer's photo: how worried to be, what it found, and
/// what to do. "Scan again" goes back to the camera.
class ScanResultScreen extends StatelessWidget {
  final Field field;
  final Uint8List photo;
  final PhotoCheck check;

  const ScanResultScreen({super.key, required this.field, required this.photo, required this.check});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final heroH = MediaQuery.sizeOf(context).height * 0.38;
    final (Color fg, Color bg, IconData icon, String headline) = switch (check.condition) {
      'healthy' => (c.goodInk, c.goodTint, PhosphorIconsFill.checkCircle, 'Looks healthy'),
      'act_now' => (c.dangerInk, c.dangerTint, PhosphorIconsFill.warning, 'Act this week'),
      'watch' => (c.warnInk, c.warnTint, PhosphorIconsFill.eye, 'Keep an eye on it'),
      _ => (c.rainInk, c.rainTint, PhosphorIconsFill.question, 'Photo not clear enough'),
    };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.cardBackground,
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  SizedBox(
                    height: heroH,
                    width: double.infinity,
                    child: Image.memory(photo, fit: BoxFit.cover, gaplessPlayback: true),
                  ),
                  Positioned(left: 16, top: MediaQuery.paddingOf(context).top + 8, child: const PhotoBackButton()),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              sliver: SliverList.list(children: [
                // The verdict.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 26, color: fg),
                          const SizedBox(width: 10),
                          Expanded(child: Text(headline, style: AppType.titleM.copyWith(color: fg))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(check.summary, style: AppType.bodyL.copyWith(color: c.textPrimary)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          FieldChip(check.subject, bg: c.cardBackground),
                          FieldChip('${_cap(check.confidence)} confidence', bg: c.cardBackground, fg: c.textSecondary),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!check.matchesField) ...[
                  const SizedBox(height: 12),
                  SlLedger(children: [
                    SlLedgerRow(
                      leading: Icon(PhosphorIconsRegular.info, color: c.warnInk),
                      title: "This doesn't look like ${field.name}",
                      meta: 'Check you chose the right field, or take a closer photo.',
                    ),
                  ]),
                ],
                if (check.findings.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('What the AI found', style: AppType.titleM.copyWith(color: c.textPrimary)),
                  const SizedBox(height: 10),
                  SlLedger(children: [
                    for (final f in check.findings)
                      SlLedgerRow(
                        title: f.title,
                        meta: f.detail,
                        status: switch (f.severity) {
                          'good' => const SlStatusTag('Good', status: SlStatus.good),
                          'act' => const SlStatusTag('Act now', status: SlStatus.danger),
                          _ => const SlStatusTag('Watch', status: SlStatus.warn),
                        },
                      ),
                  ]),
                ],
                if (check.actions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('What to do', style: AppType.titleM.copyWith(color: c.textPrimary)),
                  const SizedBox(height: 10),
                  // Steps are in order: the most urgent first.
                  for (var i = 0; i < check.actions.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
                            child: Text('${i + 1}', style: AppType.label.copyWith(color: c.brandText)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Text(check.actions[i], style: AppType.bodyL.copyWith(color: c.textPrimary)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                Text(
                  'AI can be wrong. For a sick animal, or anything spreading fast, call your vet or the county agriculture office.',
                  style: AppType.caption.copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(PhosphorIconsRegular.camera, size: 20),
                    label: const Text('Scan again'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => FieldDetailScreen(field: field)),
                    ),
                    child: Text('Open ${field.name}'),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  static String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
