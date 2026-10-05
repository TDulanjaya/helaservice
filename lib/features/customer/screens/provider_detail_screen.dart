import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../models/technician.dart';
import '../../../models/booking.dart';
import '../../../models/complaint.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/complaint_repository.dart';
import '../../../shared/widgets/pill_badge.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../../../services/review_service.dart';
import 'live_tracking_screen.dart';
import 'direct_chat_screen.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../shared/widgets/status_pill.dart';

class ProviderDetailScreen extends StatelessWidget {
  final Technician technician;
  const ProviderDetailScreen({super.key, required this.technician});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.themeBg,
        leading: Center(
          child: IconSquareButton.small(
            icon: Icons.chevron_left_rounded,
            onTap: () => Navigator.maybePop(context),
          ),
        ),
        title: Text(
          context.l10n.serviceDetail,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.themeInk,
          ),
        ),
        centerTitle: true,
        actions: [
          Center(
            child: IconSquareButton.small(
              icon: Icons.flag_outlined,
              iconColor: AppColors.error,
              tooltip: context.l10n.reportProvider,
              onTap: () => _showReportProviderSheet(context, technician),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                    ),
                    UserAvatar(
                      uid: technician.id,
                      displayName: technician.name,
                      radius: 40,
                      backgroundColor: technician.avatarColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  technician.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: context.themeInk,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${LocalizedData.getCategory(context, technician.title)} · ${technician.serviceArea.isNotEmpty ? LocalizedData.getDistrict(context, technician.serviceArea) : context.l10n.custFallbackColombo}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.themeTextSecondary,
                  ),
                ),
                if (technician.nicVerified) ...[
                  const SizedBox(height: 8),
                  StatusPill(
                    type: StatusPillType.online,
                    label: context.l10n.verifiedArtisan,
                    showDot: true,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatTile(
                  icon: Icons.star_rounded,
                  value: technician.rating.toStringAsFixed(1),
                  label: context.l10n.rating,
                ),
                _StatTile(
                  icon: Icons.task_alt_rounded,
                  value: '${technician.jobsCount}',
                  label: context.l10n.completedJobs,
                ),
                _StatTile(
                  icon: Icons.work_history_rounded,
                  value: technician.yearsExperience,
                  label: context.l10n.experience,
                ),
                _StatTile(
                  icon: Icons.timer_outlined,
                  value: technician.onTimePercent,
                  label: context.l10n.onTimeArrival,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: context.l10n.transparentPricing,
            child: Column(
              children: [
                _PriceRow(
                    context.l10n.baseInspectionFee,
                    context.l10n.baseInspectionSub,
                    'LKR ${technician.baseRateLkr}'),
                const Divider(),
                _PriceRow(context.l10n.standardHourlyLabour, null,
                    context.l10n.custRatePerHour('${technician.hourlyRateLkr}')),
                const Divider(),
                _PriceRow(context.l10n.emergencyRate, null,
                    context.l10n.custRatePerHour('${technician.emergencyRateLkr}')),
                const SizedBox(height: 6),
                Text(context.l10n.materialsBilledSeparately,
                    style: TextStyle(
                        color: context.themeTextSecondary, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: context.l10n.aboutTechnician,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(technician.about,
                    style: TextStyle(
                        color: context.themeTextSecondary, height: 1.4)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  PillBadge(label: technician.languages, icon: Icons.translate),
                  PillBadge(
                      label: LocalizedData.getDistrict(context, technician.serviceArea), icon: Icons.location_on),
                  PillBadge(
                      label: technician.certification,
                      icon: Icons.workspace_premium),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  '${context.l10n.recentWorkCompleted} (${technician.jobsCount})',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(context.l10n.viewAll,
                  style:
                      const TextStyle(color: AppColors.primary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: technician.recentWork.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final w = technician.recentWork[i];
                return Container(
                  width: 110,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: context.themeSurfaceLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: context.themeBorder)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(w.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12)),
                      Text(w.location,
                          style: TextStyle(
                              fontSize: 11, color: context.themeTextSecondary)),
                    ],
                  ),
                );
              },
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: ReviewService.instance.streamProviderReviews(technician.id),
            builder: (context, reviewSnap) {
              final liveReviews = reviewSnap.data ?? [];
              final hasReviews =
                  liveReviews.isNotEmpty || technician.reviews.isNotEmpty;
              if (!hasReviews) return const SizedBox.shrink();

              final reviewCount = liveReviews.isNotEmpty
                  ? liveReviews.length
                  : technician.reviewCount;
              double rating = technician.rating;
              if (liveReviews.isNotEmpty) {
                final total = liveReviews.fold<double>(
                  0,
                  (p, r) => p + ((r['rating'] as num?)?.toDouble() ?? 5.0),
                );
                rating = total / liveReviews.length;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    '${context.l10n.customerReviews} • ${rating.toStringAsFixed(1)} / 5 ($reviewCount ${context.l10n.verifiedArtisan})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (liveReviews.isNotEmpty)
                    ...liveReviews.map((r) {
                      final name =
                          (r['customerName'] as String?)?.isNotEmpty == true
                              ? r['customerName'] as String
                              : context.l10n.customerLabel;
                      final stars = (r['rating'] as num?)?.toInt() ?? 5;
                      final comment = (r['comment'] as String?) ?? '';
                      final tags = (r['tags'] as List?)
                              ?.map((t) => t.toString())
                              .toList() ??
                          [];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: context.themeSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: context.themeBorder)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                UserAvatar(
                                  uid: r['customerId'] as String?,
                                  displayName: name,
                                  radius: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                      Row(
                                        children: List.generate(
                                          stars.clamp(1, 5),
                                          (_) => const Icon(Icons.star,
                                              size: 12,
                                              color: AppColors.primary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
                              if (tags.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: tags
                                      .map((t) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(t,
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: AppColors.primary,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ))
                                      .toList(),
                                ),
                              ],
                              if (comment.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(comment,
                                    style: const TextStyle(
                                        fontSize: 12.5, height: 1.35)),
                              ],
                            ],
                          ),
                        ),
                      );
                    })
                  else if (technician.reviews.isNotEmpty)
                    ...technician.reviews.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: context.themeSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: context.themeBorder)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  UserAvatar(
                                    displayName: r.reviewerName,
                                    radius: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(r.reviewerName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13)),
                                        Text('${r.location} • ${r.timeAgo}',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: context
                                                    .themeTextSecondary)),
                                      ],
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 6),
                                Text(r.comment,
                                    style: const TextStyle(
                                        fontSize: 12.5, height: 1.35)),
                              ],
                            ),
                          ),
                        ))
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: Text(
                          context.l10n.noCustomerReviews,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.themeSurface,
            border: Border(top: BorderSide(color: context.themeBorder)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              IconSquareButton(
                icon: Icons.chat_bubble_outline_rounded,
                size: 54,
                radius: 16,
                tooltip: context.l10n.message,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => DirectChatScreen(
                        otherPartyId: technician.id,
                        otherPartyName: technician.name,
                        otherPartyRole: technician.title,
                        otherPartyPhone: technician.phone,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: PrimaryButton(
                    label: '${context.l10n.requestService} · LKR ${technician.baseRateLkr}',
                    trailingIcon: Icons.arrow_forward_rounded,
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                  final custName = user?.displayName?.isNotEmpty == true
                      ? user!.displayName!
                      : 'Customer';
                  final initials = custName.isNotEmpty
                      ? custName.substring(0, 1).toUpperCase()
                      : 'C';

                  final bookingObj = Booking(
                    customerId: user?.uid ?? '',
                    providerId: technician.id,
                    providerName: technician.name,
                    providerPhone: technician.phone,
                    status: 'confirmed',
                    time: 'Now',
                    relativeTime: 'Just now',
                    title: technician.title,
                    estRate: 'LKR ${technician.baseRateLkr}',
                    customerName: custName,
                    customerInitials: initials,
                    location: technician.serviceArea.isNotEmpty
                        ? technician.serviceArea
                        : 'Colombo',
                    distance: technician.etaLabel,
                  );

                  final bookingId =
                      await BookingRepository().createBooking(bookingObj);
                  if (!context.mounted) return;

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LiveTrackingScreen(
                        technician: technician,
                        booking: Booking(
                          id: bookingId,
                          customerId: bookingObj.customerId,
                          providerId: bookingObj.providerId,
                          providerName: bookingObj.providerName,
                          providerPhone: bookingObj.providerPhone,
                          status: bookingObj.status,
                          time: bookingObj.time,
                          relativeTime: bookingObj.relativeTime,
                          title: bookingObj.title,
                          estRate: bookingObj.estRate,
                          customerName: bookingObj.customerName,
                          customerInitials: bookingObj.customerInitials,
                          location: bookingObj.location,
                          distance: bookingObj.distance,
                        ),
                        showBottomNav: false,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  ),
);
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatTile(
      {required this.icon, required this.value, required this.label});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10, height: 1.15, color: context.themeTextSecondary),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: context.themeInk,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String? sub;
  final String price;
  const _PriceRow(this.label, this.sub, this.price);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: context.themeInk,
                  ),
                ),
                if (sub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      sub!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: context.themeInk,
            ),
          ),
        ],
      ),
    );
  }
}

