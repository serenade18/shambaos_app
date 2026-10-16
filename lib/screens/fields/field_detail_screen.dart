import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger.dart';
import '../../widgets/ledger_parts.dart';
import '../auth/auth_ui.dart';
import '../../widgets/phosphor_icons.dart';
import '../records/record_form.dart';
import '../records/record_forms.dart';
import '../records/record_menu.dart';
import 'field_service.dart';
import 'field_widgets.dart';
import '../../l10n/tr.dart';

/// One field, as the design's field page: its photo with the field's card,
/// how it is doing, the jobs in its plan, and Record today.
class FieldDetailScreen extends StatefulWidget {
  final Field field;
  final List<FieldMetric>? metrics;
  final List<FieldTask>? tasks;

  const FieldDetailScreen({super.key, required this.field, this.metrics, this.tasks});

  @override
  State<FieldDetailScreen> createState() => _FieldDetailScreenState();
}

class _FieldDetailScreenState extends State<FieldDetailScreen> {
  List<FieldMetric>? _metrics;
  List<FieldTask>? _tasks;
  String? _error; // why the analysis or plan could not load

  Field get f => widget.field;

  @override
  void initState() {
    super.initState();
    _metrics = widget.metrics;
    _tasks = widget.tasks;
    if (_metrics == null || _tasks == null) _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final results = await Future.wait([FieldService.analyse(f), FieldService.tasks(f)]);
      if (!mounted) return;
      setState(() {
        _metrics = results[0] as List<FieldMetric>;
        _tasks = results[1] as List<FieldTask>;
      });
    } on FieldLoadError catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// A job in the plan opens its form, filled in: the crop work, or the vaccine due.
  Future<void> _record(FieldTask t) async {
    final form = f.isCrop ? ActivityForm(field: f, type: t.code) : TreatmentForm(field: f, step: t);
    if (await openRecord(context, form)) _load();
  }

