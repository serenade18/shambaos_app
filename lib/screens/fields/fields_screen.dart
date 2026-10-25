import 'package:flutter/material.dart';

import '../farm/setup_farm_screen.dart';
import '../../widgets/phosphor_icons.dart';
import 'package:intl/intl.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/ledger.dart';
import '../../widgets/ledger_parts.dart';
import 'field_detail_screen.dart';
import 'field_service.dart';
import 'field_widgets.dart';
import '../../l10n/tr.dart';
import '../../widgets/skeleton.dart';

/// Opens a field's page.
void openField(BuildContext context, Field f) =>
    Navigator.push(context, MaterialPageRoute(builder: (_) => FieldDetailScreen(field: f)));

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

  static List<(FieldCategory, String)> get _categories => [
        (FieldCategory.animals, 'Animals'.tr),
        (FieldCategory.poultry, 'Poultry'.tr),
        (FieldCategory.crops, 'Crops'.tr),
        (FieldCategory.orchards, 'Orchards'.tr),
      ];

  /// "300 birds · started 3 Oct", "2 acres · planted 3 Oct".
  String _meta(Field f) {
    final date = {'date': DateFormat('d MMM', Localizations.localeOf(context).toString()).format(f.startedOn)};
    final when = f.isCrop ? 'planted {date}'.trArgs(date) : 'started {date}'.trArgs(date);
    return [f.size, when].where((p) => p.isNotEmpty).join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final fields = _fields;
    final shown = fields?.where((f) => _category == null || f.category == _category).toList();
    final counts = <FieldCategory, int>{};
    for (final f in fields ?? const <Field>[]) {
      counts[f.category] = (counts[f.category] ?? 0) + 1;
    }

    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      extendBody: true, // the list scrolls under the nav bar
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          color: c.shamba,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 24, 16, AppBottomNav.scrollPadding(context)),
            children: [
              Text('My fields'.tr,
                  style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
              const SizedBox(height: 2),
              Text('Your animals and crops'.tr, style: AppType.caption.copyWith(color: c.textSecondary)),
              if (fields != null && fields.isNotEmpty) ...[
                const SizedBox(height: 16),
                // How many of each, as chips; tapping one filters the list.
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(children: [
                    SlChip('All {n}'.trArgs({'n': fields.length}), selected: _category == null, onTap: () => setState(() => _category = null)),
                    for (final (cat, label) in _categories)
                      if (counts.containsKey(cat)) ...[
                        const SizedBox(width: 8),
                        SlChip('$label ${counts[cat]}',
                            selected: _category == cat, onTap: () => setState(() => _category = _category == cat ? null : cat)),
                      ],
                  ]),
                ),
              ],
              const SizedBox(height: 16),
              const SlSeasonStrip(),
              const SizedBox(height: 16),
              if (fields == null)
                const SkeletonBlocks([76, 76, 76, 76], gap: 10)
              else if (fields.isEmpty)
                SlLedger(children: [
                  SlLedgerRow(
                    onTap: _noFarm
                        ? () => setUpFarm(context).then((made) {
                              if (made) _load();
                            })
                        : null,
                    status: _noFarm ? Icon(PhosphorIconsRegular.caretRight, size: 18, color: c.textSecondary) : null,
                    title: _noFarm ? 'No farm yet'.tr : 'No fields yet'.tr,
                    meta: _noFarm
                        ? 'Set up your farm to add your animals and crops.'.tr
                        : 'Add the animals you keep and the crops you grow to see them here.'.tr,
                  ),
                ])
              else
                for (final f in shown!) ...[
                  SlEntRow(
                    leading: Image.asset(fieldIcon(f.type, crop: f.isCrop), width: 30, height: 30, excludeFromSemantics: true),
                    title: f.name,
                    meta: _meta(f),
                    end: SlTag(fieldKind(f.type)),
                    onTap: () => openField(context, f),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}
