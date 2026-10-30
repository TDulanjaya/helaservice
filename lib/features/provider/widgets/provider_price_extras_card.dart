import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../theme/app_theme.dart';
import '../../../models/booking.dart';
import '../../../models/booking_extra.dart';
import '../../../repositories/booking_repository.dart';
import '../../../utils/l10n_extension.dart';
import '../../../constants/job_status.dart';

// provider price and extras card
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
      if (visitDue <= 0) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cancel_outlined,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.customerRejectedPriceNotice,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }
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

    final canKeepPrice = b.quoteType == 'estimate' &&
        b.priceStatus == 'awaiting_confirmation' &&
        b.estimatedTotalLkr != null;
    final isInspect = b.quoteType == 'inspect';

    final proposeBtn = ElevatedButton(
      onPressed: () => _openProposePriceDialog(context, b),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(
        context.l10n.proposeNewPrice,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );

    // awaiting arrival confirmation
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
              Icon(
                isInspect ? Icons.search_rounded : Icons.price_check_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isInspect
                      ? context.l10n.inspectBookingProposePriceDesc
                      : context.l10n.priceMatchesQuoteAmount(
                          b.estimatedTotalLkr?.toString() ??
                              b.agreedPrice?.toStringAsFixed(0) ??
                              '0',
                        ),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isInspect ? FontWeight.w600 : FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (canKeepPrice)
            LayoutBuilder(
              builder: (context, constraints) {
                final samePriceBtn = OutlinedButton(
                  onPressed: () async {
                    try {
                      await BookingRepository().confirmPriceSame(
                        b.id,
                        b.estimatedTotalLkr!,
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
                        final isPermissionDenied = e is FirebaseException &&
                            e.code == 'permission-denied';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isPermissionDenied
                                  ? context.l10n.cannotKeepPriceProposeInstead
                                  : context.l10n.somethingWentWrong,
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    context.l10n.priceMatchesQuote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
            )
          else
            SizedBox(
              width: double.infinity,
              child: proposeBtn,
            ),
        ],
      ),
    );
  }

  void _openProposePriceDialog(BuildContext context, Booking b) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _ProposePriceDialog(booking: b),
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
    showDialog<void>(
      context: context,
      builder: (ctx) => _ProposeExtraDialog(booking: b),
    );
  }

  void _showVisitOnlyCompletionDialog(
      BuildContext context, Booking b, int visitDue) {
    showDialog<void>(
      context: context,
      builder: (ctx) => _VisitOnlyCompletionDialog(
        booking: b,
        visitDue: visitDue,
      ),
    );
  }
}

class _ProposePriceDialog extends StatefulWidget {
  final Booking booking;

  const _ProposePriceDialog({required this.booking});

  @override
  State<_ProposePriceDialog> createState() => _ProposePriceDialogState();
}

class _ProposePriceDialogState extends State<_ProposePriceDialog> {
  late final TextEditingController _rateCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _descCtrl;
  String _unit = 'fixed';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final b = widget.booking;
    final String initialPrice;
    if (b.estimatedTotalLkr != null) {
      initialPrice = b.estimatedTotalLkr.toString();
    } else if (b.agreedPrice != null) {
      initialPrice = b.agreedPrice!.round().toString();
    } else {
      initialPrice = '';
    }
    _rateCtrl = TextEditingController(text: initialPrice);
    _qtyCtrl = TextEditingController(text: '1');
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _rateCtrl.dispose();
    _qtyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final isFixed = _unit == 'fixed';
    final rate = int.tryParse(_rateCtrl.text.trim()) ?? 0;
    final double parsedQty =
        double.tryParse(_qtyCtrl.text.trim()) ?? (isFixed ? 1.0 : 0.0);
    final num effectiveQty = isFixed ? 1 : parsedQty;
    final travel = b.travelCostLkr ?? 0;
    final total = (rate * effectiveQty).round() + travel;

    final rateLabel =
        isFixed ? context.l10n.finalPriceLkr : context.l10n.unitRateLkr;

    final qtyLabel = _unit == 'hour'
        ? '${context.l10n.numberOfHours} ${context.l10n.quantityRangeMinMax('0.5', '60')}'
        : '${context.l10n.numberOfDays} ${context.l10n.quantityRangeMinMax('0.5', '60')}';

    return AlertDialog(
      backgroundColor: context.themeSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        context.l10n.proposeRevisedPrice,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: InputDecoration(
                labelText: context.l10n.billingUnit,
                filled: true,
                fillColor: context.themeSurfaceLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'fixed',
                  child: Text(context.l10n.billingUnitFixed),
                ),
                DropdownMenuItem(
                  value: 'hour',
                  child: Text(context.l10n.billingUnitHour),
                ),
                DropdownMenuItem(
                  value: 'day',
                  child: Text(context.l10n.billingUnitDay),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _unit = val;
                    if (_unit == 'fixed') {
                      _qtyCtrl.text = '1';
                    } else if (_qtyCtrl.text.trim().isEmpty ||
                        _qtyCtrl.text.trim() == '0') {
                      _qtyCtrl.text = '1';
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _rateCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: rateLabel,
                prefixText: 'LKR ',
                filled: true,
                fillColor: context.themeSurfaceLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (!isFixed) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _qtyCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: qtyLabel,
                  filled: true,
                  fillColor: context.themeSurfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextFormField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.l10n.priceChangeReason,
                hintText: context.l10n.priceChangeReasonHint,
                filled: true,
                fillColor: context.themeSurfaceLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  Text(
                    '${context.l10n.totalRevisedPrice}:',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'LKR $total',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
                  final desc = _descCtrl.text.trim();
                  if (desc.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(context.l10n.priceRevisionReasonRequired),
                      ),
                    );
                    return;
                  }
                  if (rate < 1 || effectiveQty < 0.5 || effectiveQty > 60) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.checkRateAndQuantity),
                      ),
                    );
                    return;
                  }
                  setState(() => _isSubmitting = true);
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final l10n = context.l10n;
                  try {
                    final travelCost = b.travelCostLkr ?? 0;
                    await BookingRepository().proposeNewPrice(
                      b.id,
                      {
                        'unitRateLkr': rate,
                        'priceUnit': _unit,
                        'quantity': isFixed ? 1 : effectiveQty,
                        'description': desc,
                        'note': desc,
                        'travelCostLkr': travelCost,
                        'totalLkr': total,
                      },
                    );
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.priceProposalSent),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  } catch (e) {
                    debugPrint('proposeNewPrice error: $e');
                    if (mounted) {
                      setState(() => _isSubmitting = false);
                    }
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.somethingWentWrong),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(context.l10n.submitProposal),
        ),
      ],
    );
  }
}

