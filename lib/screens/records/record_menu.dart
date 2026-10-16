import 'package:flutter/material.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/phosphor_icons.dart';
import '../../widgets/ledger_parts.dart';
import '../auth/auth_ui.dart';
import '../fields/field_service.dart';
import '../fields/field_widgets.dart';
import 'record_form.dart';
import 'record_forms.dart';
import 'record_service.dart';
import '../../l10n/tr.dart';

/// Something that can be recorded, as a row in the Record menu.
class _Option {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function() form;
  final SlTone tone; // the icon well's colour: green, or blue/orange/red for health, money out, leaving
  const _Option(this.icon, this.title, this.subtitle, this.form, {this.tone = SlTone.good});
}

/// What can be recorded for a field, herd or flock.
List<_Option> _fieldOptions(Field f) {
  if (f.isCrop) {
    return [
      _Option(PhosphorIconsRegular.shovel, 'Field work'.tr, 'Planting, weeding, spraying, inputs used'.tr, () => ActivityForm(field: f)),
      _Option(PhosphorIconsRegular.basket, 'Harvest'.tr, 'What was picked'.tr, () => HarvestForm(field: f)),
      _Option(PhosphorIconsRegular.storefront, 'Sale'.tr, 'Produce sold to a customer'.tr, () => SaleForm(field: f)),
      _Option(PhosphorIconsRegular.coins, 'Expense'.tr, 'Labour, transport, hire'.tr, () => MoneyForm(field: f), tone: SlTone.warn),
    ];
  }
  if (f.module == 'batches') {
    final layers = f.type == 'layers';
    return [
      _Option(PhosphorIconsRegular.notepad, 'Daily record'.tr, layers ? 'Eggs, feed and deaths'.tr : 'Feed and deaths'.tr, () => BatchDayForm(field: f)),
      if (!layers) _Option(PhosphorIconsRegular.scales, 'Weigh a sample'.tr, 'Average weight, for growth'.tr, () => SampleWeightForm(field: f)),
      _Option(PhosphorIconsRegular.syringe, 'Treatment or vaccine'.tr, 'Medicine given'.tr, () => TreatmentForm(field: f), tone: SlTone.info),
      _Option(PhosphorIconsRegular.storefront, 'Sale'.tr, layers ? 'Eggs or birds sold'.tr : 'Animals or produce sold'.tr, () => SaleForm(field: f)),
      _Option(PhosphorIconsRegular.coins, 'Expense'.tr, 'Labour, transport, vet'.tr, () => MoneyForm(field: f), tone: SlTone.warn),
    ];
  }
  return [
    if (isMilked(f.type)) _Option(PhosphorIconsRegular.drop, 'Milk'.tr, 'Litres milked'.tr, () => MilkForm(field: f)),
    _Option(PhosphorIconsRegular.grains, 'Feeding'.tr, 'Feed given to the herd'.tr, () => FeedForm(field: f)),
    _Option(PhosphorIconsRegular.syringe, 'Treatment or vaccine'.tr, 'For the herd or one animal'.tr, () => TreatmentForm(field: f), tone: SlTone.info),
    _Option(PhosphorIconsRegular.plusCircle, 'Add an animal'.tr, 'Bought or already on the farm'.tr, () => AddAnimalForm(field: f)),
    _Option(PhosphorIconsRegular.scales, 'Weigh an animal'.tr, 'Its weight today'.tr, () => AnimalWeightForm(field: f)),
    _Option(PhosphorIconsRegular.heart, 'Served'.tr, 'Natural or AI'.tr, () => ServiceForm(field: f)),
    _Option(PhosphorIconsRegular.magnifyingGlass, 'Pregnancy check'.tr, 'Pregnant or not'.tr, () => PregnancyCheckForm(field: f)),
    _Option(PhosphorIconsRegular.baby, 'Birth'.tr, givesLitters(f.type) ? 'A litter born'.tr : 'Young born'.tr, () => BirthForm(field: f)),
    _Option(PhosphorIconsRegular.signOut, 'Sold or died'.tr, 'An animal left the herd'.tr, () => AnimalExitForm(field: f), tone: SlTone.danger),
    _Option(PhosphorIconsRegular.storefront, 'Sale'.tr, isMilked(f.type) ? 'Milk sold'.tr : 'Produce sold'.tr, () => SaleForm(field: f)),
    _Option(PhosphorIconsRegular.coins, 'Expense'.tr, 'Labour, transport, vet'.tr, () => MoneyForm(field: f), tone: SlTone.warn),
  ];
}

/// Asks what to record for [field] and opens its form. True when something was saved.
Future<bool> openFieldRecordMenu(BuildContext context, Field field) async {
  final choice = await _showMenu<_Option>(context, eyebrow: field.name.toUpperCase(), options: _fieldOptions(field));
  if (choice == null || !context.mounted) return false;
  return openRecord(context, choice.form());
}

