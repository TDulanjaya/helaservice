import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/schedule_helpers.dart';

class JobScheduleResult {
  final String scheduleMode; // 'date_only', 'time_range', 'asap'
  final DateTime? scheduledDate;
  final DateTime? scheduledStartAt;
  final DateTime? scheduledEndAt;
  final String? legacySlot;

  const JobScheduleResult({
    required this.scheduleMode,
    this.scheduledDate,
    this.scheduledStartAt,
    this.scheduledEndAt,
    this.legacySlot,
  });

  // Backward compatibility getters for records like ({DateTime date, String slot})
  DateTime get date => scheduledDate ?? DateTime.now();
  String get slot => legacySlot ?? 'anytime';
}

// sheet to pick a job schedule (date only or time range)
class JobSchedulePicker extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialSlot;
  final String? initialMode;
  final TimeOfDay? initialFromTime;
  final TimeOfDay? initialToTime;
  final String? title;

  const JobSchedulePicker({
    super.key,
    this.initialDate,
    this.initialSlot,
    this.initialMode,
    this.initialFromTime,
    this.initialToTime,
    this.title,
  });

  static Future<JobScheduleResult?> pickSchedule(
    BuildContext context, {
    DateTime? initialDate,
    String? initialSlot,
    String? initialMode,
    TimeOfDay? initialFromTime,
    TimeOfDay? initialToTime,
    String? title,
  }) {
    return showModalBottomSheet<JobScheduleResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobSchedulePicker(
        initialDate: initialDate,
        initialSlot: initialSlot,
        initialMode: initialMode,
        initialFromTime: initialFromTime,
        initialToTime: initialToTime,
        title: title,
      ),
    );
  }

  @override
  State<JobSchedulePicker> createState() => _JobSchedulePickerState();
}

class _JobSchedulePickerState extends State<JobSchedulePicker> {
  late String _mode;
  late DateTime _selectedDate;
  TimeOfDay _fromTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 12, minute: 0);
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode ?? ScheduleHelpers.modeDateOnly;

    final now = DateTime.now();
    if (widget.initialDate != null &&
        !widget.initialDate!.isBefore(DateTime(now.year, now.month, now.day))) {
      _selectedDate = widget.initialDate!;
    } else {
      // Default to tomorrow if today is past cutoff
      if (!ScheduleHelpers.canChooseTodayForDateOnly()) {
        _selectedDate = now.add(const Duration(days: 1));
      } else {
        _selectedDate = now;
      }
    }

    if (widget.initialFromTime != null) _fromTime = widget.initialFromTime!;
    if (widget.initialToTime != null) _toTime = widget.initialToTime!;
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _validate();
      });
    }
  }

  Future<void> _pickTime(BuildContext context, bool isFrom) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? _fromTime : _toTime,
    );
    if (picked != null) {
      // Snap to 15-minute intervals
      final snappedMinute = (picked.minute / 15).round() * 15;
      final adjusted = snappedMinute == 60
          ? TimeOfDay(hour: (picked.hour + 1) % 24, minute: 0)
          : TimeOfDay(hour: picked.hour, minute: snappedMinute);

      setState(() {
        if (isFrom) {
          _fromTime = adjusted;
        } else {
          _toTime = adjusted;
        }
        _validate();
      });
    }
  }

  bool _validate() {
    final res = ScheduleHelpers.computeScheduleWindow(
      mode: _mode,
      date: _selectedDate,
      fromTime: _fromTime,
      toTime: _toTime,
    );

    setState(() {
      _errorMessage = res.isValid ? null : res.errorMessage;
    });

    return res.isValid;
  }

  void _submit() {
    if (!_validate()) return;

    final res = ScheduleHelpers.computeScheduleWindow(
      mode: _mode,
      date: _selectedDate,
      fromTime: _fromTime,
      toTime: _toTime,
    );

    if (!res.isValid) return;

    Navigator.pop(
      context,
      JobScheduleResult(
        scheduleMode: _mode,
        scheduledDate: res.scheduledDate,
        scheduledStartAt: res.scheduledStartAt,
        scheduledEndAt: res.scheduledEndAt,
        legacySlot: _mode == ScheduleHelpers.modeDateOnly
            ? 'anytime'
            : '${_fromTime.format(context)} - ${_toTime.format(context)}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final formattedDate = DateFormat.yMMMd(locale).format(_selectedDate);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.themeBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.title ?? context.l10n.selectScheduledDate,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mode toggle chips
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text(context.l10n.scheduleModeDateOnly),
                      selected: _mode == ScheduleHelpers.modeDateOnly,
                      onSelected: (sel) {
                        if (sel) {
                          setState(() {
                            _mode = ScheduleHelpers.modeDateOnly;
                            _validate();
                          });
                        }
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _mode == ScheduleHelpers.modeDateOnly
                            ? AppColors.primary
                            : context.themeTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text(context.l10n.scheduleModeTimeRange),
                      selected: _mode == ScheduleHelpers.modeTimeRange,
                      onSelected: (sel) {
                        if (sel) {
                          setState(() {
                            _mode = ScheduleHelpers.modeTimeRange;
                            _validate();
                          });
                        }
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _mode == ScheduleHelpers.modeTimeRange
                            ? AppColors.primary
                            : context.themeTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date selection
              Text(
                context.l10n.selectScheduledDate,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _pickDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.themeSurfaceLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_outlined,
                          size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down,
                          color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Mode-specific content
              if (_mode == ScheduleHelpers.modeDateOnly) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.scheduleAnyTime,
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Time range selection
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.scheduleFrom,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _pickTime(context, true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: context.themeSurfaceLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.themeBorder),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _fromTime.format(context),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14),
                                  ),
                                  const Icon(Icons.access_time_rounded,
                                      size: 16, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.scheduleTo,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _pickTime(context, false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: context.themeSurfaceLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.themeBorder),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _toTime.format(context),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14),
                                  ),
                                  const Icon(Icons.access_time_rounded,
                                      size: 16, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(context.l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        context.l10n.save,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
