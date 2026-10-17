import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/complaint.dart';
import '../../../repositories/complaint_repository.dart';
import '../../../repositories/technician_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/map_launcher.dart';
import '../../customer/screens/direct_chat_screen.dart';
import '../../../utils/l10n_extension.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../shared/widgets/user_avatar.dart';
import 'package:provider/provider.dart';
import '../../../models/support_message.dart';
import '../../../services/admin_log_service.dart';
import '../../../state/role_provider.dart';
import '../../../models/admin_user.dart';
import '../widgets/booking_timeline_sheet.dart';

// admin complaints screen
class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  final ComplaintRepository _complaintRepo = ComplaintRepository();
  final TechnicianRepository _techRepo = TechnicianRepository();
  final UserRepository _userRepo = UserRepository();

  String _filterStatus = 'all';
  String _filterType = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    final l10n = context.l10n;
    if (dt == null) return l10n.disputesNotAvailable;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l10n.timeJustNow;
    if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l10n.timeDaysAgo(diff.inDays);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _showResolveDialog(Complaint complaint, String newStatus) {
    final notesController = TextEditingController();
    final isResolve = newStatus == 'resolved';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurface(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isResolve
              ? context.l10n.resolveComplaint
              : context.l10n.dismissComplaint,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(ctx),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isResolve
                    ? context.l10n.disputesResolveNotesPrompt
                    : context.l10n.disputesDismissNotesPrompt,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.getTextSecondary(ctx),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                minLines: 2,
                maxLines: 4,
                style: TextStyle(
                    color: AppColors.getTextPrimary(ctx), fontSize: 14),
                decoration: InputDecoration(
                  hintText: context.l10n.disputesResolutionSummaryHint,
                  hintStyle: TextStyle(
                    color:
                        AppColors.getTextSecondary(ctx).withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: AppColors.getSurfaceLow(ctx),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.getBorder(ctx)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.l10n.cancel,
              style: TextStyle(color: AppColors.getTextSecondary(ctx)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isResolve ? AppColors.primary : AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _complaintRepo.updateComplaintStatus(
                complaint.id,
                newStatus,
                adminNotes: notesController.text.trim().isNotEmpty
                    ? notesController.text.trim()
                    : null,
              );
              await AdminLogService.instance.logAction(
                action:
                    isResolve ? 'complaint_resolved' : 'complaint_dismissed',
                targetType: 'complaint',
                targetId: complaint.id,
                details: notesController.text.trim().isNotEmpty
                    ? notesController.text.trim()
                    : '',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isResolve
                        ? context.l10n.disputesMarkedResolvedSnack
                        : context.l10n.disputesDismissedSnack),
                    backgroundColor:
                        isResolve ? AppColors.primary : AppColors.outline,
                  ),
                );
              }
            },
            child: Text(isResolve
                ? context.l10n.disputesMarkResolved
                : context.l10n.disputesConfirmDismiss),
          ),
        ],
      ),
    );
  }

  void _showBanProviderDialog(Complaint complaint) {
    final currentAdmin = context.read<RoleProvider>().currentAdmin;
    if (currentAdmin?.canManageUsers != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.permManageUsersDesc),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final reasonController = TextEditingController(
      text: context.l10n.complaintInvestigationSuspended(complaint.reason),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurface(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              context.l10n.suspendServiceProvider,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(ctx),
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.disputesBanConfirm(
                    complaint.providerName, complaint.providerTrade),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.getTextSecondary(ctx),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.reasonForBan,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(ctx),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 4,
                style: TextStyle(
                    color: AppColors.getTextPrimary(ctx), fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.getSurfaceLow(ctx),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.getBorder(ctx)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.l10n.cancel,
              style: TextStyle(color: AppColors.getTextSecondary(ctx)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _techRepo.toggleBanStatus(
                complaint.providerId,
                true,
                reason: reasonController.text.trim(),
              );
              await AdminLogService.instance.logAction(
                action: 'provider_banned',
                targetType: 'provider',
                targetId: complaint.providerId,
                details:
                    'Provider suspended from complaint ${complaint.id}. Reason: ${reasonController.text.trim()}',
              );
              await _complaintRepo.updateComplaintStatus(
                complaint.id,
                'resolved',
                adminNotes:
                    'Provider suspended by admin. Reason: ${reasonController.text.trim()}',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.disputesProviderSuspendedSnack(
                        complaint.providerName)),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text(context.l10n.disputesSuspendProvider),
          ),
        ],
      ),
    );
  }

  void _showBanCustomerDialog(Complaint complaint) {
    final currentAdmin = context.read<RoleProvider>().currentAdmin;
    if (currentAdmin?.canManageUsers != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.permManageUsersDesc),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurface(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.no_accounts_outlined,
                color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            Text(
              context.l10n.disputesSuspendCustomer,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(ctx),
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n
                    .suspendCustomerConfirmPrompt(complaint.customerName),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.getTextSecondary(ctx),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.reasonForBan,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(ctx),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 4,
                style: TextStyle(
                  color: AppColors.getTextPrimary(ctx),
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: context.l10n.enterReasonForSuspension,
                  filled: true,
                  fillColor: AppColors.getSurfaceLow(ctx),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: AppColors.getBorder(ctx)),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.l10n.cancel,
              style: TextStyle(color: AppColors.getTextSecondary(ctx)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _userRepo.toggleUserBanStatus(
                userId: complaint.customerId,
                isBanned: true,
                reason: reasonController.text.trim(),
              );
              await AdminLogService.instance.logAction(
                action: 'user_banned',
                targetType: 'user',
                targetId: complaint.customerId,
                details:
                    'Customer suspended from complaint ${complaint.id}. Reason: ${reasonController.text.trim()}',
              );
              await _complaintRepo.updateComplaintStatus(
                complaint.id,
                'resolved',
                adminNotes:
                    'Customer suspended by admin. Reason: ${reasonController.text.trim()}',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.disputesCustomerSuspendedSnack(
                        complaint.customerName)),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text(context.l10n.disputesSuspendCustomer),
          ),
        ],
      ),
    );
  }

  void _showTicketThreadSheet(BuildContext context, Complaint complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AdminTicketThreadSheet(
        complaint: complaint,
        complaintRepo: _complaintRepo,
        onStatusChanged: () => setState(() {}),
        onResolve: (c, s) => _showResolveDialog(c, s),
      ),
    );
  }

  void _openAdminChat({
    required String targetUserId,
    required String targetUserName,
    required String targetRole,
    String? targetPhone,
    String? jobRequestId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DirectChatScreen(
          otherPartyId: targetUserId,
          otherPartyName: targetUserName,
          otherPartyRole: targetRole,
          otherPartyPhone: targetPhone,
          jobRequestId: jobRequestId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final roleProvider = context.watch<RoleProvider>();
    final canHandleSupport = roleProvider.isSuperAdmin ||
        roleProvider.hasAdminPermission(AdminPermission.handleSupport);

    if (!canHandleSupport) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.sidebarNoPermission,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.noPermissionForAction,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.getTextSecondary(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<List<Complaint>>(
      stream: _complaintRepo.streamAllComplaints(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          final errStr = '${snapshot.error}'.toLowerCase();
          if (errStr.contains('permission-denied') ||
              errStr.contains('permission_denied') ||
              errStr.contains('insufficient permissions')) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_outline_rounded,
                        size: 48,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.sidebarNoPermission,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.noPermissionForAction,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.getTextSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                context.l10n.disputesErrorLoading('${snapshot.error}'),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          );
        }

        final allComplaints = snapshot.data ?? [];
        final totalCount = allComplaints.length;
        final pendingCount =
            allComplaints.where((c) => c.status == 'pending').length;
        final resolvedCount =
            allComplaints.where((c) => c.status == 'resolved').length;
        final dismissedCount =
            allComplaints.where((c) => c.status == 'dismissed').length;

        final filtered = allComplaints.where((c) {
          if (_filterStatus != 'all') {
            if (_filterStatus == 'open' &&
                !(c.status == 'open' || c.status == 'pending')) {
              return false;
            } else if (_filterStatus == 'in_review' &&
                !(c.status == 'in_progress' || c.status == 'waiting_user')) {
              return false;
            } else if (_filterStatus == 'resolved' &&
                !(c.status == 'resolved' || c.status == 'closed')) {
              return false;
            } else if (_filterStatus == 'dismissed' &&
                c.status != 'dismissed') {
              return false;
            }
          }
          if (_filterType != 'all' && c.type != _filterType) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final cName = c.customerName.toLowerCase();
            final pName = c.providerName.toLowerCase();
            final reason = c.reason.toLowerCase();
            final desc = c.description.toLowerCase();
            return cName.contains(q) ||
                pName.contains(q) ||
                reason.contains(q) ||
                desc.contains(q);
          }
          return true;
        }).toList();

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 24,
                  isMobile ? 16 : 24,
                  12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.disputeComplaintCenter,
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 28,
                        fontWeight: FontWeight.w800,
                        color: context.themeTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.reviewUserReports,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.themeTextSecondary,
                      ),
                    ),
                    SizedBox(height: isMobile ? 18 : 22),
                    Row(
                      children: [
                        _buildMetricCard(
                          context,
                          title: context.l10n.totalReports,
                          count: '$totalCount',
                        ),
                        const SizedBox(width: 10),
                        _buildMetricCard(
                          context,
                          title: context.l10n.pendingAction,
                          count: '$pendingCount',
                          countColor: AppColors.error,
                        ),
                        const SizedBox(width: 10),
                        _buildMetricCard(
                          context,
                          title: context.l10n.resolvedCases,
                          count: '$resolvedCount',
                          countColor: AppColors.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: context.themeSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.themeBorder),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(
                          () => _searchQuery = val.trim().toLowerCase(),
                        ),
                        style: TextStyle(
                          color: context.themeTextPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: context.l10n.searchDisputesPlaceholder,
                          hintStyle: TextStyle(
                            color: context.themeTextSecondary
                                .withValues(alpha: 0.6),
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: context.themeTextSecondary,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all',
                              context.l10n.disputesFilterAllCount(totalCount)),
                          const SizedBox(width: 8),
                          _buildFilterChip('open', 'Open ()'),
                          const SizedBox(width: 8),
                          _buildFilterChip('in_review', 'In Review ()'),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                              'resolved',
                              context.l10n
                                  .disputesFilterResolvedCount(resolvedCount)),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                              'dismissed',
                              context.l10n.disputesFilterDismissedCount(
                                  dismissedCount)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildTypeFilterChip('all', 'All Types'),
                          const SizedBox(width: 6),
                          _buildTypeFilterChip('complaint', 'Complaint'),
                          const SizedBox(width: 6),
                          _buildTypeFilterChip(
                              'payment_dispute', 'Payment Dispute'),
                          const SizedBox(width: 6),
                          _buildTypeFilterChip(
                              'service_issue', 'Service Issue'),
                          const SizedBox(width: 6),
                          _buildTypeFilterChip(
                              'account_issue', 'Account Issue'),
                          const SizedBox(width: 6),
                          _buildTypeFilterChip(
                              'safety_emergency', 'Safety Issue'),
                          const SizedBox(width: 6),
                          _buildTypeFilterChip('feedback', 'Feedback'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 48,
                          color: context.themeTextSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? context.l10n.disputesNoMatching
                              : context.l10n.disputesNoneRecorded,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.themeTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchQuery.isNotEmpty
                              ? context.l10n.disputesTryAdjustingSearch
                              : context.l10n.disputesAllDisputeFree,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  4,
                  isMobile ? 16 : 24,
                  isMobile ? AppBottomNav.contentBottomPadding : 24,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final complaint = filtered[index];
                      return _buildComplaintCard(context, complaint);
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String count,
    Color? countColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.themeSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.themeBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: countColor ?? context.themeTextPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: context.themeTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeFilterChip(String key, String label) {
    final isSelected = _filterType == key;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _filterType = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.themeSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? Colors.transparent : context.themeBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? AppColors.ink : context.themeTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filterStatus == key;
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => setState(() => _filterStatus = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (context.isDark ? Colors.white : AppColors.ink)
              : context.themeSurface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? Colors.transparent : context.themeBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected
                ? (context.isDark ? AppColors.ink : Colors.white)
                : context.themeTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintCard(BuildContext context, Complaint complaint) {
    Color statusColor;
    Color statusBg;
    String statusLabel;
    switch (complaint.status) {
      case 'resolved':
        statusColor = AppColors.success;
        statusBg = context.themeSuccessTint;
        statusLabel = context.l10n.disputesStatusResolvedCaps;
        break;
      case 'dismissed':
        statusColor = context.themeTextSecondary;
        statusBg = context.themeSoft;
        statusLabel = context.l10n.disputesStatusDismissedCaps;
        break;
      default:
        statusColor = AppColors.error;
        statusBg = context.themeDangerTint;
        statusLabel = context.l10n.disputesStatusPendingCaps;
        break;
    }

    final isPending = complaint.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  complaint.reason,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: context.themeTextPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.disputesFiledAgo(_formatDate(complaint.createdAt)),
            style: TextStyle(
              fontSize: 12,
              color: context.themeTextSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.themeSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.disputesCustomerCaps,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: context.themeTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          UserAvatar(
                            displayName: complaint.customerName,
                            radius: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  complaint.customerName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: context.themeTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (complaint.customerPhone.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  InkWell(
                                    onTap: () => MapLauncher.openPhoneCall(
                                      complaint.customerPhone,
                                    ),
                                    child: Text(
                                      complaint.customerPhone,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: context.themeAmberText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.themeDangerTint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.disputesReportedCaps,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          UserAvatar(
                            displayName: complaint.providerName,
                            radius: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  complaint.providerName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: context.themeTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (complaint.providerTrade.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    complaint.providerTrade,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: context.themeTextSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (complaint.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '“${complaint.description}”',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: context.themeTextPrimary,
              ),
            ),
          ],
          if (complaint.adminNotes != null &&
              complaint.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.themeInfoTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 16,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.l10n.disputesAdminNote(complaint.adminNotes!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (complaint.photos.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Attached Photos ():',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: context.themeTextSecondary,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: complaint.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) => GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (dCtx) => Dialog(
                        child: Image.network(complaint.photos[i],
                            fit: BoxFit.contain),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      complaint.photos[i],
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color: context.themeSurfaceLow,
                        child: const Icon(Icons.broken_image, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (complaint.bookingId != null &&
              complaint.bookingId!.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => BookingTimelineSheet.show(
                context,
                bookingId: complaint.bookingId!,
                bookingTitle: complaint.effectiveSubject,
              ),
              icon: const Icon(Icons.timeline_rounded, size: 15),
              label: Text(
                  context.l10n.bookingTimelineWithId(complaint.bookingId!),
                  style: const TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.ink,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.forum_outlined, size: 16),
              label: Text(context.l10n.viewTicketAndThread,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13)),
              onPressed: () => _showTicketThreadSheet(context, complaint),
            ),
          ),
          const SizedBox(height: 10),
          if (isPending) ...[
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.themeTextPrimary,
                        side: BorderSide(color: context.themeBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline_rounded,
                          size: 16),
                      label: Text(
                        context.l10n.message,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () => _openAdminChat(
                        targetUserId: complaint.customerId,
                        targetUserName: complaint.customerName,
                        targetRole: 'customer',
                        targetPhone: complaint.customerPhone,
                        jobRequestId: complaint.bookingId,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.ink,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () =>
                          _showResolveDialog(complaint, 'resolved'),
                      child: Text(
                        context.l10n.resolveComplaint,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: context.themeSoft,
                        foregroundColor: context.themeTextPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () =>
                          _showResolveDialog(complaint, 'dismissed'),
                      child: Text(
                        context.l10n.dismissComplaint,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: PopupMenuButton<String>(
                      tooltip: context.l10n.suspendAccount,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onSelected: (val) {
                        if (val == 'provider') {
                          _showBanProviderDialog(complaint);
                        } else if (val == 'customer') {
                          _showBanCustomerDialog(complaint);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'provider',
                          child: Row(
                            children: [
                              const Icon(Icons.block_flipped,
                                  size: 18, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${context.l10n.disputesSuspendProvider} (${complaint.providerName})',
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'customer',
                          child: Row(
                            children: [
                              const Icon(Icons.no_accounts_outlined,
                                  size: 18, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${context.l10n.disputesSuspendCustomer} (${complaint.customerName})',
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.gavel_rounded,
                                size: 16, color: AppColors.error),
                            SizedBox(width: 6),
                            Text(
                              'Suspend Account',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down,
                                color: AppColors.error, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.themeTextPrimary,
                  side: BorderSide(color: context.themeBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 14),
                label: Text(context.l10n.disputesReopenCase,
                    style: const TextStyle(fontSize: 12)),
                onPressed: () async {
                  await _complaintRepo.updateComplaintStatus(
                    complaint.id,
                    'pending',
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text(context.l10n.disputesCaseReopenedSnack)),
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminTicketThreadSheet extends StatefulWidget {
  final Complaint complaint;
  final ComplaintRepository complaintRepo;
  final VoidCallback onStatusChanged;
  final void Function(Complaint, String) onResolve;

  const _AdminTicketThreadSheet({
    required this.complaint,
    required this.complaintRepo,
    required this.onStatusChanged,
    required this.onResolve,
  });

  @override
  State<_AdminTicketThreadSheet> createState() =>
      _AdminTicketThreadSheetState();
}

class _AdminTicketThreadSheetState extends State<_AdminTicketThreadSheet> {
  final TextEditingController _replyController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final currentAdmin = context.read<RoleProvider>().currentAdmin;
      final msg = SupportMessage(
        senderUid: currentAdmin?.id ?? '',
        senderRole: 'admin',
        senderName: currentAdmin?.displayName ?? 'Support Admin',
        text: text,
        createdAt: DateTime.now(),
      );
      await widget.complaintRepo.addMessage(widget.complaint.id, msg);
      await AdminLogService.instance.logAction(
        action: 'ticket_reply',
        targetType: 'complaint',
        targetId: widget.complaint.id,
        details: text.length > 60 ? '...' : text,
      );
      _replyController.clear();
      widget.onStatusChanged();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AdminComplaints] _sendReply error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.l10n.somethingWentWrong),
              backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _assignToMe() async {
    final currentAdmin = context.read<RoleProvider>().currentAdmin;
    if (currentAdmin == null) return;
    try {
      await widget.complaintRepo.updateComplaintStatus(
        widget.complaint.id,
        widget.complaint.status,
        assignedAdminId: currentAdmin.id,
      );
      await AdminLogService.instance.logAction(
        action: 'ticket_assigned',
        targetType: 'complaint',
        targetId: widget.complaint.id,
        details: 'Assigned to ',
      );
      widget.onStatusChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.l10n.ticketAssignedToYou),
              backgroundColor: AppColors.primary),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AdminComplaints] _assignToMe error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(context.l10n.somethingWentWrong),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.complaint;
    final currentAdmin = context.read<RoleProvider>().currentAdmin;
    final isAssignedToMe = c.assignedAdminId == currentAdmin?.id;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.themeBorder,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.effectiveSubject,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Type:  • Status: ',
                        style: TextStyle(
                            fontSize: 12, color: context.themeTextSecondary),
                      ),
                    ],
                  ),
                ),
                if (c.assignedAdminId == null)
                  ElevatedButton(
                    onPressed: _assignToMe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.ink,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(context.l10n.ticketAssignToMe,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAssignedToMe
                          ? context.themeSuccessTint
                          : context.themeSurfaceLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAssignedToMe ? 'Assigned to you' : 'Assigned',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isAssignedToMe
                            ? AppColors.success
                            : context.themeTextSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                if (c.description.isNotEmpty) ...[
                  Text(
                    c.description,
                    style: TextStyle(
                        fontSize: 13.5,
                        color: context.themeTextPrimary,
                        height: 1.4),
                  ),
                  const SizedBox(height: 14),
                ],
                if (c.photos.isNotEmpty) ...[
                  Text(
                    'Photos ()',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextSecondary),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: c.photos.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (ctx, i) => GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (dCtx) => Dialog(
                              child: Image.network(c.photos[i],
                                  fit: BoxFit.contain),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            c.photos[i],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (c.bookingId != null && c.bookingId!.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () => BookingTimelineSheet.show(
                      context,
                      bookingId: c.bookingId!,
                      bookingTitle: c.effectiveSubject,
                    ),
                    icon: const Icon(Icons.timeline_rounded, size: 16),
                    label: Text(context.l10n.openBookingTimeline(c.bookingId!)),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Row(
                  children: [
                    if (c.status != 'in_progress')
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await widget.complaintRepo
                                .updateComplaintStatus(c.id, 'in_progress');
                            widget.onStatusChanged();
                          },
                          child: Text(context.l10n.markInReviewAction),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.ink,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onResolve(c, 'resolved');
                        },
                        child: Text(context.l10n.resolveAction),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error),
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onResolve(c, 'dismissed');
                        },
                        child: Text(context.l10n.dismissAction),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.messageHistoryTitle,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<SupportMessage>>(
                  stream: widget.complaintRepo.streamMessages(c.id),
                  builder: (ctx, snap) {
                    final messages = snap.data ?? [];
                    if (messages.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            context.l10n.noRepliesYet,
                            style: TextStyle(
                                fontSize: 12,
                                color: context.themeTextSecondary),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: messages.map((m) {
                        final isAdmin = m.isAdmin;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : context.themeSurfaceLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isAdmin
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : context.themeBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        m.senderName ??
                                            (isAdmin ? 'Admin' : m.senderRole),
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.bold,
                                          color: isAdmin
                                              ? AppColors.primary
                                              : context.themeTextPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isAdmin
                                              ? AppColors.primary
                                              : context.themeBorder,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          m.senderRole.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: isAdmin
                                                ? AppColors.ink
                                                : context.themeTextPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    m.formattedTime,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.themeTextSecondary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(m.body,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: context.themeTextPrimary)),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 12),
            decoration: BoxDecoration(
              color: context.themeSurface,
              border: Border(top: BorderSide(color: context.themeBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: context.l10n.replyAsSupportAdminHint,
                      hintStyle: TextStyle(
                          fontSize: 13, color: context.themeTextSecondary),
                      filled: true,
                      fillColor: context.themeSurfaceLow,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.themeBorder),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sending ? null : _sendReply,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded,
                          color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
