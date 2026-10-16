import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/phosphor_icons.dart';
import '../fields/field_service.dart';
import 'record_form.dart';
import 'record_service.dart';
import '../../l10n/tr.dart';

/// Inputs used on crops: seed, fertiliser, sprays and the farmer's own.
const cropInputs = {'seed', 'fertiliser', 'chemical', 'other'};
const allInputs = {'feed', 'drug', 'seed', 'fertiliser', 'chemical', 'other'};

bool _input(Item i, Set<String> categories) => i.kind == 'input' && categories.contains(i.category);

Map<String, String?> _lineErrors(RecordForm f, String item, String qty, String unit, [String? price]) =>
    {'item': f.err(item), 'qty': f.err(qty), 'unit': f.err(unit), if (price != null) 'price': f.err(price)};

/// The org's currency, for money boxes.
mixin _Currency<T extends StatefulWidget> on State<T> {
  String currency = 'KES';

  void loadCurrency() => ApiService.getOrgCurrency().then((c) {
        if (mounted) setState(() => currency = c);
      });
}

// ═══════════════════════════════════════════════════════════
// CROPS
// ═══════════════════════════════════════════════════════════

/// Work done on a crop: what, when, the inputs it used and what it cost (CRP-02).
class ActivityForm extends StatefulWidget {
  final Field field;
  final String? type;
  const ActivityForm({super.key, required this.field, this.type});

  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> with RecordForm, _Currency {
  late String? _type = widget.type;
  DateTime _date = DateTime.now();
  final _inputs = <ItemLine>[];
  final _labour = TextEditingController();
  final _service = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCurrency();
  }

  @override
  void dispose() {
    for (final l in _inputs) {
      l.dispose();
    }
    _labour.dispose();
    _service.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (_type == null) return fail('Choose the work done.'.tr, 'type');
    final lines = <Map<String, String>>[];
    for (final (i, l) in _inputs.indexed) {
      if (l.isEmpty) continue;
      if (l.item == null) return fail('Choose the input, or remove this line.'.tr, 'inputs.$i.item');
      if (l.qtyValue == null) return fail('Enter how much was used.'.tr, 'inputs.$i.qty');
      lines.add({'item_id': l.item!.id, 'qty': l.qtyValue!, 'unit': l.unit ?? ''});
    }
    final labour = RecordService.number(_labour.text);
    final service = RecordService.number(_service.text);
    if (_labour.text.trim().isNotEmpty && labour == null) return fail('Enter an amount.'.tr, 'labour_cost');
    if (_service.text.trim().isNotEmpty && service == null) return fail('Enter an amount.'.tr, 'service_cost');
    final label = activityTypes.firstWhere((t) => t.$1 == _type).$2;
    save(
      () => RecordService.activity(widget.field,
          date: _date, type: _type!, inputs: lines, labourCost: labour, serviceCost: service, note: _note.text.trim()),
      '{label} recorded on {name}'.trArgs({'label': label, 'name': widget.field.name}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return RecordPage(
      title: 'Field work'.tr,
      subtitle: widget.field.name,
      saving: saving,
      error: banner({'type', 'date', 'labour_cost', 'service_cost', 'note'}),
      onSave: _save,
      children: [
        RecordChoices<String>(
          label: 'What was done'.tr,
          options: activityTypes,
          value: _type,
          errorText: err('type'),
          onChanged: (t) => setState(() => _type = t),
        ),
        RecordDateField(value: _date, errorText: err('date'), onChanged: (d) => setState(() => _date = d)),
        RecordSection('Inputs used'.tr,
            trailing: Text('Optional'.tr, style: AppType.caption.copyWith(color: c.textSecondary))),
        for (final (i, l) in _inputs.indexed)
          ItemLineFields(
            key: ObjectKey(l),
            line: l,
            where: (it) => _input(it, cropInputs),
            suggest: cropInputs,
            itemLabel: 'Seed, fertiliser or spray'.tr,
            errors: _lineErrors(this, 'inputs.$i.item', 'inputs.$i.qty', 'inputs.$i.unit'),
            onChanged: () => setState(() {}),
            onRemove: () => setState(() => _inputs.removeAt(i).dispose()),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _inputs.add(ItemLine())),
            icon: Icon(PhosphorIconsRegular.plus, size: 18, color: c.brandText),
            label: Text(_inputs.isEmpty ? 'Add an input'.tr : 'Add another input'.tr),
          ),
        ),
        RecordSection('What it cost'.tr, trailing: Text('Optional'.tr, style: AppType.caption.copyWith(color: c.textSecondary))),
        RecordNumberField(controller: _labour, label: 'Labour paid'.tr, suffix: currency, errorText: err('labour_cost')),
        RecordNumberField(
            controller: _service, label: 'Services paid (tractor, sprayer)'.tr, suffix: currency, errorText: err('service_cost')),
        RecordTextField(controller: _note, label: 'Note (optional)'.tr, maxLines: 3, maxLength: 500, errorText: err('note')),
      ],
    );
  }
}

/// What was picked from a crop (CRP-03).
class HarvestForm extends StatefulWidget {
  final Field field;
  const HarvestForm({super.key, required this.field});

  @override
  State<HarvestForm> createState() => _HarvestFormState();
}

class _HarvestFormState extends State<HarvestForm> with RecordForm {
  DateTime _date = DateTime.now();
  final _qty = TextEditingController();
  Item? _output;
  String? _unit;
  String _moisture = 'dry';
  String? _loadError;

