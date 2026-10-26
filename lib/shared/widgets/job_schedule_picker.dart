import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';
import '../../utils/schedule_helpers.dart';

class JobScheduleResult {
  final String scheduleMode;
  final String? scheduledSlot;
  final DateTime? scheduledDate;
  final DateTime? scheduledStartAt;
  final DateTime? scheduledEndAt;
  final DateTime? expiresAt;
  final int? flexibleWindowDays;
  final String? legacySlot;

  const JobScheduleResult({
    required this.scheduleMode,
    this.scheduledSlot,
    this.scheduledDate,
    this.scheduledStartAt,
    this.scheduledEndAt,
    this.expiresAt,
    this.flexibleWindowDays,
    this.legacySlot,
  });

  DateTime get date => scheduledDate ?? DateTime.now();
  String get slot => scheduledSlot ?? legacySlot ?? 'anytime';
}

// sheet to pick a job schedule
class JobSchedulePicker extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialSlot;
  final String? initialMode;
  final TimeOfDay? initialFromTime;
  final TimeOfDay? initialToTime;
  final int? initialFlexibleDays;
  final String? title;
  final Widget? note;
  final Widget Function(
    BuildContext context,
    JobScheduleResult? Function() getSchedule,
    String? Function() getScheduleError,
  )? actionsBuilder;

  const JobSchedulePicker({
    super.key,
    this.initialDate,
    this.initialSlot,
    this.initialMode,
    this.initialFromTime,
    this.initialToTime,
    this.initialFlexibleDays,
    this.title,
    this.note,
    this.actionsBuilder,
  });

  static Future<JobScheduleResult?> pickSchedule(
    BuildContext context, {
    DateTime? initialDate,
    String? initialSlot,
    String? initialMode,
    TimeOfDay? initialFromTime,
    TimeOfDay? initialToTime,
    int? initialFlexibleDays,
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
        initialFlexibleDays: initialFlexibleDays,
        title: title,
      ),
    );
  }

  @override
  State<JobSchedulePicker> createState() => _JobSchedulePickerState();
}

