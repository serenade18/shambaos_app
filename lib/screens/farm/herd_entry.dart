import 'package:flutter/material.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger_parts.dart';
import '../../widgets/phosphor_icons.dart';
import '../../widgets/sl_form.dart';
import '../auth/auth_ui.dart';
import '../fields/field_widgets.dart';
import '../records/record_form.dart';
import 'add_to_farm.dart';
import 'farm_setup_service.dart';
import '../../l10n/tr.dart';

/// The tag after [tag]: its last number one up, keeping its zeros ("KE-009" → "KE-010").
/// Empty when the tag has no number to count on from.
String nextTag(String tag) {
  final m = RegExp(r'^(.*?)(\d+)(\D*)$').firstMatch(tag.trim());
  if (m == null) return '';
  final digits = m[2]!;
  return '${m[1]}${(int.parse(digits) + 1).toString().padLeft(digits.length, '0')}${m[3]}';
}

/// The tag a herd's next animal gets: on from its highest numbered tag, or KE-1.
String firstTag(List<String> tags) {
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
  return best == null ? 'KE-1' : nextTag(best);
}

/// What the rows' sex toggle says, short: "Cow" and "Bull".
List<(String, String)> _shortSexes(String type) => switch (type) {
      'dairy_cattle' => [('female', 'Cow'.tr), ('male', 'Bull'.tr)],
      'beef_cattle' => [('female', 'Heifer'.tr), ('male', 'Bull'.tr)],
      'dairy_goats' || 'rabbits' => [('female', 'Doe'.tr), ('male', 'Buck'.tr)],
      'sheep' => [('female', 'Ewe'.tr), ('male', 'Ram'.tr)],
      'pigs' => [('female', 'Sow'.tr), ('male', 'Boar'.tr)],
      _ => [('female', 'Female'.tr), ('male', 'Male'.tr)],
    };

class _Row {
  final tag = TextEditingController();
  bool typed = false; // the farmer changed the tag, so it no longer numbers itself
  String last = ''; // the tag as last seen: a controller also speaks up when only the cursor moves
  String sex;
  String? breed; // null: the same as the rest
  _Row(this.sex);
}

/// Quick herd entry: many animals on one screen, a row each (tag, sex, breed), with
/// tags numbering themselves on from the herd's last one. Saved together with
/// POST /animals/bulk, all or none. Opened after "Start a herd", and from a herd's
/// record menu.
class HerdEntryScreen extends StatefulWidget {
  final String herdId;
  final String herdName;
  final String type;
  final int rows;
  const HerdEntryScreen({super.key, required this.herdId, required this.herdName, required this.type, this.rows = 3});

  @override
  State<HerdEntryScreen> createState() => _HerdEntryScreenState();
}

class _HerdEntryScreenState extends State<HerdEntryScreen> with RecordForm {
  final _rows = <_Row>[];
  bool _loading = true;
  bool _numbering = false; // the tags are being filled in, not typed
  String? _breed;
  String _source = 'bought';

