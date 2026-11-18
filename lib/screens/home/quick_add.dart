import 'package:flutter/material.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger_parts.dart';
import '../auth/auth_ui.dart';
import '../farm/add_to_farm.dart';
import '../farm/setup_farm_screen.dart';
import '../fields/field_service.dart';
import '../fields/field_widgets.dart';
import '../records/record_form.dart';
import '../records/record_menu.dart';
import '../../l10n/tr.dart';

/// Home's three big doors: Add animals, Add a crop, Record today. Each goes
/// straight to its form, a tap or two away; with no farm yet, they set one up first.
class QuickAdd extends StatelessWidget {
  final Map<String, dynamic>? farm;
  final List<Field> fields;
  final VoidCallback onChanged; // something was added or recorded: Home reloads
  const QuickAdd({super.key, required this.farm, required this.fields, required this.onChanged});

  static const _notepad =
      '<path d="M13.4 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-7.4"/><path d="M2 6h4"/><path d="M2 10h4"/><path d="M2 14h4"/><path d="M2 18h4"/><path d="M21.378 5.626a1 1 0 1 0-3.004-3.004l-5.01 5.012a2 2 0 0 0-.506.854l-.837 2.87a.5.5 0 0 0 .62.62l2.87-.837a2 2 0 0 0 .854-.506z"/>';

  /// The farm to add to, or none after setting one up (the setup ends on "What are you adding?").
  Future<Map<String, dynamic>?> _farm(BuildContext context) async {
    if (farm != null) return farm;
    if (await setUpFarm(context)) onChanged();
    return null;
  }

  Future<void> _open(BuildContext context, Widget form) async {
    if (await openRecord(context, form)) onChanged();
  }

  /// Your herds first (one tap into the form for that herd), then any other kind of animal.
  Future<void> _animals(BuildContext context) async {
    final f = await _farm(context);
    if (f == null || !context.mounted) return;
    final farmId = '${f['id']}';
    final herds = [for (final x in fields) if (x.module == 'livestock' && x.isActive) x];
    final picked = await _sheet<Widget>(context, 'Add animals'.tr, [
      if (herds.isNotEmpty) ...[
        _label(context, 'TO A HERD YOU HAVE'.tr),
        for (final h in herds)
          _row(context, fieldIcon(h.type), h.name, h.size,
              () => AnimalForm(farmId: farmId, kind: FarmKind.of(h.type)!, herdId: h.id, herdName: h.name)),
        _label(context, 'SOMETHING NEW'.tr),
      ],
      _grid(context, [
        for (final k in FarmKind.all.where((k) => k.herd || k.batch))
          (fieldIcon(k.code), k.label, () => k.herd ? AnimalForm(farmId: farmId, kind: k) : BatchForm(farmId: farmId, kind: k)),
      ]),
    ]);
    if (picked != null && context.mounted) await _open(context, picked);
  }

  Future<void> _crop(BuildContext context) async {
    final f = await _farm(context);
    if (f == null || !context.mounted) return;
    final farmId = '${f['id']}';
    final picked = await _sheet<Widget>(context, 'Add a crop'.tr, [
      _grid(context, [
        for (final k in FarmKind.all.where((k) => k.crop)) (fieldIcon(k.code, crop: true), k.label, () => CropForm(farmId: farmId, kind: k)),
      ]),
    ]);
    if (picked != null && context.mounted) await _open(context, picked);
  }

  Future<void> _record(BuildContext context) async {
    final f = await _farm(context);
    if (f == null || !context.mounted) return;
    if (await openFarmRecordMenu(context, fields)) onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: _door(c, Image.asset(fieldIcon('dairy_cattle'), width: 30, height: 30, excludeFromSemantics: true), 'Add animals'.tr, () => _animals(context))),
          const SizedBox(width: 8),
          Expanded(
              child: _door(c, Image.asset(fieldIcon('maize', crop: true), width: 30, height: 30, excludeFromSemantics: true), 'Add a crop'.tr, () => _crop(context))),
          const SizedBox(width: 8),
          Expanded(child: _door(c, LineIcon(_notepad, size: 26, color: c.brandText), 'Record today'.tr, () => _record(context))),
        ]),
      ),
    );
  }

  Widget _door(AppColors c, Widget icon, String label, VoidCallback onTap) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: SlCard(
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
            child: Column(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
                child: Center(child: icon),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: AppType.text, fontSize: 14, height: 18 / 14, fontWeight: FontWeight.w700, color: c.textPrimary)),
            ]),
          ),
        ),
      );

  // ── The sheet: a title, then rows or a grid of pictures. Tapping one closes it with its form.

  static Future<T?> _sheet<T>(BuildContext context, String title, List<Widget> children) {
    final c = context.appColors;
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: c.cardBackground,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheet) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.85),
        child: SafeArea(
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(16, 20, 16, 16), children: [
            Text(title, style: TextStyle(fontFamily: AppType.text, fontSize: 21, height: 26 / 21, fontWeight: FontWeight.w500, color: c.textPrimary)),
            const SizedBox(height: 8),
            ...children,
          ]),
        ),
      ),
    );
  }

  static Widget _label(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
        child: Text(text, style: AppType.eyebrow.copyWith(color: context.appColors.textSecondary)),
      );

  static Widget _row(BuildContext context, String picture, String title, String meta, Widget Function() form) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pop(context, form()),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: c.cardBackground, shape: BoxShape.circle),
                child: Center(child: Image.asset(picture, width: 26, height: 26, excludeFromSemantics: true)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: AppType.label.copyWith(color: c.textPrimary)),
                  if (meta.isNotEmpty) Text(meta, style: AppType.caption.copyWith(color: c.textSecondary)),
                ]),
              ),
              Icon(Icons.add_rounded, color: c.brandText),
            ]),
          ),
        ),
      ),
    );
  }

  static Widget _grid(BuildContext context, List<(String, String, Widget Function())> items) {
    final c = context.appColors;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1,
      children: [
        for (final (picture, label, form) in items)
          Material(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pop(context, form()),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Image.asset(picture, width: 34, height: 34, excludeFromSemantics: true),
                  const SizedBox(height: 8),
                  Text(label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: AppType.text, fontSize: 13, height: 17 / 13, fontWeight: FontWeight.w700, color: c.textPrimary)),
                ]),
              ),
            ),
          ),
      ],
    );
  }
}