class _JobSchedulePickerState extends State<JobSchedulePicker> {
  late String _mode;
  late String _slot;
  late DateTime _selectedDate;
  TimeOfDay _fromTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 12, minute: 0);
  int _flexibleDays = 7;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final initialModeNorm = ScheduleHelpers.normalizeMode(widget.initialMode);

    if (initialModeNorm == ScheduleHelpers.modeToday &&
        !ScheduleHelpers.canChooseToday(now)) {
      _mode = ScheduleHelpers.modeDate;
    } else {
      _mode = initialModeNorm;
    }

    _slot = widget.initialSlot ?? ScheduleHelpers.slotAnytime;
    if (widget.initialFlexibleDays != null) {
      _flexibleDays = widget.initialFlexibleDays!;
    }

    if (widget.initialDate != null &&
        !widget.initialDate!.isBefore(DateTime(now.year, now.month, now.day))) {
      _selectedDate = widget.initialDate!;
    } else {
      if (!ScheduleHelpers.canChooseToday()) {
        _selectedDate = now.add(const Duration(days: 1));
      } else {
        _selectedDate = now;
      }
    }

    if (widget.initialFromTime != null) _fromTime = widget.initialFromTime!;
    if (widget.initialToTime != null) _toTime = widget.initialToTime!;

    final initialRes = ScheduleHelpers.computeScheduleWindow(
      mode: _mode,
      slot: _slot,
      date: _selectedDate,
      fromTime: _fromTime,
      toTime: _toTime,
      flexibleDays: _flexibleDays,
    );
    if (!initialRes.isValid) {
      _errorMessage = initialRes.errorMessage;
    }
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
      slot: _slot,
      date: _selectedDate,
      fromTime: _fromTime,
      toTime: _toTime,
      flexibleDays: _flexibleDays,
    );

    setState(() {
      _errorMessage = res.isValid ? null : res.errorMessage;
    });

    return res.isValid;
  }

  JobScheduleResult? _computeResult() {
    if (!_validate()) return null;

    final res = ScheduleHelpers.computeScheduleWindow(
      mode: _mode,
      slot: _slot,
      date: _selectedDate,
      fromTime: _fromTime,
      toTime: _toTime,
      flexibleDays: _flexibleDays,
    );

    if (!res.isValid) return null;

    return JobScheduleResult(
      scheduleMode: _mode,
      scheduledSlot: res.scheduledSlot,
      scheduledDate: res.scheduledDate,
      scheduledStartAt: res.scheduledStartAt,
      scheduledEndAt: res.scheduledEndAt,
      expiresAt: res.expiresAt,
      flexibleWindowDays: res.flexibleWindowDays,
      legacySlot: res.scheduledSlot ?? 'anytime',
    );
  }

  String? _getScheduleError() {
    final res = ScheduleHelpers.computeScheduleWindow(
      mode: _mode,
      slot: _slot,
      date: _selectedDate,
      fromTime: _fromTime,
      toTime: _toTime,
      flexibleDays: _flexibleDays,
    );
    return res.isValid ? null : res.errorMessage;
  }

  void _submit() {
    final result = _computeResult();
    if (result != null) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final formattedDate = DateFormat.yMMMd(locale).format(_selectedDate);
    final isTodayAvailable = ScheduleHelpers.canChooseToday();

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
                      widget.title ?? context.l10n.whenDoYouNeedThis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.note != null) ...[
                const SizedBox(height: 12),
                widget.note!,
              ],
              const SizedBox(height: 16),

              // mode selection chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text(context.l10n.scheduleModeToday),
                      selected: _mode == ScheduleHelpers.modeToday,
                      onSelected: isTodayAvailable
                          ? (sel) {
                              if (sel) {
                                setState(() {
                                  _mode = ScheduleHelpers.modeToday;
                                  if (_slot == ScheduleHelpers.slotExact) {
                                    _slot = ScheduleHelpers.slotAnytime;
                                  }
                                  _validate();
                                });
                              }
                            }
                          : null,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _mode == ScheduleHelpers.modeToday
                            ? AppColors.primary
                            : (isTodayAvailable
                                ? context.themeTextSecondary
                                : context.themeTextSecondary
                                    .withValues(alpha: 0.4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(context.l10n.scheduleModeSpecificDay),
                      selected: _mode == ScheduleHelpers.modeDate,
                      onSelected: (sel) {
                        if (sel) {
                          setState(() {
                            _mode = ScheduleHelpers.modeDate;
                            _validate();
                          });
                        }
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _mode == ScheduleHelpers.modeDate
                            ? AppColors.primary
                            : context.themeTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(context.l10n.scheduleModeFlexible),
                      selected: _mode == ScheduleHelpers.modeFlexible,
                      onSelected: (sel) {
                        if (sel) {
                          setState(() {
                            _mode = ScheduleHelpers.modeFlexible;
                            _slot = ScheduleHelpers.slotAnytime;
                            _validate();
                          });
                        }
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _mode == ScheduleHelpers.modeFlexible
                            ? AppColors.primary
                            : context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              if (!isTodayAvailable && _mode == ScheduleHelpers.modeToday) ...[
                const SizedBox(height: 8),
                Text(
                  context.l10n.todayDisabledPast20,
                  style:
                      const TextStyle(fontSize: 11.5, color: AppColors.warning),
                ),
              ],

              const SizedBox(height: 16),

              // today options
              if (_mode == ScheduleHelpers.modeToday) ...[
                Text(
                  context.l10n.selectTimeSlot,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _buildSlotChoices(isToday: true),
              ],

              // date options
              if (_mode == ScheduleHelpers.modeDate) ...[
                Text(
                  context.l10n.selectScheduledDate,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _pickDate(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
                const SizedBox(height: 14),
                Text(
                  context.l10n.selectTimeSlot,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _buildSlotChoices(
                    isToday: ScheduleHelpers.isToday(_selectedDate)),
                if (_slot == ScheduleHelpers.slotExact) ...[
                  const SizedBox(height: 12),
                  _buildExactTimePickers(),
                ],
              ],

              // flexible options
              if (_mode == ScheduleHelpers.modeFlexible) ...[
                Text(
                  context.l10n.scheduleModeFlexible,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text(context.l10n.flexibleWithin3Days),
                      selected: _flexibleDays == 3,
                      onSelected: (sel) {
                        if (sel) {
                          setState(() {
                            _flexibleDays = 3;
                            _validate();
                          });
                        }
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    ),
                    ChoiceChip(
                      label: Text(context.l10n.flexibleWithinWeek),
                      selected: _flexibleDays == 7,
                      onSelected: (sel) {
                        if (sel) {
                          setState(() {
                            _flexibleDays = 7;
                            _validate();
                          });
                        }
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                    ),
                    ChoiceChip(
                      label: Text(context.l10n.flexibleWithin2Weeks),
                      selected: _flexibleDays == 14,
                      onSelected: (sel) {
                        if (sel) {
                          setState(() {
                            _flexibleDays = 14;
                            _validate();
                          });
                        }
                      },
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
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
              if (widget.actionsBuilder != null) ...[
                widget.actionsBuilder!(context, _computeResult, _getScheduleError),
              ] else ...[
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotChoices({required bool isToday}) {
    final now = DateTime.now();
    final morningOk = !isToday ||
        ScheduleHelpers.isSlotAvailableToday(ScheduleHelpers.slotMorning, now);
    final afternoonOk = !isToday ||
        ScheduleHelpers.isSlotAvailableToday(
            ScheduleHelpers.slotAfternoon, now);
    final eveningOk = !isToday ||
        ScheduleHelpers.isSlotAvailableToday(ScheduleHelpers.slotEvening, now);
    final anytimeOk = !isToday ||
        ScheduleHelpers.isSlotAvailableToday(ScheduleHelpers.slotAnytime, now);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(context.l10n.slotAnytimeShort),
          selected: _slot == ScheduleHelpers.slotAnytime,
          onSelected: anytimeOk
              ? (sel) {
                  if (sel) {
                    setState(() {
                      _slot = ScheduleHelpers.slotAnytime;
                      _validate();
                    });
                  }
                }
              : null,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
        ),
        ChoiceChip(
          label: Text(context.l10n.slotMorningShort),
          selected: _slot == ScheduleHelpers.slotMorning,
          onSelected: morningOk
              ? (sel) {
                  if (sel) {
                    setState(() {
                      _slot = ScheduleHelpers.slotMorning;
                      _validate();
                    });
                  }
                }
              : null,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
        ),
        ChoiceChip(
          label: Text(context.l10n.slotAfternoonShort),
          selected: _slot == ScheduleHelpers.slotAfternoon,
          onSelected: afternoonOk
              ? (sel) {
                  if (sel) {
                    setState(() {
                      _slot = ScheduleHelpers.slotAfternoon;
                      _validate();
                    });
                  }
                }
              : null,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
        ),
        ChoiceChip(
          label: Text(context.l10n.slotEveningShort),
          selected: _slot == ScheduleHelpers.slotEvening,
          onSelected: eveningOk
              ? (sel) {
                  if (sel) {
                    setState(() {
                      _slot = ScheduleHelpers.slotEvening;
                      _validate();
                    });
                  }
                }
              : null,
          selectedColor: AppColors.primary.withValues(alpha: 0.15),
        ),
        if (_mode == ScheduleHelpers.modeDate)
          ChoiceChip(
            label: Text(context.l10n.slotExactTime),
            selected: _slot == ScheduleHelpers.slotExact,
            onSelected: (sel) {
              if (sel) {
                setState(() {
                  _slot = ScheduleHelpers.slotExact;
                  _validate();
                });
              }
            },
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
          ),
      ],
    );
  }

  Widget _buildExactTimePickers() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.l10n.scheduleFrom,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _pickTime(context, true),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.themeSurfaceLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_fromTime.format(context),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
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
              Text(context.l10n.scheduleTo,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _pickTime(context, false),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: context.themeSurfaceLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_toTime.format(context),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
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
    );
  }
}
