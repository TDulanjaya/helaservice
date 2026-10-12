import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../repositories/booking_repository.dart';
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';
import 'primary_button.dart';

// bottom sheet for proposing a booking reschedule
class RescheduleSheet extends StatefulWidget {
  final Booking booking;
  final String currentUid;
  final String actorRole;

  const RescheduleSheet({
    super.key,
    required this.booking,
    required this.currentUid,
    required this.actorRole,
  });

  static Future<void> show({
    required BuildContext context,
    required Booking booking,
    required String currentUid,
    required String actorRole,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RescheduleSheet(
        booking: booking,
        currentUid: currentUid,
        actorRole: actorRole,
      ),
    );
  }

  @override
  State<RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<RescheduleSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = 'morning';
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
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
      lastDate: now.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.rescheduleReasonPrompt),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await BookingRepository().requestReschedule(
        bookingId: widget.booking.id,
        requestedBy: widget.currentUid,
        proposedDate: _selectedDate,
        proposedSlot: _getSlotLabel(context, _selectedSlot),
        reason: reason,
        actorRole: widget.actorRole,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.rescheduleRequestedNotice),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.somethingWentWrong}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
                    child: const Icon(Icons.calendar_month_rounded,
                        color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    context.l10n.rescheduleBooking,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.selectScheduledDate,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _pickDate(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.themeSurfaceLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.themeBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_outlined, size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        formattedDate,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.selectTimeSlot,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : context.themeSurfaceLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : context.themeBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: isSelected ? AppColors.primary : context.themeTextSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _getSlotLabel(context, slot),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : context.themeTextPrimary,
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
              const SizedBox(height: 12),
              Text(
                context.l10n.rescheduleReasonPrompt,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                style: TextStyle(color: context.themeTextPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: context.l10n.rescheduleReasonHint,
                  hintStyle: TextStyle(color: context.themeTextSecondary, fontSize: 13),
                  filled: true,
                  fillColor: context.themeSurfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.themeBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.themeBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: context.l10n.submitRescheduleRequest,
                loading: _isSubmitting,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// banner showing pending reschedule proposal on booking card
class RescheduleProposalBanner extends StatelessWidget {
  final Booking booking;
  final String currentUid;
  final String actorRole;

  const RescheduleProposalBanner({
    super.key,
    required this.booking,
    required this.currentUid,
    required this.actorRole,
  });

  @override
  Widget build(BuildContext context) {
    if (!booking.hasPendingReschedule) return const SizedBox.shrink();

    final isRequester = booking.rescheduleRequestedBy == currentUid;
    final proposedDate = booking.rescheduleProposedDate;
    final dateStr = proposedDate != null
        ? DateFormat('yyyy-MM-dd', Localizations.localeOf(context).languageCode).format(proposedDate)
        : '';
    final slotStr = booking.rescheduleProposedSlot ?? '';
    final reasonStr = booking.rescheduleReason ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.themeAmberTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.rescheduleProposalBanner,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${context.l10n.newTimeLabel} $dateStr ${slotStr.isNotEmpty ? "($slotStr)" : ""}',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: context.themeInk,
            ),
          ),
          if (reasonStr.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '${context.l10n.reasonLabel} $reasonStr',
              style: TextStyle(
                fontSize: 12,
                color: context.themeTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (!isRequester)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await BookingRepository().declineReschedule(
                        bookingId: booking.id,
                        declinedBy: currentUid,
                        actorRole: actorRole,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      context.l10n.declineReschedule,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await BookingRepository().acceptReschedule(
                        bookingId: booking.id,
                        acceptedBy: currentUid,
                        actorRole: actorRole,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      context.l10n.acceptReschedule,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.rescheduleRequestedNotice,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await BookingRepository().declineReschedule(
                      bookingId: booking.id,
                      declinedBy: currentUid,
                      actorRole: actorRole,
                    );
                  },
                  child: Text(
                    context.l10n.cancelRescheduleProposal,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
