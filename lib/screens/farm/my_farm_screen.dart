import 'package:flutter/material.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger.dart';
import '../../widgets/ledger_parts.dart';
import '../../widgets/phosphor_icons.dart';
import '../auth/auth_ui.dart';
import '../fields/field_widgets.dart';
import 'add_to_farm.dart';
import 'farm_map_screen.dart';
import 'farm_setup_service.dart';
import '../../l10n/tr.dart';

/// My farm, from Profile: the farm, its boundary (the farm map), what it runs,
/// and "Add to your farm", which opens "What are you adding?".
class MyFarmScreen extends StatefulWidget {
  const MyFarmScreen({super.key});

  @override
  State<MyFarmScreen> createState() => _MyFarmScreenState();
}

class _MyFarmScreenState extends State<MyFarmScreen> {
  Map<String, dynamic>? _farm;
  List<String> _types = const [];
  bool _loading = true;
  String? _error;

  static const _farmIcon = '<path d="M14 9.536V7a4 4 0 0 1 4-4h1.5a.5.5 0 0 1 .5.5V5a4 4 0 0 1-4 4 4 4 0 0 0-4 4c0 2 1 3 1 5a5 5 0 0 1-1 3"/><path d="M4 9a5 5 0 0 1 8 4 5 5 0 0 1-8-4"/><path d="M5 21h14"/>';
  static const _mapIcon = '<path d="M14.106 5.553a2 2 0 0 0 1.788 0l3.659-1.83A1 1 0 0 1 21 4.619v12.764a1 1 0 0 1-.553.894l-4.553 2.277a2 2 0 0 1-1.788 0l-4.212-2.106a2 2 0 0 0-1.788 0l-3.659 1.83A1 1 0 0 1 3 19.381V6.618a1 1 0 0 1 .553-.894l4.553-2.277a2 2 0 0 1 1.788 0z"/><path d="M15 5.764v15"/><path d="M9 3.236v15"/>';
  static const _plus = '<path d="M5 12h14"/><path d="M12 5v14"/>';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await FarmSetupService.load();
    if (!mounted) return;
    setState(() {
      _farm = r.farm;
      _types = r.types;
      _error = r.error;
      _loading = false;
    });
  }

  Future<void> _openMap() async {
    final farm = _farm;
    if (farm == null) return;
    await FarmMapScreen.open(context, farm);
    _load();
  }

  Future<void> _add() async {
    final farm = _farm;
    if (farm == null) return;
    final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => AddToFarmScreen(farm: farm)));
    if (added == true) _load();
  }

  /// Hectares as farmers say it: acres, to one decimal.
  static String? _acres(dynamic ha) {
    final v = num.tryParse('${ha ?? ''}');
    if (v == null || v <= 0) return null;
    final acres = v * 2.47105;
    return acres >= 10 ? acres.round().toString() : acres.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final farm = _farm;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      body: Stack(children: [
        SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _load,
            color: c.shamba,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 20, 16, 112 + bottom),
              children: [
                Row(children: [
                  Semantics(
                    button: true,
                    label: 'Back'.tr,
                    excludeSemantics: true,
                    child: Container(
                      decoration: BoxDecoration(
                        color: c.cardBackground,
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
                      ),
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => Navigator.maybePop(context),
                          child: SizedBox(width: 44, height: 44, child: Icon(PhosphorIconsRegular.arrowLeft, size: 22, color: c.textPrimary)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('My farm'.tr,
                        style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
                  ),
                ]),
                const SizedBox(height: 16),
                if (_loading && farm == null)
                  Padding(padding: const EdgeInsets.only(top: 64), child: Center(child: CircularProgressIndicator(color: c.shamba)))
                else if (farm == null)
                  SlLedger(children: [
                    SlLedgerRow(
                      title: _error == null ? 'No farm yet'.tr : 'Could not load your farm'.tr,
                      meta: _error ?? 'Set up your farm from Home first.'.tr,
                      status: _error == null ? null : TextButton(onPressed: _load, child: Text('Try again'.tr)),
                    ),
                  ])
                else ...[
                  _farmCard(c, farm),
                  SlGroupLabel('Land'.tr),
                  SlLedger(children: [
                    SlIconRow(
                      icon: _mapIcon,
                      title: 'Farm boundary'.tr,
                      meta: farm['boundary'] == null
                          ? 'Not mapped yet. Draw or walk it for weather and crop checks on your exact land.'.tr
                          : (_acres(farm['area_ha']) == null ? 'Mapped'.tr : 'Mapped · {acres} acres'.trArgs({'acres': _acres(farm['area_ha'])})),
                      end: farm['boundary'] == null ? SlTag('Map it'.tr, tone: SlTone.warn) : null,
                      onTap: _openMap,
                    ),
                  ]),
                  SlGroupLabel("What you're running".tr),
                  _running(c),
                ],
              ],
            ),
          ),
        ),
        if (farm != null)
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
              child: LedgerButton(label: 'Add to your farm'.tr, icon: const LineIcon(_plus, size: 20, color: Colors.white), onPressed: _add),
            ),
          ),
      ]),
    );
  }

  Widget _farmCard(AppColors c, Map<String, dynamic> farm) {
    final county = '${farm['county'] ?? ''}';
    return SlCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
          child: Center(child: LineIcon(_farmIcon, size: 26, color: c.brandText)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${farm['name'] ?? ''}',
                style: TextStyle(fontFamily: AppType.text, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, color: c.textPrimary)),
            if (county.isNotEmpty) Text(county, style: AppType.caption.copyWith(color: c.textSecondary)),
          ]),
        ),
      ]),
    );
  }

  /// The kinds of animals and crops the farm keeps, each with its icon.
  Widget _running(AppColors c) {
    if (_types.isEmpty) {
      return SlLedger(children: [
        SlLedgerRow(title: 'Nothing yet'.tr, meta: 'Add the animals you keep and the crops you grow.'.tr),
      ]);
    }
    return SlCard(
      child: Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in _types)
          Container(
            height: 40,
            padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
            decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(999)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: c.cardBackground, shape: BoxShape.circle),
                child: Center(
                  child: Image.asset(fieldIcon(t, crop: FarmKind.of(t)?.crop ?? false), width: 20, height: 20, excludeFromSemantics: true),
                ),
              ),
              const SizedBox(width: 8),
              Text(FarmKind.of(t)?.label ?? t,
                  style: TextStyle(fontFamily: AppType.text, fontSize: 14, fontWeight: FontWeight.w700, color: c.brandText)),
            ]),
          ),
      ]),
    );
  }
}