void _showReportProviderSheet(BuildContext context, Technician technician) {
  final reasons = [
    'Unprofessional Conduct',
    'Late or No-Show',
    'Overcharging / Price Dispute',
    'Poor Quality of Work',
    'Safety or Harassment Concern',
    'Fraud or Identity Issue',
    'Other Issue',
  ];

  String selectedReason = reasons.first;
  final descController = TextEditingController();
  bool isSubmitting = false;

  String getLocalizedComplaintReason(BuildContext ctx, String reason) {
    switch (reason) {
      case 'Unprofessional Conduct':
        return ctx.l10n.complaintUnprofessionalConduct;
      case 'Late or No-Show':
        return ctx.l10n.complaintLateNoShow;
      case 'Overcharging / Price Dispute':
        return ctx.l10n.complaintPriceDispute;
      case 'Poor Quality of Work':
        return ctx.l10n.complaintPoorQuality;
      case 'Safety or Harassment Concern':
        return ctx.l10n.complaintSafetyConcern;
      case 'Fraud or Identity Issue':
        return ctx.l10n.complaintFraudIssue;
      case 'Other Issue':
        return ctx.l10n.complaintOtherIssue;
      default:
        return reason;
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.getSurface(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final surface = AppColors.getSurface(ctx);
          final onSurface = AppColors.getTextPrimary(ctx);
          final onSurfaceVar = AppColors.getTextSecondary(ctx);

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.getBorder(ctx),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              AppColors.errorContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.flag_rounded,
                            color: AppColors.error, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ctx.l10n.reportServiceProvider,
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: onSurface,
                              ),
                            ),
                            Text(
                              ctx.l10n.reportingTechnician(technician.name, technician.title),
                              style:
                                  TextStyle(fontSize: 12, color: onSurfaceVar),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ctx.l10n.selectComplaintReason,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.getBorder(ctx)),
                      color: AppColors.getSurfaceLow(ctx),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedReason,
                        isExpanded: true,
                        dropdownColor: surface,
                        items: reasons.map((r) {
                          return DropdownMenuItem<String>(
                            value: r,
                            child: Text(getLocalizedComplaintReason(ctx, r),
                                style:
                                    TextStyle(color: onSurface, fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => selectedReason = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ctx.l10n.explainIncidentDetails,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    minLines: 3,
                    maxLines: 5,
                    style: TextStyle(color: onSurface, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: ctx.l10n.explainIncidentHint,
                      hintStyle: TextStyle(
                          color: onSurfaceVar.withValues(alpha: 0.6),
                          fontSize: 13),
                      filled: true,
                      fillColor: AppColors.getSurfaceLow(ctx),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.getBorder(ctx)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.getBorder(ctx)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final text = descController.text.trim();
                              if (text.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          ctx.l10n.describeIssueBeforeSubmitting)),
                                );
                                return;
                              }

                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          ctx.l10n.signInToSubmitComplaint)),
                                );
                                return;
                              }

                              setModalState(() => isSubmitting = true);

                              try {
                                final complaint = Complaint(
                                  customerId: user.uid,
                                  customerName: (user.displayName != null &&
                                          user.displayName!.isNotEmpty)
                                      ? user.displayName!
                                      : (user.phoneNumber != null
                                          ? 'User (${user.phoneNumber})'
                                          : 'Customer'),
                                  customerPhone: user.phoneNumber ?? '',
                                  providerId: technician.id,
                                  providerName: technician.name,
                                  providerTrade: technician.title,
                                  reason: selectedReason,
                                  description: text,
                                );

                                await ComplaintRepository()
                                    .submitComplaint(complaint);

                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle,
                                              color: Colors.white, size: 20),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                                context.l10n.complaintSubmittedSuccess),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: AppColors.primary,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  setModalState(() => isSubmitting = false);
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            '${ctx.l10n.failedToSubmitReport}: $e')),
                                  );
                                }
                              }
                            },
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              ctx.l10n.submitOfficialReport,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