class _ProposeExtraDialog extends StatefulWidget {
  final Booking booking;

  const _ProposeExtraDialog({required this.booking});

  @override
  State<_ProposeExtraDialog> createState() => _ProposeExtraDialogState();
}

class _ProposeExtraDialogState extends State<_ProposeExtraDialog> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
    _descCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return AlertDialog(
      backgroundColor: context.themeSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        context.l10n.addExtraWorkItem,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: context.l10n.extraDescription,
              hintText: context.l10n.extraDescriptionHint,
              filled: true,
              fillColor: context.themeSurfaceLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.l10n.extraAmountLkr,
              prefixText: 'LKR ',
              filled: true,
              fillColor: context.themeSurfaceLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
                  final desc = _descCtrl.text.trim();
                  final amount = int.tryParse(_amountCtrl.text.trim());
                  if (desc.isEmpty || desc.length > 300) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.extraDescriptionLimit),
                      ),
                    );
                    return;
                  }
                  if (amount == null || amount <= 0 || amount > 1000000) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.extraAmountLimit)),
                    );
                    return;
                  }
                  setState(() => _isSubmitting = true);
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final l10n = context.l10n;
                  try {
                    await BookingRepository().proposeExtra(
                      bookingId: b.id,
                      customerId: b.customerId,
                      amountLkr: amount,
                      description: desc,
                    );
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.extraProposalSent),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  } catch (e) {
                    debugPrint('proposeExtra error: $e');
                    if (mounted) {
                      setState(() => _isSubmitting = false);
                    }
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.somethingWentWrong),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(context.l10n.proposeExtra),
        ),
      ],
    );
  }
}

