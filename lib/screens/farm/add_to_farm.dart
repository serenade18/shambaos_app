import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger_parts.dart';
import '../../widgets/phosphor_icons.dart';
import '../auth/auth_ui.dart';
import '../customers/customer_service.dart';
import '../fields/field_widgets.dart';
import '../records/record_form.dart';
import '../../widgets/sl_form.dart';
import 'farm_setup_service.dart';
import 'herd_entry.dart';
import '../../l10n/tr.dart';

/// One thing a farm can run, as screen 27 groups them.
class FarmKind {
  final String code; // the catalogue's type code
  final String label;
  final String group; // animals | birds | crops | trees
  const FarmKind(this.code, this.label, this.group);

  bool get herd => group == 'animals';

  /// A new herd's name: "Dairy herd", "Pigs herd".
  String get herdName => code == 'dairy_cattle' ? 'Dairy herd'.tr : '{kind} herd'.trArgs({'kind': label});
  bool get batch => group == 'birds';
  bool get crop => group == 'crops' || group == 'trees';
  bool get orchard => group == 'trees';

  static List<FarmKind> get all => [
        FarmKind('dairy_cattle', 'Dairy cows'.tr, 'animals'),
        FarmKind('beef_cattle', 'Beef cattle'.tr, 'animals'),
        FarmKind('dairy_goats', 'Dairy goats'.tr, 'animals'),
        FarmKind('sheep', 'Sheep'.tr, 'animals'),
        FarmKind('pigs', 'Pigs'.tr, 'animals'),
        FarmKind('rabbits', 'Rabbits'.tr, 'animals'),
        FarmKind('layers', 'Layers'.tr, 'birds'),
        FarmKind('broilers', 'Broilers'.tr, 'birds'),
        FarmKind('fish', 'Fish'.tr, 'birds'),
        FarmKind('maize', 'Maize'.tr, 'crops'),
        FarmKind('beans', 'Beans'.tr, 'crops'),
        FarmKind('rice', 'Rice'.tr, 'crops'),
        FarmKind('wheat', 'Wheat'.tr, 'crops'),
        FarmKind('tomatoes', 'Tomatoes'.tr, 'crops'),
        FarmKind('kales', 'Sukuma (kales)'.tr, 'crops'),
        FarmKind('spinach', 'Spinach'.tr, 'crops'),
        FarmKind('bananas', 'Bananas'.tr, 'trees'),
        FarmKind('avocados', 'Avocados'.tr, 'trees'),
      ];

  static FarmKind? of(String code) => all.where((k) => k.code == code).firstOrNull;
}

// The design's line icons for the non-farming tiles (Lucide, ISC licence).
const _plotIcon = '<path d="m12 8 6-3-6-3v10"/><path d="m8 11.99-5.5 3.14a1 1 0 0 0 0 1.74l8.5 4.86a2 2 0 0 0 2 0l8.5-4.86a1 1 0 0 0 0-1.74L16 12"/><path d="m6.49 12.85 11.02 6.3"/><path d="M17.51 12.85 6.5 19.15"/>';
const _buildingIcon = '<path d="M18 21V10a1 1 0 0 0-1-1H7a1 1 0 0 0-1 1v11"/><path d="M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V8a2 2 0 0 1 1.132-1.803l7.95-3.974a2 2 0 0 1 1.837 0l7.948 3.974A2 2 0 0 1 22 8z"/><path d="M6 13h12"/><path d="M6 17h12"/>';
const _storeIcon = '<path d="M15 21v-5a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v5"/><path d="M17.774 10.31a1.12 1.12 0 0 0-1.549 0 2.5 2.5 0 0 1-3.451 0 1.12 1.12 0 0 0-1.548 0 2.5 2.5 0 0 1-3.452 0 1.12 1.12 0 0 0-1.549 0 2.5 2.5 0 0 1-3.77-3.248l2.889-4.184A2 2 0 0 1 7 2h10a2 2 0 0 1 1.653.873l2.895 4.192a2.5 2.5 0 0 1-3.774 3.244"/><path d="M4 10.95V19a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8.05"/>';
const _truckIcon = '<path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"/><path d="M15 18H9"/><path d="M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.624l-3.48-4.35A1 1 0 0 0 17.52 8H14"/><circle cx="17" cy="18" r="2"/><circle cx="7" cy="18" r="2"/>';
const _teamIcon = '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><line x1="19" x2="19" y1="8" y2="14"/><line x1="22" x2="16" y1="11" y2="11"/>';
const _plusIcon = '<path d="M5 12h14"/><path d="M12 5v14"/>';

/// Screen 27, "What are you adding?": everything a farm can add, by kind. Each
/// tile opens its form; closes with true when something was added.
class AddToFarmScreen extends StatefulWidget {
  final Map<String, dynamic> farm;
  const AddToFarmScreen({super.key, required this.farm});

  @override
  State<AddToFarmScreen> createState() => _AddToFarmScreenState();
}

class _AddToFarmScreenState extends State<AddToFarmScreen> {
  bool _added = false;

  String get _farmId => '${widget.farm['id']}';

  Future<void> _open(Widget form, {Future<void> Function()? then}) async {
    if (await openRecord(context, form)) {
      _added = true;
      if (then != null) await then();
    }
  }

  Future<void> _kind(FarmKind k) async {
    if (k.herd) return _open(AnimalForm(farmId: _farmId, kind: k));
    if (k.batch) return _open(BatchForm(farmId: _farmId, kind: k));
    return _open(CropForm(farmId: _farmId, kind: k));
  }

