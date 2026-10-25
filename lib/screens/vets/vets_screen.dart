import 'package:flutter/material.dart';

import '../farm/setup_farm_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger.dart';
import '../../widgets/ledger_parts.dart';
import '../../widgets/phosphor_icons.dart';
import '../auth/auth_ui.dart';
import '../home_service.dart';
import '../../l10n/tr.dart';
import '../../widgets/skeleton.dart';

/// Vets for the farm, nearest first (GET /vets?farm_id=&animal=). The list is
/// kept by Shamba OS, the same for every farm.
class VetsService {
  static Future<({List<Map<String, dynamic>>? vets, bool noFarm, String? error})> load({String? animal}) async {
    final farms = await HomeService.listFarms();
    if (farms.isEmpty) return (vets: null, noFarm: true, error: null);
    final res = await ApiService.get('/vets?farm_id=${farms.first['id']}${animal == null ? '' : '&animal=$animal'}');
    if (res.error || res.data is! Map) {
      return (vets: null, noFarm: false, error: res.message ?? 'Check your connection and try again.'.tr);
    }
    final rows = (res.data['results'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return (vets: rows, noFarm: false, error: null);
  }
}

/// The design's Vets near you: a call-now banner for the nearest, a filter by
/// animal, and a card per vet with Call and Message.
class VetsScreen extends StatefulWidget {
  const VetsScreen({super.key});

  @override
  State<VetsScreen> createState() => _VetsScreenState();
}

class _VetsScreenState extends State<VetsScreen> {
  List<Map<String, dynamic>>? _vets;
  bool _noFarm = false;
  bool _loading = true;
  String? _error;
  String? _animal;

  static const _alert = '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/><path d="M12 9v4"/><path d="M12 17h.01"/>';
  static const _vet = '<path d="M11 2v2"/><path d="M5 2v2"/><path d="M5 3H4a2 2 0 0 0-2 2v4a6 6 0 0 0 12 0V5a2 2 0 0 0-2-2h-1"/><path d="M8 15a6 6 0 0 0 12 0v-3"/><circle cx="20" cy="10" r="2"/>';
  static const _phone = '<path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/>';

  static Map<String, String> get _animals => {
        'cattle': 'Cattle'.tr,
        'poultry': 'Poultry'.tr,
        'goats_sheep': 'Goats & sheep'.tr,
        'pigs': 'Pigs'.tr,
        'fish': 'Fish'.tr,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await VetsService.load(animal: _animal);
    if (!mounted) return;
    setState(() {
      _vets = r.vets;
      _noFarm = r.noFarm;
      _error = r.error;
      _loading = false;
    });
  }

  void _filter(String? animal) {
    if (animal == _animal) return;
    setState(() => _animal = animal);
    _load();
  }

  Future<void> _open(Uri uri) async {
    final ok = await launchUrl(uri);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open your phone app.'.tr)));
    }
  }

  void _call(Map<String, dynamic> v) => _open(Uri(scheme: 'tel', path: '${v['phone']}'));
  void _message(Map<String, dynamic> v) => _open(Uri(scheme: 'sms', path: '${v['phone']}'));

  String _where(Map<String, dynamic> v) {
    final km = v['distance_km'];
    return [
      if ('${v['clinic'] ?? ''}'.isNotEmpty) '${v['clinic']}' else if ('${v['county'] ?? ''}'.isNotEmpty) '${v['county']}',
      if (km is num) '{km} km'.trArgs({'km': km}),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final vets = _vets;
    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: c.shamba,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
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
                  child: Text('Vets near you'.tr,
                      style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
                ),
                if (_loading && vets != null) SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.shamba)),
              ]),
              const SizedBox(height: 16),
              if (_noFarm)
                SlLedger(children: [SlLedgerRow(title: 'No farm yet'.tr, meta: 'Set up your farm to find vets near it.'.tr, status: Icon(PhosphorIconsRegular.caretRight, size: 18, color: context.appColors.textSecondary), onTap: () => setUpFarm(context).then((made) {
                    if (made) _load();
                  }))])
              else if (vets == null && _loading)
                const Column(children: [SkeletonBlocks([132]), SizedBox(height: 56), SkeletonLedger(rows: 4)])
              else if (vets == null)
                SlLedger(children: [
                  SlLedgerRow(title: 'Could not load vets'.tr, meta: _error, status: TextButton(onPressed: _load, child: Text('Try again'.tr))),
                ])
              else ...[
                if (vets.isNotEmpty && _animal == null) ...[_urgent(c, vets.first), const SizedBox(height: 12)],
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(children: [
                    SlChip('All'.tr, selected: _animal == null, onTap: () => _filter(null)),
                    for (final e in _animals.entries) ...[
                      const SizedBox(width: 8),
                      SlChip(e.value, selected: _animal == e.key, onTap: () => _filter(_animal == e.key ? null : e.key)),
                    ],
                  ]),
                ),
                const SizedBox(height: 12),
                if (vets.isEmpty)
                  SlLedger(children: [
                    SlLedgerRow(
                      title: _animal == null ? 'No vets listed near you yet'.tr : 'No vets listed for these animals yet'.tr,
                      meta: 'We are adding vets county by county. Your county agriculture office can help meanwhile.'.tr,
                    ),
                  ]),
                for (final v in vets) ...[_card(c, v), const SizedBox(height: 12)],
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// "Animal very sick?" with the nearest vet and Call now.
  Widget _urgent(AppColors c, Map<String, dynamic> v) {
    final km = v['distance_km'];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(color: c.dangerTint, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: c.cardBackground, shape: BoxShape.circle),
          child: Center(child: LineIcon(_alert, size: 22, color: c.dangerInk)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Animal very sick?'.tr,
                style: TextStyle(fontFamily: AppType.text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
            Text(km is num ? '{name} is {km} km away'.trArgs({'name': v['name'], 'km': km}) : 'Call {name}'.trArgs({'name': v['name']}),
                maxLines: 2, overflow: TextOverflow.ellipsis, style: AppType.caption.copyWith(color: c.textPrimary)),
          ]),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: () => _call(v),
            style: ElevatedButton.styleFrom(
              backgroundColor: c.dangerInk,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: const TextStyle(fontFamily: AppType.text, fontSize: 15, fontWeight: FontWeight.w700),
            ),
            child: Text('Call now'.tr),
          ),
        ),
      ]),
    );
  }

  Widget _card(AppColors c, Map<String, dynamic> v) {
    final animals = (v['animals'] as List? ?? []).map((a) => _animals['$a']).whereType<String>().toList();
    final hours = '${v['hours'] ?? ''}';
    return SlCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
            child: Center(child: LineIcon(_vet, size: 24, color: c.brandText)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${v['name']}',
                  style: TextStyle(fontFamily: AppType.text, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, color: c.textPrimary)),
              if (_where(v).isNotEmpty) Text(_where(v), style: AppType.caption.copyWith(color: c.textSecondary)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          if (animals.isEmpty) SlTag('All animals'.tr) else for (final a in animals) SlTag(a),
          if (v['farm_visits'] == true) SlTag('Farm visits'.tr, tone: SlTone.good),
          if (hours.isNotEmpty) SlTag(hours, icon: SlTag.clock),
        ]),
        const SizedBox(height: 12),
        Divider(height: 1, thickness: 1, color: c.divider),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: LedgerButton(
              label: 'Call'.tr,
              large: false,
              icon: const LineIcon(_phone, size: 18, color: Colors.white),
              onPressed: () => _call(v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LedgerButton(label: 'Message'.tr, large: false, kind: LedgerButtonKind.secondary, onPressed: () => _message(v)),
          ),
        ]),
      ]),
    );
  }
}