/// The menu as the design's sheet: white with rounded top corners and a grabber.
Future<T?> _showMenu<T>(BuildContext context, {String? eyebrow, required List<_Option> options, List<Field> fields = const []}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false, // the menu draws the design's own grabber
      backgroundColor: context.appColors.cardBackground,
      barrierColor: const Color(0x7317211A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => _Menu(eyebrow: eyebrow, options: options, fields: fields),
    );

/// Asks what to record on the farm: money, or something for one of its fields.
Future<bool> openFarmRecordMenu(BuildContext context, List<Field> fields) async {
  final options = [
    _Option(PhosphorIconsRegular.storefront, 'Sale'.tr, 'Produce or animals sold'.tr, () => const SaleForm()),
    _Option(PhosphorIconsRegular.shoppingCart, 'Purchase'.tr, 'Feed, seed, medicine bought'.tr, () => const PurchaseForm()),
    _Option(PhosphorIconsRegular.coins, 'Expense'.tr, 'Labour, rent, transport'.tr, () => const MoneyForm(), tone: SlTone.warn),
    _Option(PhosphorIconsRegular.handCoins, 'Money in'.tr, 'A grant, hiring out'.tr, () => const MoneyForm(kind: 'revenue')),
  ];
  final choice = await _showMenu<Object>(context, options: options, fields: fields);
  if (choice == null || !context.mounted) return false;
  if (choice is Field) return openFieldRecordMenu(context, choice);
  return openRecord(context, (choice as _Option).form());
}

class _Menu extends StatelessWidget {
  final String? eyebrow; // the field's name, when recording for one field
  final List<_Option> options;
  final List<Field> fields;
  const _Menu({this.eyebrow, required this.options, this.fields = const []});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + MediaQuery.paddingOf(context).bottom),
        children: [
          Center(
            child: Container(width: 40, height: 5, decoration: BoxDecoration(color: c.divider, borderRadius: BorderRadius.circular(999))),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (eyebrow != null)
                    Text(eyebrow!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.eyebrow.copyWith(color: c.textSecondary)),
                  const SizedBox(height: 2),
                  Text('What do you want to record?'.tr,
                      style: TextStyle(fontFamily: AppType.text, fontSize: 21, height: 26 / 21, fontWeight: FontWeight.w500, color: c.textPrimary)),
                ]),
              ),
              const SizedBox(width: 12),
              Semantics(
                button: true,
                label: 'Close'.tr,
                excludeSemantics: true,
                child: Material(
                  color: c.scaffoldBackground,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(context),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(child: LineIcon('<path d="M18 6 6 18"/><path d="m6 6 12 12"/>', size: 22, color: c.textPrimary)),
                    ),
                  ),
                ),
              ),
            ]),
          ),
          for (var i = 0; i < options.length; i++)
            _row(context, c, options[i].icon, options[i].tone, options[i].title, options[i].subtitle, first: i == 0,
                () => Navigator.pop(context, options[i])),
          if (fields.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 20, 4, 4),
              child: Text('FOR A FIELD'.tr, style: AppType.eyebrow.copyWith(color: c.textSecondary)),
            ),
            for (var i = 0; i < fields.length; i++)
              _fieldRow(context, c, fields[i], first: i == 0),
          ],
        ],
      ),
    );
  }

  /// A row (the design's row-ico): a round tinted icon, the name and a line
  /// under it, a chevron; rows split by hairlines.
  Widget _row(BuildContext context, AppColors c, IconData icon, SlTone tone, String title, String subtitle, VoidCallback onTap,
      {required bool first, Widget? leading}) {
    final (bg, fg) = switch (tone) {
      SlTone.info => (c.rainTint, c.rainInk),
      SlTone.warn => (c.warnTint, c.warnInk),
      SlTone.danger => (c.dangerTint, c.dangerInk),
      _ => (c.brandSoft, c.brandText),
    };
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: c.divider))),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: leading ?? Icon(icon, size: 20, color: fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontFamily: AppType.text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
                  Text(subtitle, style: AppType.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            LineIcon('<path d="m9 18 6-6-6-6"/>', size: 20, color: c.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _fieldRow(BuildContext context, AppColors c, Field f, {required bool first}) => _row(
        context,
        c,
        PhosphorIconsRegular.plant,
        SlTone.good,
        f.name,
        f.size.isEmpty ? f.startedLine : '${f.size} · ${f.startedLine}',
        () => Navigator.pop(context, f),
        first: first,
        leading: Image.asset(fieldIcon(f.type, crop: f.isCrop), width: 26, height: 26, excludeFromSemantics: true),
      );
}
