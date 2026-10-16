import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/app_colors.dart';
import '../../services/app_type.dart';
import '../../widgets/ledger.dart';
import '../../widgets/phosphor_icons.dart';
import '../records/record_form.dart';
import '../records/record_forms.dart';
import '../records/record_menu.dart';
import 'field_service.dart';
import 'field_widgets.dart';
import '../../l10n/tr.dart';

/// One field: its photo, how it is doing, and the jobs in its plan.
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
    final heroH = MediaQuery.sizeOf(context).height * 0.42;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: c.cardBackground,
        floatingActionButton: f.isActive
            ? FloatingActionButton.extended(
                onPressed: _recordAny,
                backgroundColor: c.shamba,
                foregroundColor: c.onShamba,
                icon: const Icon(PhosphorIconsBold.plus),
                label: Text('Record'.tr),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: _load,
          color: c.shamba,
          edgeOffset: MediaQuery.paddingOf(context).top,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SizedBox(height: heroH, width: double.infinity, child: FieldPhoto(type: f.type)),
                    Positioned(
                      left: 16,
                      top: MediaQuery.paddingOf(context).top + 8,
                      child: const PhotoBackButton(),
                    ),
                    // The card sits on the photo's lower edge.
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, heroH - 84, 16, 0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 20, offset: const Offset(0, 6))],
                        ),
                        child: FieldCard(field: f),
                      ),
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                sliver: SliverList.list(children: [
                  Row(
                    children: [
                      Expanded(child: Text('Field analysis'.tr, style: AppType.titleM.copyWith(color: c.textPrimary))),
                      Icon(PhosphorIconsFill.sparkle, size: 18, color: c.brandText),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildMetrics(c),
                  const SizedBox(height: 28),
                  _buildTasksHead(c),
                  const SizedBox(height: 12),
                  ..._buildTasks(c),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetrics(AppColors c) {
    final tints = [c.warnTint, c.rainTint, c.brandSoft];
    final icons = f.isCrop
        ? [PhosphorIconsRegular.plant, PhosphorIconsRegular.cloudRain, PhosphorIconsRegular.drop]
        : [PhosphorIconsRegular.chartLine, PhosphorIconsRegular.heartbeat, PhosphorIconsRegular.coins];
    final inks = [c.warnInk, c.rainInk, c.brandText];
    final metrics = _metrics;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: tints[i], borderRadius: BorderRadius.circular(14)),
                child: metrics == null
                    ? const SizedBox(height: 86)
                    : i >= metrics.length
                        ? const SizedBox(height: 86)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(icons[i], size: 16, color: inks[i]),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(metrics[i].label,
                                        style: AppType.caption.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(metrics[i].value, style: AppType.figureL.copyWith(color: c.textPrimary)),
                              ),
                              if (metrics[i].note != null && metrics[i].note!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(_cap(metrics[i].note!), style: AppType.caption.copyWith(fontSize: 12, color: c.textSecondary)),
                              ],
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(f.isCrop ? 'Activity this field'.tr : 'Vaccinations'.tr,
              style: AppType.titleM.copyWith(color: c.textPrimary)),
        ),
        if (tasks != null && tasks.isNotEmpty)
          Text('{done} / {total} completed'.trArgs({'done': done, 'total': tasks.length}), style: AppType.label.copyWith(color: c.textSecondary)),
      ],
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
        height: 76,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(14)),
      );

  IconData _taskIcon(FieldTask t) => switch (t.code) {
        'land_preparation' => PhosphorIconsRegular.shovel,
        'planting' => PhosphorIconsRegular.plant,
        'weeding' => PhosphorIconsRegular.scissors,
        'fertilising' => PhosphorIconsRegular.drop,
        'spraying' => PhosphorIconsRegular.sprayBottle,
        _ => PhosphorIconsRegular.syringe,
      };

  Widget _taskCard(AppColors c, FieldTask t) {
    final dateText = t.date == null
        ? (t.done ? 'Done'.tr : 'To do'.tr)
        : t.done
            ? 'Done {date}'.trArgs({'date': DateFormat('d MMM').format(t.date!)})
            : 'Due {date}'.trArgs({'date': DateFormat('EEE d MMM').format(t.date!)});
    final canRecord = f.isActive && !t.done && (f.isCrop ? t.code != null : t.vaccine != null);

    Widget trailing;
    if (f.isCrop) {
      trailing = Icon(
        t.done ? PhosphorIconsFill.checkSquare : PhosphorIconsRegular.square,
        size: 26,
        color: t.done ? c.brandText : c.border,
      );
    } else {
      trailing = switch (t.status) {
        'done' => SlStatusTag('Done'.tr, status: SlStatus.good),
        'overdue' => SlStatusTag('Overdue'.tr, status: SlStatus.danger),
        'due' => SlStatusTag('Due soon'.tr, status: SlStatus.warn),
        _ => SlStatusTag('Upcoming'.tr),
      };
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: c.scaffoldBackground,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canRecord ? () => _record(t) : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: c.brandSoft, borderRadius: BorderRadius.circular(10)),
                  child: Icon(_taskIcon(t), size: 22, color: c.brandText),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FieldChip(dateText, bg: c.cardBackground, fg: c.textSecondary),
                      const SizedBox(height: 6),
                      Text(
                        t.title,
                        style: AppType.label.copyWith(
                          fontSize: 16,
                          color: t.done ? c.textSecondary : c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Semantics(
                  label: t.done ? 'Done'.tr : (canRecord ? 'Not done. Tap to record'.tr : 'Not done'.tr),
                  child: trailing,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
