import 'package:flutter/material.dart';
import '../../../constants/job_status.dart';
import '../../../models/booking.dart';
import '../../../repositories/booking_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';
import '../../support/screens/help_support_screen.dart';

// booking cancellation sheet for customer and provider
class BookingCancellationSheet extends StatefulWidget {
  final Booking booking;
  final bool isCustomer;
  final VoidCallback? onCancelled;

  const BookingCancellationSheet({
    super.key,
    required this.booking,
    required this.isCustomer,
    this.onCancelled,
  });

  // helper to show the cancellation bottom sheet
  static Future<bool?> show(
    BuildContext context, {
    required Booking booking,
    required bool isCustomer,
    VoidCallback? onCancelled,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingCancellationSheet(
        booking: booking,
        isCustomer: isCustomer,
        onCancelled: onCancelled,
      ),
    );
  }

  @override
  State<BookingCancellationSheet> createState() =>
      _BookingCancellationSheetState();
}

class _BookingCancellationSheetState extends State<BookingCancellationSheet> {
  String? _selectedReason;
  bool _chooseAnotherQuote = true;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final status = widget.booking.status;
    final isBlocked = status == JobStatus.inProgress ||
        status == JobStatus.completed;

    if (isBlocked) {
      return _buildBlockedContent(context);
    }

    final reasons = widget.isCustomer
        ? [
            context.l10n.cancelReasonFoundSomeone,
            context.l10n.cancelReasonNoLongerNeeded,
            context.l10n.cancelReasonScheduleConflict,
            context.l10n.cancelReasonPriceDispute,
            context.l10n.cancelReasonOther,
          ]
        : [
            context.l10n.providerCancelReasonEmergency,
            context.l10n.providerCancelReasonBreakdown,
            context.l10n.providerCancelReasonUnreachable,
            context.l10n.providerCancelReasonScope,
            context.l10n.cancelReasonOther,
          ];

    _selectedReason ??= reasons.first;

    final hasQuotes = widget.booking.jobRequestId != null &&
        widget.booking.jobRequestId!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
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
                      color: AppColors.error.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: AppColors.error,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.cancelBookingOrQuote,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          context.l10n.cancellationReasonPrompt,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (status == JobStatus.enRoute) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.isCustomer
                              ? context.l10n.providerEnRouteWarning
                              : context.l10n.providerSelfEnRouteWarning,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: context.themeTextPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                context.l10n.cancellationReasonPrompt,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: context.themeSurfaceLow,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.themeBorder),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedReason,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down_rounded),
                    items: reasons
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(
                              r,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _isSubmitting
                        ? null
                        : (val) {
                            if (val != null) {
                              setState(() => _selectedReason = val);
                            }
                          },
                  ),
                ),
              ),
              if (widget.isCustomer && hasQuotes) ...[
                const SizedBox(height: 20),
                Text(
                  context.l10n.cancelJobActionTitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _buildOptionTile(
                  selected: _chooseAnotherQuote,
                  title: context.l10n.cancelJobOptionB,
                  subtitle: context.l10n.cancelJobOptionBDesc,
                  onTap: () => setState(() => _chooseAnotherQuote = true),
                ),
                const SizedBox(height: 8),
                _buildOptionTile(
                  selected: !_chooseAnotherQuote,
                  title: context.l10n.cancelJobOptionA,
                  subtitle: context.l10n.cancelJobOptionADesc,
                  onTap: () => setState(() => _chooseAnotherQuote = false),
                ),
              ],
              const SizedBox(height: 24),
              // action buttons stack on small screen
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleConfirmCancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            context.l10n.confirmCancellation,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: context.themeBorder),
                    ),
                    child: Text(
                      context.l10n.keepBooking,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.themeTextPrimary,
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

  Widget _buildOptionTile({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _isSubmitting ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : context.themeSurfaceLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : context.themeBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 18,
                color: selected
                    ? AppColors.primary
                    : context.themeTextSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.primary
                          : context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.themeTextSecondary,
                      height: 1.3,
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

  Widget _buildBlockedContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.themeBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Icon(
              Icons.support_agent_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 14),
            Text(
              context.l10n.cannotCancelInProgressBooking,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HelpSupportScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.help_outline_rounded, size: 18),
              label: Text(context.l10n.contactSupport),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: BorderSide(color: context.themeBorder),
              ),
              child: Text(
                context.l10n.cancel,
                style: TextStyle(
                  color: context.themeTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleConfirmCancel() async {
    final reason = _selectedReason ?? context.l10n.cancelReasonOther;
    setState(() => _isSubmitting = true);

    try {
      await BookingRepository().cancelBooking(
        bookingId: widget.booking.id,
        reason: reason,
        cancelledByRole: widget.isCustomer ? 'customer' : 'provider',
        jobRequestId: widget.booking.jobRequestId,
        chooseAnotherQuote: widget.isCustomer && _chooseAnotherQuote,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        widget.onCancelled?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.bookingCancelledSuccess),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.somethingWentWrong),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

