import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger_parts.dart';
import '../../widgets/phosphor_icons.dart';
import '../auth/auth_ui.dart';
import '../fields/field_service.dart';
import 'record_service.dart';
import '../../l10n/tr.dart';

/// What a record form shares: saving, and the server's errors shown on its fields.
mixin RecordForm<T extends StatefulWidget> on State<T> {
  bool saving = false;
  String? error; // shown above the Save button
  Map<String, String> fieldErrors = {};

  String? err(String key) => fieldErrors[key];

  /// Shows a problem found before sending.
  void fail(String message, [String? field]) => setState(() {
        error = field == null ? message : null;
        fieldErrors = field == null ? {} : {field: message};
      });

  /// Sends the record. On success the page closes with [done], which the caller shows.
  Future<void> save(Future<ApiResponse> Function() send, String done) async {
    FocusScope.of(context).unfocus();
    setState(() {
      saving = true;
      error = null;
      fieldErrors = {};
    });
    final res = await send();
    if (!mounted) return;
    if (!res.error) {
      Navigator.pop(context, done);
      return;
    }
    final fields = <String, String>{};
    final raw = res.data is Map ? res.data['fields'] : null;
    if (raw is Map) {
      raw.forEach((k, v) {
        final m = v is List && v.isNotEmpty ? '${v.first}' : '$v';
        if (m.isNotEmpty) fields['$k'] = m;
      });
    }
    setState(() {
      saving = false;
      fieldErrors = fields;
      error = res.data == null
          ? 'Could not save. Check your connection and try again.'.tr
          : fields.isNotEmpty && res.data is Map && res.data['code'] == 'validation_error'
              ? _checkFields
              : (res.message ?? 'Could not save. Try again.'.tr);
    });
  }

  /// The message above Save, with any field error no input on the page shows.
  String? banner(Set<String> shown) {
    final rest = [for (final e in fieldErrors.entries) if (!shown.contains(e.key)) e.value];
    if (rest.isEmpty) return error;
    return error == null || error == _checkFields ? rest.join('\n') : '$error\n${rest.join('\n')}';
  }
}

String get _checkFields => 'Check the fields marked below.'.tr;

/// Opens a record form; when it saves, says so and returns true.
Future<bool> openRecord(BuildContext context, Widget form) async {
  final done = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => form));
  if (done == null || !context.mounted) return false;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
  return true;
}

/// A page that records one thing, as the design's record pages: a round back
/// button, what it is (an eyebrow) over what it is for (the title), its fields,
/// and Save as a pill fixed at the bottom.
class RecordPage extends StatelessWidget {
  final String title; // what is being recorded: "Daily record"
  final String? subtitle; // the field or farm it is for
  final String? eyebrow; // in place of the title in capitals: "DAILY RECORD · FRI 16 OCT"
  final List<Widget> children;
  final bool saving;
  final String? error;
  final VoidCallback? onSave;
  final String? saveLabel;

