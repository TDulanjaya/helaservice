import 'package:flutter/material.dart';
import '../../../models/booking.dart';
import '../../../models/booking_extra.dart';
import '../../../repositories/booking_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';

class CustomerPaymentCard extends StatefulWidget {
  final Booking booking;
  final VoidCallback? onUpdated;

  const CustomerPaymentCard({
    super.key,
    required this.booking,
    this.onUpdated,
  });

  @override
  State<CustomerPaymentCard> createState() => _CustomerPaymentCardState();
}

class _CustomerPaymentCardState extends State<CustomerPaymentCard> {
  bool _isLoading = false;

  Future<void> _handleConfirmPayment() async {
    setState(() => _isLoading = true);
    try {
      await BookingRepository().confirmPayment(widget.booking.id);
      widget.onUpdated?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.cashPaymentConfirmed),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('confirmPaid error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.somethingWentWrong),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDisputePayment() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          context.l10n.reportPaymentProblem,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.disputePaymentPrompt,
              style: TextStyle(fontSize: 13, color: ctx.themeTextSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: context.l10n.disputePaymentReasonHint,
                filled: true,
                fillColor: ctx.themeSurfaceLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: ctx.themeBorder),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(context.l10n.submitDispute),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.trim().isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await BookingRepository().disputePayment(
          widget.booking.id,
          reason: reasonController.text.trim(),
        );
        widget.onUpdated?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.paymentDisputedWithReason(reasonController.text.trim()),
              ),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      } catch (e) {
        debugPrint('dispute payment error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.somethingWentWrong),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final amountVal = b.finalAmount ?? b.agreedPrice ?? 0.0;
    final amountStr = amountVal > 0 ? 'LKR ${amountVal.toStringAsFixed(0)}' : 'LKR --';
    final providerName = b.providerName.isNotEmpty ? b.providerName : context.l10n.technician;

    if (b.customerConfirmedPaidAt != null) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${context.l10n.cashPaymentConfirmed} ($amountStr)',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (b.paymentDisputed == true) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.paymentDisputedWithReason(b.paymentDisputeReason ?? ''),
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // unconfirmed completed job
    String quoteTypeLabel;
    switch (b.quoteType) {
      case 'estimate':
        quoteTypeLabel = context.l10n.quoteTypeEstimate;
        break;
      case 'inspect':
        quoteTypeLabel = context.l10n.quoteTypeInspect;
        break;
      case 'firm':
      default:
        quoteTypeLabel = context.l10n.quoteTypeFirm;
        break;
    }

    final initialEstimateVal = b.estimatedTotalLkr ?? b.agreedPrice?.round() ?? b.agreedPriceLkr;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeSurfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.didYouPayAmount(amountStr, providerName),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: context.themeTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // price breakdown
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.themeSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.themeBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      quoteTypeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            b.completionType == 'visit_only'
                                ? context.l10n.visitFeeOnly
                                : context.l10n.withinAgreedPrice,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                _buildBreakdownRow(
                  context.l10n.initialEstimateLabel,
                  'LKR $initialEstimateVal',
                  context,
                ),
                if (b.priceStatus == 'approved' && b.approvedTotalLkr != null) ...[
                  const SizedBox(height: 6),
                  _buildBreakdownRow(
                    context.l10n.revisedAgreedPrice,
                    'LKR ${b.approvedTotalLkr}',
                    context,
                  ),
                ],
                StreamBuilder<List<BookingExtra>>(
                  stream: BookingRepository().streamExtras(b.id),
                  builder: (context, snap) {
                    final extras = (snap.data ?? []).where((e) => e.status == 'approved').toList();
                    if (extras.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        ...extras.map((ex) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '+ ${ex.description}',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: context.themeTextSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    'LKR ${ex.amountLkr}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: context.themeTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    );
                  },
                ),
                const Divider(height: 16),
                _buildBreakdownRow(
                  context.l10n.finalAmountToPay,
                  amountStr,
                  context,
                  isBold: true,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          if (b.paymentNote != null && b.paymentNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${context.l10n.noteLabel} ${b.paymentNote}',
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: context.themeTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _handleConfirmPayment,
                    icon: const Icon(Icons.check, size: 16),
                    label: Text(
                      context.l10n.yesPaid,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: OutlinedButton(
                    onPressed: _handleDisputePayment,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      context.l10n.reportPaymentProblem,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    String value,
    BuildContext context, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: color ?? (isBold ? context.themeTextPrimary : context.themeTextSecondary),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w700,
            color: color ?? context.themeTextPrimary,
          ),
        ),
      ],
    );
  }
}
