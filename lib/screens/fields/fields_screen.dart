import 'package:flutter/material.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/ledger.dart';
import '../../widgets/phosphor_icons.dart';
import 'field_scan_screen.dart';
import 'field_service.dart';
import 'field_widgets.dart';

/// The round category buttons above a list of fields. Tapping one filters the
/// list; tapping it again shows everything.
class FieldCategories extends StatelessWidget {
  final FieldCategory? selected;
  final ValueChanged<FieldCategory?> onChanged;
  final Set<FieldCategory> present; // categories the farm has

  const FieldCategories({super.key, required this.selected, required this.onChanged, required this.present});

  static const items = [
    (FieldCategory.animals, PhosphorIconsRegular.cow, 'Animals'),
    (FieldCategory.poultry, PhosphorIconsRegular.egg, 'Poultry'),
    (FieldCategory.crops, PhosphorIconsRegular.grains, 'Crops'),
    (FieldCategory.orchards, PhosphorIconsRegular.tree, 'Orchards'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (cat, icon, label) in items)
          _circle(c, icon, label, selected == cat, present.contains(cat), () => onChanged(selected == cat ? null : cat)),
        _circle(c, PhosphorIconsRegular.squaresFour, 'All', selected == null, true, () => onChanged(null)),
      ],
    );
  }

  Widget _circle(AppColors c, IconData icon, String label, bool on, bool enabled, VoidCallback onTap) {
    return Semantics(
      button: true,
      selected: on,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: on ? c.shamba : c.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 26, color: on ? c.onShamba : c.brandText),
                ),
                const SizedBox(height: 6),
                Text(label, style: AppType.caption.copyWith(color: c.textPrimary, fontWeight: on ? FontWeight.w700 : FontWeight.w400)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens a field: the scan screen first, as on the home screen.
void openField(BuildContext context, Field f) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => FieldScanScreen(field: f)));

/// Every field, herd and flock on the farm.
class FieldsScreen extends StatefulWidget {
  const FieldsScreen({super.key});

  @override
  State<FieldsScreen> createState() => _FieldsScreenState();
}

class _FieldsScreenState extends State<FieldsScreen> {
  List<Field>? _fields;
  bool _noFarm = false;
  FieldCategory? _category;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final (farm, fields) = await FieldService.load();
    if (!mounted) return;
    setState(() {
      _noFarm = farm == null;
      _fields = fields;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final fields = _fields;
    final shown = fields?.where((f) => _category == null || f.category == _category).toList();

    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: c.shamba,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
            children: [
              Text('My fields', style: AppType.titleL.copyWith(color: c.textPrimary)),
              Text('Your animals and crops', style: AppType.caption.copyWith(color: c.textSecondary)),
              const SizedBox(height: 20),
              if (fields != null && fields.isNotEmpty) ...[
                FieldCategories(
                  selected: _category,
                  present: fields.map((f) => f.category).toSet(),
                  onChanged: (cat) => setState(() => _category = cat),
                ),
                const SizedBox(height: 20),
              ],
              if (fields == null)
                Padding(padding: const EdgeInsets.only(top: 80), child: Center(child: CircularProgressIndicator(color: c.shamba)))
              else if (fields.isEmpty)
                SlLedger(children: [
                  SlLedgerRow(
                    title: _noFarm ? 'No farm yet' : 'No fields yet',
                    meta: _noFarm
                        ? 'Set up your farm to add your animals and crops.'
                        : 'Add the animals you keep and the crops you grow to see them here.',
                  ),
                ])
              else
                for (final f in shown!) ...[
                  FieldCard(field: f, onTap: () => openField(context, f)),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
