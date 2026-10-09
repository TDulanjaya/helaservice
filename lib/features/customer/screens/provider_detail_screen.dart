import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_theme.dart';
import '../../../models/technician.dart';
import '../../../models/booking.dart';
import '../../../models/portfolio_item.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/portfolio_repository.dart';
import '../../../services/category_service.dart';
import '../../../repositories/technician_repository.dart';
import '../../../shared/widgets/pill_badge.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/photo_viewer_dialog.dart';
import '../../../shared/widgets/block_report_dialog.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../../../services/review_service.dart';
import 'live_tracking_screen.dart';
import 'direct_chat_screen.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/icon_square_button.dart';
import '../../../shared/widgets/status_pill.dart';
import '../../../shared/widgets/job_location_picker.dart';
import '../../../services/call_service.dart';

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
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: context.themeInk),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'report') {
                BlockReportHelper.showReportSheet(
                  context,
                  targetUid: technician.id,
                  targetName: technician.name,
                  targetRole: 'provider',
                  tradeCategory: technician.title,
                );
              } else if (value == 'block') {
                BlockReportHelper.showBlockConfirmation(
                  context,
                  targetUid: technician.id,
                  targetName: technician.name,
                  onBlocked: () => Navigator.pop(context),
                );
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined, size: 18, color: AppColors.error),
                    const SizedBox(width: 10),
                    Text(ctx.l10n.reportProvider),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    const Icon(Icons.block_rounded, size: 18, color: AppColors.error),
                    const SizedBox(width: 10),
                    Text(ctx.l10n.blockUserAction),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
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
                  '${CategoryService.instance.nameOf(technician.category.isNotEmpty ? technician.category : technician.title, context: context)} · ${technician.serviceArea.isNotEmpty ? LocalizedData.getDistrict(context, technician.serviceArea) : context.l10n.custFallbackColombo}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.themeTextSecondary,
                  ),
                ),
                if (!technician.isApproved) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                        SizedBox(width: 8),
                        Text(
                          'Pending Admin Approval · Unavailable for hire',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (technician.nicVerified)
                        StatusPill(
                          type: StatusPillType.online,
                          label: context.l10n.verifiedArtisan,
                          showDot: true,
                        ),
                      StatusPill(
                        type: technician.isAvailableNow
                            ? StatusPillType.online
                            : (technician.online
                                ? StatusPillType.pending
                                : StatusPillType.offline),
                        label: technician.isAvailableNow
                            ? context.l10n.availableNow
                            : (technician.online
                                ? context.l10n.outsideWorkingHours
                                : context.l10n.statusOffline),
                        showDot: true,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star_rounded,
                            color: AppColors.secondaryContainer, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (technician.isNewProvider || technician.rating == null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  context.l10n.newProviderBadge,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Row(
                                children: [
                                  Text(
                                    technician.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '(${technician.reviewCount})',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: context.themeTextSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.rating,
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
                ),
                Container(
                  width: 1,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: context.themeBorder,
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded,
                            color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocalizedData.getDistrict(context, technician.serviceArea),
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              context.l10n.district,
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.contact_phone_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Direct Contact & Fast Quotes',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            technician.phone.isNotEmpty
                                ? technician.phone
                                : 'Verified phone available',
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          String phone = technician.phone.trim();
                          if (phone.isEmpty) {
                            final t = await TechnicianRepository().getById(technician.id);
                            phone = t?.phone.trim() ?? '';
                          }
                          if (phone.isNotEmpty && context.mounted) {
                            CallService.instance.startCall(
                              context: context,
                              calleePhone: phone,
                              calleeName: technician.name,
                              calleeUid: technician.id,
                              calleeRole: technician.category.isNotEmpty
                                  ? technician.category
                                  : 'provider',
                            );
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(context.l10n.providerPhoneNotAvailable)),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: Text(context.l10n.callTech),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
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
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: Text(context.l10n.chat),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: context.l10n.aboutTechnician,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (technician.about.trim().isNotEmpty)
                  Text(technician.about,
                      style: TextStyle(
                          color: context.themeTextSecondary, height: 1.4)),
                if (technician.about.trim().isNotEmpty)
                  const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (technician.serviceArea.trim().isNotEmpty)
                      PillBadge(
                        label: '${context.l10n.district}: ${LocalizedData.getDistrict(context, technician.serviceArea)}',
                        icon: Icons.location_on,
                      ),
                    if (technician.languages.trim().isNotEmpty)
                      PillBadge(
                        label: technician.languages,
                        icon: Icons.translate,
                      ),
                    if (technician.certification.trim().isNotEmpty)
                      PillBadge(
                        label: technician.certification,
                        icon: Icons.workspace_premium,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: context.l10n.workingHoursTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      technician.isAvailableNow
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                      size: 18,
                      color: technician.isAvailableNow
                          ? const Color(0xFF22C55E)
                          : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        technician.isAvailableNow
                            ? context.l10n.availableNow
                            : (technician.online
                                ? context.l10n.outsideWorkingHours
                                : context.l10n.statusOffline),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: technician.isAvailableNow
                              ? const Color(0xFF22C55E)
                              : context.themeInk,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.l10n.serviceRadiusKm(
                            technician.serviceRadiusKm.round()),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          StreamBuilder<List<PortfolioItem>>(
            stream: PortfolioRepository()
                .streamPortfolio(technician.id, approvedOnly: true),
            builder: (context, portSnap) {
              final portfolioItems = portSnap.data ?? [];
              if (portfolioItems.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.portfolioTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${portfolioItems.length}',
                          style: TextStyle(
                            color: context.themeTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: portfolioItems.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, i) {
                          final p = portfolioItems[i];
                          return GestureDetector(
                            onTap: () => PhotoViewerDialog.show(
                              context,
                              photoUrl: p.photoUrl,
                              title: p.title,
                            ),
                            child: Container(
                              width: 140,
                              decoration: BoxDecoration(
                                color: context.themeSurfaceLow,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: context.themeBorder),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Image.network(
                                      p.photoUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: context.themeSurface,
                                        child: const Icon(
                                            Icons.broken_image_rounded),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Text(
                                      p.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }

              if (technician.recentWork.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.recentWorkCompleted,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          context.l10n.viewAll,
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 12),
                        ),
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
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12)),
                                Text(w.location,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.themeTextSecondary)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }

              return const SizedBox.shrink();
            },
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
              double rating = technician.rating ?? 5.0;
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
                icon: Icons.phone_rounded,
                size: 54,
                radius: 16,
                tooltip: context.l10n.callTech,
                onTap: () async {
                  String phone = technician.phone.trim();
                  if (phone.isEmpty) {
                    final t = await TechnicianRepository().getById(technician.id);
                    phone = t?.phone.trim() ?? '';
                  }
                  if (phone.isNotEmpty && context.mounted) {
                    CallService.instance.startCall(
                      context: context,
                      calleePhone: phone,
                      calleeName: technician.name,
                      calleeUid: technician.id,
                      calleeRole: technician.category.isNotEmpty
                          ? technician.category
                          : 'provider',
                    );
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.providerPhoneNotAvailable)),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: 8),
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
                    label: !technician.isApproved
                        ? 'Provider Verification Pending'
                        : context.l10n.requestService,
                    trailingIcon: technician.isApproved ? Icons.arrow_forward_rounded : null,
                    onPressed: !technician.isApproved
                        ? null
                        : () async {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.l10n.signIn),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }

                            // pick location first
                            final location =
                                await JobLocationPicker.pickLocation(
                              context,
                              title: context.l10n.confirmServiceLocation,
                            );
                            if (location == null || !context.mounted) return;

                            final custName =
                                user.displayName?.isNotEmpty == true
                                    ? user.displayName!
                                    : 'Customer';
                            final initials = custName.isNotEmpty
                                ? custName.substring(0, 1).toUpperCase()
                                : 'C';

                            final bookingObj = Booking(
                              customerId: user.uid,
                              providerId: technician.id,
                              providerName: technician.name,
                              providerPhone: technician.phone,
                              status: 'confirmed',
                              time: 'Now',
                              relativeTime: 'Just now',
                              title: technician.title,
                              estRate: 'Custom Quote',
                              customerName: custName,
                              customerInitials: initials,
                              customerLatitude: location.latitude,
                              customerLongitude: location.longitude,
                              location: location.address,
                              entryInstructions: location.landmark,
                              distance: technician.etaLabel,
                            );

                            final bookingId = await BookingRepository()
                                .createBooking(bookingObj);
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
                                    customerInitials:
                                        bookingObj.customerInitials,
                                    customerLatitude:
                                        bookingObj.customerLatitude,
                                    customerLongitude:
                                        bookingObj.customerLongitude,
                                    location: bookingObj.location,
                                    entryInstructions:
                                        bookingObj.entryInstructions,
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

