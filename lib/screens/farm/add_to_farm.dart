import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger_parts.dart';
import '../../widgets/phosphor_icons.dart';
import '../auth/auth_ui.dart';
import '../customers/customer_screen.dart';
import '../fields/field_widgets.dart';
import '../records/record_form.dart';
import 'farm_setup_service.dart';
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

  /// A new herd, then its first animal, as the design's Start herd leads to Add a cow.
  Future<void> _newHerd() async {
    String? type;
    await _open(HerdForm(farmId: _farmId, onStarted: (t) => type = t), then: () async {
      final k = type == null ? null : FarmKind.of(type!);
      if (k != null && mounted) await _open(AnimalForm(farmId: _farmId, kind: k));
    });
  }

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
              if (note != null) Text(note, style: AppType.caption.copyWith(color: c.textSecondary)),
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
                _Pick(label: 'Customer'.tr, icon: LineIcon(_storeIcon, size: 22, color: c.brandText), onTap: () => _open(const AddCustomerScreen())),
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

/// The kind being added, with its icon (the design's type-head).
class _KindHead extends StatelessWidget {
  final FarmKind kind;
  final String note;
  const _KindHead(this.kind, this.note);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return SlCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
          child: Center(child: Image.asset(fieldIcon(kind.code, crop: kind.crop), width: 28, height: 28, excludeFromSemantics: true)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(kind.label,
                style: TextStyle(fontFamily: AppType.text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
            Text(note, style: AppType.caption.copyWith(color: c.textSecondary)),
          ]),
        ),
      ]),
    );
  }
}

/// A tinted note in a form.
class _Note extends StatelessWidget {
  final String text;
  const _Note(this.text);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(color: c.rainTint, borderRadius: BorderRadius.circular(24)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(PhosphorIconsRegular.info, size: 20, color: c.rainInk),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppType.caption.copyWith(color: c.textPrimary))),
      ]),
    );
  }
}

/// A quiet link under a field: "Add a plot".
class _Link extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _Link(this.text, this.onTap);

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(minimumSize: const Size(0, 32), padding: const EdgeInsets.symmetric(horizontal: 4)),
          child: Text(text,
              style: TextStyle(fontFamily: AppType.text, fontSize: 14, fontWeight: FontWeight.w700, color: context.appColors.brandText)),
        ),
      );
}

/// Buildings (or ponds) to keep something in, with "Add a building" to make one.
class _KeptIn extends StatelessWidget {
  final List<Map<String, dynamic>>? options;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String addLabel;
  final VoidCallback onAdd;
  final String? errorText;
  const _KeptIn({required this.options, required this.value, required this.onChanged, required this.addLabel, required this.onAdd, this.errorText});

