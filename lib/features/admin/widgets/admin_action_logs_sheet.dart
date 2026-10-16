import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/admin_log.dart';
import '../../../services/admin_log_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';

// sheet displaying admin audit logs with filters and csv export
class AdminActionLogsSheet extends StatefulWidget {
  const AdminActionLogsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const AdminActionLogsSheet(),
    );
  }

  @override
  State<AdminActionLogsSheet> createState() => _AdminActionLogsSheetState();
}

class _AdminActionLogsSheetState extends State<AdminActionLogsSheet> {
  String _selectedFilter = 'all';

  void _exportAdminLogsCsv(BuildContext context, List<AdminLog> logs) {
    if (logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.noEntriesToExport)),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln(
        'Log ID,Admin UID,Admin Email,Action,Target Type,Target ID,Details,Timestamp');

    for (final l in logs) {
      final tsStr = l.timestamp != null
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(l.timestamp!)
          : '';
      final details = l.details.replaceAll('"', '""');
      buffer.writeln(
          '"${l.id}","${l.adminUid}","${l.adminEmail}","${l.action}","${l.targetType}","${l.targetId}","$details","$tsStr"');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.exportCsv),
        content: SingleChildScrollView(
          child: SelectableText(
            buffer.toString(),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: StreamBuilder<List<AdminLog>>(
        stream: AdminLogService.instance.streamRecentLogs(),
        builder: (context, snapshot) {
          final allLogs = snapshot.data ?? [];
          final filteredLogs = _selectedFilter == 'all'
              ? allLogs
              : allLogs
                  .where((l) => l.targetType.toLowerCase() == _selectedFilter)
                  .toList();

          return Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.themeBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.adminActionLogsTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: context.themeTextPrimary,
                            ),
                          ),
                          Text(
                            context.l10n.adminAuditTrailSubtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          _exportAdminLogsCsv(context, filteredLogs),
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: Text(context.l10n.exportCsv),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              // filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    _buildFilterChip('all', context.l10n.filterAll),
                    const SizedBox(width: 8),
                    _buildFilterChip('user', context.l10n.filterUsers),
                    const SizedBox(width: 8),
                    _buildFilterChip('provider', context.l10n.filterProviders),
                    const SizedBox(width: 8),
                    _buildFilterChip('booking', context.l10n.filterBookings),
                    const SizedBox(width: 8),
                    _buildFilterChip('system', context.l10n.filterSystem),
                  ],
                ),
              ),
              const Divider(height: 12),
              Expanded(
                child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : filteredLogs.isEmpty
                        ? Center(
                            child: Text(
                              context.l10n.noAdminLogsFound,
                              style:
                                  TextStyle(color: context.themeTextSecondary),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: filteredLogs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final log = filteredLogs[index];
                              final locale =
                                  Localizations.localeOf(context).languageCode;
                              final timeStr = log.timestamp != null
                                  ? DateFormat('MMM d, hh:mm a', locale)
                                      .format(log.timestamp!)
                                  : '';

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: context.themeSurfaceLow,
                                  borderRadius: BorderRadius.circular(14),
                                  border:
                                      Border.all(color: context.themeBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            log.action.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          timeStr,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: context.themeTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      log.details,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: context.themeTextPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline_rounded,
                                            size: 13,
                                            color: context.themeTextSecondary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            log.adminEmail.isNotEmpty
                                                ? log.adminEmail
                                                : log.adminUid,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: context.themeTextSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${log.targetType}: ${log.targetId}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontFamily: 'monospace',
                                            color: context.themeTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? AppColors.primary : context.themeTextPrimary,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : context.themeBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