  bool get _grain => const {'maize', 'beans', 'rice', 'wheat'}.contains(widget.field.type);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final out = await RecordService.outputOf(widget.field);
      if (!mounted) return;
      setState(() {
        _output = out;
        _unit = out?.displayUnit;
        if (out == null) _loadError = 'Could not find what this crop produces.'.tr;
      });
    } on FieldLoadError catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  void _save() {
    final qty = RecordService.number(_qty.text);
    if (qty == null) return fail('Enter how much was harvested.'.tr, 'qty');
    if (_unit == null) return fail('Choose a unit.'.tr, 'unit');
    save(
      () => RecordService.harvest(widget.field, date: _date, qty: qty, unit: _unit!, moisture: _grain ? _moisture : null),
      'Harvest of {qty} {unit} recorded on {name}'.trArgs({'qty': qty, 'unit': _unit, 'name': widget.field.name}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final out = _output;
    return RecordPage(
      title: 'Harvest'.tr,
      subtitle: widget.field.name,
      saving: saving,
      error: banner({'date', 'qty', 'unit', 'moisture'}),
      onSave: out == null ? null : _save,
      children: [
        RecordDateField(value: _date, errorText: err('date'), onChanged: (d) => setState(() => _date = d)),
        if (out == null)
          RecordLoading(error: _loadError, onRetry: _load)
        else ...[
          RecordNumberField(controller: _qty, label: '{name} harvested'.trArgs({'name': out.name}), suffix: _unit, errorText: err('qty')),
          if (out.units.length > 1)
            RecordChoices<String>(
              label: 'Counted in'.tr,
              options: [for (final u in out.units) (u, u)],
              value: _unit,
              errorText: err('unit'),
              onChanged: (u) => setState(() => _unit = u),
            ),
          if (_grain)
            RecordChoices<String>(
              label: 'Grain was'.tr,
              options: [('dry', 'Dry'.tr), ('green', 'Green (not dried)'.tr)],
              value: _moisture,
              errorText: err('moisture'),
              onChanged: (m) => setState(() => _moisture = m),
            ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// BATCHES — flocks, ponds, litters
// ═══════════════════════════════════════════════════════════

/// The day's feed, deaths and (layers) eggs for a batch (BAT-01/02).
class BatchDayForm extends StatefulWidget {
  final Field field;
  const BatchDayForm({super.key, required this.field});

  @override
  State<BatchDayForm> createState() => _BatchDayFormState();
}

class _BatchDayFormState extends State<BatchDayForm> with RecordForm {
  DateTime _date = DateTime.now();
  final _feed = ItemLine();
  final _deaths = TextEditingController();
  final _eggs = TextEditingController();
  final _note = TextEditingController();

  bool get _layers => widget.field.type == 'layers';

  @override
  void dispose() {
    _feed.dispose();
    _deaths.dispose();
    _eggs.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final feedQty = _feed.qtyValue;
    if (_feed.qty.text.trim().isNotEmpty && feedQty == null) return fail('Enter how much feed.'.tr, 'feed_qty');
    if (feedQty != null && _feed.item == null) return fail('Choose the feed.'.tr, 'feed_item_id');
    final deaths = int.tryParse(_deaths.text.trim()) ?? 0;
    final eggs = RecordService.number(_eggs.text);
    if (_eggs.text.trim().isNotEmpty && eggs == null) return fail('Enter the trays collected.'.tr, 'eggs_trays');
    if (feedQty == null && deaths == 0 && eggs == null && _note.text.trim().isEmpty) {
      return fail(_layers ? 'Enter the feed, deaths or eggs for the day.'.tr : 'Enter the feed or deaths for the day.'.tr);
    }
    save(
      () => RecordService.batchDay(widget.field,
          date: _date,
          feedItemId: feedQty == null ? null : _feed.item!.id,
          feedQty: feedQty,
          feedUnit: _feed.unit ?? '',
          deaths: deaths,
          eggsTrays: _layers ? eggs : null,
          note: _note.text.trim()),
      'Day recorded on {name}'.trArgs({'name': widget.field.name}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = DateFormat('EEE d MMM', Localizations.localeOf(context).toString()).format(_date).toUpperCase();
    return RecordPage(
      title: 'Daily record'.tr,
      eyebrow: '{title} · {day}'.trArgs({'title': 'Daily record'.tr.toUpperCase(), 'day': day}),
      subtitle: widget.field.name,
      saving: saving,
      error: banner({'date', 'feed_item_id', 'feed_qty', 'feed_unit', 'deaths', 'eggs_trays', 'note'}),
      onSave: _save,
      saveLabel: "Save today's record".tr,
      children: [
        RecordDateField(value: _date, errorText: err('date'), onChanged: (d) => setState(() => _date = d)),
        if (_layers)
          RecordTally(
            label: 'Eggs collected'.tr,
            controller: _eggs,
            unit: 'trays'.tr,
            packs: [('+10 trays'.tr, 10)],
            errorText: err('eggs_trays'),
            onChanged: () => setState(() {}),
          ),
        RecordCard(label: 'Feed given'.tr, children: [
          ItemLineFields(
            line: _feed,
            where: (i) => _input(i, const {'feed'}),
            suggest: const {'feed'},
            itemLabel: 'Feed'.tr,
            errors: _lineErrors(this, 'feed_item_id', 'feed_qty', 'feed_unit'),
            onChanged: () => setState(() {}),
          ),
        ]),
        RecordTally(
          label: 'Birds that died'.tr,
          note: 'Leave at 0 if none'.tr,
          controller: _deaths,
          unit: 'birds'.tr,
          errorText: err('deaths'),
          onChanged: () => setState(() {}),
        ),
        RecordCard(children: [
          RecordTextField(controller: _note, label: 'Note (optional)'.tr, maxLines: 3, maxLength: 500, errorText: err('note')),
        ]),
      ],
    );
  }
}

/// A few animals of a batch weighed, for its growth (BAT-03).
class SampleWeightForm extends StatefulWidget {
  final Field field;
  const SampleWeightForm({super.key, required this.field});

  @override
  State<SampleWeightForm> createState() => _SampleWeightFormState();
}

class _SampleWeightFormState extends State<SampleWeightForm> with RecordForm {
  DateTime _date = DateTime.now();
  final _size = TextEditingController();
  final _avg = TextEditingController();

  @override
  void dispose() {
    _size.dispose();
    _avg.dispose();
    super.dispose();
  }

  void _save() {
    final size = int.tryParse(_size.text.trim());
    if (size == null || size < 1) return fail('Enter how many were weighed.'.tr, 'sample_size');
    final avg = RecordService.number(_avg.text);
    if (avg == null) return fail('Enter their average weight.'.tr, 'avg_kg');
    save(() => RecordService.sampleWeight(widget.field, date: _date, sampleSize: size, avgKg: avg),
        'Weights recorded on {name}'.trArgs({'name': widget.field.name}));
  }

  @override
  Widget build(BuildContext context) {
    return RecordPage(
      title: 'Weigh a sample'.tr,
      subtitle: widget.field.name,
      saving: saving,
      error: banner({'date', 'sample_size', 'avg_kg'}),
      onSave: _save,
      children: [
        RecordDateField(value: _date, errorText: err('date'), onChanged: (d) => setState(() => _date = d)),
        RecordNumberField(controller: _size, label: 'How many were weighed'.tr, whole: true, errorText: err('sample_size')),
        RecordNumberField(controller: _avg, label: 'Average weight'.tr, suffix: 'kg', errorText: err('avg_kg')),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// HERDS AND BATCHES
// ═══════════════════════════════════════════════════════════

/// A treatment or vaccination for a herd, one animal or a batch (LIV-04, BAT-04). From a
/// step of the vaccination plan, it marks that step done.
class TreatmentForm extends StatefulWidget {
  final Field field;
  final FieldTask? step;
  const TreatmentForm({super.key, required this.field, this.step});

  @override
  State<TreatmentForm> createState() => _TreatmentFormState();
}

class _TreatmentFormState extends State<TreatmentForm> with RecordForm {
  DateTime _date = DateTime.now();
  final _drug = ItemLine();
  final _dose = TextEditingController();
  Animal? _animal;

  bool get _herd => widget.field.module != 'batches';

  @override
  void dispose() {
    _drug.dispose();
    _dose.dispose();
    super.dispose();
  }

  void _save() {
    if (_drug.item == null) return fail('Choose the medicine or vaccine.'.tr, 'item_id');
    final qty = _drug.qtyValue;
    if (qty == null) return fail('Enter how much was given.'.tr, 'qty');
    final step = widget.step;
    save(
      () => RecordService.treatment(widget.field,
          date: _date,
          itemId: _drug.item!.id,
          qty: qty,
          unit: _drug.unit ?? '',
          doseNote: _dose.text.trim(),
          animalId: step?.animalId ?? _animal?.id,
          scheduleKey: step?.scheduleKey,
          scheduleDay: step?.scheduleDay),
      '{p0} recorded on {name}'.trArgs({'p0': step?.vaccine ?? _drug.item!.name, 'name': widget.field.name}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final step = widget.step;
    return RecordPage(
      title: step == null ? 'Treatment or vaccine'.tr : 'Vaccination'.tr,
      subtitle: widget.field.name,
      saving: saving,
      error: banner({'date', 'item_id', 'qty', 'unit', 'dose_note', 'animal_id', 'schedule_key', 'schedule_day'}),
      onSave: _save,
      children: [
        if (step != null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(12)),
            child: Text('Marks "{title}" done in the vaccination plan.'.trArgs({'title': step.title}),
                style: AppType.body.copyWith(color: c.brandText)),
          ),
        RecordDateField(value: _date, errorText: err('date'), onChanged: (d) => setState(() => _date = d)),
        ItemLineFields(
          line: _drug,
          where: (i) => _input(i, const {'drug', 'chemical'}),
          suggest: const {'drug'},
          itemLabel: 'Medicine or vaccine'.tr,
          qtyLabel: 'How much was given'.tr,
          errors: _lineErrors(this, 'item_id', 'qty', 'unit'),
          onChanged: () => setState(() {}),
        ),
        if (_herd && step?.animalId == null)
          AnimalPicker(
            field: widget.field,
            value: _animal,
            label: 'Given to'.tr,
            noneLabel: 'The whole herd'.tr,
            errorText: err('animal_id'),
            onChanged: (a) => setState(() => _animal = a),
          ),
        RecordTextField(
            controller: _dose, label: 'Dose or reason (optional)'.tr, hint: '5 ml each, for worms'.tr, maxLength: 200, errorText: err('dose_note')),
      ],
    );
  }
}

/// Litres milked on a day, for the herd or one animal (LIV-02).
class MilkForm extends StatefulWidget {
  final Field field;
  const MilkForm({super.key, required this.field});

  @override
  State<MilkForm> createState() => _MilkFormState();
}

class _MilkFormState extends State<MilkForm> with RecordForm {
  DateTime _date = DateTime.now();
  final _litres = TextEditingController();
  Animal? _animal;

  @override
  void dispose() {
    _litres.dispose();
    super.dispose();
  }

  void _save() {
    final litres = RecordService.number(_litres.text);
    if (litres == null) return fail('Enter the litres milked.'.tr, 'litres');
    save(() => RecordService.milk(widget.field, date: _date, litres: litres, animalId: _animal?.id),
        '{litres} litres recorded on {name}'.trArgs({'litres': litres, 'name': widget.field.name}));
  }

  @override
  Widget build(BuildContext context) {
    return RecordPage(
      title: 'Milk'.tr,
      subtitle: widget.field.name,
      saving: saving,
      error: banner({'date', 'litres', 'animal_id'}),
      onSave: _save,
      children: [
        RecordDateField(value: _date, errorText: err('date'), onChanged: (d) => setState(() => _date = d)),
        RecordNumberField(controller: _litres, label: 'Milk'.tr, suffix: 'litres', errorText: err('litres')),
        AnimalPicker(
          field: widget.field,
          value: _animal,
          label: 'From'.tr,
          noneLabel: 'The whole herd'.tr,
          where: (a) => a.isFemale,
          errorText: err('animal_id'),
          onChanged: (a) => setState(() => _animal = a),
        ),
      ],
    );
  }
}

/// Feed given to a herd on a day (LIV-03).
class FeedForm extends StatefulWidget {
  final Field field;
  const FeedForm({super.key, required this.field});

  @override
  State<FeedForm> createState() => _FeedFormState();
}

class _FeedFormState extends State<FeedForm> with RecordForm {
  DateTime _date = DateTime.now();
  final _feed = ItemLine();

  @override
  void dispose() {
    _feed.dispose();
    super.dispose();
  }

  void _save() {
    if (_feed.item == null) return fail('Choose the feed.'.tr, 'item_id');
    final qty = _feed.qtyValue;
    if (qty == null) return fail('Enter how much feed.'.tr, 'qty');
    save(
      () => RecordService.feeding(widget.field, date: _date, itemId: _feed.item!.id, qty: qty, unit: _feed.unit ?? ''),
      'Feed recorded on {name}'.trArgs({'name': widget.field.name}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RecordPage(
      title: 'Feeding'.tr,
      subtitle: widget.field.name,
      saving: saving,
      error: banner({'date', 'item_id', 'qty', 'unit'}),
      onSave: _save,
      children: [
        RecordDateField(value: _date, errorText: err('date'), onChanged: (d) => setState(() => _date = d)),
        ItemLineFields(
          line: _feed,
          where: (i) => _input(i, const {'feed'}),
          suggest: const {'feed'},
          itemLabel: 'Feed'.tr,
          errors: _lineErrors(this, 'item_id', 'qty', 'unit'),
          onChanged: () => setState(() {}),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ANIMALS — one by one, in a herd
// ═══════════════════════════════════════════════════════════

/// An animal joins the herd: bought, or born before the app (LIV-01).
class AddAnimalForm extends StatefulWidget {
  final Field field;
  const AddAnimalForm({super.key, required this.field});

  @override
  State<AddAnimalForm> createState() => _AddAnimalFormState();
}

class _AddAnimalFormState extends State<AddAnimalForm> with RecordForm, _Currency {
  final _tag = TextEditingController();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _cost = TextEditingController();
  String? _sex;
  String _source = 'bought';
  DateTime? _born;

  @override
  void initState() {
    super.initState();
    loadCurrency();
  }

  @override
  void dispose() {
    _tag.dispose();
    _name.dispose();
    _breed.dispose();
    _cost.dispose();
    super.dispose();
  }

  void _save() {
    final tag = _tag.text.trim();
    if (tag.isEmpty) return fail("Enter the animal's tag or number.".tr, 'tag');
    if (_sex == null) return fail('Choose female or male.'.tr, 'sex');
    final cost = RecordService.number(_cost.text);
    if (_cost.text.trim().isNotEmpty && cost == null) return fail('Enter an amount.'.tr, 'cost');
    save(
      () => RecordService.addAnimal(widget.field,
          tag: tag,
          name: _name.text.trim(),
          sex: _sex!,
          breed: _breed.text.trim(),
          birthDate: _born,
          source: _source,
          cost: _source == 'bought' ? cost : null),
      '{tag} added to {name}'.trArgs({'tag': tag, 'name': widget.field.name}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RecordPage(
      title: 'Add an animal'.tr,
      subtitle: widget.field.name,
      saving: saving,
      error: banner({'tag', 'name', 'sex', 'breed', 'birth_date', 'source', 'cost'}),
      onSave: _save,
      children: [
        RecordTextField(controller: _tag, label: 'Tag or number'.tr, hint: 'KE-0142', maxLength: 40, caps: TextCapitalization.characters, errorText: err('tag')),
        RecordTextField(controller: _name, label: 'Name (optional)'.tr, maxLength: 80, caps: TextCapitalization.words, errorText: err('name')),
        RecordChoices<String>(
          label: 'Sex'.tr,
          options: [('female', 'Female'.tr), ('male', 'Male'.tr)],
          value: _sex,
          errorText: err('sex'),
          onChanged: (s) => setState(() => _sex = s),
        ),
        RecordTextField(controller: _breed, label: 'Breed (optional)'.tr, hint: 'Friesian'.tr, maxLength: 80, caps: TextCapitalization.words, errorText: err('breed')),
        RecordChoices<String>(
          label: 'Where it came from'.tr,
          options: [('bought', 'Bought'.tr), ('born', 'Born on the farm'.tr)],
          value: _source,
          errorText: err('source'),
          onChanged: (s) => setState(() => _source = s),
        ),
        if (_born == null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _born = DateTime.now()),
              child: Text('Add date of birth'.tr),
            ),
          )
        else
          RecordDateField(
            label: 'Date of birth'.tr,
            value: _born!,
            errorText: err('birth_date'),
            onChanged: (d) => setState(() => _born = d),
          ),
        if (_source == 'bought')
          RecordNumberField(controller: _cost, label: 'Price paid (optional)'.tr, suffix: currency, errorText: err('cost')),
      ],
    );
  }
}

/// One animal weighed (LIV-06).
class AnimalWeightForm extends StatefulWidget {
  final Field field;
  const AnimalWeightForm({super.key, required this.field});

  @override
  State<AnimalWeightForm> createState() => _AnimalWeightFormState();
}

class _AnimalWeightFormState extends State<AnimalWeightForm> with RecordForm {
  DateTime _date = DateTime.now();
  final _kg = TextEditingController();
  Animal? _animal;

  @override
  void dispose() {
    _kg.dispose();
    super.dispose();
  }

  void _save() {
    final a = _animal;
    if (a == null) return fail('Choose the animal.'.tr, 'animal');
    final kg = RecordService.number(_kg.text);
    if (kg == null) return fail('Enter its weight.'.tr, 'kg');
    save(() => RecordService.weigh(a, date: _date, kg: kg), '{tag} weighed {kg} kg'.trArgs({'tag': a.tag, 'kg': kg}));
  }

  @override
  Widget build(BuildContext context) {
    return RecordPage(
      title: 'Weigh an animal'.tr,
      subtitle: widget.field.name,
      saving: saving,
      error: banner({'animal', 'date', 'kg'}),
      onSave: _save,
      children: [
        AnimalPicker(field: widget.field, value: _animal, errorText: err('animal'), onChanged: (a) => setState(() => _animal = a)),
        RecordDateField(value: _date, errorText: err('date'), onChanged: (d) => setState(() => _date = d)),
        RecordNumberField(controller: _kg, label: 'Weight'.tr, suffix: 'kg', errorText: err('kg')),
      ],
    );
  }
}

/// A female was served, naturally or by AI (LIV-05).
class ServiceForm extends StatefulWidget {
  final Field field;
  const ServiceForm({super.key, required this.field});

  @override
  State<ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> with RecordForm {
  DateTime _date = DateTime.now();
  Animal? _animal;
  String _method = 'natural';
  final _sire = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _sire.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final a = _animal;
    if (a == null) return fail('Choose the female served.'.tr, 'animal');
    save(() => RecordService.serve(a, date: _date, method: _method, sire: _sire.text.trim(), note: _note.text.trim()),
        '{tag}: service recorded'.trArgs({'tag': a.tag}));
  }

  @override
  Widget build(BuildContext context) {
    return RecordPage(
      title: 'Served'.tr,
      subtitle: widget.field.name,
      saving: saving,
      error: banner({'animal', 'service_date', 'method', 'sire', 'note'}),
      onSave: _save,
      children: [
        AnimalPicker(
          field: widget.field,
          value: _animal,
          label: 'Female'.tr,
          where: (a) => a.isFemale,
          errorText: err('animal'),
          onChanged: (a) => setState(() => _animal = a),
        ),
        RecordDateField(label: 'Date served'.tr, value: _date, errorText: err('service_date'), onChanged: (d) => setState(() => _date = d)),
        RecordChoices<String>(
          label: 'How'.tr,
          options: [('natural', 'Natural'.tr), ('ai', 'AI')],
          value: _method,
          errorText: err('method'),
          onChanged: (m) => setState(() => _method = m),
        ),
        RecordTextField(
            controller: _sire, label: _method == 'ai' ? 'Bull or semen code (optional)'.tr : 'Sire (optional)'.tr, maxLength: 80, errorText: err('sire')),
        RecordTextField(controller: _note, label: 'Note (optional)'.tr, maxLines: 3, maxLength: 500, errorText: err('note')),
      ],
    );
  }
}

/// A served female was checked: pregnant, or not.
class PregnancyCheckForm extends StatefulWidget {
  final Field field;
  const PregnancyCheckForm({super.key, required this.field});

  @override
  State<PregnancyCheckForm> createState() => _PregnancyCheckFormState();
}

class _PregnancyCheckFormState extends State<PregnancyCheckForm> with RecordForm {
  DateTime _date = DateTime.now();
  Animal? _animal;
  Map<String, dynamic>? _service;
  bool _looking = false;
  bool? _pregnant;

  Future<void> _choose(Animal? a) async {
    setState(() {
      _animal = a;
      _service = null;
      _looking = a != null;
    });
    if (a == null) return;
    final s = await RecordService.openService(a);
    if (!mounted || _animal?.id != a.id) return;
    setState(() {
      _service = s;
      _looking = false;
    });
  }

  void _save() {
    final a = _animal;
    if (a == null) return fail('Choose the female checked.'.tr, 'animal');
    final s = _service;
    if (s == null) return fail('{tag} has no service on record. Record the service first.'.trArgs({'tag': a.tag}), 'animal');
    if (_pregnant == null) return fail('Choose pregnant or not.'.tr, 'pregnant');
    save(() => RecordService.pregnancyCheck('${s['id']}', date: _date, pregnant: _pregnant!),
        '${a.tag}: ${_pregnant! ? 'pregnant' : 'not pregnant'}');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final s = _service;
    return RecordPage(
      title: 'Pregnancy check'.tr,
      subtitle: widget.field.name,
      saving: saving,
      error: banner({'animal', 'date', 'pregnant'}),
      onSave: _save,
      children: [
        AnimalPicker(
          field: widget.field,
          value: _animal,
          label: 'Female'.tr,
          where: (a) => a.isFemale,
          errorText: err('animal'),
          onChanged: _choose,
        ),
        if (_looking)
          const RecordLoading(onRetry: _noop)
        else if (_animal != null)
          Text(
            s == null
                ? 'No open service on record for {p0}.'.trArgs({'p0': _animal!.tag})
                : 'Served {served}, due {due}.'.trArgs({'served': _fmt(s['service_date']), 'due': _fmt(s['expected_due'])}),
            style: AppType.body.copyWith(color: s == null ? c.dangerInk : c.textSecondary),
          ),
        RecordDateField(label: 'Date checked'.tr, value: _date, errorText: err('date'), onChanged: (d) => setState(() => _date = d)),
        RecordChoices<bool>(
          label: 'Result'.tr,
          options: [(true, 'Pregnant'.tr), (false, 'Not pregnant'.tr)],
          value: _pregnant,
          errorText: err('pregnant'),
          onChanged: (p) => setState(() => _pregnant = p),
        ),
      ],
    );
  }
}

void _noop() {}

String _fmt(dynamic iso) {
  final d = DateTime.tryParse('$iso');
  return d == null ? '—' : DateFormat('d MMM yyyy').format(d);
}

/// A female gave birth. Cows and goats: each young one named joins the herd. Pigs and
/// rabbits: how many were born alive and dead; the live ones are raised as a batch (LIV-05).
class BirthForm extends StatefulWidget {
  final Field field;
  const BirthForm({super.key, required this.field});

  @override
  State<BirthForm> createState() => _BirthFormState();
}

class _Young {
  final tag = TextEditingController();
  final name = TextEditingController();
  String? sex;

  void dispose() {
    tag.dispose();
    name.dispose();
  }
}

class _BirthFormState extends State<BirthForm> with RecordForm {
  DateTime _date = DateTime.now();
  Animal? _mother;
  final _alive = TextEditingController();
  final _dead = TextEditingController();
  final _young = <_Young>[_Young()];

  bool get _litter => givesLitters(widget.field.type);

  @override
  void dispose() {
    _alive.dispose();
    _dead.dispose();
    for (final y in _young) {
      y.dispose();
    }
    super.dispose();
  }

  void _save() {
    final m = _mother;
    if (m == null) return fail('Choose the mother.'.tr, 'animal');
    if (_litter) {
      final alive = int.tryParse(_alive.text.trim());
      if (alive == null) return fail('Enter how many were born alive.'.tr, 'born_alive');
      final dead = int.tryParse(_dead.text.trim()) ?? 0;
      save(() => RecordService.birth(m, date: _date, bornAlive: alive, bornDead: dead),
          alive == 0 ? '{tag}: birth recorded'.trArgs({'tag': m.tag}) : '{tag}: {alive} born alive, raised as a new batch'.trArgs({'tag': m.tag, 'alive': alive}));
      return;
    }
    final offspring = <Map<String, String>>[];
    for (final (i, y) in _young.indexed) {
      final tag = y.tag.text.trim();
      if (tag.isEmpty && y.sex == null && y.name.text.trim().isEmpty) continue;
      if (tag.isEmpty) return fail("Enter the young one's tag.".tr, 'offspring.$i.tag');
      if (y.sex == null) return fail('Choose female or male.'.tr, 'offspring.$i.sex');
      offspring.add({'tag': tag, 'sex': y.sex!, 'name': y.name.text.trim()});
    }
    save(() => RecordService.birth(m, date: _date, offspring: offspring),
        offspring.isEmpty ? '{tag}: birth recorded'.trArgs({'tag': m.tag}) : '{tag}: {length} young added to {name}'.trArgs({'tag': m.tag, 'length': offspring.length, 'name': widget.field.name}));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return RecordPage(
      title: 'Birth'.tr,
      subtitle: widget.field.name,
      saving: saving,
      error: banner({
        'animal', 'date', 'born_alive', 'born_dead',
        for (var i = 0; i < _young.length; i++) ...['offspring.$i.tag', 'offspring.$i.sex'],
      }),
      onSave: _save,
      children: [
        AnimalPicker(
          field: widget.field,
          value: _mother,
          label: 'Mother'.tr,
          where: (a) => a.isFemale,
          errorText: err('animal'),
          onChanged: (a) => setState(() => _mother = a),
        ),
        RecordDateField(label: 'Date of birth'.tr, value: _date, errorText: err('date'), onChanged: (d) => setState(() => _date = d)),
        if (_litter) ...[
          RecordNumberField(controller: _alive, label: 'Born alive'.tr, whole: true, errorText: err('born_alive')),
          RecordNumberField(controller: _dead, label: 'Born dead'.tr, whole: true, hint: '0', errorText: err('born_dead')),
        ] else ...[
          RecordSection('The young'.tr, trailing: Text('Leave empty if none survived'.tr, style: AppType.caption.copyWith(color: c.textSecondary))),
          for (final (i, y) in _young.indexed) ...[
            Row(
              children: [
                Expanded(
                  child: RecordTextField(
                      controller: y.tag, label: 'Tag'.tr, maxLength: 40, caps: TextCapitalization.characters, errorText: err('offspring.$i.tag')),
                ),
                const SizedBox(width: 12),
                Expanded(child: RecordTextField(controller: y.name, label: 'Name (optional)'.tr, maxLength: 80, caps: TextCapitalization.words)),
                if (_young.length > 1)
                  IconButton(
                    tooltip: 'Remove'.tr,
                    onPressed: () => setState(() => _young.removeAt(i).dispose()),
                    icon: Icon(PhosphorIconsRegular.x, color: c.textSecondary),
                  ),
              ],
            ),
            RecordChoices<String>(
              options: [('female', 'Female'.tr), ('male', 'Male'.tr)],
              value: y.sex,
              errorText: err('offspring.$i.sex'),
              onChanged: (s) => setState(() => y.sex = s),
            ),
          ],
          if (_young.length < 6)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _young.add(_Young())),
                icon: Icon(PhosphorIconsRegular.plus, size: 18, color: c.brandText),
                label: Text('Add another'.tr),
              ),
            ),
        ],
      ],
    );
  }
}

/// An animal left the herd: sold, or died (LIV-06).
class AnimalExitForm extends StatefulWidget {
  final Field field;
  const AnimalExitForm({super.key, required this.field});

  @override
  State<AnimalExitForm> createState() => _AnimalExitFormState();
}

class _AnimalExitFormState extends State<AnimalExitForm> with RecordForm, _Currency {
  DateTime _date = DateTime.now();
  Animal? _animal;
  String? _reason;
  final _value = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCurrency();
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _save() {
    final a = _animal;
    if (a == null) return fail('Choose the animal.'.tr, 'animal');
    if (_reason == null) return fail('Choose sold or died.'.tr, 'reason');
    final value = RecordService.number(_value.text);
    if (_value.text.trim().isNotEmpty && value == null) return fail('Enter an amount.'.tr, 'value');
    save(() => RecordService.exit(a, date: _date, reason: _reason!, value: _reason == 'sold' ? value : null),
        '${a.tag}: ${_reason == 'sold' ? 'sold' : 'death recorded'}');
  }

  @override
  Widget build(BuildContext context) {
    return RecordPage(
      title: 'Sold or died'.tr,
      subtitle: widget.field.name,
      saving: saving,
      error: banner({'animal', 'reason', 'date', 'value'}),
      onSave: _save,
      children: [
        AnimalPicker(field: widget.field, value: _animal, errorText: err('animal'), onChanged: (a) => setState(() => _animal = a)),
        RecordChoices<String>(
          label: 'What happened'.tr,
          options: [('sold', 'Sold'.tr), ('dead', 'Died'.tr)],
          value: _reason,
          errorText: err('reason'),
          onChanged: (r) => setState(() => _reason = r),
        ),
        RecordDateField(value: _date, errorText: err('date'), onChanged: (d) => setState(() => _date = d)),
        if (_reason == 'sold')
          RecordNumberField(controller: _value, label: 'Sold for'.tr, suffix: currency, errorText: err('value')),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MONEY — the whole farm, or one field
// ═══════════════════════════════════════════════════════════

/// The farm and its fields, which money is recorded against.
mixin _Farm<T extends StatefulWidget> on State<T> {
  Map<String, dynamic>? farm;
  List<Field> fields = const [];
  String? farmError;
  bool farmLoaded = false;

  Future<void> loadFarm() async {
    setState(() => farmError = null);
    try {
      final (f, list) = await FieldService.load();
      if (!mounted) return;
      setState(() {
        farm = f;
        fields = list;
        farmLoaded = true;
        if (f == null) farmError = 'Set up your farm first.'.tr;
      });
    } catch (_) {
      if (mounted) setState(() => farmError = 'Could not load your farm. Check your connection.'.tr);
    }
  }

  Widget fieldPicker(String label, String? value, ValueChanged<String?> onChanged, {String? errorText, bool Function(Field)? where}) {
    final shown = fields.where(where ?? (_) => true).toList();
    final chosen = shown.any((f) => f.id == value) ? value! : '';
    return DropdownButtonFormField<String>(
      key: ValueKey('$label-$chosen-${shown.length}'),
      initialValue: chosen,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, errorText: errorText),
      items: [
        DropdownMenuItem(value: '', child: Text('The whole farm'.tr)),
        for (final f in shown) DropdownMenuItem(value: f.id, child: Text(f.name, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (id) => onChanged(id == null || id.isEmpty ? null : id),
    );
  }
}

/// Money in or out that isn't a sale or a purchase: labour, rent, transport, a grant.
class MoneyForm extends StatefulWidget {
  final Field? field;
  final String kind; // cost | revenue
  const MoneyForm({super.key, this.field, this.kind = 'cost'});

  @override
  State<MoneyForm> createState() => _MoneyFormState();
}

class _MoneyFormState extends State<MoneyForm> with RecordForm, _Currency, _Farm {
  late String _kind = widget.kind;
  String? _category;
  DateTime _date = DateTime.now();
  late String? _fieldId = widget.field?.id;
  final _amount = TextEditingController();
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCurrency();
    loadFarm();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  List<(String, String)> get _categories => _kind == 'cost' ? costCategories : revenueCategories;

  void _save() {
    final f = farm;
    if (f == null) return fail(farmError ?? 'Set up your farm first.'.tr);
    if (_category == null) return fail('Choose what it was for.'.tr, 'category');
    final amount = RecordService.number(_amount.text);
    if (amount == null) return fail('Enter the amount.'.tr, 'amount');
    save(
      () => RecordService.money(
          farmId: '${f['id']}', kind: _kind, category: _category!, amount: amount, date: _date, enterpriseId: _fieldId, note: _note.text.trim()),
      _kind == 'cost' ? 'Expense of {currency} {amount} recorded'.trArgs({'currency': currency, 'amount': amount}) : '{currency} {amount} received recorded'.trArgs({'currency': currency, 'amount': amount}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RecordPage(
      title: _kind == 'cost' ? 'Expense'.tr : 'Money in'.tr,
      subtitle: widget.field?.name ?? farm?['name'],
      saving: saving,
      error: banner({'kind', 'category', 'amount', 'occurred_on', 'enterprise_id', 'note'}) ?? (farmLoaded ? farmError : null),
      onSave: farm == null ? null : _save,
      children: [
        RecordChoices<String>(
          options: [('cost', 'Money out'.tr), ('revenue', 'Money in'.tr)],
          value: _kind,
          onChanged: (k) => setState(() {
            _kind = k;
            _category = null;
          }),
        ),
        RecordChoices<String>(
          label: 'What for'.tr,
          options: _categories,
          value: _category,
          errorText: err('category'),
          onChanged: (c) => setState(() => _category = c),
        ),
        RecordNumberField(controller: _amount, label: 'Amount'.tr, suffix: currency, errorText: err('amount')),
        RecordDateField(value: _date, errorText: err('occurred_on'), onChanged: (d) => setState(() => _date = d)),
        if (!farmLoaded && farmError == null)
          const RecordLoading(onRetry: _noop)
        else if (farmError != null && !farmLoaded)
          RecordLoading(error: farmError, onRetry: loadFarm)
        else
          fieldPicker('For'.tr, _fieldId, (id) => setState(() => _fieldId = id), errorText: err('enterprise_id')),
        RecordTextField(controller: _note, label: 'Note (optional)'.tr, hint: 'Casual labour, cleaning the shed'.tr, maxLength: 300, errorText: err('note')),
      ],
    );
  }
}

/// A sale to a customer: what was sold, at what price, and how it was paid (SAL-02).
class SaleForm extends StatefulWidget {
  final Field? field;
  const SaleForm({super.key, this.field});

  @override
  State<SaleForm> createState() => _SaleFormState();
}

class _SaleFormState extends State<SaleForm> with RecordForm, _Currency, _Farm {
  Party? _customer;
  DateTime _date = DateTime.now();
  final _lines = <ItemLine>[];
  String _method = 'cash';
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCurrency();
    loadFarm();
    _lines.add(ItemLine()..fieldId = widget.field?.id);
    if (widget.field != null) {
      RecordService.outputOf(widget.field!).then((out) {
        if (out != null && mounted && _lines.first.item == null) setState(() => _lines.first.choose(out));
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    _code.dispose();
    super.dispose();
  }

  num get _total => _lines.fold<num>(0, (t, l) => t + (num.tryParse(l.qtyValue ?? '') ?? 0) * (num.tryParse(l.priceValue ?? '') ?? 0));

  void _save() {
    final f = farm;
    if (f == null) return fail(farmError ?? 'Set up your farm first.'.tr);
    final c = _customer;
    if (c == null) return fail('Choose a customer or add a new one.'.tr, 'customer_id');
    final lines = <Map<String, dynamic>>[];
    for (final (i, l) in _lines.indexed) {
      if (l.isEmpty && _lines.length > 1) continue;
      if (l.item == null) return fail('Choose the product.'.tr, 'lines.$i.item_id');
      if (l.qtyValue == null) return fail('Enter how much was sold.'.tr, 'lines.$i.qty');
      if (l.priceValue == null) return fail('Enter the price.'.tr, 'lines.$i.unit_price');
      // A line keeps its field only if that field produces what was sold.
      final from = fields.where((f) => f.id == l.fieldId && l.item!.producedBy.contains(f.type)).firstOrNull;
      lines.add({'item_id': l.item!.id, 'qty': l.qtyValue, 'unit': l.unit ?? '', 'unit_price': l.priceValue, 'enterprise_id': from?.id});
    }
    if (lines.isEmpty) return fail('Add at least one product.'.tr);
    if (_method == 'mpesa_code' && _code.text.trim().length != 10) {
      return fail("Enter the 10-character M-Pesa code from the customer's SMS.".tr, 'code');
    }
    save(
      () => RecordService.sale(
          farmId: '${f['id']}', customerId: c.id, date: _date, lines: lines, method: _method, code: _code.text.trim().toUpperCase()),
      'Sale to {name} recorded'.trArgs({'name': c.name}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final shown = {'customer_id', 'date', 'lines', 'code', 'method'};
    for (var i = 0; i < _lines.length; i++) {
      shown.addAll(['lines.$i.item_id', 'lines.$i.qty', 'lines.$i.unit', 'lines.$i.unit_price', 'lines.$i.enterprise_id']);
    }
    return RecordPage(
      title: 'Sale'.tr,
      subtitle: widget.field?.name ?? farm?['name'],
      saving: saving,
      error: banner(shown) ?? (farmLoaded ? farmError : null),
      onSave: farm == null ? null : _save,
      saveLabel: _total > 0
          ? 'Save sale · {amount}'.trArgs({'amount': '$currency ${NumberFormat('#,##0.##').format(_total)}'})
          : 'Save sale'.tr,
      children: [
        PartyPicker(value: _customer, errorText: err('customer_id'), onChanged: (p) => setState(() => _customer = p)),
        RecordDateField(value: _date, errorText: err('date'), onChanged: (d) => setState(() => _date = d)),
        RecordSection('What was sold'.tr),
        for (final (i, l) in _lines.indexed)
          ItemLineFields(
            key: ObjectKey(l),
            line: l,
            where: (it) => it.kind == 'output',
            itemLabel: 'Product'.tr,
            qtyLabel: 'Quantity'.tr,
            priceLabel: 'Price'.tr,
            currency: currency,
            errors: _lineErrors(this, 'lines.$i.item_id', 'lines.$i.qty', 'lines.$i.unit', 'lines.$i.unit_price'),
            onChanged: () => setState(() {}),
            onRemove: _lines.length > 1 ? () => setState(() => _lines.removeAt(i).dispose()) : null,
            extra: l.item == null || !farmLoaded
                ? null
                : fieldPicker('From'.tr, l.fieldId, (id) => setState(() => l.fieldId = id),
                    errorText: err('lines.$i.enterprise_id'), where: (f) => l.item!.producedBy.contains(f.type)),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _lines.add(ItemLine())),
            icon: Icon(PhosphorIconsRegular.plus, size: 18, color: c.brandText),
            label: Text('Add another product'.tr),
          ),
        ),
        RecordChoices<String>(
          label: 'Paid by'.tr,
          options: paymentMethods,
          value: _method,
          errorText: err('method'),
          onChanged: (m) => setState(() => _method = m),
        ),
        if (_method == 'mpesa_code')
          RecordTextField(
              controller: _code, label: 'M-Pesa code'.tr, hint: 'RJK4XY1234', maxLength: 10, caps: TextCapitalization.characters, errorText: err('code')),
      ],
    );
  }
}

/// Inputs bought from a supplier: they go into stock at the price paid (PRC-02).
class PurchaseForm extends StatefulWidget {
  const PurchaseForm({super.key});

  @override
  State<PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends State<PurchaseForm> with RecordForm, _Currency, _Farm {
  Party? _supplier;
  DateTime _date = DateTime.now();
  final _lines = <ItemLine>[ItemLine()];
  bool _paid = true;

  @override
  void initState() {
    super.initState();
    loadCurrency();
    loadFarm();
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  num get _total => _lines.fold<num>(0, (t, l) => t + (num.tryParse(l.qtyValue ?? '') ?? 0) * (num.tryParse(l.priceValue ?? '') ?? 0));

  void _save() {
    final f = farm;
    if (f == null) return fail(farmError ?? 'Set up your farm first.'.tr);
    final s = _supplier;
    if (s == null) return fail('Choose a supplier or add a new one.'.tr, 'supplier_id');
    final lines = <Map<String, dynamic>>[];
    for (final (i, l) in _lines.indexed) {
      if (l.isEmpty && _lines.length > 1) continue;
      if (l.item == null) return fail('Choose the item.'.tr, 'lines.$i.item_id');
      if (l.qtyValue == null) return fail('Enter how much was bought.'.tr, 'lines.$i.qty');
      if (l.priceValue == null) return fail('Enter the price paid.'.tr, 'lines.$i.unit_price');
      lines.add({'item_id': l.item!.id, 'qty': l.qtyValue, 'unit': l.unit ?? '', 'unit_price': l.priceValue});
    }
    if (lines.isEmpty) return fail('Add at least one item.'.tr);
    save(() => RecordService.purchase(farmId: '${f['id']}', supplierId: s.id, date: _date, lines: lines, paid: _paid),
        'Purchase from {name} recorded'.trArgs({'name': s.name}));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final shown = {'supplier_id', 'date', 'lines', 'paid'};
    for (var i = 0; i < _lines.length; i++) {
      shown.addAll(['lines.$i.item_id', 'lines.$i.qty', 'lines.$i.unit', 'lines.$i.unit_price']);
    }
    return RecordPage(
      title: 'Purchase'.tr,
      subtitle: farm?['name'],
      saving: saving,
      error: banner(shown) ?? (farmLoaded ? farmError : null),
      onSave: farm == null ? null : _save,
      saveLabel: _total > 0
          ? 'Save purchase · {amount}'.trArgs({'amount': '$currency ${NumberFormat('#,##0.##').format(_total)}'})
          : 'Save purchase'.tr,
      children: [
        PartyPicker(suppliers: true, value: _supplier, errorText: err('supplier_id'), onChanged: (p) => setState(() => _supplier = p)),
        RecordDateField(value: _date, errorText: err('date'), onChanged: (d) => setState(() => _date = d)),
        RecordSection('What was bought'.tr),
        for (final (i, l) in _lines.indexed)
          ItemLineFields(
            key: ObjectKey(l),
            line: l,
            where: (it) => it.kind == 'input',
            suggest: allInputs,
            itemLabel: 'Item'.tr,
            qtyLabel: 'Quantity'.tr,
            priceLabel: 'Price'.tr,
            currency: currency,
            errors: _lineErrors(this, 'lines.$i.item_id', 'lines.$i.qty', 'lines.$i.unit', 'lines.$i.unit_price'),
            onChanged: () => setState(() {}),
            onRemove: _lines.length > 1 ? () => setState(() => _lines.removeAt(i).dispose()) : null,
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _lines.add(ItemLine())),
            icon: Icon(PhosphorIconsRegular.plus, size: 18, color: c.brandText),
            label: Text('Add another item'.tr),
          ),
        ),
        RecordChoices<bool>(
          label: 'Paid'.tr,
          options: [(true, 'Paid in full'.tr), (false, 'On credit'.tr)],
          value: _paid,
          onChanged: (p) => setState(() => _paid = p),
        ),
      ],
    );
  }
}