  /// Screen 28; it goes on to add the herd's animals one by one.
  Future<void> _newHerd() => _open(HerdForm(farmId: _farmId));

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final kinds = FarmKind.all;
    Widget group(String title, String? note, List<Widget> tiles) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Expanded(
                child: Text(title,
                    style: TextStyle(fontFamily: AppType.text, fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w500, color: c.textPrimary)),
              ),
              if (note != null)
                Flexible(child: Text(note, textAlign: TextAlign.end, style: AppType.caption.copyWith(color: c.textSecondary))),
            ]),
          ),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.82,
            children: tiles,
          ),
        ]);
    Widget kindTile(FarmKind k) => _Pick(
          label: k.label,
          icon: Image.asset(fieldIcon(k.code, crop: k.crop), width: 26, height: 26, excludeFromSemantics: true),
          tone: k.code == 'fish' ? SlTone.info : (k.batch || k.code == 'bananas' ? SlTone.warn : SlTone.neutral),
          onTap: () => _kind(k),
        );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _added);
      },
      child: Scaffold(
        backgroundColor: c.scaffoldBackground,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            children: [
              Row(children: [
                _RoundButton(icon: PhosphorIconsRegular.x, label: 'Close'.tr, onTap: () => Navigator.pop(context, _added)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ADD TO {farm}'.trArgs({'farm': '${widget.farm['name'] ?? ''}'.toUpperCase()}),
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.eyebrow.copyWith(color: c.textSecondary)),
                    Text('What are you adding?'.tr,
                        style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
                  ]),
                ),
              ]),
              group('Animals'.tr, 'Each one by tag'.tr, [
                for (final k in kinds.where((k) => k.herd)) kindTile(k),
                _Pick(label: 'New herd'.tr, icon: LineIcon(_plusIcon, size: 22, color: c.brandText), onTap: _newHerd),
              ]),
              group('Birds and fish'.tr, 'Counted as a batch'.tr, [for (final k in kinds.where((k) => k.batch)) kindTile(k)]),
              group('Crops'.tr, 'One season on a plot'.tr, [for (final k in kinds.where((k) => k.group == 'crops')) kindTile(k)]),
              group('Fruit trees'.tr, 'Planted once, picked for years'.tr, [for (final k in kinds.where((k) => k.orchard)) kindTile(k)]),
              group('Land, buildings and people'.tr, null, [
                _Pick(label: 'Plot'.tr, icon: LineIcon(_plotIcon, size: 22, color: c.brandText), onTap: () => _open(PlotForm(farmId: _farmId))),
                _Pick(
                    label: 'Building or pond'.tr,
                    icon: LineIcon(_buildingIcon, size: 22, color: c.brandText),
                    onTap: () => _open(StructureForm(farmId: _farmId))),
                _Pick(label: 'Customer'.tr, icon: LineIcon(_storeIcon, size: 22, color: c.brandText), onTap: () => _open(const CustomerForm())),
                _Pick(label: 'Supplier'.tr, icon: LineIcon(_truckIcon, size: 22, color: c.brandText), onTap: () => _open(const SupplierForm())),
                _Pick(label: 'Team member'.tr, icon: LineIcon(_teamIcon, size: 22, color: c.brandText), onTap: () => _open(const TeamForm())),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tile on screen 27 (the design's pick): an icon in a round well and its name.
class _Pick extends StatelessWidget {
  final String label;
  final Widget icon;
  final SlTone tone;
  final VoidCallback onTap;
  const _Pick({required this.label, required this.icon, this.tone = SlTone.neutral, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final well = switch (tone) {
      SlTone.warn => c.warnTint,
      SlTone.info => c.rainTint,
      _ => c.brandSoft,
    };
    return Container(
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Column(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: well, shape: BoxShape.circle), child: Center(child: icon)),
              const SizedBox(height: 6),
              Expanded(
                child: Text(label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: AppType.text, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w700, color: c.textPrimary)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Semantics(
      button: true,
      label: label,
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
            onTap: onTap,
            child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 22, color: c.textPrimary)),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// Shared bits of the add forms
// ═══════════════════════════════════════════════════════════

String _day(DateTime d) => DateFormat('yyyy-MM-dd').format(d);
num? _num(TextEditingController c) => num.tryParse(c.text.replaceAll(',', '').trim());

// ═══════════════════════════════════════════════════════════
// ANIMALS (screens 28–34)
// ═══════════════════════════════════════════════════════════

/// What the design calls each kind's animals, for counts and hints.
String animalUnit(String type, int n) => switch (type) {
      'dairy_cattle' => n == 1 ? 'cow'.tr : 'cows'.tr,
      'beef_cattle' => 'head'.tr,
      'dairy_goats' => n == 1 ? 'goat'.tr : 'goats'.tr,
      'sheep' => 'sheep'.tr,
      'pigs' => n == 1 ? 'pig'.tr : 'pigs'.tr,
      'rabbits' => n == 1 ? 'rabbit'.tr : 'rabbits'.tr,
      _ => n == 1 ? 'animal'.tr : 'animals'.tr,
    };

/// The sexes of each kind of animal, as farmers say them.
List<(String, String)> animalSexes(String type) => switch (type) {
      'dairy_cattle' => [('female', 'Cow (female)'.tr), ('male', 'Bull (male)'.tr)],
      'beef_cattle' => [('female', 'Heifer or cow'.tr), ('male', 'Bull or steer'.tr)],
      'dairy_goats' || 'rabbits' => [('female', 'Doe (female)'.tr), ('male', 'Buck (male)'.tr)],
      'sheep' => [('female', 'Ewe (female)'.tr), ('male', 'Ram (male)'.tr)],
      'pigs' => [('female', 'Sow or gilt (female)'.tr), ('male', 'Boar (male)'.tr)],
      _ => [('female', 'Female'.tr), ('male', 'Male'.tr)],
    };

/// The common breeds of each kind, for chips.
List<String> animalBreeds(String type) => switch (type) {
      'dairy_cattle' => ['Friesian', 'Ayrshire', 'Jersey', 'Guernsey'],
      'beef_cattle' => ['Boran', 'Sahiwal', 'Angus', 'Hereford'],
      'dairy_goats' => ['Toggenburg', 'Saanen', 'Alpine', 'Galla'],
      'sheep' => ['Dorper', 'Red Maasai', 'Merino', 'Hampshire Down'],
      'pigs' => ['Large White', 'Landrace', 'Duroc', 'Hampshire'],
      'rabbits' => ['New Zealand White', 'California', 'Chinchilla', 'Flemish Giant'],
      _ => [],
    };

String _pretty(DateTime d) => DateFormat('EEE d MMM yyyy').format(d);

Future<DateTime?> _pickDate(BuildContext context, DateTime initial, {int yearsBack = 30}) {
  final now = DateTime.now();
  return showDatePicker(context: context, initialDate: initial, firstDate: DateTime(now.year - yearsBack), lastDate: now);
}

/// Screens 29–34, "Add a dairy cow" and its kin: one animal by tag into its herd
/// (POST /animals; its weight with POST /animals/{id}/weights). The tag starts as
/// the herd's next one; what most animals are saved without is under More details. With no
/// herd of its kind yet, one is started first (POST /herds). After "Start a herd",
/// it is shown once per animal: [index] of [total].
class AnimalForm extends StatefulWidget {
  final String farmId;
  final FarmKind kind;
  final String? herdId; // the herd just started
  final String? herdName;
  final int index;
  final int total;
  final String? lastTag; // the animal saved just before this one
  const AnimalForm(
      {super.key, required this.farmId, required this.kind, this.herdId, this.herdName, this.index = 1, this.total = 1, this.lastTag});

  @override
  State<AnimalForm> createState() => _AnimalFormState();
}

class _AnimalFormState extends State<AnimalForm> with RecordForm {
  final _tag = TextEditingController();
  final _name = TextEditingController();
  final _cost = TextEditingController();
  final _weight = TextEditingController();
  final _sire = TextEditingController();
  final _rfid = TextEditingController();
  List<Map<String, dynamic>>? _herds;
  String? _herd;
  String _sex = 'female'; // female | male | steer (a castrated male)
  String? _stage;
  String? _breed;
  String _source = 'bought';
  DateTime? _born;
  List<Map<String, dynamic>> _mothers = const []; // the herd's females
  String? _mother;
  String? _lastTag; // the herd's highest tag, for "Next after KE-047"
  String _suggested = ''; // the tag filled in; replaced when the herd changes, unless typed over

  static const _strip =
      '<rect width="7" height="7" x="3" y="3" rx="1"/><rect width="7" height="7" x="14" y="3" rx="1"/><rect width="7" height="7" x="14" y="14" rx="1"/><rect width="7" height="7" x="3" y="14" rx="1"/>';

  String get _type => widget.kind.code;
  bool get _sequence => widget.total > 1;
  bool get _beef => _type == 'beef_cattle';
  bool get _female => _sex == 'female';
  // Beef bought by weight: its weight is on the form itself (screen 30); for the rest it is a detail.
  bool get _weightUp => _beef && _source == 'bought';

  @override
  void initState() {
    super.initState();
    _sex = _beef ? 'male' : 'female';
    _loadHerds();
  }

  Future<void> _loadHerds() async {
    final h = await FarmSetupService.herds(widget.farmId, _type);
    if (!mounted) return;
    setState(() {
      _herds = h;
      _herd = widget.herdId ?? _herd ?? (h.isEmpty ? null : '${h.first['id']}');
    });
    _loadHerd();
  }

  /// The chosen herd's animals: its next tag and the mothers to pick from.
  Future<void> _loadHerd() async {
    final herd = _herd;
    if (herd == null) {
      _suggest(widget.lastTag == null ? 'KE-1' : nextTag(widget.lastTag!), null);
      return;
    }
    final animals = await FarmSetupService.animals(herd);
    if (!mounted || herd != _herd) return;
    final tags = [for (final a in animals) '${a['tag'] ?? ''}'];
    final next = firstTag(tags);
    setState(() {
      _mothers = [for (final a in animals) if (a['sex'] == 'female' && a['status'] == 'active') a];
      if (!_mothers.any((m) => '${m['id']}' == _mother)) _mother = null;
    });
    _suggest(next, tags.isEmpty ? null : _highest(tags));
  }

  /// The highest numbered tag, which the next one follows.
  static String? _highest(List<String> tags) {
    String? best;
    var high = -1;
    for (final t in tags) {
      final m = RegExp(r'(\d+)\D*$').firstMatch(t);
      final n = m == null ? null : int.tryParse(m[1]!);
      if (n != null && n > high) {
        high = n;
        best = t;
      }
    }
    return best;
  }

  void _suggest(String tag, String? after) {
    setState(() {
      if (_tag.text.isEmpty || _tag.text == _suggested) _tag.text = tag;
      _suggested = tag;
      _lastTag = after;
    });
  }

  @override
  void dispose() {
    for (final c in [_tag, _name, _cost, _weight, _sire, _rfid]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Where a milked female is in her life (screen 29), for milk recording and breeding.
  List<(String, String)>? get _stages => switch (_type) {
        'dairy_cattle' => [('milking', 'Milking'.tr), ('dry', 'In calf or dry'.tr), ('heifer', 'Heifer'.tr), ('young', 'Calf'.tr)],
        'dairy_goats' => [('milking', 'Milking'.tr), ('dry', 'Dry'.tr), ('heifer', 'Young doe'.tr), ('young', 'Kid'.tr)],
        _ => null,
      };

  List<String> get _breeds => animalBreeds(_type);

  String get _title => switch (_type) {
        'dairy_cattle' => 'Add a dairy cow'.tr,
        'beef_cattle' => 'Add a beef animal'.tr,
        'dairy_goats' => 'Add a dairy goat'.tr,
        'sheep' => 'Add a sheep'.tr,
        'pigs' => 'Add a pig'.tr,
        'rabbits' => 'Add a rabbit'.tr,
        _ => 'Add an animal'.tr,
      };

  String get _tagHint {
    final last = _lastTag;
    if (last != null && _tag.text == _suggested) return 'Next after {tag}. Change it if the ear tag says otherwise.'.trArgs({'tag': last});
    return switch (_type) {
      'sheep' => 'On the ear tag, or a number you paint on.'.tr,
      'rabbits' => 'On the ear tattoo or cage card.'.tr,
      _ => 'On the ear tag, or a number you give it.'.tr,
    };
  }

  String? get _note => switch (_type) {
        'dairy_goats' => 'For a kid born to one of your does, use Record a birth on the mother. It links them.'.tr,
        'pigs' => 'Piglets are not added here. Record a litter on the sow and they are raised as one group.'.tr,
        'rabbits' => 'Kits are not added here. Record a litter on the doe and they are raised as one group.'.tr,
        _ => null,
      };

  /// "2 yrs 8 mos", short, for the tag in the date box.
  String _age(DateTime born) {
    final now = DateTime.now();
    final days = now.difference(born).inDays;
    if (days < 56) return days < 14 ? '{n} days'.trArgs({'n': days}) : '{n} wks'.trArgs({'n': days ~/ 7});
    var months = (now.year - born.year) * 12 + now.month - born.month - (now.day < born.day ? 1 : 0);
    if (months < 12) return '{n} mos'.trArgs({'n': months});
    final years = months ~/ 12;
    months %= 12;
    final y = years == 1 ? '1 yr'.tr : '{n} yrs'.trArgs({'n': years});
    return months == 0 ? y : '$y ${'{n} mos'.trArgs({'n': months})}';
  }

  /// "Dairy herd · 5 cows", or "Dairy herd · 2 of 5" while filling a new herd.
  String get _meta {
    final herds = _herds;
    if (herds == null) return 'Loading your herds…'.tr;
    final herd = herds.where((h) => '${h['id']}' == _herd).firstOrNull;
    if (_sequence) {
      final line = '{herd} · {i} of {n}'.trArgs({'herd': widget.herdName ?? herd?['name'] ?? '', 'i': widget.index, 'n': widget.total});
      return widget.lastTag == null ? line : '$line · ${'{tag} saved'.trArgs({'tag': widget.lastTag!})}';
    }
    if (herd == null) return _herd == null ? 'A new herd starts with this animal'.tr : '${widget.herdName ?? ''}';
    final n = int.tryParse('${herd['head_count'] ?? 0}') ?? 0;
    return '{herd} · {n} {unit}'.trArgs({'herd': herd['name'], 'n': n, 'unit': animalUnit(_type, n)});
  }

  /// Change: another herd of this kind, or a new one (screen 28).
  Future<void> _change() async {
    final herds = _herds ?? const [];
    final picked = await slPick<String>(context,
        title: 'Which herd?'.tr,
        value: _herd,
        options: [for (final h in herds) ('${h['id']}', '${h['name']}'), ('new', 'Start a new herd'.tr)]);
    if (picked == null || !mounted) return;
    if (picked == 'new') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => HerdForm(farmId: widget.farmId, initialType: _type)));
      return;
    }
    setState(() => _herd = picked);
    _loadHerd();
  }

  /// Quick herd entry for this herd, in place of this form.
  void _several() {
    final herd = (_herds ?? const []).where((h) => '${h['id']}' == _herd).firstOrNull;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HerdEntryScreen(herdId: _herd!, herdName: '${herd?['name'] ?? widget.herdName ?? ''}', type: _type)),
    );
  }

  Future<void> _pickMother() async {
    final picked = await slPick<String>(context, title: 'Mother'.tr, value: _mother ?? '', options: [
      ('', 'Not known'.tr),
      for (final m in _mothers) ('${m['id']}', '${m['name']}'.isEmpty ? '${m['tag']}' : '${m['tag']} · ${m['name']}'),
    ]);
    if (picked != null) setState(() => _mother = picked.isEmpty ? null : picked);
  }

  void _setSex(String v) => setState(() {
        _sex = v;
        if (v != 'female' && _stage != 'young') _stage = null; // milking, dry and heifer are hers
      });

  Future<void> _save() async {
    final tag = _tag.text.trim();
    if (tag.isEmpty) return fail("Enter the animal's tag.".tr, 'tag');
    final cost = _source == 'bought' && _cost.text.trim().isNotEmpty ? _num(_cost) : null;
    final kg = _weight.text.trim().isEmpty ? null : _num(_weight);
    if (_weight.text.trim().isNotEmpty && (kg == null || kg <= 0)) return fail('Enter the weight in kg.'.tr, 'kg');
    final done = '{tag} added'.trArgs({'tag': tag});
    await save(() async {
      var herd = _herd;
      if (herd == null) {
        final started = await FarmSetupService.startHerd({
          'farm_id': widget.farmId,
          'type': _type,
          'name': widget.kind.herdName,
          'date': _day(DateTime.now()),
        });
        if (started.error) return started;
        herd = '${started.data['id']}';
        _herd = herd;
      }
      final res = await FarmSetupService.addAnimal({
        'enterprise_id': herd,
        'tag': tag,
        'name': _name.text.trim(),
        'sex': _sex == 'steer' ? 'male' : _sex,
        'castrated': _sex == 'steer',
        'stage': _stage ?? '',
        'breed': _breed ?? '',
        'source': _source,
        'birth_date': _born == null ? null : _day(_born!),
        'mother_id': _source == 'born' ? _mother : null,
        'sire': _sire.text.trim(),
        'rfid': _rfid.text.replaceAll(' ', ''),
        'cost': cost?.toString(),
      });
      // Its weight today is its first weighing (a failed weighing doesn't undo the animal).
      if (!res.error && kg != null && res.data is Map) {
        await FarmSetupService.weigh('${res.data['id']}', {'date': _day(DateTime.now()), 'kg': kg.toString()});
      }
      return res;
    }, done, next: (_) {
      if (_sequence && widget.index < widget.total) {
        // The next animal's form says this one was saved; a snack bar would cover its button.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AnimalForm(
                farmId: widget.farmId,
                kind: widget.kind,
                herdId: _herd,
                herdName: widget.herdName,
                index: widget.index + 1,
                total: widget.total,
                lastTag: tag),
          ),
          result: done,
        );
      } else {
        Navigator.pop(context, done);
      }
    });
  }

  /// Quick weights to start from, by what the animal is.
  List<(num, String)> get _presets => switch (_type) {
        'dairy_cattle' => [(280, 'Heifer'.tr), (420, 'Cow'.tr), (550, 'Bull'.tr)],
        'beef_cattle' => [(200, 'Weaner'.tr), (300, 'Grower'.tr), (450, 'Finished'.tr)],
        'dairy_goats' => [(15, 'Kid'.tr), (45, 'Doe'.tr), (60, 'Buck'.tr)],
        'sheep' => [(20, 'Lamb'.tr), (40, 'Ewe'.tr), (60, 'Ram'.tr)],
        'pigs' => [(30, 'Weaner'.tr), (70, 'Grower'.tr), (150, 'Sow'.tr)],
        'rabbits' => [(1.5, 'Young'.tr), (3, 'Doe'.tr), (4, 'Buck'.tr)],
        _ => const [],
      };

  static const _icons = (
    tag: '<path d="M12.586 2.586A2 2 0 0 0 11.172 2H4a2 2 0 0 0-2 2v7.172a2 2 0 0 0 .586 1.414l8.704 8.704a2.426 2.426 0 0 0 3.42 0l6.58-6.58a2.426 2.426 0 0 0 0-3.42z"/><circle cx="7.5" cy="7.5" r=".5"/>',
    next: '<path d="M21 12a9 9 0 1 1-9-9c2.52 0 4.93 1 6.74 2.74L21 8"/><path d="M21 3v5h-5"/>',
    paw: '<circle cx="11" cy="4" r="2"/><circle cx="18" cy="8" r="2"/><circle cx="20" cy="16" r="2"/><path d="M9 10a5 5 0 0 1 5 5v3.5a3.5 3.5 0 0 1-6.84 1.045Q6.52 17.48 4.46 16.84A3.5 3.5 0 0 1 5.5 10Z"/>',
    pulse: '<path d="M22 12h-2.48a2 2 0 0 0-1.93 1.46l-2.35 8.36a.25.25 0 0 1-.48 0L9.24 2.18a.25.25 0 0 0-.48 0l-2.35 8.36A2 2 0 0 1 4.49 12H2"/>',
    venus: '<path d="M12 15v7"/><path d="M9 19h6"/><circle cx="12" cy="9" r="6"/>',
    mars: '<path d="M16 3h5v5"/><path d="m21 3-6.75 6.75"/><circle cx="10" cy="14" r="6"/>',
    minus: '<path d="M5 12h14"/>',
    award: '<path d="m15.477 12.89 1.515 8.526a.5.5 0 0 1-.81.47l-3.58-2.687a1 1 0 0 0-1.197 0l-3.586 2.686a.5.5 0 0 1-.81-.469l1.514-8.526"/><circle cx="12" cy="8" r="6"/>',
    fork: '<circle cx="12" cy="18" r="3"/><circle cx="6" cy="6" r="3"/><circle cx="18" cy="6" r="3"/><path d="M18 9v2c0 .6-.4 1-1 1H7c-.6 0-1-.4-1-1V9"/><path d="M12 12v3"/>',
    house: '<path d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"/><path d="M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/>',
    scale: '<path d="m16 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="m2 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="M7 21h10"/><path d="M12 3v18"/><path d="M3 7h2c2 0 5-1 7-2 2 1 5 2 7 2h2"/>',
    save: '<path d="M15.2 3a2 2 0 0 1 1.4.6l3.8 3.8a2 2 0 0 1 .6 1.4V19a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z"/><path d="M17 21v-7a1 1 0 0 0-1-1H8a1 1 0 0 0-1 1v7"/><path d="M7 3v4a1 1 0 0 0 1 1h7"/>',
  );

  /// "Tag and sex are in. 5 of 8 details filled; the rest can wait."
  (bool, String) get _readiness {
    if (_tag.text.trim().isEmpty) return (false, 'Add the tag to save.'.tr);
    final stage = _stages != null && _female;
    final filled = [
      true, // tag
      true, // sex
      if (stage) _stage != null,
      _breed != null,
      _born != null,
      _source == 'born' ? _mother != null : _cost.text.trim().isNotEmpty,
      _sire.text.trim().isNotEmpty,
      _weight.text.trim().isNotEmpty,
      _name.text.trim().isNotEmpty,
    ];
    final n = filled.where((f) => f).length;
    return (true, 'Tag and sex are in. {n} of {total} details filled; the rest can wait.'.trArgs({'n': n, 'total': filled.length}));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final stages = _female ? _stages : null;
    final sexes = animalSexesShort(_type);
    final icons = _icons;
    final (ready, readyText) = _readiness;
    Widget label(String text, {bool required = false, bool optional = false, String? note}) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: text),
                  if (required) TextSpan(text: ' *', style: TextStyle(color: c.dangerInk)),
                  if (optional) TextSpan(text: ' ${'(optional)'.tr}', style: TextStyle(fontWeight: FontWeight.w400, color: c.textSecondary)),
                ]),
                style: AppType.label.copyWith(color: c.textPrimary),
              ),
            ),
            if (note != null) Flexible(child: Text(note, textAlign: TextAlign.end, style: AppType.caption.copyWith(color: c.textSecondary))),
          ]),
        );
    Widget under(String? error, String? hint) => error == null && hint == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(error ?? hint!, style: AppType.caption.copyWith(color: error != null ? c.dangerInk : c.textSecondary)),
          );
    Widget field(Widget box, String text, {bool required = false, bool optional = false, String? note, String? error, String? hint}) =>
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          label(text, required: required, optional: optional, note: note),
          box,
          under(error, hint),
        ]);

    return SlFormPage(
      eyebrow: 'ADD AN ANIMAL'.tr,
      title: _title,
      close: true,
      gap: 12,
      saving: saving,
      error: banner({'tag', 'name', 'sex', 'stage', 'castrated', 'breed', 'birth_date', 'mother_id', 'cost', 'kg', 'sire', 'rfid'}),
      saveLabel: 'Save animal'.tr,
      saveIcon: icons.save,
      onSave: _herds == null ? null : _save,
      children: [
        if (!_sequence && _herd != null) _severalStrip(c),
        _herdHead(c),
        SlSection(icon: icons.tag, title: 'IDENTIFICATION & TAGS'.tr, note: _lastTag == null ? null : 'Auto-suggested'.tr, noteGood: true, children: [
          field(
            SlFilledBox(
              controller: _tag,
              mono: true,
              placeholder: 'KE-0142',
              caps: TextCapitalization.characters,
              error: err('tag') != null,
              action: _NextButton(icon: icons.next, onTap: _bumpTag),
            ),
            'Tag or number'.tr,
            required: true,
            error: err('tag'),
            hint: _tagHint,
          ),
          field(
            SlFilledBox(controller: _name, icon: icons.paw, placeholder: 'e.g. Baraka, Mrembo, Chebet'.tr, caps: TextCapitalization.words),
            'Name'.tr,
            optional: true,
            error: err('name'),
          ),
          field(
            SlFilledBox(controller: _rfid, mono: true, number: true, fontSize: 17, placeholder: '15 digits'.tr, error: err('rfid') != null),
            'RFID'.tr,
            optional: true,
            error: err('rfid'),
          ),
        ]),
        SlSection(icon: icons.pulse, title: stages == null && _stages == null ? 'SEX'.tr : 'SEX & STAGE'.tr, children: [
          field(
            SlTiles<String>(
              options: [
                for (final (v, t) in sexes) (v, t, v == 'female' ? icons.venus : icons.mars),
                if (_beef) ('steer', 'Steer'.tr, icons.minus),
              ],
              value: _sex,
              columns: _beef ? 3 : 2,
              onChanged: _setSex,
            ),
            'Sex'.tr,
            required: true,
            error: err('sex') ?? err('castrated'),
          ),
          if (stages != null)
            field(SlSoftChoices<String>(options: stages, value: _stage, onChanged: (v) => setState(() => _stage = v)), 'Stage'.tr,
                optional: true, error: err('stage')),
        ]),
        if (_breeds.isNotEmpty)
          SlSection(icon: icons.award, title: 'BREED'.tr, note: 'Optional'.tr, children: [
            SlTiles<String>(
              options: [for (final b in _breeds) (b, b, null), ('Cross', 'Cross'.tr, null), ('', 'Other'.tr, null)],
              value: _breed,
              columns: 3,
              column: true,
              radio: true,
              onChanged: (v) => setState(() => _breed = v),
            ),
          ]),
        SlSection(icon: icons.fork, title: 'ORIGIN & LINEAGE'.tr, children: [
          SlTiles<String>(
            options: [('born', 'Born on the farm'.tr, icons.house), ('bought', 'Bought'.tr, _storeIcon)],
            value: _source,
            onChanged: (v) => setState(() => _source = v),
          ),
          if (_source == 'bought')
            field(SlFilledBox(controller: _cost, prefix: 'KSh'.tr, mono: true, number: true, fontSize: 19, error: err('cost') != null), 'Price paid'.tr,
                optional: true, error: err('cost')),
          field(
            SlFilledSelect(
              icon: SlSelectBox.calendar,
              text: _born == null ? 'Choose a date'.tr : _pretty(_born!),
              muted: _born == null,
              pill: _born == null ? null : _age(_born!),
              error: err('birth_date') != null,
              onTap: () async {
                final d = await _pickDate(context, _born ?? DateTime.now().subtract(const Duration(days: 365)));
                if (d != null) setState(() => _born = d);
              },
            ),
            'Date of birth'.tr,
            optional: true,
            error: err('birth_date'),
          ),
          if (_source == 'born' && _mothers.isNotEmpty)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: field(
                  SlFilledSelect(
                      icon: icons.venus, text: _motherTag ?? 'Choose'.tr, muted: _mother == null, error: err('mother_id') != null, onTap: _pickMother),
                  'Mother'.tr,
                  error: err('mother_id'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: field(SlFilledBox(controller: _sire, icon: icons.mars, placeholder: 'KE-012', fontSize: 15, caps: TextCapitalization.characters),
                    'Sire'.tr,
                    error: err('sire')),
              ),
            ])
          else
            field(SlFilledBox(controller: _sire, icon: icons.mars, placeholder: "Father's tag, or the AI straw name".tr, fontSize: 15),
                'Sire'.tr,
                optional: true,
                error: err('sire')),
          Text(
              _source == 'born' && _mothers.isNotEmpty
                  ? "Mother: the females in this herd. Sire: a male's tag, or the AI straw name.".tr
                  : 'Not in your herd? Write what the AI receipt says.'.tr,
              style: AppType.caption.copyWith(color: c.textSecondary)),
        ]),
        SlSection(icon: icons.scale, title: 'WEIGHT'.tr, note: 'Optional'.tr, children: [
          field(
            SlStepper(
              controller: _weight,
              unit: 'kg',
              step: _type == 'rabbits' ? 0.5 : 5,
              presets: _presets,
              error: err('kg') != null,
              onChanged: () => setState(() {}),
            ),
            _weightUp ? 'Weight when bought'.tr : 'Weight now'.tr,
            note: _weightUp ? 'To track gain from day one'.tr : 'Saved as the first weighing'.tr,
            error: err('kg'),
          ),
        ]),
        if (_note != null) SlInfoNote(_note!),
        SlReadyCard(ready: ready, text: readyText),
        if (_sequence && widget.index < widget.total)
          Text('Next: {unit} {i} of {n}'.trArgs({'unit': animalUnit(_type, 1), 'i': widget.index + 1, 'n': widget.total}),
              style: AppType.caption.copyWith(color: c.textSecondary)),
      ],
    );
  }

  /// "Next": the tag after the one in the box.
  void _bumpTag() {
    final next = nextTag(_tag.text.trim().isEmpty ? (_lastTag ?? 'KE-0') : _tag.text);
    if (next.isEmpty) return;
    setState(() {
      _tag.text = next;
      _suggested = next;
    });
  }

  String? get _motherTag => _mothers.where((m) => '${m['id']}' == _mother).map((m) => '${m['tag']}').firstOrNull;

  /// "Adding several cows at once? Herd entry →", on top: it is decided first.
  Widget _severalStrip(AppColors c) => SlCard(
        padding: EdgeInsets.zero,
        onTap: _several,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(children: [
            LineIcon(_strip, size: 20, color: c.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Text('Adding several {unit} at once?'.trArgs({'unit': animalUnit(_type, 2)}),
                  style: TextStyle(fontFamily: AppType.text, fontSize: 14, height: 18 / 14, color: c.textPrimary)),
            ),
            Text('Herd entry'.tr, style: TextStyle(fontFamily: AppType.text, fontSize: 13, fontWeight: FontWeight.w700, color: c.brandText)),
            const SizedBox(width: 4),
            LineIcon('<path d="M5 12h14"/><path d="m12 5 7 7-7 7"/>', size: 16, color: c.brandText),
          ]),
        ),
      );

  /// The herd it joins: its picture, the kind, the herd and its size, and Change.
  Widget _herdHead(AppColors c) => SlCard(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(14)),
            child: Center(child: Image.asset(fieldIcon(_type), width: 32, height: 32, excludeFromSemantics: true)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('HERD'.tr, style: AppType.eyebrow.copyWith(fontSize: 11, color: c.textSecondary)),
              Text(widget.kind.label, style: AppType.titleM.copyWith(fontWeight: FontWeight.w500, color: c.textPrimary)),
              Text(_meta, style: AppType.caption.copyWith(color: c.textSecondary)),
            ]),
          ),
          if (_herds != null && !_sequence)
            Material(
              color: c.surfaceMuted,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: _change,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Change'.tr, style: TextStyle(fontFamily: AppType.text, fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary)),
                    LineIcon('<path d="m6 9 6 6 6-6"/>', size: 16, color: c.textPrimary),
                  ]),
                ),
              ),
            ),
        ]),
      );
}