  String get _type => widget.type;
  String get _female => _type == 'beef_cattle' ? 'male' : 'female';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final tags = await FarmSetupService.tags(widget.herdId);
    if (!mounted) return;
    var tag = firstTag(tags);
    for (var i = 0; i < widget.rows.clamp(1, 200); i++) {
      _addRow(tag);
      tag = nextTag(tag);
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.tag.dispose();
    }
    super.dispose();
  }

  void _addRow(String tag) {
    final row = _Row(_rows.isEmpty ? _female : _rows.last.sex);
    row.tag.text = tag;
    row.last = tag;
    row.tag.addListener(() => _typed(row));
    _rows.add(row);
  }

  /// A tag typed by hand: the rows under it that still number themselves follow on from it.
  void _typed(_Row row) {
    if (row.tag.text == row.last) return;
    row.last = row.tag.text;
    if (_numbering) return;
    row.typed = true;
    _numbering = true;
    var tag = row.tag.text;
    for (final r in _rows.skip(_rows.indexOf(row) + 1)) {
      if (r.typed) break;
      tag = nextTag(tag);
      if (r.tag.text != tag) {
        r.tag.text = tag;
        r.last = tag;
      }
    }
    _numbering = false;
    if (fieldErrors.isNotEmpty) setState(() => fieldErrors = {});
  }

  void _more() => setState(() {
        _numbering = true;
        _addRow(_rows.isEmpty ? 'KE-1' : nextTag(_rows.last.tag.text));
        _numbering = false;
      });

  void _remove(_Row row) => setState(() {
        _rows.remove(row);
        row.tag.dispose();
        fieldErrors = {};
      });

  Future<void> _pickBreed(_Row row) async {
    final breeds = animalBreeds(_type);
    final picked = await slPick<String>(context,
        title: 'Breed'.tr,
        value: row.breed ?? _breed,
        options: [for (final b in breeds) (b, b), ('Cross', 'Cross'.tr), ('', 'Other'.tr)]);
    if (picked != null) setState(() => row.breed = picked);
  }

  void _save() {
    final seen = <String, int>{};
    for (var i = 0; i < _rows.length; i++) {
      final tag = _rows[i].tag.text.trim();
      if (tag.isEmpty) return fail("Enter the animal's tag.".tr, 'animals.$i.tag');
      if (seen.containsKey(tag)) return fail('Row {n} has this tag too.'.trArgs({'n': seen[tag]! + 1}), 'animals.$i.tag');
      seen[tag] = i;
    }
    final n = _rows.length;
    save(
      () => FarmSetupService.addAnimals({
        'enterprise_id': widget.herdId,
        'source': _source,
        'animals': [
          for (final r in _rows) {'tag': r.tag.text.trim(), 'sex': r.sex, 'breed': r.breed ?? _breed ?? ''},
        ],
      }),
      '{n} {unit} added to {herd}'.trArgs({'n': n, 'unit': animalUnit(_type, n), 'herd': widget.herdName}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final n = _rows.length;
    final breeds = animalBreeds(_type);
    return SlFormPage(
      eyebrow: 'ADD ANIMALS'.tr,
      title: 'Add your {unit}'.trArgs({'unit': animalUnit(_type, 2)}),
      saving: saving,
      error: banner({for (var i = 0; i < n; i++) 'animals.$i.tag'}),
      saveLabel: n == 0 ? 'Save'.tr : 'Save {n} {unit}'.trArgs({'n': n, 'unit': animalUnit(_type, n)}),
      onSave: _loading || n == 0 ? null : _save,
      children: [
        SlTypeHead(
          icon: Image.asset(fieldIcon(_type), width: 28, height: 28, excludeFromSemantics: true),
          title: widget.herdName,
          meta: 'A row each. Tags number themselves; change any.'.tr,
        ),
        if (breeds.isNotEmpty)
          SlField(
            label: 'Breed'.tr,
            optional: true,
            hint: 'For all of them. Change one on its row.'.tr,
            child: SlChoices<String>(
              options: [for (final b in breeds) (b, b), ('Cross', 'Cross'.tr), ('', 'Other'.tr)],
              value: _breed,
              onChanged: (v) => setState(() => _breed = v),
            ),
          ),
        SlField(
          label: 'Where they came from'.tr,
          child: SlChoices<String>(
            options: [('bought', 'Bought'.tr), ('born', 'Born on the farm'.tr)],
            value: _source,
            onChanged: (v) => setState(() => _source = v),
          ),
        ),
        if (_loading)
          Padding(padding: const EdgeInsets.only(top: 24), child: Center(child: CircularProgressIndicator(color: c.shamba)))
        else ...[
          for (var i = 0; i < n; i++) _rowCard(c, i, breeds.isNotEmpty),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _more,
              icon: Icon(PhosphorIconsRegular.plusCircle, size: 20, color: c.brandText),
              label: Text('Add another {unit}'.trArgs({'unit': animalUnit(_type, 1)}),
                  style: TextStyle(fontFamily: AppType.text, fontSize: 15, fontWeight: FontWeight.w700, color: c.brandText)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _rowCard(AppColors c, int i, bool hasBreeds) {
    final row = _rows[i];
    final error = err('animals.$i.tag') ?? err('animals.$i.sex') ?? err('animals.$i.breed');
    final breed = row.breed ?? _breed;
    return SlCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: c.brandSoft, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('${i + 1}', style: TextStyle(fontFamily: AppType.mono, fontSize: 13, fontWeight: FontWeight.w700, color: c.brandText)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              label: 'Tag, row {n}'.trArgs({'n': i + 1}),
              child: SlTextBox(controller: row.tag, mono: true, placeholder: 'KE-0142', caps: TextCapitalization.characters, error: error != null),
            ),
          ),
          IconButton(
            tooltip: 'Remove row'.tr,
            onPressed: () => _remove(row),
            icon: Icon(PhosphorIconsRegular.x, size: 20, color: c.textSecondary),
          ),
        ]),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(38, 6, 8, 0),
            child: Text(error, style: TextStyle(fontFamily: AppType.text, fontSize: 13, height: 18 / 13, color: c.dangerInk)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(38, 10, 8, 0),
          child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            for (final (v, text) in _shortSexes(_type)) SlChip(text, selected: row.sex == v, onTap: () => setState(() => row.sex = v)),
            if (hasBreeds)
              ActionChip(
                onPressed: () => _pickBreed(row),
                backgroundColor: c.cardBackground,
                side: BorderSide(color: c.border),
                shape: const StadiumBorder(),
                avatar: LineIcon('<path d="m6 9 6 6 6-6"/>', size: 16, color: c.textSecondary),
                label: Text(breed == null || breed.isEmpty ? 'Breed'.tr : (breed == 'Cross' ? 'Cross'.tr : breed),
                    style: TextStyle(fontFamily: AppType.text, fontSize: 14, color: breed == null || breed.isEmpty ? c.textSecondary : c.textPrimary)),
              ),
          ]),
        ),
      ]),
    );
  }
}
