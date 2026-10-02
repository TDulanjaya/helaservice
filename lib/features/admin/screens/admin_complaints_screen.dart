import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/complaint.dart';
import '../../../repositories/complaint_repository.dart';
import '../../../repositories/technician_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/map_launcher.dart';
import '../../customer/screens/direct_chat_screen.dart';
import '../../../utils/l10n_extension.dart';
import '../../../shared/widgets/app_bottom_nav.dart';

/// Screen for admins to review and resolve customer complaints.
class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});

  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  final ComplaintRepository _complaintRepo = ComplaintRepository();
  final TechnicianRepository _techRepo = TechnicianRepository();

  String _filterStatus = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'N/A';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
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
                    ? 'Add resolution notes detailing the outcome of the investigation or customer compensation.'
                    : 'Add notes explaining why this dispute is dismissed.',
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
                  hintText: 'Enter internal admin resolution summary...',
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
              'Cancel',
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
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isResolve
                        ? 'Complaint marked as Resolved.'
                        : 'Complaint dismissed.'),
                    backgroundColor:
                        isResolve ? AppColors.primary : AppColors.outline,
                  ),
                );
              }
            },
            child: Text(isResolve ? 'Mark Resolved' : 'Confirm Dismiss'),
          ),
        ],
      ),
    );
  }

  void _showBanProviderDialog(Complaint complaint) {
    final reasonController = TextEditingController(
      text:
          'Suspended following complaint investigation: "${complaint.reason}"',
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
                'Are you sure you want to ban ${complaint.providerName} (${complaint.providerTrade})? They will be locked offline and hidden from customer discovery.',
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
              'Cancel',
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
              await _complaintRepo.updateComplaintStatus(
                complaint.id,
                'resolved',
                adminNotes:
                    'Provider suspended by admin. Reason: ${reasonController.text.trim()}',
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Provider ${complaint.providerName} has been suspended.'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Suspend Provider'),
          ),
        ],
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
    final surfaceColor = AppColors.getSurface(context);
    final onSurface = AppColors.getTextPrimary(context);
    final onSurfaceVar = AppColors.getTextSecondary(context);
    final borderColor = AppColors.getBorder(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.disputeComplaintCenter,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: onSurface,
              ),
            ),
            Text(
              context.l10n.reviewUserReports,
              style: TextStyle(fontSize: 11, color: onSurfaceVar),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Complaint>>(
        stream: _complaintRepo.streamAllComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error loading complaints: ${snapshot.error}',
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
            if (_filterStatus != 'all' && c.status != _filterStatus) {
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

          final isMobile = MediaQuery.of(context).size.width < 768;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildMetricCard(
                            context,
                            title: context.l10n.totalReports,
                            count: '$totalCount',
                            icon: Icons.assignment_late_outlined,
                            accentColor: AppColors.primary,
                          ),
                          const SizedBox(width: 12),
                          _buildMetricCard(
                            context,
                            title: context.l10n.pendingAction,
                            count: '$pendingCount',
                            icon: Icons.pending_actions_rounded,
                            accentColor: AppColors.secondary,
                            isHighlighted: pendingCount > 0,
                          ),
                          const SizedBox(width: 12),
                          _buildMetricCard(
                            context,
                            title: context.l10n.resolvedCases,
                            count: '$resolvedCount',
                            icon: Icons.check_circle_outline,
                            accentColor: Colors.teal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _searchController,
                              onChanged: (val) => setState(() =>
                                  _searchQuery = val.trim().toLowerCase()),
                              style: TextStyle(color: onSurface, fontSize: 14),
                              decoration: InputDecoration(
                                hintText:
                                    context.l10n.searchDisputesPlaceholder,
                                hintStyle: TextStyle(
                                    color: onSurfaceVar.withValues(alpha: 0.6),
                                    fontSize: 13),
                                prefixIcon: Icon(Icons.search,
                                    color: onSurfaceVar, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: AppColors.getSurfaceLow(context),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildFilterChip('all', 'All ($totalCount)'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                      'pending', 'Pending ($pendingCount)'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip(
                                      'resolved', 'Resolved ($resolvedCount)'),
                                  const SizedBox(width: 8),
                                  _buildFilterChip('dismissed',
                                      'Dismissed ($dismissedCount)'),
                                ],
                              ),
                            ),
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
                          Icon(Icons.verified_user_outlined,
                              size: 48, color: onSurfaceVar),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No matching complaints found'
                                : 'No complaints recorded',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try adjusting your search criteria.'
                                : 'All service transactions are currently dispute-free.',
                            style: TextStyle(fontSize: 13, color: onSurfaceVar),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    isMobile ? AppBottomNav.contentBottomPadding : 8,
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
      ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String count,
    required IconData icon,
    required Color accentColor,
    bool isHighlighted = false,
  }) {
    final surfaceColor = AppColors.getSurface(context);
    final borderColor = AppColors.getBorder(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighlighted
                ? accentColor.withValues(alpha: 0.6)
                : borderColor,
            width: isHighlighted ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 20, color: accentColor),
                if (isHighlighted)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              count,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.getTextSecondary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _filterStatus == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filterStatus = key),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.getSurfaceLow(context),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.black : AppColors.getTextSecondary(context),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.getBorder(context),
        ),
      ),
    );
  }

  Widget _buildComplaintCard(BuildContext context, Complaint complaint) {
    final surfaceColor = AppColors.getSurface(context);
    final onSurface = AppColors.getTextPrimary(context);
    final onSurfaceVar = AppColors.getTextSecondary(context);
    final borderColor = AppColors.getBorder(context);

    Color statusColor;
    String statusLabel;
    switch (complaint.status) {
      case 'resolved':
        statusColor = Colors.teal;
        statusLabel = 'RESOLVED';
        break;
      case 'dismissed':
        statusColor = AppColors.outline;
        statusLabel = 'DISMISSED';
        break;
      default:
        statusColor = AppColors.secondary;
        statusLabel = 'PENDING';
        break;
    }

    final isPending = complaint.status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPending
              ? AppColors.secondary.withValues(alpha: 0.4)
              : borderColor,
          width: isPending ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.report_problem_outlined,
                        size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        complaint.reason,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Filed: ${_formatDate(complaint.createdAt)}',
            style: TextStyle(
                fontSize: 11, color: onSurfaceVar.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.getSurfaceLow(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Complainant',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: onSurfaceVar,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        complaint.customerName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      if (complaint.customerPhone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => MapLauncher.openPhoneCall(
                              complaint.customerPhone),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.phone,
                                  size: 12, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                complaint.customerPhone,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: borderColor,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reported Artisan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: onSurfaceVar,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        complaint.providerName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: onSurface,
                        ),
                      ),
                      Text(
                        complaint.providerTrade,
                        style: TextStyle(fontSize: 11, color: onSurfaceVar),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Incident Statement:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: onSurfaceVar,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              complaint.description,
              style: TextStyle(
                fontSize: 13,
                color: onSurface,
                height: 1.4,
              ),
            ),
          ),
          if (complaint.adminNotes != null &&
              complaint.adminNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.admin_panel_settings,
                      size: 16, color: Colors.teal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Admin Note: ${complaint.adminNotes}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.teal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isPending) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onSurface,
                    side: BorderSide(color: borderColor),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Message Customer',
                      style: TextStyle(fontSize: 12)),
                  onPressed: () => _openAdminChat(
                    targetUserId: complaint.customerId,
                    targetUserName: complaint.customerName,
                    targetRole: 'customer',
                    targetPhone: complaint.customerPhone,
                    jobRequestId: complaint.bookingId,
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Resolve Dispute',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _showResolveDialog(complaint, 'resolved'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onSurface,
                    side: BorderSide(color: borderColor),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                  onPressed: () => _showResolveDialog(complaint, 'dismissed'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.gavel, size: 16),
                  label: const Text('Suspend Provider',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () => _showBanProviderDialog(complaint),
                ),
              ] else ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: onSurface,
                    side: BorderSide(color: borderColor),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.refresh, size: 14),
                  label:
                      const Text('Reopen Case', style: TextStyle(fontSize: 11)),
                  onPressed: () async {
                    await _complaintRepo.updateComplaintStatus(
                        complaint.id, 'pending');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dispute case reopened.')),
                      );
                    }
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