  @override
  Widget build(BuildContext context) {
    final list = options;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (list == null)
        const LinearProgressIndicator(minHeight: 2)
      else if (list.isNotEmpty)
        RecordChoices<String?>(
          label: '${'Kept in'.tr} ${'(optional)'.tr}',
          options: [(null, 'Not set'.tr), for (final s in list) ('${s['id']}', '${s['name']}')],
          value: value,
          onChanged: onChanged,
          errorText: errorText,
        ),
      _Link(addLabel, onAdd),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════
// ANIMALS
// ═══════════════════════════════════════════════════════════

/// The design's "Add a dairy cow" (and goat, sheep, pig...): one animal by tag
/// into its herd (POST /animals). With no herd of its kind yet, one is started
/// for it first (POST /herds).
class AnimalForm extends StatefulWidget {
  final String farmId;
  final FarmKind kind;
  const AnimalForm({super.key, required this.farmId, required this.kind});

  @override
  State<AnimalForm> createState() => _AnimalFormState();
}

class _AnimalFormState extends State<AnimalForm> with RecordForm {
  final _tag = TextEditingController();
  final _name = TextEditingController();
  final _cost = TextEditingController();
  List<Map<String, dynamic>>? _herds;
  String? _herd;
  String _sex = 'female';
  String? _breed;
  String _source = 'bought';
  DateTime? _born;

  String get _type => widget.kind.code;

  @override
  void initState() {
    super.initState();
    FarmSetupService.herds(widget.farmId, _type).then((h) {
      if (!mounted) return;
      setState(() {
        _herds = h;
        _herd = h.isEmpty ? null : '${h.first['id']}';
      });
    });
  }

  @override
  void dispose() {
    _tag.dispose();
    _name.dispose();
    _cost.dispose();
    super.dispose();
  }

  List<(String, String)> get _sexes => switch (_type) {
        'dairy_cattle' || 'beef_cattle' => [('female', 'Cow (female)'.tr), ('male', 'Bull (male)'.tr)],
        'dairy_goats' || 'rabbits' => [('female', 'Doe (female)'.tr), ('male', 'Buck (male)'.tr)],
        'sheep' => [('female', 'Ewe (female)'.tr), ('male', 'Ram (male)'.tr)],
        'pigs' => [('female', 'Sow or gilt (female)'.tr), ('male', 'Boar (male)'.tr)],
        _ => [('female', 'Female'.tr), ('male', 'Male'.tr)],
      };

  List<String> get _breeds => switch (_type) {
        'dairy_cattle' => ['Friesian', 'Ayrshire', 'Jersey', 'Guernsey', 'Cross'.tr],
        'beef_cattle' => ['Boran', 'Sahiwal', 'Zebu', 'Cross'.tr],
        'dairy_goats' => ['Toggenburg', 'Saanen', 'Alpine', 'Cross'.tr],
        'sheep' => ['Dorper', 'Red Maasai', 'Merino', 'Cross'.tr],
        'pigs' => ['Large White', 'Landrace', 'Duroc', 'Hampshire', 'Cross'.tr],
        'rabbits' => ['New Zealand White', 'California White', 'Flemish Giant', 'Cross'.tr],
        _ => [],
      };

  String get _title => switch (_type) {
        'dairy_cattle' => 'Add a dairy cow'.tr,
        'beef_cattle' => 'Add a beef animal'.tr,
        'dairy_goats' => 'Add a dairy goat'.tr,
        'sheep' => 'Add a sheep'.tr,
        'pigs' => 'Add a pig'.tr,
        'rabbits' => 'Add a rabbit'.tr,
        _ => 'Add an animal'.tr,
      };

  String _age(DateTime born) {
    final now = DateTime.now();
    var months = (now.year - born.year) * 12 + now.month - born.month - (now.day < born.day ? 1 : 0);
    if (months < 1) return 'Under a month old'.tr;
    if (months < 12) return months == 1 ? '1 month old'.tr : '{n} months old'.trArgs({'n': months});
    final years = months ~/ 12;
    months %= 12;
    final y = years == 1 ? '1 year'.tr : '{n} years'.trArgs({'n': years});
    if (months == 0) return '{age} old'.trArgs({'age': y});
    final m = months == 1 ? '1 month'.tr : '{n} months'.trArgs({'n': months});
    return '{years} {months} old'.trArgs({'years': y, 'months': m});
  }

  Future<void> _save() async {
    final tag = _tag.text.trim();
    if (tag.isEmpty) return fail("Enter the animal's tag.".tr, 'tag');
    final cost = _cost.text.trim().isEmpty ? null : _num(_cost);
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
      return FarmSetupService.addAnimal({
        'enterprise_id': herd,
        'tag': tag,
        'name': _name.text.trim(),
        'sex': _sex,
        'breed': _breed ?? '',
        'source': _source,
        'birth_date': _born == null ? null : _day(_born!),
        'cost': cost?.toString(),
      });
    }, '{tag} added'.trArgs({'tag': tag}));
  }