/// The "Next" key in the tag box: the next number on.
class _NextButton extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;
  const _NextButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: c.cardBackground,
      shape: StadiumBorder(side: BorderSide(color: c.border, width: 1.5)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            LineIcon(icon, size: 16, color: c.textPrimary),
            const SizedBox(width: 6),
            Text('Next'.tr, style: TextStyle(fontFamily: AppType.text, fontSize: 13, fontWeight: FontWeight.w700, color: c.textPrimary)),
          ]),
        ),
      ),
    );
  }
}

/// Screen 28, "Start a herd": which animals, the herd's name, when it started,
/// where it is kept and how many there are now (POST /herds). The herd starts
/// empty; then its animals are added by tag, a row each (quick herd entry).
class HerdForm extends StatefulWidget {
  final String farmId;
  final String initialType;
  const HerdForm({super.key, required this.farmId, this.initialType = 'dairy_cattle'});

  @override
  State<HerdForm> createState() => _HerdFormState();
}

class _HerdFormState extends State<HerdForm> with RecordForm {
  final _name = TextEditingController();
  final _count = TextEditingController();
  late String _type = widget.initialType;
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>>? _buildings;
  String? _building;
  bool _named = false; // the farmer typed their own name

  @override
  void initState() {
    super.initState();
    _name.text = _defaultName;
    _name.addListener(() {
      if (_name.text != _defaultName) _named = true;
    });
    _loadBuildings();
  }

