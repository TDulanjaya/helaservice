import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/booking.dart';
import '../../../models/booking_extra.dart';
import '../../../repositories/booking_repository.dart';
import '../../../utils/l10n_extension.dart';

class ProviderPriceExtrasCard extends StatelessWidget {
  final String bookingId;
  final VoidCallback? onCompleteVisitOnly;

  const ProviderPriceExtrasCard({
    super.key,
    required this.bookingId,
    this.onCompleteVisitOnly,
  });

  @override
  Widget build(BuildContext context) {
    if (bookingId.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<Booking?>(
      stream: BookingRepository().streamBooking(bookingId),
      builder: (context, snap) {
        final b = snap.data;
        if (b == null) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // price section
            _buildPriceSection(context, b),
            const SizedBox(height: 10),
            // extras section
            _buildExtrasSection(context, b),
          ],
        );
      },
    );
  }

  Widget _buildPriceSection(BuildContext context, Booking b) {
    if (b.priceStatus == 'proposed') {
      final total = b.proposedPrice?['totalLkr'] ?? b.agreedPrice ?? 0;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.hourglass_top_rounded,
                color: AppColors.warning, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${context.l10n.priceRevisionProposed} (LKR $total). ${context.l10n.awaitingCustomerApproval}.',
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (b.priceStatus == 'approved') {
      final total = b.approvedTotalLkr ?? b.agreedPrice ?? 0;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${context.l10n.revisedAgreedPrice}: LKR $total (${context.l10n.arrivalConfirmed})',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success),
              ),
            ),
          ],
        ),
      );
    }

    if (b.priceStatus == 'rejected') {
      final visitDue = (b.visitFeeLkr ?? 0) + (b.travelCostLkr ?? 0);
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cancel_outlined,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n
                        .customerDidNotAgreeVisitOnly(visitDue.toString()),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (onCompleteVisitOnly != null) {
                    onCompleteVisitOnly!();
                  } else {
                    _showVisitOnlyCompletionDialog(context, b, visitDue);
                  }
                },
                icon: const Icon(Icons.pin_outlined, size: 16),
                label: Text(
                  context.l10n.completionTypeVisitOnly,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default: awaiting arrival confirmation
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeSurfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.price_check_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.priceMatchesQuoteAmount(
                      b.agreedPrice?.toStringAsFixed(0) ?? '0'),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final samePriceBtn = OutlinedButton(
                onPressed: () async {
                  try {
                    await BookingRepository().confirmPriceSame(
                      b.id,
                      b.agreedPrice ?? b.agreedPriceLkr.toDouble(),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.priceConfirmedMatches),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('confirmPriceSame error: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(context.l10n.somethingWentWrong),
                            backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(context.l10n.priceMatchesQuote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              );

              final proposeBtn = ElevatedButton(
                onPressed: () => _openProposePriceDialog(context, b),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(context.l10n.proposeNewPrice,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              );

              // stack buttons when narrow
              if (constraints.maxWidth < 360) {
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: samePriceBtn),
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: proposeBtn),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: samePriceBtn),
                  const SizedBox(width: 8),
                  Expanded(child: proposeBtn),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _openProposePriceDialog(BuildContext context, Booking b) {
    final rateCtrl =
        TextEditingController(text: '${b.agreedPrice?.round() ?? 2500}');
    final qtyCtrl = TextEditingController(text: '1.0');
    final descCtrl = TextEditingController();
    String unit = 'fixed';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final rate = int.tryParse(rateCtrl.text.trim()) ?? 0;
          final qty = double.tryParse(qtyCtrl.text.trim()) ?? 1.0;
          final total = (rate * qty).round();

          return AlertDialog(
            backgroundColor: ctx.themeSurface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(context.l10n.proposeRevisedPrice,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: unit,
                    decoration: InputDecoration(
                      labelText: context.l10n.billingUnit,
                      filled: true,
                      fillColor: ctx.themeSurfaceLow,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: 'fixed',
                          child: Text(context.l10n.billingUnitFixed)),
                      DropdownMenuItem(
                          value: 'hour',
                          child: Text(context.l10n.billingUnitHour)),
                      DropdownMenuItem(
                          value: 'day',
                          child: Text(context.l10n.billingUnitDay)),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => unit = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: rateCtrl,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText: context.l10n.unitRateLkr,
                      prefixText: 'LKR ',
                      filled: true,
                      fillColor: ctx.themeSurfaceLow,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: qtyCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText:
                          '${context.l10n.quantityLabel} ${context.l10n.quantityRangeMinMax('0.5', '60')}',
                      filled: true,
                      fillColor: ctx.themeSurfaceLow,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: context.l10n.priceChangeReason,
                      hintText: context.l10n.priceChangeReasonHint,
                      filled: true,
                      fillColor: ctx.themeSurfaceLow,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${context.l10n.totalRevisedPrice}:',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        Text('LKR $total',
                            style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(context.l10n.cancel)),
              ElevatedButton(
                onPressed: () async {
                  final desc = descCtrl.text.trim();
                  if (desc.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(context.l10n.priceRevisionReasonRequired)),
                    );
                    return;
                  }
                  if (rate < 1 || qty < 0.5 || qty > 60) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(context.l10n.checkRateAndQuantity)),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  try {
                    await BookingRepository().proposeNewPrice(
                      b.id,
                      {
                        'unitRateLkr': rate,
                        'priceUnit': unit,
                        'quantity': qty,
                        'description': desc,
                        'totalLkr': total,
                      },
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.priceProposalSent),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('proposeNewPrice error: $e');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(context.l10n.somethingWentWrong),
                            backgroundColor: AppColors.error),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
                child: Text(context.l10n.submitProposal),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExtrasSection(BuildContext context, Booking b) {
    return StreamBuilder<List<BookingExtra>>(
      stream: BookingRepository().streamExtras(b.id),
      builder: (context, snap) {
        final extras = snap.data ?? [];

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openProposeExtraDialog(context, b),
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: Text(context.l10n.addExtraWorkItem,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
            if (extras.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...extras.map((ex) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.themeSurfaceLow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ex.description,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              Text('LKR ${ex.amountLkr}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: context.themeTextSecondary)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ex.status == 'approved'
                                ? AppColors.success.withValues(alpha: 0.12)
                                : ex.status == 'rejected'
                                    ? AppColors.error.withValues(alpha: 0.12)
                                    : AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ex.status == 'approved'
                                ? context.l10n.statusApproved
                                : ex.status == 'rejected'
                                    ? context.l10n.rejectedStatus
                                    : context.l10n.awaitingCustomerApproval,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: ex.status == 'approved'
                                  ? AppColors.success
                                  : ex.status == 'rejected'
                                      ? AppColors.error
                                      : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        );
      },
    );
  }

  void _openProposeExtraDialog(BuildContext context, Booking b) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.l10n.addExtraWorkItem,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.l10n.extraDescription,
                hintText: context.l10n.extraDescriptionHint,
                filled: true,
                fillColor: ctx.themeSurfaceLow,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.l10n.extraAmountLkr,
                prefixText: 'LKR ',
                filled: true,
                fillColor: ctx.themeSurfaceLow,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel)),
          ElevatedButton(
            onPressed: () async {
              final desc = descCtrl.text.trim();
              final amount = int.tryParse(amountCtrl.text.trim());
              if (desc.isEmpty || desc.length > 300) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.extraDescriptionLimit)),
                );
                return;
              }
              if (amount == null || amount <= 0 || amount > 1000000) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.l10n.extraAmountLimit)),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await BookingRepository().proposeExtra(
                  bookingId: b.id,
                  customerId: b.customerId,
                  amountLkr: amount,
                  description: desc,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.extraProposalSent),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('proposeExtra error: $e');
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(context.l10n.somethingWentWrong),
                        backgroundColor: AppColors.error),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: Text(context.l10n.proposeExtra),
          ),
        ],
      ),
    );
  }

  void _showVisitOnlyCompletionDialog(
      BuildContext context, Booking b, int visitDue) {
    final pinController = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: ctx.themeSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            context.l10n.completionTypeVisitOnly,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.customerDidNotAgreeVisitOnly(visitDue.toString()),
                style: TextStyle(
                  fontSize: 12.5,
                  color: ctx.themeTextSecondary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.pinCode,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: pinController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••••',
                  filled: true,
                  fillColor: ctx.themeSurfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: ctx.themeBorder),
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  errorMessage!,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: Text(context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final pin = pinController.text.trim();
                      if (pin.length != 6 && pin.length != 4) {
                        setDialogState(() {
                          errorMessage = context.l10n.pleaseEnterSixDigits;
                        });
                        return;
                      }
                      setDialogState(() {
                        isSubmitting = true;
                        errorMessage = null;
                      });
                      final result =
                          await BookingRepository().verifyAndCompleteJob(
                        bookingId: b.id,
                        enteredPin: pin,
                        jobRequestId: b.jobRequestId,
                        finalAmount: visitDue.toDouble(),
                        completionType: 'visit_only',
                      );
                      if (result.success) {
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text(context.l10n.jobCompletedSuccessfully),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } else {
                        setDialogState(() {
                          isSubmitting = false;
                          errorMessage = result.errorMessage ??
                              context.l10n.somethingWentWrong;
                        });
                      }
                    },
              child: Text(context.l10n.confirm),
            ),
          ],
        ),
      ),
    );
  }
}