  Future<void> _recordAny() async {
    if (await openFieldRecordMenu(context, f)) _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.scaffoldBackground,
        body: Stack(children: [
          RefreshIndicator(
            onRefresh: _load,
            color: c.shamba,
            edgeOffset: top,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _hero(c, top)),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, (f.isActive ? 104 : 24) + bottom),
                  sliver: SliverList.list(children: [
                    _sectionHead(c, 'Field analysis'.tr, null),
                    const SizedBox(height: 10),
                    _buildMetrics(c),
                    const SizedBox(height: 20),
                    _buildTasksHead(c),
                    const SizedBox(height: 10),
                    ..._buildTasks(c),
                  ]),
                ),
              ],
            ),
          ),
          // Record today, fixed at the bottom over a fade of the page.
          if (f.isActive)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 24, 16, 24 + bottom),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.35],
                    colors: [c.scaffoldBackground.withValues(alpha: 0), c.scaffoldBackground],
                  ),
                ),
                child: LedgerButton(
                  label: 'Record today'.tr,
                  icon: const LineIcon('<path d="M5 12h14"/><path d="M12 5v14"/>', size: 20, color: Colors.white),
                  onPressed: _recordAny,
                ),
              ),
            ),
        ]),
      ),
    );
  }

  /// The photo with rounded bottom corners, a frosted back button, and the
  /// field's card on a frosted panel at its foot (the design's sl-hero).
  Widget _hero(AppColors c, double top) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
      child: SizedBox(
        height: 300 + top,
        child: Stack(children: [
          Positioned.fill(child: ColoredBox(color: c.shamba)),
          Positioned.fill(child: FieldPhoto(type: f.type)),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 140 + top,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x7317211A), Color(0x0017211A)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            top: top + 20,
            child: Semantics(
              button: true,
              label: 'Back'.tr,
              excludeSemantics: true,
              child: _glass(
                c,
                radius: 999,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.maybePop(context),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(child: LineIcon('<path d="m12 19-7-7 7-7"/><path d="M19 12H5"/>', size: 22, color: c.textPrimary)),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _glass(
              c,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  FieldIconTile(field: f, width: 72, height: 64, iconSize: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(f.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: AppType.text, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, color: c.textPrimary)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        f.isActive ? SlTag('Active'.tr, tone: SlTone.good, icon: SlTag.check) : SlTag('Closed'.tr),
                        if (f.size.isNotEmpty) SlTag(f.size),
                      ]),
                      const SizedBox(height: 4),
                      Text(f.startedLine, style: AppType.caption.copyWith(color: c.textSecondary)),
                    ]),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  /// A frosted panel over the photo (sl-glass).
  Widget _glass(AppColors c, {required Widget child, double radius = 24}) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Material(color: c.cardBackground.withValues(alpha: 0.86), child: child),
        ),
      );

  Widget _sectionHead(AppColors c, String title, String? note) => Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(title,
                style: TextStyle(fontFamily: AppType.text, fontSize: 19, height: 24 / 19, fontWeight: FontWeight.w500, color: c.textPrimary)),
          ),
          if (note != null) Text(note, style: AppType.caption.copyWith(color: c.textSecondary)),
        ],
      );

  /// Three tiles (sl-metric): green, blue, then white.
  Widget _buildMetrics(AppColors c) {
    final tiles = [(c.goodTint, c.goodInk), (c.rainTint, c.rainInk), (c.cardBackground, c.textSecondary)];
    final metrics = _metrics;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 116),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: tiles[i].$1, borderRadius: BorderRadius.circular(24)),
                child: metrics == null || i >= metrics.length
                    ? const SizedBox()
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(metrics[i].label, style: AppType.caption.copyWith(color: tiles[i].$2)),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(metrics[i].value,
                                  style: TextStyle(
                                      fontFamily: AppType.text,
                                      fontSize: 28,
                                      height: 32 / 28,
                                      fontWeight: FontWeight.w500,
                                      color: c.textPrimary,
                                      fontFeatures: const [FontFeature.tabularFigures()])),
                            ),
                            if (metrics[i].note != null && metrics[i].note!.isNotEmpty)
                              Text(_cap(metrics[i].note!), style: AppType.caption.copyWith(fontSize: 12, color: c.textSecondary)),
                          ]),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTasksHead(AppColors c) {
    final tasks = _tasks;
    final done = tasks?.where((t) => t.done).length ?? 0;
    return _sectionHead(
      c,
      f.isCrop ? 'Activity this field'.tr : 'Vaccinations'.tr,
      tasks == null || tasks.isEmpty ? null : '{done} / {total} completed'.trArgs({'done': done, 'total': tasks.length}),
    );
  }

  List<Widget> _buildTasks(AppColors c) {
    final tasks = _tasks;
    if (_error != null && tasks == null) {
      return [
        SlLedger(children: [
          SlLedgerRow(title: 'Could not load this field'.tr, meta: _error),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(onPressed: _load, child: Text('Try again'.tr)),
            ),
          ),
        ]),
      ];
    }
    if (tasks == null) {
      return [for (var i = 0; i < 3; i++) _taskSkeleton(c)];
    }
    if (tasks.isEmpty) {
      return [
        SlLedger(children: [SlLedgerRow(title: 'Nothing planned'.tr, meta: 'No vaccinations are due for this group.'.tr)]),
      ];
    }
    return [for (final t in tasks) _taskCard(c, t)];
  }

  Widget _taskSkeleton(AppColors c) => Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(24)),
      );

  IconData _taskIcon(FieldTask t) => switch (t.code) {
        'land_preparation' => PhosphorIconsRegular.shovel,
        'planting' => PhosphorIconsRegular.plant,
        'weeding' => PhosphorIconsRegular.scissors,
        'fertilising' => PhosphorIconsRegular.drop,
        'spraying' => PhosphorIconsRegular.sprayBottle,
        _ => PhosphorIconsRegular.syringe,
      };

  /// A job as the design's task card (sl-task): an icon, its date as a tag,
  /// what to do, and a tick box. Due and overdue jobs are drawn in warning
  /// colours; done ones are crossed through.
  Widget _taskCard(AppColors c, FieldTask t) {
    final today = DateUtils.dateOnly(DateTime.now());
    final overdue = !t.done && (t.status == 'overdue' || (t.status == null && t.date != null && t.date!.isBefore(today)));
    // Due: the server says so, or (crop jobs, which carry no status) it falls within the week.
    final due = !t.done &&
        !overdue &&
        (t.status == 'due' || (t.status == null && t.date != null && t.date!.difference(today).inDays <= 7));
    final dateText = t.date == null
        ? (t.done ? 'Done'.tr : (overdue ? 'Overdue'.tr : 'To do'.tr))
        : t.done
            ? 'Done {date}'.trArgs({'date': DateFormat('d MMM').format(t.date!)})
            : overdue
                ? 'Overdue since {date}'.trArgs({'date': DateFormat('EEE d MMM').format(t.date!)})
                : 'Due {date}'.trArgs({'date': DateFormat('EEE d MMM').format(t.date!)});
    final tone = t.done ? SlTone.neutral : overdue ? SlTone.danger : due ? SlTone.warn : SlTone.neutral;
    final (wellBg, wellFg) = t.done ? (c.brandSoft, c.brandText) : overdue ? (c.dangerTint, c.dangerInk) : due ? (c.warnTint, c.warnInk) : (c.rainTint, c.rainInk);
    final canRecord = f.isActive && !t.done && (f.isCrop ? t.code != null : t.vaccine != null);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SlCard(
        onTap: canRecord ? () => _record(t) : null,
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: wellBg, shape: BoxShape.circle),
              child: Icon(_taskIcon(t), size: 22, color: wellFg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SlTag(dateText, tone: tone),
                const SizedBox(height: 4),
                Text(
                  t.title,
                  style: AppType.body.copyWith(
                    color: t.done ? c.textSecondary : c.textPrimary,
                    decoration: t.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ]),
            ),
            Semantics(
              label: t.done ? 'Done'.tr : (canRecord ? 'Not done. Tap to record'.tr : 'Not done'.tr),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: t.done ? c.shamba : null,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: t.done ? c.shamba : c.border, width: 1.5),
                    ),
                    child: t.done ? Center(child: LineIcon(SlTag.check, size: 16, strokeWidth: 3, color: c.onShamba)) : null,
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
