import 'package:flutter/material.dart';
import '../../../models/technician.dart';
import '../../../repositories/technician_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';
import '../../../shared/widgets/primary_button.dart';

class WorkingHoursSheet extends StatefulWidget {
  final Technician technician;

  const WorkingHoursSheet({super.key, required this.technician});

  static Future<void> show(BuildContext context, Technician technician) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WorkingHoursSheet(technician: technician),
    );
  }

  @override
  State<WorkingHoursSheet> createState() => _WorkingHoursSheetState();
}

class _WorkingHoursSheetState extends State<WorkingHoursSheet> {
  late Map<String, WorkingDaySchedule> _schedule;
  bool _isSaving = false;

  final List<String> _daysOrder = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  @override
  void initState() {
    super.initState();
    _schedule = Map<String, WorkingDaySchedule>.from(
      widget.technician.workingHours.isNotEmpty
          ? widget.technician.workingHours
          : WorkingDaySchedule.defaultWeek(),
    );
  }

  String _getDayName(BuildContext context, String dayKey) {
    switch (dayKey) {
      case 'monday':
        return context.l10n.dayMonday;
      case 'tuesday':
        return context.l10n.dayTuesday;
      case 'wednesday':
        return context.l10n.dayWednesday;
      case 'thursday':
        return context.l10n.dayThursday;
      case 'friday':
        return context.l10n.dayFriday;
      case 'saturday':
        return context.l10n.daySaturday;
      case 'sunday':
        return context.l10n.daySunday;
      default:
        return dayKey;
    }
  }

  void _applyPresetWeekdays() {
    setState(() {
      _schedule = {
        'monday': const WorkingDaySchedule(
            enabled: true, start: '08:00', end: '18:00'),
        'tuesday': const WorkingDaySchedule(
            enabled: true, start: '08:00', end: '18:00'),
        'wednesday': const WorkingDaySchedule(
            enabled: true, start: '08:00', end: '18:00'),
        'thursday': const WorkingDaySchedule(
            enabled: true, start: '08:00', end: '18:00'),
        'friday': const WorkingDaySchedule(
            enabled: true, start: '08:00', end: '18:00'),
        'saturday': const WorkingDaySchedule(
            enabled: false, start: '08:00', end: '18:00'),
        'sunday': const WorkingDaySchedule(
            enabled: false, start: '08:00', end: '18:00'),
      };
    });
  }

  void _applyPresetAllDays() {
    setState(() {
      _schedule = {
        'monday': const WorkingDaySchedule(
            enabled: true, start: '08:00', end: '20:00'),
        'tuesday': const WorkingDaySchedule(
            enabled: true, start: '08:00', end: '20:00'),
        'wednesday': const WorkingDaySchedule(
            enabled: true, start: '08:00', end: '20:00'),
        'thursday': const WorkingDaySchedule(
            enabled: true, start: '08:00', end: '20:00'),
        'friday': const WorkingDaySchedule(
            enabled: true, start: '08:00', end: '20:00'),
        'saturday': const WorkingDaySchedule(
            enabled: true, start: '08:00', end: '20:00'),
        'sunday': const WorkingDaySchedule(
            enabled: true, start: '08:00', end: '20:00'),
      };
    });
  }

  void _applyPreset247() {
    setState(() {
      _schedule = {
        'monday': const WorkingDaySchedule(
            enabled: true, start: '00:00', end: '23:59'),
        'tuesday': const WorkingDaySchedule(
            enabled: true, start: '00:00', end: '23:59'),
        'wednesday': const WorkingDaySchedule(
            enabled: true, start: '00:00', end: '23:59'),
        'thursday': const WorkingDaySchedule(
            enabled: true, start: '00:00', end: '23:59'),
        'friday': const WorkingDaySchedule(
            enabled: true, start: '00:00', end: '23:59'),
        'saturday': const WorkingDaySchedule(
            enabled: true, start: '00:00', end: '23:59'),
        'sunday': const WorkingDaySchedule(
            enabled: true, start: '00:00', end: '23:59'),
      };
    });
  }

  Future<void> _pickTime(
      BuildContext context, String dayKey, bool isStart) async {
    final currentDay = _schedule[dayKey] ?? const WorkingDaySchedule();
    final timeStr = isStart ? currentDay.start : currentDay.end;
    final parts = timeStr.split(':').map(int.parse).toList();
    final initialTime =
        TimeOfDay(hour: parts[0], minute: parts.length > 1 ? parts[1] : 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        _schedule[dayKey] = WorkingDaySchedule(
          enabled: currentDay.enabled,
          start: isStart ? formatted : currentDay.start,
          end: isStart ? currentDay.end : formatted,
        );
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      await TechnicianRepository().updateWorkingHours(
        widget.technician.id,
        _schedule,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.savedScheduleSuccess),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('[WorkingHoursSheet] Failed to save schedule: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToSaveSchedule),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
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
                  child: const Icon(Icons.schedule_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.workingHoursTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPresetChip(
                    context,
                    label: context.l10n.presetWeekdays,
                    onTap: _applyPresetWeekdays,
                  ),
                  const SizedBox(width: 8),
                  _buildPresetChip(
                    context,
                    label: context.l10n.presetAllDays,
                    onTap: _applyPresetAllDays,
                  ),
                  const SizedBox(width: 8),
                  _buildPresetChip(
                    context,
                    label: context.l10n.preset247,
                    onTap: _applyPreset247,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView(
                children: _daysOrder.map((dayKey) {
                  final daySched =
                      _schedule[dayKey] ?? const WorkingDaySchedule();
                  final isEnabled = daySched.enabled;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isEnabled
                          ? context.themeSurfaceLow
                          : context.themeSurfaceLow.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isEnabled
                            ? AppColors.primary.withValues(alpha: 0.25)
                            : context.themeBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            _getDayName(context, dayKey),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: isEnabled
                                  ? context.themeInk
                                  : context.themeTextSecondary,
                            ),
                          ),
                        ),
                        if (isEnabled) ...[
                          InkWell(
                            onTap: () => _pickTime(context, dayKey, true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                daySched.start,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text('-',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          InkWell(
                            onTap: () => _pickTime(context, dayKey, false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                daySched.end,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          Text(
                            context.l10n.closedDay,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Switch(
                          value: isEnabled,
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() {
                              _schedule[dayKey] = WorkingDaySchedule(
                                enabled: val,
                                start: daySched.start,
                                end: daySched.end,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: context.l10n.saveChanges,
              loading: _isSaving,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(BuildContext context,
      {required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: context.themeSurfaceLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.themeBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: context.themeInk,
          ),
        ),
      ),
    );
  }
}