  @override
  void dispose() {
    _name.dispose();
    _count.dispose();
    super.dispose();
  }

  String get _defaultName => FarmKind.of(_type)!.herdName;

  Future<void> _loadBuildings({String? pick}) async {
    final s = await FarmSetupService.structures(widget.farmId);
    if (!mounted) return;
    setState(() {
      _buildings = s.where((b) => b['type'] != 'pond').toList();
      if (pick != null) _building = pick;
    });
  }

  Future<void> _chooseBuilding() async {
    final list = _buildings ?? const [];
    if (list.isEmpty) return _addBuilding();
    final picked = await slPick<String>(context,
        title: 'Kept in'.tr, value: _building ?? '', options: [('', 'Not set'.tr), for (final b in list) ('${b['id']}', '${b['name']}')]);
    if (picked != null) setState(() => _building = picked.isEmpty ? null : picked);
  }

  Future<void> _addBuilding() async {
    final before = {for (final b in _buildings ?? const []) '${b['id']}'};
    if (await openRecord(context, StructureForm(farmId: widget.farmId, initialType: 'shed'))) {
      final all = await FarmSetupService.structures(widget.farmId);
      await _loadBuildings(pick: all.map((b) => '${b['id']}').where((id) => !before.contains(id)).firstOrNull);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final count = _num(_count);
    if (name.isEmpty) return fail('Give the herd a name.'.tr, 'name');
    if (count == null || count < 1) return fail('Enter how many you have now.'.tr, 'count');
    final done = '{name} started. Now add its animals.'.trArgs({'name': name});
    await save(
      () => FarmSetupService.startHerd({'farm_id': widget.farmId, 'type': _type, 'name': name, 'date': _day(_date), 'structure_id': _building}),
      done,
      next: (res) => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HerdEntryScreen(herdId: '${res.data['id']}', herdName: name, type: _type, rows: count.round().clamp(1, 200)),
        ),
        result: done,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _num(_count)?.round() ?? 2;
    final building = (_buildings ?? const []).where((b) => '${b['id']}' == _building).firstOrNull;
    return SlFormPage(
      eyebrow: 'ANIMALS'.tr,
      title: 'Start a herd'.tr,
      saving: saving,
      error: banner({'type', 'name', 'date', 'structure_id', 'count'}),
      saveLabel: 'Start herd'.tr,
      onSave: _save,
      children: [
        SlField(
          label: 'Animals'.tr,
          required: true,
          error: err('type'),
          child: SlChoices<String>(
            options: [for (final k in FarmKind.all.where((k) => k.herd)) (k.code, k.label)],
            value: _type,
            onChanged: (v) => setState(() {
              _type = v;
              if (!_named) _name.text = _defaultName;
            }),
          ),
        ),
        SlField(
          label: 'Herd name'.tr,
          required: true,
          error: err('name'),
          child: SlTextBox(controller: _name, caps: TextCapitalization.sentences, error: err('name') != null),
        ),
        SlField(
          label: 'Started on'.tr,
          required: true,
          error: err('date'),
          child: SlSelectBox(
            icon: SlSelectBox.calendar,
            text: _pretty(_date),
            onTap: () async {
              final d = await _pickDate(context, _date);
              if (d != null) setState(() => _date = d);
            },
          ),
        ),
        SlField(
          label: 'Kept in'.tr,
          optional: true,
          error: err('structure_id'),
          below: SlLink('Add a building'.tr, _addBuilding),
          child: SlSelectBox(
            icon: SlSelectBox.building,
            text: building == null ? 'Not set'.tr : '${building['name']}',
            muted: building == null,
            onTap: _chooseBuilding,
          ),
        ),
        SlField(
          label: 'How many you have now'.tr,
          required: true,
          hint: 'Next you can add each {unit} with its tag.'.trArgs({'unit': animalUnit(_type, 1)}),
          error: err('count'),
          child: SlTextBox(controller: _count, number: true, suffix: animalUnit(_type, count), error: err('count') != null),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SHARED PICKERS
// ═══════════════════════════════════════════════════════════

const _plotPath = '<path d="m12 8 6-3-6-3v10"/><path d="m8 11.99-5.5 3.14a1 1 0 0 0 0 1.74l8.5 4.86a2 2 0 0 0 2 0l8.5-4.86a1 1 0 0 0 0-1.74L16 12"/><path d="m6.49 12.85 11.02 6.3"/><path d="M17.51 12.85 6.5 19.15"/>';

String _acres(dynamic v) {
  final n = num.tryParse('${v ?? ''}');
  if (n == null) return '${v ?? ''}';
  return n == n.roundToDouble() ? n.round().toString() : n.toString().replaceAll(RegExp(r'0+$'), '');
}

String _acresText(dynamic v) {
  final a = _acres(v);
  return a == '1' ? '1 acre'.tr : '{n} acres'.trArgs({'n': a});
}

/// The farm's buildings or ponds as a select box with "Add a …": [kinds] picks
/// which (ponds for fish, the rest for animals and birds).
mixin _Places<T extends StatefulWidget> on State<T> {
  List<Map<String, dynamic>>? places;
  String? place;

  String get placesFarm;
  bool placeFits(Map<String, dynamic> s);

  Future<void> loadPlaces({String? pick}) async {
    final s = await FarmSetupService.structures(placesFarm);
    if (!mounted) return;
    setState(() {
      places = s.where(placeFits).toList();
      if (pick != null) place = pick;
    });
  }

  Future<void> choosePlace(String title, {bool optional = true}) async {
    final list = places ?? const [];
    final picked = await slPick<String>(context,
        title: title, value: place ?? '', options: [if (optional) ('', 'Not set'.tr), for (final b in list) ('${b['id']}', '${b['name']}')]);
    if (picked != null) setState(() => place = picked.isEmpty ? null : picked);
  }

  Future<void> addPlace(String type) async {
    final before = {for (final b in places ?? const []) '${b['id']}'};
    if (await openRecord(context, StructureForm(farmId: placesFarm, initialType: type))) {
      final all = await FarmSetupService.structures(placesFarm);
      await loadPlaces(pick: all.map((b) => '${b['id']}').where((id) => !before.contains(id)).firstOrNull);
    }
  }

  String? get placeName => (places ?? const []).where((b) => '${b['id']}' == place).map((b) => '${b['name']}').firstOrNull;
}

// ═══════════════════════════════════════════════════════════
// BIRDS AND FISH (screens 35–37)
// ═══════════════════════════════════════════════════════════

/// Screens 35–37, "New layers batch", "New broiler batch" and "Stock a pond"
/// (POST /batches).
class BatchForm extends StatefulWidget {
  final String farmId;
  final FarmKind kind;
  const BatchForm({super.key, required this.farmId, required this.kind});

  @override
  State<BatchForm> createState() => _BatchFormState();
}

class _BatchFormState extends State<BatchForm> with RecordForm, _Places {
  final _name = TextEditingController();
  final _count = TextEditingController();
  final _weeks = TextEditingController();
  final _source = TextEditingController();
  final _cost = TextEditingController();
  DateTime _date = DateTime.now();
  String _age = 'day_old'; // day_old | point_of_lay | other
  bool _older = false; // broilers: "they came older"
  String? _breed;

  bool get _fish => widget.kind.code == 'fish';
  bool get _layers => widget.kind.code == 'layers';

  @override
  String get placesFarm => widget.farmId;
  @override
  bool placeFits(Map<String, dynamic> s) => _fish ? s['type'] == 'pond' : s['type'] != 'pond';

  @override
  void initState() {
    super.initState();
    _name.text = _fish
        ? 'Pond, {date}'.trArgs({'date': DateFormat('MMM yyyy').format(DateTime.now())})
        : '{kind}, {date}'.trArgs({'kind': widget.kind.label, 'date': DateFormat('MMM yyyy').format(DateTime.now())});
    if (_fish) _breed = 'Tilapia';
    loadPlaces();
  }

  @override
  void dispose() {
    for (final c in [_name, _count, _weeks, _source, _cost]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _breeds => switch (widget.kind.code) {
        'layers' => ['Kenbro', 'Kuroiler', 'Isa Brown', 'Hy-Line'],
        'broilers' => ['Cobb 500', 'Ross 308', 'Arbor Acres'],
        'fish' => ['Tilapia', 'Catfish'],
        _ => [],
      };

  int get _ageDays {
    final weeks = ((_num(_weeks) ?? 0) * 7).round();
    if (_fish) return weeks;
    if (!_layers) return _older ? weeks : 0;
    return switch (_age) { 'point_of_lay' => 18 * 7, 'other' => weeks, _ => 0 };
  }

  Future<void> _save() async {
    final count = _num(_count);
    if (_name.text.trim().isEmpty) return fail('Give the batch a name.'.tr, 'name');
    if (count == null || count < 1) return fail(_fish ? 'Enter how many fish.'.tr : 'Enter how many birds.'.tr, 'count');
    if (_fish && place == null) return fail('Choose the pond, or add one.'.tr, 'structure_id');
    await save(
        () => FarmSetupService.startBatch({
              'farm_id': widget.farmId,
              'type': widget.kind.code,
              'name': _name.text.trim(),
              'count': count.round(),
              'date': _day(_date),
              'age_days': _ageDays,
              'breed': _breed ?? '',
              'source': _source.text.trim(),
              'cost': _cost.text.trim().isEmpty ? null : _num(_cost)?.toString(),
              'structure_id': place,
            }),
        '{name} started'.trArgs({'name': _name.text.trim()}));
  }

  @override
  Widget build(BuildContext context) {
    final count = _num(_count)?.round() ?? 2;
    final pond = _fish;
    return SlFormPage(
      eyebrow: pond ? 'FISH'.tr : 'BIRDS'.tr,
      title: pond ? 'Stock a pond'.tr : (_layers ? 'New layers batch'.tr : 'New broiler batch'.tr),
      saving: saving,
      error: banner({'name', 'count', 'date', 'age_days', 'source', 'cost', 'structure_id', 'breed'}),
      saveLabel: pond ? 'Stock pond'.tr : 'Start batch'.tr,
      onSave: _save,
      children: [
        SlTypeHead(
          icon: Image.asset(fieldIcon(widget.kind.code), width: 28, height: 28, excludeFromSemantics: true),
          title: widget.kind.label,
          meta: pond ? 'Counted by pond'.tr : (_layers ? 'Kept for eggs'.tr : 'Kept for meat'.tr),
          onChange: () => Navigator.maybePop(context),
        ),
        if (pond)
          SlField(
            label: 'Fish'.tr,
            required: true,
            child: SlChoices<String>(options: [for (final b in _breeds) (b, b)], value: _breed, onChanged: (v) => setState(() => _breed = v)),
          )
        else ...[
          SlField(
            label: 'Batch name'.tr,
            required: true,
            error: err('name'),
            child: SlTextBox(controller: _name, caps: TextCapitalization.sentences, error: err('name') != null),
          ),
          SlField(
            label: 'Breed'.tr,
            optional: true,
            child: SlChoices<String>(options: [for (final b in _breeds) (b, b)], value: _breed, onChanged: (v) => setState(() => _breed = v)),
          ),
        ],
        if (pond)
          SlField(
            label: 'Pond'.tr,
            required: true,
            error: err('structure_id'),
            below: SlLink('Add a pond'.tr, () => addPlace('pond')),
            child: SlSelectBox(
              icon: SlSelectBox.building,
              text: placeName ?? ((places?.isEmpty ?? false) ? 'No ponds yet'.tr : 'Choose the pond'.tr),
              muted: placeName == null,
              error: err('structure_id') != null,
              onTap: () => (places?.isEmpty ?? true) ? addPlace('pond') : choosePlace('Pond'.tr, optional: false),
            ),
          ),
        SlField(
          label: pond ? 'Fingerlings stocked'.tr : (_layers ? 'Number of birds'.tr : 'Number of chicks'.tr),
          required: true,
          error: err('count'),
          child: SlTextBox(
            controller: _count,
            number: true,
            suffix: pond ? 'fish'.tr : (_layers ? 'birds'.tr : (count == 1 ? 'chick'.tr : 'chicks'.tr)),
            error: err('count') != null,
          ),
        ),
        if (pond)
          SlField(label: 'Age of the fingerlings'.tr, optional: true, child: SlTextBox(controller: _weeks, number: true, suffix: 'weeks'.tr))
        else if (_layers) ...[
          SlField(
            label: 'Age when they came'.tr,
            required: true,
            hint: 'Vaccination reminders follow this age.'.tr,
            error: err('age_days'),
            child: SlChoices<String>(
              options: [('day_old', 'Day-old chicks'.tr), ('point_of_lay', 'Point of lay'.tr), ('other', 'Other age'.tr)],
              value: _age,
              onChanged: (v) => setState(() => _age = v),
            ),
          ),
          if (_age == 'other') SlField(label: 'Age in weeks'.tr, child: SlTextBox(controller: _weeks, number: true, suffix: 'weeks'.tr)),
        ],
        SlField(
          label: pond ? 'Stocked on'.tr : (_layers ? 'Started on'.tr : 'Arrived on'.tr),
          required: true,
          hint: !pond && !_layers && !_older ? 'Taken as day-old. Change it if they came older.'.tr : null,
          error: err('date'),
          below: !pond && !_layers && !_older ? SlLink('They came older'.tr, () => setState(() => _older = true)) : null,
          child: SlSelectBox(
            icon: SlSelectBox.calendar,
            text: _pretty(_date),
            onTap: () async {
              final d = await _pickDate(context, _date);
              if (d != null) setState(() => _date = d);
            },
          ),
        ),
        if (!pond && !_layers && _older)
          SlField(label: 'Age when they came'.tr, child: SlTextBox(controller: _weeks, number: true, suffix: 'weeks'.tr)),
        if (!pond)
          SlField(
            label: 'Kept in'.tr,
            optional: true,
            error: err('structure_id'),
            below: SlLink('Add a poultry house'.tr, () => addPlace('poultry_house')),
            child: SlSelectBox(
              icon: SlSelectBox.building,
              text: placeName ?? 'Not set'.tr,
              muted: placeName == null,
              onTap: () => (places?.isEmpty ?? true) ? addPlace('poultry_house') : choosePlace('Kept in'.tr),
            ),
          ),
        if (!_layers)
          SlField(
            label: pond ? 'Where they came from'.tr : 'Hatchery'.tr,
            optional: true,
            error: err('source'),
            child: SlTextBox(controller: _source, caps: TextCapitalization.words),
          ),
        SlField(
          label: pond ? 'Cost'.tr : 'Cost of the chicks'.tr,
          optional: true,
          hint: _layers ? "Counted as the batch's first cost.".tr : null,
          error: err('cost'),
          child: SlTextBox(controller: _cost, prefix: 'KSh'.tr, number: true, error: err('cost') != null),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CROPS AND FRUIT TREES (screens 38–46)
// ═══════════════════════════════════════════════════════════

/// Screens 38–46: "New maize season" and the other crops, "Add bananas" and
/// "Add avocados" (POST /seasons). An orchard is started the same way, with its
/// trees and what it was planted from.
class CropForm extends StatefulWidget {
  final String farmId;
  final FarmKind kind;
  const CropForm({super.key, required this.farmId, required this.kind});

  @override
  State<CropForm> createState() => _CropFormState();
}

class _CropFormState extends State<CropForm> with RecordForm {
  final _area = TextEditingController();
  final _plants = TextEditingController();
  final _name = TextEditingController();
  List<Map<String, dynamic>>? _plots;
  String? _plot;
  String? _variety;
  String? _from;
  DateTime _date = DateTime.now();

  String get _code => widget.kind.code;
  bool get _orchard => widget.kind.orchard;

  @override
  void initState() {
    super.initState();
    _name.text = _defaultName;
    _loadPlots();
  }

  @override
  void dispose() {
    for (final c in [_area, _plants, _name]) {
      c.dispose();
    }
    super.dispose();
  }

  /// "Maize, short rains 2026", "Tomatoes, Oct 2026", "Wheat 2026".
  String get _defaultName {
    final now = DateTime.now();
    final label = _code == 'kales' ? 'Sukuma'.tr : widget.kind.label;
    if (_orchard) return '{kind} orchard'.trArgs({'kind': label});
    if (_code == 'maize' || _code == 'beans') {
      final long = now.month >= 3 && now.month <= 8;
      return long
          ? '{kind}, long rains {year}'.trArgs({'kind': label, 'year': now.year})
          : '{kind}, short rains {year}'.trArgs({'kind': label, 'year': now.year});
    }
    if (_code == 'wheat') return '{kind} {year}'.trArgs({'kind': label, 'year': now.year});
    if (_code == 'rice') return '{kind}, main crop {year}'.trArgs({'kind': label, 'year': now.year});
    return '{kind}, {date}'.trArgs({'kind': label, 'date': DateFormat('MMM yyyy').format(now)});
  }

  Future<void> _loadPlots({String? pick}) async {
    final p = await FarmSetupService.plots(widget.farmId);
    if (!mounted) return;
    setState(() {
      _plots = p;
      _plot = pick != null && p.any((x) => '${x['id']}' == pick) ? pick : (_plot ?? (p.isEmpty ? null : '${p.first['id']}'));
    });
  }

  Future<void> _addPlot() async {
    final before = {for (final p in _plots ?? const []) '${p['id']}'};
    if (await openRecord(context, PlotForm(farmId: widget.farmId))) {
      final p = await FarmSetupService.plots(widget.farmId);
      await _loadPlots(pick: p.map((x) => '${x['id']}').where((id) => !before.contains(id)).firstOrNull);
    }
  }

  Future<void> _choosePlot() async {
    final plots = _plots ?? const [];
    if (plots.isEmpty) return _addPlot();
    final picked = await slPick<String>(context,
        title: 'Plot'.tr, value: _plot, options: [for (final p in plots) ('${p['id']}', '${p['name']} · ${_acresText(p['area_acres'])}')]);
    if (picked != null) setState(() => _plot = picked);
  }

  List<String> get _varieties => switch (_code) {
        'maize' => ['H614D', 'DH04', 'SC Duma 43', 'WH505'],
        'beans' => ['Rosecoco', 'Mwitemania', 'KK8', 'Nyota'],
        'rice' => ['Basmati 370', 'IR 2793', 'Komboka'],
        'wheat' => ['Kenya Robin', 'Eagle 10', 'Kingbird'],
        'tomatoes' => ['Anna F1', 'Kilele F1', 'Rio Grande', 'Cal J'],
        'kales' => ['Thousand-headed', 'Southern Georgia', 'Mfalme F1'],
        'spinach' => ['Fordhook Giant', 'Malabar'],
        'bananas' => ['Williams', 'Grand Nain', 'FHIA-17', 'Uganda Green'],
        'avocados' => ['Hass', 'Fuerte', 'Pinkerton'],
        _ => [],
      };

  List<(String, String)> get _froms => switch (_code) {
        'bananas' => [('tissue_culture', 'Tissue culture'.tr), ('suckers', 'Suckers'.tr)],
        'avocados' => [('grafted', 'Grafted seedlings'.tr), ('seed', 'Seed'.tr)],
        _ => [],
      };

  String get _dateLabel => switch (_code) {
        'rice' || 'tomatoes' || 'kales' => 'Transplanted on'.tr,
        'wheat' || 'spinach' => 'Sown on'.tr,
        _ => 'Planted on'.tr,
      };

  String? get _note => switch (_code) {
        'maize' => "Shamba OS lists the season's field jobs from the planting date.".tr,
        'rice' => 'Use the day the seedlings went into the paddy, not the nursery day.'.tr,
        'tomatoes' => 'Use the day the seedlings went from the nursery into the ground.'.tr,
        'kales' => 'Kales are picked many times. Record each picking as a harvest.'.tr,
        'avocados' => 'Grafted trees usually start bearing in 3 to 4 years.'.tr,
        _ => null,
      };

  String get _title => switch (_code) {
        'maize' => 'New maize season'.tr,
        'beans' => 'New beans season'.tr,
        'rice' => 'New rice season'.tr,
        'wheat' => 'New wheat season'.tr,
        'tomatoes' => 'New tomatoes season'.tr,
        'kales' => 'New sukuma (kales) season'.tr,
        'spinach' => 'New spinach season'.tr,
        'bananas' => 'Add bananas'.tr,
        'avocados' => 'Add avocados'.tr,
        _ => widget.kind.label,
      };

  Future<void> _save() async {
    final area = _num(_area);
    if (_plot == null) return fail('Choose a plot, or add one.'.tr, 'plot_id');
    if (area == null || area <= 0) return fail('Enter the area planted.'.tr, 'area_acres');
    final plants = _num(_plants);
    if (_orchard && (plants == null || plants < 1)) {
      return fail(_code == 'bananas' ? 'Enter how many stools.'.tr : 'Enter how many trees.'.tr, 'plant_count');
    }
    if (_name.text.trim().isEmpty) return fail('Give the season a name.'.tr, 'name');
    await save(
        () => FarmSetupService.startSeason({
              'farm_id': widget.farmId,
              'type': _code,
              'plot_id': _plot,
              'area_acres': area.toString(),
              'variety': _variety ?? '',
              'plant_count': plants?.round(),
              'planted_from': _from ?? '',
              'date': _day(_date),
              'name': _name.text.trim(),
            }),
        '{name} started'.trArgs({'name': _name.text.trim()}));
  }

  @override
  Widget build(BuildContext context) {
    final plots = _plots;
    final plot = (plots ?? const []).where((p) => '${p['id']}' == _plot).firstOrNull;
    return SlFormPage(
      eyebrow: _orchard ? 'FRUIT TREES'.tr : 'CROPS'.tr,
      title: _title,
      saving: saving,
      error: banner({'plot_id', 'area_acres', 'plant_count', 'variety', 'planted_from', 'date', 'name'}),
      saveLabel: _orchard ? 'Save orchard'.tr : 'Start season'.tr,
      onSave: plots == null ? null : _save,
      children: [
        SlTypeHead(
          icon: Image.asset(fieldIcon(_code, crop: true), width: 28, height: 28, excludeFromSemantics: true),
          title: widget.kind.label,
          meta: _orchard ? 'Fruit trees on one plot'.tr : 'One season on one plot'.tr,
          onChange: () => Navigator.maybePop(context),
        ),
        SlField(
          label: 'Plot'.tr,
          required: true,
          error: err('plot_id'),
          below: SlLink('Add a plot'.tr, _addPlot),
          child: SlSelectBox(
            icon: _plotPath,
            text: plot == null
                ? (plots == null ? 'Loading your plots…'.tr : 'No plots yet. Add one.'.tr)
                : '${plot['name']} · ${_acresText(plot['area_acres'])}',
            muted: plot == null,
            error: err('plot_id') != null,
            onTap: _choosePlot,
          ),
        ),
        SlField(
          label: _orchard ? 'Area'.tr : 'Area planted'.tr,
          required: true,
          hint: plot == null ? null : 'Up to {area} on this plot.'.trArgs({'area': _acresText(plot['area_acres'])}),
          error: err('area_acres'),
          child: SlTextBox(controller: _area, number: true, suffix: 'acres'.tr, error: err('area_acres') != null),
        ),
        if (_orchard)
          SlField(
            label: _code == 'bananas' ? 'Number of stools'.tr : 'Number of trees'.tr,
            required: true,
            hint: _code == 'bananas' ? 'A stool is the mother plant with its suckers.'.tr : 'Count the trees you planted, even young ones.'.tr,
            error: err('plant_count'),
            child: SlTextBox(
                controller: _plants, number: true, suffix: _code == 'bananas' ? 'stools'.tr : 'trees'.tr, error: err('plant_count') != null),
          ),
        if (_varieties.isNotEmpty)
          SlField(
            label: 'Variety'.tr,
            optional: true,
            child: SlChoices<String>(
                options: [for (final v in _varieties) (v, v)], value: _variety, onChanged: (v) => setState(() => _variety = v == _variety ? null : v)),
          ),
        if (_froms.isNotEmpty)
          SlField(
            label: 'Planted from'.tr,
            optional: true,
            error: err('planted_from'),
            child: SlChoices<String>(options: _froms, value: _from, onChanged: (v) => setState(() => _from = v == _from ? null : v)),
          ),
        SlField(
          label: _dateLabel,
          required: true,
          hint: _orchard ? 'The month is enough for older trees.'.tr : null,
          error: err('date'),
          child: SlSelectBox(
            icon: SlSelectBox.calendar,
            text: _orchard ? DateFormat('MMM yyyy').format(_date) : _pretty(_date),
            onTap: () async {
              final d = await _pickDate(context, _date, yearsBack: 40);
              if (d != null) setState(() => _date = d);
            },
          ),
        ),
        if (!_orchard)
          SlField(
            label: 'Season name'.tr,
            required: true,
            error: err('name'),
            child: SlTextBox(controller: _name, caps: TextCapitalization.sentences, error: err('name') != null),
          ),
        if (_note != null) SlInfoNote(_note!),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// LAND, BUILDINGS AND PEOPLE (screens 47–51)
// ═══════════════════════════════════════════════════════════

/// Screen 47, "Add a plot" (POST /plots).
class PlotForm extends StatefulWidget {
  final String farmId;
  const PlotForm({super.key, required this.farmId});

  @override
  State<PlotForm> createState() => _PlotFormState();
}

class _PlotFormState extends State<PlotForm> with RecordForm {
  final _name = TextEditingController();
  final _area = TextEditingController();
  final _lease = TextEditingController();
  String _tenure = 'owned';

  @override
  void dispose() {
    for (final c in [_name, _area, _lease]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final area = _num(_area);
    if (_name.text.trim().isEmpty) return fail('Give the plot a name.'.tr, 'name');
    if (area == null || area <= 0) return fail('Enter an area greater than zero.'.tr, 'area_acres');
    await save(
        () => FarmSetupService.addPlot({
              'farm_id': widget.farmId,
              'name': _name.text.trim(),
              'area_acres': area.toString(),
              'tenure': _tenure,
              'lease_cost': _tenure == 'leased' && _lease.text.trim().isNotEmpty ? _num(_lease)?.toString() : null,
            }),
        '{name} added'.trArgs({'name': _name.text.trim()}));
  }

  @override
  Widget build(BuildContext context) {
    return SlFormPage(
      eyebrow: 'LAND'.tr,
      title: 'Add a plot'.tr,
      saving: saving,
      error: banner({'name', 'area_acres', 'tenure', 'lease_cost'}),
      saveLabel: 'Save plot'.tr,
      onSave: _save,
      children: [
        SlField(
          label: 'Plot name'.tr,
          required: true,
          hint: 'What you call it, like Near the river.'.tr,
          error: err('name'),
          child: SlTextBox(controller: _name, caps: TextCapitalization.sentences, error: err('name') != null),
        ),
        SlField(
          label: 'Size'.tr,
          required: true,
          hint: '1 acre is about 63 by 63 metres.'.tr,
          error: err('area_acres'),
          child: SlTextBox(controller: _area, number: true, suffix: 'acres'.tr, error: err('area_acres') != null),
        ),
        SlField(
          label: 'Who owns the land'.tr,
          error: err('tenure'),
          child: SlChoices<String>(
            options: [('owned', 'Owned'.tr), ('leased', 'Leased'.tr), ('family', 'Family land'.tr)],
            value: _tenure,
            onChanged: (v) => setState(() => _tenure = v),
          ),
        ),
        if (_tenure == 'leased')
          SlField(
            label: 'Lease cost'.tr,
            optional: true,
            hint: "What you pay for this land. Counted in the crop's costs.".tr,
            error: err('lease_cost'),
            child: SlTextBox(controller: _lease, prefix: 'KSh'.tr, number: true, error: err('lease_cost') != null),
          ),
      ],
    );
  }
}

/// Screen 48, "Add a building or pond" (POST /structures).
class StructureForm extends StatefulWidget {
  final String farmId;
  final String initialType;
  const StructureForm({super.key, required this.farmId, this.initialType = 'poultry_house'});

  @override
  State<StructureForm> createState() => _StructureFormState();
}

class _StructureFormState extends State<StructureForm> with RecordForm {
  final _name = TextEditingController();
  final _capacity = TextEditingController();
  late String _type = widget.initialType;

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return fail('Give it a name.'.tr, 'name');
    await save(
        () => FarmSetupService.addStructure({
              'farm_id': widget.farmId,
              'name': _name.text.trim(),
              'type': _type,
              'capacity': _capacity.text.trim().isEmpty ? null : _num(_capacity)?.round(),
            }),
        '{name} added'.trArgs({'name': _name.text.trim()}));
  }

  @override
  Widget build(BuildContext context) {
    return SlFormPage(
      eyebrow: 'BUILDINGS'.tr,
      title: 'Add a building or pond'.tr,
      saving: saving,
      error: banner({'name', 'type', 'capacity'}),
      saveLabel: _type == 'pond' ? 'Save pond'.tr : 'Save building'.tr,
      onSave: _save,
      children: [
        SlField(
          label: 'What is it'.tr,
          required: true,
          error: err('type'),
          child: SlChoices<String>(
            options: [('shed', 'Shed'.tr), ('poultry_house', 'Poultry house'.tr), ('pen', 'Pen'.tr), ('pond', 'Pond'.tr), ('store', 'Store'.tr)],
            value: _type,
            onChanged: (v) => setState(() => _type = v),
          ),
        ),
        SlField(
          label: 'Name'.tr,
          required: true,
          error: err('name'),
          child: SlTextBox(controller: _name, caps: TextCapitalization.sentences, error: err('name') != null),
        ),
        if (_type != 'store')
          SlField(
            label: 'How many it holds'.tr,
            optional: true,
            error: err('capacity'),
            child: SlTextBox(
              controller: _capacity,
              number: true,
              suffix: _type == 'pond' ? 'fish'.tr : (_type == 'poultry_house' ? 'birds'.tr : 'animals'.tr),
              error: err('capacity') != null,
            ),
          ),
      ],
    );
  }
}

/// A phone number as the API takes it from the "+254" box: "722 118 409" → "+254722118409".
String _phone(TextEditingController c) {
  var digits = c.text.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  if (digits.startsWith('254')) digits = digits.substring(3);
  if (digits.startsWith('0')) digits = digits.substring(1);
  return '+254$digits';
}

/// Screen 49, "Add a customer" (POST /customers).
class CustomerForm extends StatefulWidget {
  const CustomerForm({super.key});

  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> with RecordForm {
  final _name = TextEditingController();
  final _phoneBox = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phoneBox.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return fail('Enter a name.'.tr, 'name');
    await save(() => CustomerService.createCustomer(name: name, phone: _phone(_phoneBox)), 'Customer added'.tr);
  }

  @override
  Widget build(BuildContext context) {
    return SlFormPage(
      eyebrow: 'SALES'.tr,
      title: 'Add a customer'.tr,
      saving: saving,
      error: banner({'name', 'phone'}),
      saveLabel: 'Save customer'.tr,
      onSave: _save,
      children: [
        SlField(
          label: 'Name'.tr,
          required: true,
          error: err('name'),
          child: SlTextBox(controller: _name, caps: TextCapitalization.words, error: err('name') != null),
        ),
        SlField(
          label: 'Phone number'.tr,
          optional: true,
          error: err('phone'),
          child: SlTextBox(controller: _phoneBox, prefix: '+254', mono: true, number: true, error: err('phone') != null),
        ),
        SlInfoNote('What they owe you is worked out from sales they have not paid for yet.'.tr),
      ],
    );
  }
}

/// Screen 50, "Add a supplier" (POST /suppliers), with what the farm buys from them.
class SupplierForm extends StatefulWidget {
  const SupplierForm({super.key});

  @override
  State<SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<SupplierForm> with RecordForm {
  final _name = TextEditingController();
  final _phoneBox = TextEditingController();
  final _buys = <String>{};

  @override
  void dispose() {
    _name.dispose();
    _phoneBox.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return fail('Enter a name.'.tr, 'name');
    await save(
        () => FarmSetupService.addSupplier({'name': _name.text.trim(), 'phone': _phone(_phoneBox), 'supplies': _buys.toList()}),
        'Supplier added'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final supplies = [('feed', 'Feed'.tr), ('chicks', 'Chicks'.tr), ('medicine', 'Medicine'.tr), ('seed', 'Seed'.tr), ('fertiliser', 'Fertiliser'.tr)];
    return SlFormPage(
      eyebrow: 'PURCHASES'.tr,
      title: 'Add a supplier'.tr,
      saving: saving,
      error: banner({'name', 'phone', 'supplies'}),
      saveLabel: 'Save supplier'.tr,
      onSave: _save,
      children: [
        SlField(
          label: 'Name'.tr,
          required: true,
          error: err('name'),
          child: SlTextBox(controller: _name, caps: TextCapitalization.words, error: err('name') != null),
        ),
        SlField(
          label: 'Phone number'.tr,
          optional: true,
          error: err('phone'),
          child: SlTextBox(controller: _phoneBox, prefix: '+254', mono: true, number: true, error: err('phone') != null),
        ),
        SlField(
          label: 'What you buy from them'.tr,
          optional: true,
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (code, label) in supplies)
              SlChip(label, selected: _buys.contains(code), onTap: () => setState(() => _buys.contains(code) ? _buys.remove(code) : _buys.add(code))),
          ]),
        ),
        SlInfoNote('What you owe them is worked out from purchases you have not paid for yet.'.tr),
      ],
    );
  }
}

/// Screen 51, "Invite to your farm" (POST /invitations).
class TeamForm extends StatefulWidget {
  const TeamForm({super.key});

  @override
  State<TeamForm> createState() => _TeamFormState();
}

class _TeamFormState extends State<TeamForm> with RecordForm {
  final _phoneBox = TextEditingController();
  String _role = 'field_worker';

  static const _manager = '<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><path d="M16 3.128a4 4 0 0 1 0 7.744"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><circle cx="9" cy="7" r="4"/>';
  static const _worker = '<path d="m10 11 11 .9a1 1 0 0 1 .8 1.1l-.665 4.158a1 1 0 0 1-.988.842H20"/><path d="M16 18h-5"/><path d="M18 5a1 1 0 0 0-1 1v5.573"/><path d="M3 4h8.129a1 1 0 0 1 .99.863L13 11.246"/><path d="M4 11V4"/><path d="M7 15h.01"/><path d="M8 10.1V4"/><circle cx="18" cy="18" r="2"/><circle cx="7" cy="15" r="5"/>';

  @override
  void dispose() {
    _phoneBox.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final phone = _phone(_phoneBox);
    if (phone.isEmpty) return fail('Enter their phone number.'.tr, 'phone');
    await save(() => FarmSetupService.invite({'phone': phone, 'role': _role}), 'Invitation sent'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    Widget role(String value, String icon, String title, String meta) {
      final picked = _role == value;
      return SlIconRow(
        icon: icon,
        title: title,
        meta: meta,
        onTap: () => setState(() => _role = value),
        end: Semantics(
          selected: picked,
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: picked ? c.brandSoft : c.cardBackground,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: picked ? c.brandText : c.border, width: 1.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (picked) ...[LineIcon('<path d="M20 6 9 17l-5-5"/>', size: 16, color: c.brandText), const SizedBox(width: 4)],
              Text(picked ? 'Picked'.tr : 'Pick'.tr,
                  style: TextStyle(fontFamily: AppType.text, fontSize: 13, fontWeight: FontWeight.w700, color: picked ? c.brandText : c.textPrimary)),
            ]),
          ),
        ),
      );
    }

    return SlFormPage(
      eyebrow: 'TEAM'.tr,
      title: 'Invite to your farm'.tr,
      saving: saving,
      error: banner({'phone', 'role'}),
      saveLabel: 'Send invitation'.tr,
      onSave: _save,
      children: [
        SlField(
          label: 'Their phone number'.tr,
          required: true,
          hint: 'They join the next time they sign in with this number.'.tr,
          error: err('phone'),
          child: SlTextBox(controller: _phoneBox, prefix: '+254', mono: true, number: true, error: err('phone') != null),
        ),
        SlField(
          label: 'What they can do'.tr,
          required: true,
          error: err('role'),
          child: SlCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              role('manager', _manager, 'Manager'.tr, 'Records, stock, sales, purchases, money and the team'.tr),
              Divider(height: 1, thickness: 1, color: c.divider),
              role('field_worker', _worker, 'Field worker'.tr, 'Daily records and seeing stock. No money.'.tr),
            ]),
          ),
        ),
        SlInfoNote("The invitation ends after a while if they don't sign in. You can send it again.".tr),
      ],
    );
  }
}