  @override
  Widget build(BuildContext context) {
    final herds = _herds;
    final herdNote = herds == null
        ? 'Loading your herds…'.tr
        : herds.isEmpty
            ? 'A new herd starts with this animal'.tr
            : '{herd} · {n} now'.trArgs({'herd': '${herds.firstWhere((h) => '${h['id']}' == _herd, orElse: () => herds.first)['name']}', 'n': herds.firstWhere((h) => '${h['id']}' == _herd, orElse: () => herds.first)['head_count'] ?? 0});
    return RecordPage(
      title: 'ADD AN ANIMAL'.tr,
      eyebrow: 'ADD AN ANIMAL'.tr,
      subtitle: _title,
      saving: saving,
      error: banner({'tag', 'name', 'sex', 'breed', 'birth_date', 'cost'}),
      saveLabel: 'Save animal'.tr,
      onSave: herds == null ? null : _save,
      children: [
        _KindHead(widget.kind, herdNote),
        if (herds != null && herds.length > 1)
          RecordChoices<String?>(
            label: 'Herd'.tr,
            options: [for (final h in herds) ('${h['id']}', '${h['name']}')],
            value: _herd,
            onChanged: (v) => setState(() => _herd = v),
          ),
        RecordTextField(
            controller: _tag, label: 'Tag or number'.tr, hint: 'KE-0142', errorText: err('tag'), caps: TextCapitalization.characters),
        RecordTextField(controller: _name, label: '${'Name'.tr} ${'(optional)'.tr}', caps: TextCapitalization.words, errorText: err('name')),
        RecordChoices<String>(label: 'Sex'.tr, options: _sexes, value: _sex, onChanged: (v) => setState(() => _sex = v), errorText: err('sex')),
        if (_breeds.isNotEmpty)
          RecordChoices<String?>(
            label: '${'Breed'.tr} ${'(optional)'.tr}',
            options: [for (final b in _breeds) (b, b), (null, 'Other'.tr)],
            value: _breed,
            onChanged: (v) => setState(() => _breed = v),
          ),
        RecordChoices<String>(
          label: 'Where it came from'.tr,
          options: [('bought', 'Bought'.tr), ('born', 'Born on the farm'.tr)],
          value: _source,
          onChanged: (v) => setState(() => _source = v),
        ),
        if (_born == null)
          _Link('Add date of birth'.tr, () => setState(() => _born = DateTime.now().subtract(const Duration(days: 365))))
        else
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            RecordDateField(label: 'Date of birth'.tr, value: _born!, errorText: err('birth_date'), onChanged: (d) => setState(() => _born = d)),
            const SizedBox(height: 4),
            Text(_age(_born!), style: AppType.caption.copyWith(color: context.appColors.textSecondary)),
          ]),
        if (_source == 'bought')
          RecordNumberField(controller: _cost, label: '${'Price paid'.tr} ${'(optional)'.tr}', suffix: 'KSh'.tr, errorText: err('cost')),
        if (_type == 'pigs' || _type == 'rabbits')
          _Note('Young ones are not added here. Record a litter on the mother and they are raised as one group.'.tr),
      ],
    );
  }
}

/// The design's "Start a herd": which animals, the herd's name, when it started and
/// where it is kept (POST /herds). Its animals are added next, one by one.
class HerdForm extends StatefulWidget {
  final String farmId;
  final ValueChanged<String> onStarted; // the herd's type, for adding its first animal
  const HerdForm({super.key, required this.farmId, required this.onStarted});

  @override
  State<HerdForm> createState() => _HerdFormState();
}

class _HerdFormState extends State<HerdForm> with RecordForm {
  final _name = TextEditingController();
  String _type = 'dairy_cattle';
  DateTime _date = DateTime.now();
  List<Map<String, dynamic>>? _buildings;
  String? _building;
  bool _named = false; // the farmer typed their own name

