import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../models/booking.dart';
import '../../../models/booking_extra.dart';
import '../../../repositories/booking_repository.dart';
import '../../../utils/l10n_extension.dart';

class PriceProposalBanner extends StatefulWidget {
  final Booking booking;

  const PriceProposalBanner({super.key, required this.booking});

  @override
  State<PriceProposalBanner> createState() => _PriceProposalBannerState();
}

class _PriceProposalBannerState extends State<PriceProposalBanner> {
  bool _responding = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    if (b.priceStatus != 'proposed' || b.proposedPrice == null) {
      return const SizedBox.shrink();
    }

    final total = b.proposedPrice!['totalLkr'] ?? b.agreedPrice ?? 0;
    final desc = b.proposedPrice!['description'] as String? ??
        context.l10n.revisedEstimateDefault;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.price_change_outlined,
                  color: AppColors.warning, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${context.l10n.priceRevisionProposed}: LKR $total',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(
              fontSize: 12.5,
              color: context.themeTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          if (_responding)
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final rejectBtn = OutlinedButton(
                  onPressed: () async {
                    setState(() => _responding = true);
                    try {
                      final total =
                          (b.proposedPrice?['totalLkr'] as num?)?.toInt() ?? 0;
                      await BookingRepository().customerRespondToProposedPrice(
                        b.id,
                        approve: false,
                        totalLkr: total,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text(context.l10n.priceProposalRejected)),
                        );
                      }
                    } catch (e) {
                      debugPrint('priceProposal reject error: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(context.l10n.somethingWentWrong),
                              backgroundColor: AppColors.error),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _responding = false);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(context.l10n.reject,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                );

                final approveBtn = ElevatedButton(
                  onPressed: () async {
                    setState(() => _responding = true);
                    try {
                      final total =
                          (b.proposedPrice?['totalLkr'] as num?)?.toInt() ?? 0;
                      await BookingRepository().customerRespondToProposedPrice(
                        b.id,
                        approve: true,
                        totalLkr: total,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(context.l10n.priceProposalApproved),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('priceProposal approve error: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(context.l10n.somethingWentWrong),
                              backgroundColor: AppColors.error),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _responding = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(context.l10n.approve,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                );

                // stack buttons when narrow
                if (constraints.maxWidth < 280) {
                  return Column(
                    children: [
                      SizedBox(width: double.infinity, child: approveBtn),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: rejectBtn),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: rejectBtn),
                    const SizedBox(width: 10),
                    Expanded(child: approveBtn),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class ExtrasCustomerBanner extends StatelessWidget {
  final Booking booking;

  const ExtrasCustomerBanner({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    if (booking.id.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<List<BookingExtra>>(
      stream: BookingRepository().streamExtras(booking.id),
      builder: (context, snap) {
        final extras = snap.data ?? [];
        if (extras.isEmpty) return const SizedBox.shrink();

        final pendingExtras =
            extras.where((e) => e.status == 'proposed').toList();
        final approvedExtras =
            extras.where((e) => e.status == 'approved').toList();

        return Column(
          children: [
            ...pendingExtras.map((extra) => _PendingExtraCard(
                  booking: booking,
                  extra: extra,
                )),
            if (approvedExtras.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${context.l10n.approvedExtrasBreakdown}: +LKR ${booking.approvedExtrasLkr ?? 0} (Total: LKR ${booking.approvedTotalLkr ?? booking.agreedPrice})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PendingExtraCard extends StatefulWidget {
  final Booking booking;
  final BookingExtra extra;

  const _PendingExtraCard({required this.booking, required this.extra});

  @override
  State<_PendingExtraCard> createState() => _PendingExtraCardState();
}

class _PendingExtraCardState extends State<_PendingExtraCard> {
  bool _responding = false;

  @override
  Widget build(BuildContext context) {
    final extra = widget.extra;
    final b = widget.booking;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeSurfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_task_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${context.l10n.extraWorkRequested}: LKR ${extra.amountLkr}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            extra.description,
            style: TextStyle(fontSize: 12, color: context.themeTextSecondary),
          ),
          const SizedBox(height: 10),
          if (_responding)
            const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final rejectBtn = OutlinedButton(
                  onPressed: () async {
                    setState(() => _responding = true);
                    try {
                      await BookingRepository().customerRespondToExtra(
                        bookingId: b.id,
                        extraId: extra.id,
                        extraAmountLkr: extra.amountLkr,
                        approve: false,
                        currentApprovedExtrasLkr: b.approvedExtrasLkr ?? 0,
                        currentApprovedTotalLkr:
                            b.approvedTotalLkr ?? b.agreedPriceLkr,
                      );
                    } catch (e) {
                      debugPrint('extra reject error: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(context.l10n.somethingWentWrong),
                              backgroundColor: AppColors.error),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _responding = false);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(context.l10n.reject,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                );

                final approveBtn = ElevatedButton(
                  onPressed: () async {
                    setState(() => _responding = true);
                    try {
                      await BookingRepository().customerRespondToExtra(
                        bookingId: b.id,
                        extraId: extra.id,
                        extraAmountLkr: extra.amountLkr,
                        approve: true,
                        currentApprovedExtrasLkr: b.approvedExtrasLkr ?? 0,
                        currentApprovedTotalLkr:
                            b.approvedTotalLkr ?? b.agreedPriceLkr,
                      );
                    } catch (e) {
                      debugPrint('extra approve error: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(context.l10n.somethingWentWrong),
                              backgroundColor: AppColors.error),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _responding = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(context.l10n.approve,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                );

                // stack buttons when narrow
                if (constraints.maxWidth < 280) {
                  return Column(
                    children: [
                      SizedBox(width: double.infinity, child: approveBtn),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: rejectBtn),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: rejectBtn),
                    const SizedBox(width: 10),
                    Expanded(child: approveBtn),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