  const RecordPage({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    required this.children,
    required this.saving,
    this.error,
    required this.onSave,
    this.saveLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: c.scaffoldBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(children: [
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
                        onTap: () => Navigator.pop(context),
                        child: SizedBox(width: 44, height: 44, child: Icon(PhosphorIconsRegular.arrowLeft, size: 22, color: c.textPrimary)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (subtitle != null)
                      Text(eyebrow ?? title.toUpperCase(),
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.eyebrow.copyWith(color: c.textSecondary)),
                    Text(subtitle ?? title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: AppType.text, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w500, color: c.textPrimary)),
                  ]),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  for (final w in children) ...[w, const SizedBox(height: 12)],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 16 + bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: c.dangerTint, borderRadius: BorderRadius.circular(16)),
                      child: Text(error!, style: AppType.body.copyWith(color: c.dangerInk)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // The design's primary pill.
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: saving ? null : onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.shamba,
                        foregroundColor: c.onShamba,
                        disabledBackgroundColor: c.shamba.withValues(alpha: 0.45),
                        disabledForegroundColor: c.onShamba,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(fontFamily: AppType.text, fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      child: saving
                          ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: c.onShamba))
                          : Text(saveLabel ?? 'Save'.tr),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A number counted with big − and + buttons (the design's tally): eggs, deaths.
/// The figure can also be typed. [packs] add a set amount: ("+10 trays", 10).
class RecordTally extends StatelessWidget {
  final String label;
  final String? note; // on the right of the label: "Yesterday 220 trays"
  final TextEditingController controller;
  final String unit;
  final num step;
  final bool whole;
  final List<(String, num)> packs;
  final String? errorText;
  final VoidCallback? onChanged;

  const RecordTally({
    super.key,
    required this.label,
    this.note,
    required this.controller,
    required this.unit,
    this.step = 1,
    this.whole = true,
    this.packs = const [],
    this.errorText,
    this.onChanged,
  });

  num get _value => num.tryParse(controller.text.replaceAll(',', '').trim()) ?? 0;

  void _set(num v) {
    final n = v < 0 ? 0 : v;
    controller.text = whole || n == n.roundToDouble() ? '${n.round()}' : n.toStringAsFixed(1);
    onChanged?.call();
  }

  Widget _button(AppColors c, {required bool add, required String label}) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: add ? c.shamba : c.surfaceMuted,
          shape: CircleBorder(side: BorderSide(color: add ? c.shamba : c.border, width: 1.5)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => _set(_value + (add ? step : -step)),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: LineIcon(add ? '<path d="M5 12h14"/><path d="M12 5v14"/>' : '<path d="M5 12h14"/>',
                    size: 22, strokeWidth: 2.4, color: add ? c.onShamba : c.textPrimary),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
          Expanded(child: Text(label, style: AppType.label.copyWith(color: c.textPrimary))),
          if (note != null) Text(note!, style: AppType.caption.copyWith(color: c.textSecondary)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _button(c, add: false, label: 'Less'.tr),
          const SizedBox(width: 8),
          Expanded(
            child: Column(children: [
              TextField(
                controller: controller,
                onChanged: (_) => onChanged?.call(),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.numberWithOptions(decimal: !whole),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(whole ? r'[0-9]' : r'[0-9.,]'))],
                style: TextStyle(
                    fontFamily: AppType.text,
                    fontSize: 28,
                    height: 32 / 28,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()]),
                decoration: InputDecoration(
                  hintText: '0',
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  semanticCounterText: label,
                ),
              ),
              Text(unit, style: AppType.caption.copyWith(color: c.textSecondary)),
            ]),
          ),
          const SizedBox(width: 8),
          _button(c, add: true, label: 'More'.tr),
        ]),
        if (packs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (text, amount) in packs) SlChip(text, onTap: () => _set(_value + amount)),
          ]),
        ],
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(errorText!, style: AppType.caption.copyWith(color: c.dangerInk)),
        ],
      ]),
    );
  }
}

/// A white card holding a few fields, as the design groups them.
class RecordCard extends StatelessWidget {
  final String? label;
  final String? note;
  final List<Widget> children;
  const RecordCard({super.key, this.label, this.note, required this.children});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Color(0x1217211A), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (label != null) ...[
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Expanded(child: Text(label!, style: AppType.label.copyWith(color: c.textPrimary))),
            if (note != null) Text(note!, style: AppType.caption.copyWith(color: c.textSecondary)),
          ]),
          const SizedBox(height: 12),
        ],
        for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 12), children[i]],
      ]),
    );
  }
}

/// A short heading inside a form.
class RecordSection extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const RecordSection(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(child: Text(text, style: AppType.label.copyWith(color: c.textPrimary, fontSize: 16))),
          if (trailing != null) Flexible(child: trailing!),
        ],
      ),
    );
  }
}

/// The day a record is for: today unless changed, never later.
class RecordDateField extends StatelessWidget {
  final String? label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;
  final DateTime? first;

  const RecordDateField({super.key, this.label, required this.value, required this.onChanged, this.errorText, this.first});

  static String friendly(DateTime d) {
    final today = DateUtils.dateOnly(DateTime.now());
    final day = DateUtils.dateOnly(d);
    if (day == today) return 'Today, {date}'.trArgs({'date': DateFormat('d MMM').format(d)});
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, {date}'.trArgs({'date': DateFormat('d MMM').format(d)});
    }
    return DateFormat('EEE d MMM yyyy').format(d);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: first ?? DateTime(now.year - 30),
          lastDate: now,
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label ?? 'Date'.tr,
          errorText: errorText,
          suffixIcon: Icon(PhosphorIconsRegular.calendarBlank, color: c.textSecondary),
        ),
        child: Text(friendly(value), style: AppType.body.copyWith(color: c.textPrimary)),
      ),
    );
  }
}