class _VisitOnlyCompletionDialog extends StatefulWidget {
  final Booking booking;
  final int visitDue;

  const _VisitOnlyCompletionDialog({
    required this.booking,
    required this.visitDue,
  });

  @override
  State<_VisitOnlyCompletionDialog> createState() =>
      _VisitOnlyCompletionDialogState();
}

class _VisitOnlyCompletionDialogState
    extends State<_VisitOnlyCompletionDialog> {
  late final TextEditingController _pinController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    return AlertDialog(
      backgroundColor: context.themeSurface,
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
            context.l10n.customerDidNotAgreeVisitOnly(widget.visitDue.toString()),
            style: TextStyle(
              fontSize: 12.5,
              color: context.themeTextSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            context.l10n.pinCode,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _pinController,
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
              fillColor: context.themeSurfaceLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.themeBorder),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
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
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(context.l10n.cancel),
        ),
        ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () async {
                  final pin = _pinController.text.trim();
                  if (pin.length != 6 && pin.length != 4) {
                    setState(() {
                      _errorMessage = context.l10n.pleaseEnterSixDigits;
                    });
                    return;
                  }
                  if (b.status != JobStatus.inProgress) {
                    setState(() {
                      _errorMessage = context.l10n.markArrivalFirst;
                    });
                    return;
                  }

                  setState(() {
                    _isSubmitting = true;
                    _errorMessage = null;
                  });
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final l10n = context.l10n;
                  final result = await BookingRepository().verifyAndCompleteJob(
                    bookingId: b.id,
                    enteredPin: pin,
                    jobRequestId: b.jobRequestId,
                    finalAmount: widget.visitDue.toDouble(),
                    completionType: 'visit_only',
                  );
                  if (result.success) {
                    nav.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.jobCompletedSuccessfully),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  } else {
                    if (mounted) {
                      setState(() {
                        _isSubmitting = false;
                        if (result.errorCode == 'invalid_pin_length') {
                          _errorMessage = l10n.pleaseEnterSixDigits;
                        } else if (result.errorCode == 'not_in_progress') {
                          _errorMessage = l10n.markArrivalFirst;
                        } else if (result.errorCode == 'price_not_confirmed') {
                          _errorMessage = l10n.confirmPriceWithCustomerFirst;
                        } else if (result.errorCode == 'network_error') {
                          _errorMessage = l10n.networkErrorTryAgain;
                        } else if (result.errorCode == 'too_many_attempts') {
                          _errorMessage = l10n.tooManyWrongPins;
                        } else if (result.errorCode == 'invalid_amount') {
                          _errorMessage = l10n.invalidFinalAmount;
                        } else if (result.errorCode == 'invalid_id' ||
                            result.errorCode == 'not_found' ||
                            result.errorCode == 'job_not_found') {
                          _errorMessage = l10n.bookingOrJobNotFound;
                        } else if (result.errorCode == 'incorrect_pin') {
                          _errorMessage = l10n.incorrectPinAttemptsUsed(
                              result.attempts, 5);
                        } else {
                          _errorMessage = result.errorMessage ??
                              l10n.somethingWentWrong;
                        }
                      });
                    }
                  }
                },
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(context.l10n.confirm),
        ),
      ],
    );
  }
}