  @override
  void initState() {
    super.initState();
    _name.text = _defaultName;
    _loadBuildings();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _defaultName => FarmKind.of(_type)!.herdName;

  Future<void> _loadBuildings() async {
    final s = await FarmSetupService.structures(widget.farmId);
    if (mounted) setState(() => _buildings = s.where((b) => b['type'] != 'pond').toList());
  }

  Future<void> _addBuilding() async {
    if (await openRecord(context, StructureForm(farmId: widget.farmId, initialType: 'shed'))) _loadBuildings();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return fail('Give the herd a name.'.tr, 'name');
    await save(() async {
      final res = await FarmSetupService.startHerd({
        'farm_id': widget.farmId,
        'type': _type,
        'name': name,
        'date': _day(_date),
        'structure_id': _building,
      });
      if (!res.error) widget.onStarted(_type);
      return res;
    }, '{name} started. Now add its animals.'.trArgs({'name': name}));
  }

  @override
  Widget build(BuildContext context) {
    return RecordPage(
      title: 'ANIMALS'.tr,
      eyebrow: 'ANIMALS'.tr,
      subtitle: 'Start a herd'.tr,
      saving: saving,
      error: banner({'type', 'name', 'date', 'structure_id'}),
      saveLabel: 'Start herd'.tr,
      onSave: _save,
      children: [
        RecordChoices<String>(
          label: 'Animals'.tr,
          options: [for (final k in FarmKind.all.where((k) => k.herd)) (k.code, k.label)],
          value: _type,
          errorText: err('type'),
          onChanged: (v) => setState(() {
            _type = v;
            if (!_named) _name.text = _defaultName;
          }),
        ),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => _named = true,
          decoration: InputDecoration(labelText: 'Herd name'.tr, errorText: err('name')),
        ),
        RecordDateField(label: 'Started on'.tr, value: _date, errorText: err('date'), onChanged: (d) => setState(() => _date = d)),
        _KeptIn(
          options: _buildings,
          value: _building,
          onChanged: (v) => setState(() => _building = v),
          addLabel: 'Add a building'.tr,
          onAdd: _addBuilding,
          errorText: err('structure_id'),
        ),
        _Note('Next you add each animal with its tag.'.tr),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BIRDS AND FISH
// ═══════════════════════════════════════════════════════════

/// The design's "New layers batch", "New broiler batch" and "Stock a pond"
/// (POST /batches).
class BatchForm extends StatefulWidget {
  final String farmId;
  final FarmKind kind;
  const BatchForm({super.key, required this.farmId, required this.kind});

  @override
  State<BatchForm> createState() => _BatchFormState();
}

class _BatchFormState extends State<BatchForm> with RecordForm {
  final _name = TextEditingController();
  final _count = TextEditingController();
  final _weeks = TextEditingController();
  final _source = TextEditingController();
  final _cost = TextEditingController();
  DateTime _date = DateTime.now();
  String _age = 'day_old'; // day_old | point_of_lay | other
  List<Map<String, dynamic>>? _places;
  String? _place;

  bool get _fish => widget.kind.code == 'fish';
  bool get _layers => widget.kind.code == 'layers';

  @override
  void initState() {
    super.initState();
    _name.text = '{kind}, {date}'.trArgs({'kind': widget.kind.label, 'date': DateFormat('MMM yyyy').format(DateTime.now())});
    _loadPlaces();
  }

  @override
  void dispose() {
    for (final c in [_name, _count, _weeks, _source, _cost]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPlaces() async {
    final s = await FarmSetupService.structures(widget.farmId);
    if (mounted) setState(() => _places = s.where((b) => _fish ? b['type'] == 'pond' : b['type'] != 'pond').toList());
  }

  Future<void> _addPlace() async {
    final form = StructureForm(farmId: widget.farmId, initialType: _fish ? 'pond' : 'poultry_house');
    if (await openRecord(context, form)) _loadPlaces();
  }

  int get _ageDays => switch (_age) {
        'point_of_lay' => 18 * 7,
        'other' => ((_num(_weeks) ?? 0) * 7).round(),
        _ => 0,
      };

  Future<void> _save() async {
    final count = _num(_count);
    if (_name.text.trim().isEmpty) return fail('Give the batch a name.'.tr, 'name');
    if (count == null || count < 1) return fail(_fish ? 'Enter how many fish.'.tr : 'Enter how many birds.'.tr, 'count');
    await save(
        () => FarmSetupService.startBatch({
              'farm_id': widget.farmId,
              'type': widget.kind.code,
              'name': _name.text.trim(),
              'count': count.round(),
              'date': _day(_date),
              'age_days': _fish ? ((_num(_weeks) ?? 0) * 7).round() : _ageDays,
              'source': _source.text.trim(),
              'cost': _cost.text.trim().isEmpty ? null : _num(_cost)?.toString(),
              'structure_id': _place,
            }),
        '{name} started'.trArgs({'name': _name.text.trim()}));
  }

  @override
  Widget build(BuildContext context) {
    final unit = _fish ? 'fish'.tr : 'birds'.tr;
    return RecordPage(
      title: _fish ? 'FISH'.tr : 'BIRDS'.tr,
      eyebrow: _fish ? 'FISH'.tr : 'BIRDS'.tr,
      subtitle: _fish ? 'Stock a pond'.tr : (_layers ? 'New layers batch'.tr : 'New broiler batch'.tr),
      saving: saving,
      error: banner({'name', 'count', 'date', 'age_days', 'source', 'cost', 'structure_id'}),
      saveLabel: _fish ? 'Stock pond'.tr : 'Start batch'.tr,
      onSave: _save,
      children: [
        _KindHead(widget.kind, _fish ? 'Counted by pond'.tr : (_layers ? 'Kept for eggs'.tr : 'Kept for meat'.tr)),
        RecordTextField(controller: _name, label: _fish ? 'Name'.tr : 'Batch name'.tr, errorText: err('name')),
        RecordNumberField(
            controller: _count, label: _fish ? 'Fingerlings stocked'.tr : 'Number of birds'.tr, suffix: unit, whole: true, errorText: err('count')),
        if (_fish)
          RecordNumberField(controller: _weeks, label: '${'Age of the fingerlings'.tr} ${'(optional)'.tr}', suffix: 'weeks'.tr, whole: true)
        else ...[
          RecordChoices<String>(
            label: 'Age when they came'.tr,
            options: [('day_old', 'Day-old chicks'.tr), if (_layers) ('point_of_lay', 'Point of lay'.tr), ('other', 'Other age'.tr)],
            value: _age,
            errorText: err('age_days'),
            onChanged: (v) => setState(() => _age = v),
          ),
          if (_age == 'other') RecordNumberField(controller: _weeks, label: 'Age in weeks'.tr, suffix: 'weeks'.tr, whole: true),
          Text('Vaccination reminders follow this age.'.tr, style: AppType.caption.copyWith(color: context.appColors.textSecondary)),
        ],
        RecordDateField(label: _fish ? 'Stocked on'.tr : 'Started on'.tr, value: _date, errorText: err('date'), onChanged: (d) => setState(() => _date = d)),
        _KeptIn(
          options: _places,
          value: _place,
          onChanged: (v) => setState(() => _place = v),
          addLabel: _fish ? 'Add a pond'.tr : 'Add a poultry house'.tr,
          onAdd: _addPlace,
          errorText: err('structure_id'),
        ),
        RecordTextField(controller: _source, label: '${'Where they came from'.tr} ${'(optional)'.tr}', errorText: err('source')),
        RecordNumberField(
          controller: _cost,
          label: '${_fish ? 'Cost'.tr : 'Cost of the chicks'.tr} ${'(optional)'.tr}',
          suffix: 'KSh'.tr,
          hint: "Counted as the batch's first cost.".tr,
          errorText: err('cost'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CROPS AND FRUIT TREES
// ═══════════════════════════════════════════════════════════

/// The design's "New maize season" and "Add bananas": a crop on (part of) a
/// plot (POST /seasons). An orchard is started the same way, with its trees.
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
  DateTime _date = DateTime.now();

  bool get _orchard => widget.kind.orchard;

  @override
  void initState() {
    super.initState();
    _name.text = _orchard
        ? '{kind} orchard'.trArgs({'kind': widget.kind.label})
        : '{kind}, {date}'.trArgs({'kind': widget.kind.label, 'date': DateFormat('MMM yyyy').format(DateTime.now())});
    _loadPlots();
  }

  @override
  void dispose() {
    for (final c in [_area, _plants, _name]) {
      c.dispose();
    }
    super.dispose();
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
      final added = p.where((x) => !before.contains('${x['id']}')).map((x) => '${x['id']}').firstOrNull;
      await _loadPlots(pick: added);
    }
  }

  List<String> get _varieties => switch (widget.kind.code) {
        'maize' => ['H614D', 'DH04', 'SC Duma 43', 'WH505'],
        'beans' => ['Rosecoco', 'Mwitemania', 'KAT B1'],
        'rice' => ['Basmati 370', 'IR 2793'],
        'wheat' => ['Kenya Fahari', 'Robin'],
        'tomatoes' => ['Anna F1', 'Rio Grande', 'Kilele F1'],
        'kales' => ['Thousand-headed', 'Collards'],
        'spinach' => ['Fordhook Giant'],
        'bananas' => ['Williams', 'Grand Nain', 'FHIA-17', 'Uganda Green'],
        'avocados' => ['Hass', 'Fuerte'],
        _ => [],
      };

  Future<void> _save() async {
    final area = _num(_area);
    if (_plot == null) return fail('Choose a plot, or add one.'.tr, 'plot_id');
    if (area == null || area <= 0) return fail('Enter the area planted.'.tr, 'area_acres');
    final plants = _num(_plants);
    if (_orchard && (plants == null || plants < 1)) {
      return fail(widget.kind.code == 'bananas' ? 'Enter how many stools.'.tr : 'Enter how many trees.'.tr, 'plant_count');
    }
    if (_name.text.trim().isEmpty) return fail('Give the season a name.'.tr, 'name');
    await save(
        () => FarmSetupService.startSeason({
              'farm_id': widget.farmId,
              'type': widget.kind.code,
              'plot_id': _plot,
              'area_acres': area.toString(),
              'variety': _variety ?? '',
              'plant_count': plants?.round(),
              'date': _day(_date),
              'name': _name.text.trim(),
            }),
        '{name} started'.trArgs({'name': _name.text.trim()}));
  }

  @override
  Widget build(BuildContext context) {
    final plots = _plots;
    final c = context.appColors;
    return RecordPage(
      title: _orchard ? 'FRUIT TREES'.tr : 'CROPS'.tr,
      eyebrow: _orchard ? 'FRUIT TREES'.tr : 'CROPS'.tr,
      subtitle: _orchard
          ? 'Add {kind}'.trArgs({'kind': widget.kind.label.toLowerCase()})
          : 'New {kind} season'.trArgs({'kind': widget.kind.label.toLowerCase()}),
      saving: saving,
      error: banner({'plot_id', 'area_acres', 'plant_count', 'variety', 'date', 'name'}),
      saveLabel: _orchard ? 'Save orchard'.tr : 'Start season'.tr,
      onSave: plots == null ? null : _save,
      children: [
        _KindHead(widget.kind, _orchard ? 'Fruit trees on one plot'.tr : 'One season on one plot'.tr),
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (plots == null)
            const LinearProgressIndicator(minHeight: 2)
          else if (plots.isEmpty)
            Text('No plots yet. Add the land this grows on.'.tr, style: AppType.caption.copyWith(color: c.textSecondary))
          else
            RecordChoices<String?>(
              label: 'Plot'.tr,
              options: [
                for (final p in plots)
                  ('${p['id']}', '{name} · {acres} acres'.trArgs({'name': p['name'], 'acres': num.tryParse('${p['area_acres']}')?.toString().replaceAll(RegExp(r'\.0$'), '') ?? p['area_acres']}))
              ],
              value: _plot,
              errorText: err('plot_id'),
              onChanged: (v) => setState(() => _plot = v),
            ),
          _Link('Add a plot'.tr, _addPlot),
        ]),
        RecordNumberField(controller: _area, label: _orchard ? 'Area'.tr : 'Area planted'.tr, suffix: 'acres'.tr, errorText: err('area_acres')),
        if (_orchard)
          RecordNumberField(
            controller: _plants,
            label: widget.kind.code == 'bananas' ? 'Number of stools'.tr : 'Number of trees'.tr,
            suffix: widget.kind.code == 'bananas' ? 'stools'.tr : 'trees'.tr,
            whole: true,
            hint: widget.kind.code == 'bananas' ? 'A stool is the mother plant with its suckers.'.tr : null,
            errorText: err('plant_count'),
          ),
        if (_varieties.isNotEmpty)
          RecordChoices<String?>(
            label: '${'Variety'.tr} ${'(optional)'.tr}',
            options: [for (final v in _varieties) (v, v), (null, 'Other'.tr)],
            value: _variety,
            onChanged: (v) => setState(() => _variety = v),
          ),
        RecordDateField(
          label: 'Planted on'.tr,
          value: _date,
          first: DateTime(DateTime.now().year - 40),
          errorText: err('date'),
          onChanged: (d) => setState(() => _date = d),
        ),
        RecordTextField(controller: _name, label: _orchard ? 'Name'.tr : 'Season name'.tr, errorText: err('name')),
        if (!_orchard) _Note("Shamba OS lists the season's field jobs from the planting date.".tr),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// LAND, BUILDINGS AND PEOPLE
// ═══════════════════════════════════════════════════════════

/// The design's "Add a plot" (POST /plots).
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
    return RecordPage(
      title: 'LAND'.tr,
      eyebrow: 'LAND'.tr,
      subtitle: 'Add a plot'.tr,
      saving: saving,
      error: banner({'name', 'area_acres', 'tenure', 'lease_cost'}),
      saveLabel: 'Save plot'.tr,
      onSave: _save,
      children: [
        RecordTextField(controller: _name, label: 'Plot name'.tr, hint: 'What you call it, like Near the river.'.tr, errorText: err('name')),
        RecordNumberField(
            controller: _area, label: 'Size'.tr, suffix: 'acres'.tr, hint: '1 acre is about 63 by 63 metres.'.tr, errorText: err('area_acres')),
        RecordChoices<String>(
          label: 'Who owns the land'.tr,
          options: [('owned', 'Owned'.tr), ('leased', 'Leased'.tr), ('family', 'Family land'.tr)],
          value: _tenure,
          errorText: err('tenure'),
          onChanged: (v) => setState(() => _tenure = v),
        ),
        if (_tenure == 'leased')
          RecordNumberField(
            controller: _lease,
            label: '${'Lease cost'.tr} ${'(optional)'.tr}',
            suffix: 'KSh'.tr,
            hint: "What you pay for this land. Counted in the crop's costs.".tr,
            errorText: err('lease_cost'),
          ),
      ],
    );
  }
}

/// The design's "Add a building or pond" (POST /structures).
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
    return RecordPage(
      title: 'BUILDINGS'.tr,
      eyebrow: 'BUILDINGS'.tr,
      subtitle: 'Add a building or pond'.tr,
      saving: saving,
      error: banner({'name', 'type', 'capacity'}),
      saveLabel: _type == 'pond' ? 'Save pond'.tr : 'Save building'.tr,
      onSave: _save,
      children: [
        RecordChoices<String>(
          label: 'What is it'.tr,
          options: [('shed', 'Shed'.tr), ('poultry_house', 'Poultry house'.tr), ('pen', 'Pen'.tr), ('pond', 'Pond'.tr), ('store', 'Store'.tr)],
          value: _type,
          errorText: err('type'),
          onChanged: (v) => setState(() => _type = v),
        ),
        RecordTextField(controller: _name, label: 'Name'.tr, errorText: err('name')),
        if (_type != 'store')
          RecordNumberField(
            controller: _capacity,
            label: '${'How many it holds'.tr} ${'(optional)'.tr}',
            suffix: _type == 'pond' ? 'fish'.tr : (_type == 'poultry_house' ? 'birds'.tr : 'animals'.tr),
            whole: true,
            errorText: err('capacity'),
          ),
      ],
    );
  }
}

/// The design's "Add a supplier" (POST /suppliers).
class SupplierForm extends StatefulWidget {
  const SupplierForm({super.key});

  @override
  State<SupplierForm> createState() => _SupplierFormState();
}

class _SupplierFormState extends State<SupplierForm> with RecordForm {
  final _name = TextEditingController();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) return fail('Enter a name.'.tr, 'name');
    await save(() => FarmSetupService.addSupplier({'name': _name.text.trim(), 'phone': _phone.text.trim()}), 'Supplier added'.tr);
  }

  @override
  Widget build(BuildContext context) {
    return RecordPage(
      title: 'PURCHASES'.tr,
      eyebrow: 'PURCHASES'.tr,
      subtitle: 'Add a supplier'.tr,
      saving: saving,
      error: banner({'name', 'phone'}),
      saveLabel: 'Save supplier'.tr,
      onSave: _save,
      children: [
        RecordTextField(controller: _name, label: 'Name'.tr, caps: TextCapitalization.words, errorText: err('name')),
        RecordTextField(
            controller: _phone, label: 'Phone number (optional)'.tr, hint: '0712 345 678', keyboard: TextInputType.phone, errorText: err('phone')),
        _Note('What you owe them is worked out from purchases you have not paid for yet.'.tr),
      ],
    );
  }
}

/// The design's "Invite to your farm" (POST /invitations).
class TeamForm extends StatefulWidget {
  const TeamForm({super.key});

  @override
  State<TeamForm> createState() => _TeamFormState();
}

class _TeamFormState extends State<TeamForm> with RecordForm {
  final _phone = TextEditingController();
  String _role = 'field_worker';

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_phone.text.trim().isEmpty) return fail('Enter their phone number.'.tr, 'phone');
    await save(() => FarmSetupService.invite({'phone': _phone.text.trim(), 'role': _role}), 'Invitation sent'.tr);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    Widget role(String value, String title, String meta) => SlCard(
          onTap: () => setState(() => _role = value),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: TextStyle(fontFamily: AppType.text, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w700, color: c.textPrimary)),
                Text(meta, style: AppType.caption.copyWith(color: c.textSecondary)),
              ]),
            ),
            const SizedBox(width: 12),
            LineIcon(_role == value ? '<circle cx="12" cy="12" r="10"/><path d="m9 12 2 2 4-4"/>' : '<circle cx="12" cy="12" r="10"/>',
                size: 24, color: _role == value ? c.brandText : c.textHint),
          ]),
        );
    return RecordPage(
      title: 'TEAM'.tr,
      eyebrow: 'TEAM'.tr,
      subtitle: 'Invite to your farm'.tr,
      saving: saving,
      error: banner({'phone', 'role'}),
      saveLabel: 'Send invitation'.tr,
      onSave: _save,
      children: [
        RecordTextField(
          controller: _phone,
          label: 'Their phone number'.tr,
          hint: '0712 345 678',
          keyboard: TextInputType.phone,
          errorText: err('phone'),
        ),
        Text('They join the next time they sign in with this number.'.tr, style: AppType.caption.copyWith(color: c.textSecondary)),
        Text('What they can do'.tr, style: AppType.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w700)),
        role('manager', 'Manager'.tr, 'Records, stock, sales, purchases, money and the team'.tr),
        role('field_worker', 'Field worker'.tr, 'Daily records and seeing stock. No money.'.tr),
        _Note("The invitation ends after a while if they don't sign in. You can send it again.".tr),
      ],
    );
  }
}