/// A number box: "2.5", "1,500".
class RecordNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final String? hint;
  final String? errorText;
  final bool whole;
  final ValueChanged<String>? onChanged;

  const RecordNumberField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.hint,
    this.errorText,
    this.whole = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: !whole),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(whole ? r'[0-9]' : r'[0-9.,]'))],
      decoration: InputDecoration(labelText: label, suffixText: suffix, hintText: hint, errorText: errorText),
    );
  }
}

/// A line of text: a note, a tag, a name.
class RecordTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? errorText;
  final int maxLines;
  final int? maxLength;
  final TextCapitalization caps;
  final TextInputType? keyboard;

  const RecordTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.errorText,
    this.maxLines = 1,
    this.maxLength,
    this.caps = TextCapitalization.sentences,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: 1,
      maxLength: maxLength,
      textCapitalization: caps,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, hintText: hint, errorText: errorText, counterText: ''),
    );
  }
}

/// One choice from a few, as chips.
class RecordChoices<T> extends StatelessWidget {
  final String? label;
  final List<(T, String)> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final String? errorText;

  const RecordChoices({super.key, this.label, required this.options, required this.value, required this.onChanged, this.errorText});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppType.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (v, text) in options)
              ChoiceChip(
                label: Text(text),
                selected: v == value,
                onSelected: (_) => onChanged(v),
                labelStyle: AppType.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: v == value ? c.brandText : c.textPrimary,
                ),
              ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(errorText!, style: AppType.caption.copyWith(color: c.dangerInk)),
        ],
      ],
    );
  }
}

