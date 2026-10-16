import 'package:flutter/material.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/phosphor_icons.dart';
import '../fields/field_service.dart';
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
  const _Option(this.icon, this.title, this.subtitle, this.form);
}

/// What can be recorded for a field, herd or flock.
List<_Option> _fieldOptions(Field f) {
  if (f.isCrop) {
    return [
      _Option(PhosphorIconsRegular.shovel, 'Field work'.tr, 'Planting, weeding, spraying, inputs used'.tr, () => ActivityForm(field: f)),
      _Option(PhosphorIconsRegular.basket, 'Harvest'.tr, 'What was picked'.tr, () => HarvestForm(field: f)),
      _Option(PhosphorIconsRegular.storefront, 'Sale'.tr, 'Produce sold to a customer'.tr, () => SaleForm(field: f)),
      _Option(PhosphorIconsRegular.coins, 'Expense'.tr, 'Labour, transport, hire'.tr, () => MoneyForm(field: f)),
    ];
  }
  if (f.module == 'batches') {
    final layers = f.type == 'layers';
    return [
      _Option(PhosphorIconsRegular.notepad, 'Daily record'.tr, layers ? 'Eggs, feed and deaths'.tr : 'Feed and deaths'.tr, () => BatchDayForm(field: f)),
      if (!layers) _Option(PhosphorIconsRegular.scales, 'Weigh a sample'.tr, 'Average weight, for growth'.tr, () => SampleWeightForm(field: f)),
      _Option(PhosphorIconsRegular.syringe, 'Treatment or vaccine'.tr, 'Medicine given'.tr, () => TreatmentForm(field: f)),
      _Option(PhosphorIconsRegular.storefront, 'Sale'.tr, layers ? 'Eggs or birds sold'.tr : 'Animals or produce sold'.tr, () => SaleForm(field: f)),
      _Option(PhosphorIconsRegular.coins, 'Expense'.tr, 'Labour, transport, vet'.tr, () => MoneyForm(field: f)),
    ];
  }
  return [
    if (isMilked(f.type)) _Option(PhosphorIconsRegular.drop, 'Milk'.tr, 'Litres milked'.tr, () => MilkForm(field: f)),
    _Option(PhosphorIconsRegular.grains, 'Feeding'.tr, 'Feed given to the herd'.tr, () => FeedForm(field: f)),
    _Option(PhosphorIconsRegular.syringe, 'Treatment or vaccine'.tr, 'For the herd or one animal'.tr, () => TreatmentForm(field: f)),
    _Option(PhosphorIconsRegular.plusCircle, 'Add an animal'.tr, 'Bought or already on the farm'.tr, () => AddAnimalForm(field: f)),
    _Option(PhosphorIconsRegular.scales, 'Weigh an animal'.tr, 'Its weight today'.tr, () => AnimalWeightForm(field: f)),
    _Option(PhosphorIconsRegular.heart, 'Served'.tr, 'Natural or AI'.tr, () => ServiceForm(field: f)),
    _Option(PhosphorIconsRegular.magnifyingGlass, 'Pregnancy check'.tr, 'Pregnant or not'.tr, () => PregnancyCheckForm(field: f)),
    _Option(PhosphorIconsRegular.baby, 'Birth'.tr, givesLitters(f.type) ? 'A litter born'.tr : 'Young born'.tr, () => BirthForm(field: f)),
    _Option(PhosphorIconsRegular.signOut, 'Sold or died'.tr, 'An animal left the herd'.tr, () => AnimalExitForm(field: f)),
    _Option(PhosphorIconsRegular.storefront, 'Sale'.tr, isMilked(f.type) ? 'Milk sold'.tr : 'Produce sold'.tr, () => SaleForm(field: f)),
    _Option(PhosphorIconsRegular.coins, 'Expense'.tr, 'Labour, transport, vet'.tr, () => MoneyForm(field: f)),
  ];
}

/// Asks what to record for [field] and opens its form. True when something was saved.
Future<bool> openFieldRecordMenu(BuildContext context, Field field) async {
  final choice = await showModalBottomSheet<_Option>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _Menu(title: 'Record for {name}'.trArgs({'name': field.name}), options: _fieldOptions(field)),
  );
  if (choice == null || !context.mounted) return false;
  return openRecord(context, choice.form());
}

/// Asks what to record on the farm: money, or something for one of its fields.
Future<bool> openFarmRecordMenu(BuildContext context, List<Field> fields) async {
  final options = [
    _Option(PhosphorIconsRegular.storefront, 'Sale'.tr, 'Produce or animals sold'.tr, () => const SaleForm()),
    _Option(PhosphorIconsRegular.shoppingCart, 'Purchase'.tr, 'Feed, seed, medicine bought'.tr, () => const PurchaseForm()),
    _Option(PhosphorIconsRegular.coins, 'Expense'.tr, 'Labour, rent, transport'.tr, () => const MoneyForm()),
    _Option(PhosphorIconsRegular.handCoins, 'Money in'.tr, 'A grant, hiring out'.tr, () => const MoneyForm(kind: 'revenue')),
  ];
  final choice = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _Menu(title: 'Record'.tr, options: options, fields: fields),
  );
  if (choice == null || !context.mounted) return false;
  if (choice is Field) return openFieldRecordMenu(context, choice);
  return openRecord(context, (choice as _Option).form());
}

class _Menu extends StatelessWidget {
  final String title;
  final List<_Option> options;
  final List<Field> fields;
  const _Menu({required this.title, required this.options, this.fields = const []});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (ctx, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          Text(title, style: AppType.titleM.copyWith(color: c.textPrimary)),
          const SizedBox(height: 12),
          for (final o in options) _row(context, c, o.icon, o.title, o.subtitle, () => Navigator.pop(context, o)),
          if (fields.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('For a field'.tr, style: AppType.label.copyWith(color: c.textSecondary)),
            const SizedBox(height: 8),
            for (final f in fields)
              _row(context, c, _fieldIcon(f), f.name, f.size.isEmpty ? f.startedLine : '${f.size} · ${f.startedLine}',
                  () => Navigator.pop(context, f)),
          ],
        ],
      ),
    );
  }

  IconData _fieldIcon(Field f) => switch (f.category) {
        FieldCategory.crops => PhosphorIconsRegular.plant,
        FieldCategory.orchards => PhosphorIconsRegular.tree,
        FieldCategory.poultry => PhosphorIconsRegular.bird,
        FieldCategory.animals => PhosphorIconsRegular.cow,
      };

  Widget _row(BuildContext context, AppColors c, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.scaffoldBackground,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 20, color: c.brandText),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppType.label.copyWith(fontSize: 16, color: c.textPrimary)),
                      Text(subtitle, style: AppType.caption.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                Icon(PhosphorIconsRegular.caretRight, size: 18, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
