import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';

// sheet to pick a job date and time slot
class JobSchedulePicker extends StatefulWidget {
  final DateTime? initialDate;
  final String? initialSlot;
  final String? title;

  const JobSchedulePicker({
    super.key,
    this.initialDate,
    this.initialSlot,
    this.title,
  });

  static Future<({DateTime date, String slot})?> pickSchedule(
    BuildContext context, {
    DateTime? initialDate,
    String? initialSlot,
    String? title,
  }) {
    return showModalBottomSheet<({DateTime date, String slot})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobSchedulePicker(
        initialDate: initialDate,
        initialSlot: initialSlot,
        title: title,
      ),
    );
  }

  @override
  State<JobSchedulePicker> createState() => _JobSchedulePickerState();
}

class _JobSchedulePickerState extends State<JobSchedulePicker> {
  late DateTime _selectedDate;
  String _selectedSlot = 'morning';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    if (widget.initialDate != null && !widget.initialDate!.isBefore(now)) {
      _selectedDate = widget.initialDate!;
    } else {
      _selectedDate = now.add(const Duration(days: 1));
    }

    if (widget.initialSlot != null) {
      final s = widget.initialSlot!.toLowerCase();
      if (s.contains('afternoon') ||
          s.contains('12:00') ||
          s.contains('දහවල්') ||
          s.contains('மதியம்')) {
        _selectedSlot = 'afternoon';
      } else if (s.contains('evening') ||
          s.contains('4:00') ||
          s.contains('සවස') ||
          s.contains('மாலை')) {
        _selectedSlot = 'evening';
      } else {
        _selectedSlot = 'morning';
      }
    }
  }

  String _getSlotLabel(BuildContext context, String slotKey) {
    switch (slotKey) {
      case 'morning':
        return context.l10n.slotMorning;
      case 'afternoon':
        return context.l10n.slotAfternoon;
      case 'evening':
        return context.l10n.slotEvening;
      default:
        return slotKey;
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
      setState(() => _selectedDate = picked);
    }
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
              Text(
                context.l10n.selectTimeSlot,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Column(
                children: ['morning', 'afternoon', 'evening'].map((slot) {
                  final isSelected = _selectedSlot == slot;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => setState(() => _selectedSlot = slot),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : context.themeSurfaceLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : context.themeBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected
                                  ? AppColors.primary
                                  : context.themeTextSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _getSlotLabel(context, slot),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : context.themeTextPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
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
                      onPressed: () {
                        Navigator.pop(context, (
                          date: _selectedDate,
                          slot: _getSlotLabel(context, _selectedSlot),
                        ));
                      },
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