/// A list the form waits for (items, animals, customers), with a retry when it fails.
class RecordLoading extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;
  const RecordLoading({super.key, this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    if (error == null) {
      return Container(height: 56, decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(12)));
    }
    return Row(
      children: [
        Expanded(child: Text(error!, style: AppType.body.copyWith(color: c.dangerInk))),
        TextButton(onPressed: onRetry, child: Text('Try again'.tr)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ITEMS — feed, medicine, seed, fertiliser, produce
// ═══════════════════════════════════════════════════════════

/// An item with how much of it, in which unit, and (sales, purchases) at what price.
class ItemLine {
  Item? item;
  String? unit;
  String? fieldId; // the field a sale line came from
  final qty = TextEditingController();
  final price = TextEditingController();

  String? get qtyValue => RecordService.number(qty.text);
  String? get priceValue => RecordService.number(price.text);
  bool get isEmpty => item == null && qty.text.trim().isEmpty;

  void choose(Item? i) {
    item = i;
    unit = i == null ? null : (i.units.contains(i.displayUnit) ? i.displayUnit : (i.units.isEmpty ? null : i.units.first));
  }

  void dispose() {
    qty.dispose();
    price.dispose();
  }
}

/// Picks an item, its quantity and unit (and a price). Only items [where] allows are
/// offered; inputs in [suggest] categories the farm doesn't keep yet can be added here.
class ItemLineFields extends StatefulWidget {
  final ItemLine line;
  final bool Function(Item) where;
  final Set<String> suggest;
  final String itemLabel;
  final String? qtyLabel;
  final String? priceLabel; // shown when set: "Price per unit"
  final String? currency;
  final Map<String, String?> errors; // item, qty, unit, price
  final VoidCallback onChanged;
  final VoidCallback? onRemove;
  final Widget? extra; // under the item: the field a sale came from

  const ItemLineFields({
    super.key,
    required this.line,
    required this.where,
    this.suggest = const {},
    required this.itemLabel,
    this.qtyLabel,
    this.priceLabel,
    this.currency,
    this.errors = const {},
    required this.onChanged,
    this.onRemove,
    this.extra,
  });

  @override
  State<ItemLineFields> createState() => _ItemLineFieldsState();
}

class _ItemLineFieldsState extends State<ItemLineFields> {
  List<Item>? _items;
  List<Suggestion> _suggestions = const [];
  String? _loadError;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() => _loadError = null);
    try {
      final items = await RecordService.items(refresh: refresh);
      final sugg = widget.suggest.isEmpty ? <Suggestion>[] : await RecordService.suggestions();
      if (!mounted) return;
      setState(() {
        _items = items.where(widget.where).toList()..sort((a, b) => a.name.compareTo(b.name));
        _suggestions = sugg.where((s) => widget.suggest.contains(s.category)).toList();
      });
    } on FieldLoadError catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  Future<void> _pick(String? value) async {
    if (value == null) return;
    if (value.startsWith('s:')) {
      final s = _suggestions.firstWhere((s) => 's:${s.code}' == value);
      setState(() => _adding = true);
      final (item, problem) = await RecordService.addSuggestion(s);
      if (!mounted) return;
      setState(() => _adding = false);
      if (item == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem!)));
        return;
      }
      await _load(refresh: true);
      if (!mounted) return;
      final list = _items ?? <Item>[];
      if (!list.any((i) => i.id == item.id)) setState(() => _items = [...list, item]);
      widget.line.choose(_items!.firstWhere((i) => i.id == item.id));
    } else {
      widget.line.choose(_items!.firstWhere((i) => i.id == value));
    }
    setState(() {});
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final items = _items;
    final line = widget.line;
    final e = widget.errors;
    if (items == null) return RecordLoading(error: _loadError, onRetry: _load);

    final options = <DropdownMenuItem<String>>[
      for (final i in items) DropdownMenuItem(value: i.id, child: Text(i.name, overflow: TextOverflow.ellipsis)),
      for (final s in _suggestions)
        DropdownMenuItem(
          value: 's:${s.code}',
          child: Text('Add {name}'.trArgs({'name': s.name}), overflow: TextOverflow.ellipsis, style: TextStyle(color: c.brandText)),
        ),
    ];
    final units = line.item?.units ?? const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: options.isEmpty
                  ? InputDecorator(
                      decoration: InputDecoration(labelText: widget.itemLabel, errorText: e['item']),
                      child: Text('None on this farm yet. Add them in the web dashboard.'.tr,
                          style: AppType.caption.copyWith(color: c.textSecondary)),
                    )
                  : DropdownButtonFormField<String>(
                      key: ValueKey('${line.item?.id}-${items.length}'),
                      initialValue: line.item?.id,
                      isExpanded: true,
                      items: options,
                      onChanged: _adding ? null : _pick,
                      decoration: InputDecoration(
                        labelText: widget.itemLabel,
                        errorText: e['item'],
                        suffixIcon: _adding
                            ? Padding(
                                padding: const EdgeInsets.all(14),
                                child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: c.shamba)),
                              )
                            : null,
                      ),
                    ),
            ),
            if (widget.onRemove != null)
              IconButton(
                tooltip: 'Remove'.tr,
                onPressed: widget.onRemove,
                icon: Icon(PhosphorIconsRegular.x, color: c.textSecondary),
              ),
          ],
        ),
        if (widget.extra != null) ...[const SizedBox(height: 12), widget.extra!],
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RecordNumberField(
                controller: line.qty,
                label: widget.qtyLabel ?? 'How much'.tr,
                suffix: line.unit,
                errorText: e['qty'],
                onChanged: (_) => widget.onChanged(),
              ),
            ),
            if (widget.priceLabel != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: RecordNumberField(
                  controller: line.price,
                  label: widget.priceLabel!,
                  hint: line.unit == null ? null : 'per ${line.unit}',
                  suffix: widget.currency,
                  errorText: e['price'],
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
            ],
          ],
        ),
        if (units.length > 1) ...[
          const SizedBox(height: 12),
          RecordChoices<String>(
            label: 'Counted in'.tr,
            options: [for (final u in units) (u, u)],
            value: line.unit,
            errorText: e['unit'],
            onChanged: (u) {
              setState(() => line.unit = u);
              widget.onChanged();
            },
          ),
        ] else if (e['unit'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(e['unit']!, style: AppType.caption.copyWith(color: c.dangerInk)),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ANIMALS
// ═══════════════════════════════════════════════════════════

/// Picks an animal in the herd. With [noneLabel], "none" (the whole herd) is a choice.
class AnimalPicker extends StatefulWidget {
  final Field field;
  final Animal? value;
  final ValueChanged<Animal?> onChanged;
  final bool Function(Animal)? where;
  final String? label;
  final String? noneLabel;
  final String? errorText;

  const AnimalPicker({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.where,
    this.label,
    this.noneLabel,
    this.errorText,
  });

  @override
  State<AnimalPicker> createState() => _AnimalPickerState();
}

class _AnimalPickerState extends State<AnimalPicker> {
  List<Animal>? _animals;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final all = await RecordService.animals(widget.field);
      if (mounted) setState(() => _animals = all.where(widget.where ?? (_) => true).toList());
    } on FieldLoadError catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final animals = _animals;
    if (animals == null) return RecordLoading(error: _loadError, onRetry: _load);
    if (animals.isEmpty && widget.noneLabel == null) {
      return InputDecorator(
        decoration: InputDecoration(labelText: widget.label ?? 'Animal'.tr, errorText: widget.errorText),
        child: Text('No animals to choose. Add them to this herd first.'.tr, style: AppType.caption.copyWith(color: c.textSecondary)),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: widget.value?.id ?? '',
      isExpanded: true,
      decoration: InputDecoration(labelText: widget.label ?? 'Animal'.tr, errorText: widget.errorText),
      items: [
        DropdownMenuItem(value: '', child: Text(widget.noneLabel ?? 'Choose an animal'.tr)),
        for (final a in animals) DropdownMenuItem(value: a.id, child: Text(a.label, overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (id) => widget.onChanged(id == null || id.isEmpty ? null : animals.firstWhere((a) => a.id == id)),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// CUSTOMERS AND SUPPLIERS
// ═══════════════════════════════════════════════════════════

/// Picks a customer or supplier, or adds a new one.
class PartyPicker extends StatefulWidget {
  final bool suppliers;
  final Party? value;
  final ValueChanged<Party?> onChanged;
  final String? errorText;

  const PartyPicker({super.key, this.suppliers = false, required this.value, required this.onChanged, this.errorText});

  @override
  State<PartyPicker> createState() => _PartyPickerState();
}

class _PartyPickerState extends State<PartyPicker> {
  List<Party>? _parties;
  String? _loadError;


  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final all = widget.suppliers ? await RecordService.suppliers() : await RecordService.customers();
      if (mounted) setState(() => _parties = all..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())));
    } on FieldLoadError catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  Future<void> _add() async {
    final added = await showDialog<Party>(context: context, builder: (_) => _NewPartyDialog(suppliers: widget.suppliers));
    if (added == null || !mounted) return;
    setState(() => _parties = [...?_parties, added]);
    widget.onChanged(added);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final parties = _parties;
    if (parties == null) return RecordLoading(error: _loadError, onRetry: _load);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (parties.isNotEmpty)
          DropdownButtonFormField<String>(
            key: ValueKey('${widget.value?.id}-${parties.length}'),
            initialValue: widget.value?.id,
            isExpanded: true,
            decoration: InputDecoration(labelText: widget.suppliers ? 'Supplier'.tr : 'Customer'.tr, errorText: widget.errorText),
            items: [
              for (final p in parties)
                DropdownMenuItem(
                  value: p.id,
                  child: Text(p.phone.isEmpty ? p.name : '${p.name} · ${p.phone}', overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (id) => widget.onChanged(parties.firstWhere((p) => p.id == id)),
          )
        else if (widget.errorText != null)
          Text(widget.errorText!, style: AppType.caption.copyWith(color: c.dangerInk)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _add,
            icon: Icon(PhosphorIconsRegular.plus, size: 18, color: c.brandText),
            label: Text(widget.suppliers ? 'New supplier'.tr : 'New customer'.tr),
          ),
        ),
      ],
    );
  }
}

/// Adds a customer or supplier: a name, and a phone number if they have one.
class _NewPartyDialog extends StatefulWidget {
  final bool suppliers;
  const _NewPartyDialog({required this.suppliers});

  @override
  State<_NewPartyDialog> createState() => _NewPartyDialogState();
}

class _NewPartyDialogState extends State<_NewPartyDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _problem;
  bool _saving = false;


  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final name = _name.text.trim();
    if (name.isEmpty) return setState(() => _problem = 'Enter a name.'.tr);
    setState(() {
      _saving = true;
      _problem = null;
    });
    final res = widget.suppliers
        ? await RecordService.addSupplier(name, _phone.text.trim())
        : await RecordService.addCustomer(name, _phone.text.trim());
    if (!mounted) return;
    if (res.error || res.data is! Map) {
      setState(() {
        _saving = false;
        _problem = res.message ?? (widget.suppliers ? 'Could not add the supplier.'.tr : 'Could not add the customer.'.tr);
      });
      return;
    }
    Navigator.pop(context, Party.from(Map<String, dynamic>.from(res.data)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.suppliers ? 'New supplier'.tr : 'New customer'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RecordTextField(controller: _name, label: 'Name'.tr, caps: TextCapitalization.words, maxLength: 120),
          const SizedBox(height: 12),
          RecordTextField(controller: _phone, label: 'Phone (optional)'.tr, keyboard: TextInputType.phone, maxLength: 32),
          if (_problem != null) ...[
            const SizedBox(height: 12),
            Text(_problem!, style: AppType.caption.copyWith(color: context.appColors.dangerInk)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel'.tr)),
        TextButton(onPressed: _saving ? null : _add, child: Text('Add'.tr)),
      ],
    );
  }
}
