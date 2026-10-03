import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as pv;
import '../../../theme/app_theme.dart';
import '../../../state/role_provider.dart';
import '../../../models/admin_user.dart';
import '../../../models/admin_models.dart';
import '../../../models/complaint.dart';
import '../../../repositories/category_repository.dart';
import '../../../repositories/complaint_repository.dart';
import '../../../repositories/technician_repository.dart';
import '../../../models/technician.dart';
import '../../../utils/location_utils.dart';
import '../../../utils/map_launcher.dart';
import '../../../utils/l10n_extension.dart';
import '../../../utils/app_localizations_helpers.dart';
import '../../../shared/widgets/app_bottom_nav.dart';

List<String> get kAllSriLankanDistricts =>
    LocationUtils.districtCoordinates.keys.toList();

class CategoryDistrictManagementScreen extends StatefulWidget {
  const CategoryDistrictManagementScreen({super.key});

  @override
  State<CategoryDistrictManagementScreen> createState() =>
      _CategoryDistrictManagementScreenState();
}

class _CategoryDistrictManagementScreenState
    extends State<CategoryDistrictManagementScreen> {
  int _selectedTab = 0;
  String _artisanSearch = '';
  String _artisanFilter = 'all';
  final TextEditingController _artisanSearchController =
      TextEditingController();

  @override
  void dispose() {
    _artisanSearchController.dispose();
    super.dispose();
  }

  void _openAddCategoryDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedIconKey = 'handyman';
    IconData selectedIcon = Icons.handyman;

    final iconChoices = <String, IconData>{
      'handyman': Icons.handyman,
      'electrical_services': Icons.electrical_services,
      'plumbing': Icons.plumbing,
      'hvac': Icons.hvac,
      'carpenter': Icons.carpenter,
      'microwave': Icons.microwave,
      'format_paint': Icons.format_paint,
      'roofing': Icons.roofing,
      'cleaning_services': Icons.cleaning_services,
      'pest_control': Icons.pest_control,
      'yard': Icons.yard,
      'security': Icons.security,
      'local_shipping': Icons.local_shipping,
      'solar_power': Icons.solar_power,
    };

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: context.themeSurface,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_circle_outline,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                context.l10n.addServiceCategory,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.themeTextPrimary,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: MediaQuery.of(dialogCtx).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.cdmPublishedCategoriesInfo,
                            style: TextStyle(
                                fontSize: 11.5,
                                color: context.themeTextPrimary,
                                height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(context.l10n.categoryTitle,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.themeTextPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    style: TextStyle(color: context.themeTextPrimary),
                    decoration: InputDecoration(
                      hintText: context.l10n.cdmCategoryTitleHint,
                      hintStyle: TextStyle(color: context.themeTextSecondary),
                      prefixIcon: Icon(selectedIcon,
                          size: 20, color: AppColors.primary),
                      filled: true,
                      fillColor: context.themeSurfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.themeBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(context.l10n.serviceDescription,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.themeTextPrimary)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    style: TextStyle(color: context.themeTextPrimary),
                    decoration: InputDecoration(
                      hintText: context.l10n.cdmServiceDescriptionHint,
                      hintStyle: TextStyle(color: context.themeTextSecondary),
                      filled: true,
                      fillColor: context.themeSurfaceLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: context.themeBorder),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(context.l10n.selectTradeIcon,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: context.themeTextPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: iconChoices.entries.map((entry) {
                      final isSelected = selectedIconKey == entry.key;
                      return InkWell(
                        onTap: () {
                          setDialogState(() {
                            selectedIconKey = entry.key;
                            selectedIcon = entry.value;
                          });
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : context.themeSurfaceLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : context.themeBorder,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Icon(
                            entry.value,
                            color: isSelected
                                ? AppColors.primary
                                : context.themeTextSecondary,
                            size: 22,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(context.l10n.cancel,
                  style: TextStyle(color: context.themeTextSecondary)),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l10n.cdmEnterCategoryTitle),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                final desc = descriptionController.text.trim().isNotEmpty
                    ? descriptionController.text.trim()
                    : 'Certified domestic $title services across Sri Lanka.';

                final cat = CategoryRow(
                  icon: selectedIcon,
                  name: title,
                  description: desc,
                  registered: '0 Registered',
                  onlineNow: '0 Online Now',
                  baseFee: 'Dynamic Quote',
                  hourlyCap: 'Artisan Bid',
                  districts: kAllSriLankanDistricts,
                  surge: 'Market Rate',
                  status: 'Active',
                  iconKey: selectedIconKey,
                );

                await CategoryRepository().addCategory(cat);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(context.l10n.cdmCategorySaved(title)),
                        ],
                      ),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.check, size: 16),
              label: Text(context.l10n.savePublishCategory),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, CategoryRow c) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: context.themeSurface,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.error, size: 22),
            const SizedBox(width: 8),
            Text(context.l10n.deleteCategory,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.themeTextPrimary)),
          ],
        ),
        content: Text(
          context.l10n.cdmDeleteCategoryConfirm(c.name),
          style: TextStyle(fontSize: 13, color: context.themeTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(context.l10n.cancel,
                style: TextStyle(color: context.themeTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              await CategoryRepository().deleteCategory(c.id);
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.cdmCategoryDeleted(c.name)),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.cdmDelete),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    final roleProvider = pv.Provider.of<RoleProvider>(context);
    final canManageCategories =
        roleProvider.hasAdminPermission(AdminPermission.manageCategories);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : 24,
        isMobile ? 16 : 24,
        isMobile ? 16 : 24,
        isMobile ? AppBottomNav.contentBottomPadding : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_selectedTab == 0) ...[
            if (isMobile) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.tradeCategoriesTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.themeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (canManageCategories)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => _openAddCategoryDialog(context),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(
                          context.l10n.addNewCategoryAction,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.ink,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: context.themeAmberTint,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: context.themeAmberText.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline,
                              size: 16, color: context.themeAmberText),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.l10n.readOnlyOpsGovernance,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: context.themeAmberText),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.tradeCategoriesTitle,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.themeTextPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (canManageCategories)
                    ElevatedButton.icon(
                      onPressed: () => _openAddCategoryDialog(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(context.l10n.addNewCategoryAction,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.ink,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            context.l10n.cdmReadOnlyModeOpsGovernance,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.activeArtisanFleetTitle,
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.cdmFleetSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.themeTextSecondary,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: isMobile ? 16 : 20),
          _CatalogMetricsBar(
            isMobile: isMobile,
            selectedTab: _selectedTab,
            onTabSelected: (tab) => setState(() => _selectedTab = tab),
          ),
          SizedBox(height: isMobile ? 16 : 20),
          if (_selectedTab == 0)
            Container(
              padding: EdgeInsets.all(isMobile ? 14 : 16),
              decoration: BoxDecoration(
                color: context.themeSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.themeBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: context.isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                  )
                ],
              ),
              child: StreamBuilder<List<Technician>>(
                stream: TechnicianRepository().streamTechnicians(),
                builder: (context, techSnapshot) {
                  final technicians = techSnapshot.data ?? [];
                  return StreamBuilder<List<CategoryRow>>(
                    stream: CategoryRepository().streamCategoryRows(),
                    builder: (context, snapshot) {
                      final categories = snapshot.data ?? [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.publishedTradeCategories,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: context.themeTextPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              context.l10n.categoriesCount('${categories.length}'),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (categories.isEmpty &&
                          snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary),
                          ),
                        )
                      else if (categories.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: context.themeSurfaceLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.themeBorder),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.category_outlined,
                                    size: 32, color: AppColors.primary),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                context.l10n.noCategoriesInDb,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: context.themeTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.l10n.cdmNoCategoriesDesc,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: context.themeTextSecondary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _openAddCategoryDialog(context),
                                icon: const Icon(Icons.add, size: 16),
                                label: Text(context.l10n.addFirstCategory,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (isMobile)
                        Column(
                          children: categories.map((c) {
                            final catNameLower = c.name.toLowerCase().trim();
                            final matchingTechs = technicians.where((t) {
                              final title = t.title.toLowerCase().trim();
                              return title == catNameLower ||
                                  (title.isNotEmpty &&
                                      (title.contains(catNameLower) ||
                                          catNameLower.contains(title)));
                            }).toList();
                            final registeredCount = matchingTechs.length;
                            final onlineCount =
                                matchingTechs.where((t) => t.online).length;
                            return _MobileCategoryCard(
                              c: c,
                              registeredCount: registeredCount,
                              onlineCount: onlineCount,
                              onToggleStatus: () async {
                                await CategoryRepository()
                                    .toggleCategoryStatus(c.id, c.status);
                              },
                              onDelete: () =>
                                  _confirmDeleteCategory(context, c),
                            );
                          }).toList(),
                        )
                      else
                        Column(
                          children: categories.map((c) {
                            final isActive = c.status.toLowerCase() == 'active';
                            final catNameLower = c.name.toLowerCase().trim();
                            final matchingTechs = technicians.where((t) {
                              final title = t.title.toLowerCase().trim();
                              return title == catNameLower ||
                                  (title.isNotEmpty &&
                                      (title.contains(catNameLower) ||
                                          catNameLower.contains(title)));
                            }).toList();
                            final registeredCount = matchingTechs.length;
                            final onlineCount =
                                matchingTechs.where((t) => t.online).length;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: context.themeSurfaceLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.themeBorder),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(c.icon,
                                        color: AppColors.primary, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          LocalizedData.getCategory(context, c.name),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            color: context.themeTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          c.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: context.themeTextSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          context.l10n.registeredOnlineCount(
                                            '$registeredCount',
                                            '$onlineCount',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 3,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: context.themeSurface,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: context.themeBorder),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.gavel_rounded,
                                              size: 14,
                                              color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  context.l10n.cdmDynamicQuotes,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 11,
                                                    color: context
                                                        .themeTextPrimary,
                                                  ),
                                                ),
                                                Text(
                                                  context.l10n.cdmArtisansBidPerJob,
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    color: context
                                                        .themeTextSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.public,
                                            size: 12, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text(
                                          context.l10n.islandWideBadge,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  InkWell(
                                    onTap: () async {
                                      await CategoryRepository()
                                          .toggleCategoryStatus(c.id, c.status);
                                    },
                                    borderRadius: BorderRadius.circular(999),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (isActive
                                                ? AppColors.primary
                                                : AppColors.error)
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isActive
                                                ? Icons.check_circle
                                                : Icons.pause_circle_outline,
                                            size: 13,
                                            color: isActive
                                                ? AppColors.primary
                                                : AppColors.error,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            LocalizedData.getStatus(context, c.status),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isActive
                                                  ? AppColors.primary
                                                  : AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert,
                                        size: 18,
                                        color: context.themeTextSecondary),
                                    onSelected: (val) {
                                      if (val == 'toggle') {
                                        CategoryRepository()
                                            .toggleCategoryStatus(
                                                c.id, c.status);
                                      } else if (val == 'delete') {
                                        _confirmDeleteCategory(context, c);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      PopupMenuItem(
                                        value: 'toggle',
                                        child: Row(
                                          children: [
                                            Icon(
                                              isActive
                                                  ? Icons.pause_outlined
                                                  : Icons.play_arrow_outlined,
                                              size: 16,
                                              color: context.themeTextPrimary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(isActive
                                                ? context.l10n.cdmPauseCategory
                                                : context.l10n.cdmActivateCategory),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            const Icon(Icons.delete_outline,
                                                size: 16,
                                                color: AppColors.error),
                                            const SizedBox(width: 8),
                                            Text(context.l10n.deleteCategory,
                                                style: const TextStyle(
                                                    color: AppColors.error)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
          if (_selectedTab == 1) _buildArtisanFleetView(context, isMobile),
        ],
      ),
    );
  }

  Widget _buildArtisanFleetView(BuildContext context, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.2 : 0.04),
            blurRadius: 10,
          )
        ],
      ),
      child: StreamBuilder<List<Technician>>(
        stream: TechnicianRepository().streamTechnicians(),
        builder: (context, snapshot) {
          final technicians = snapshot.data ?? [];

          final filtered = technicians.where((t) {
            if (_artisanFilter == 'active' && (t.isBanned || !t.online)) {
              return false;
            }
            if (_artisanFilter == 'suspended' && !t.isBanned) {
              return false;
            }
            if (_artisanFilter == 'offline' && (t.isBanned || t.online)) {
              return false;
            }

            if (_artisanSearch.isNotEmpty) {
              final q = _artisanSearch.toLowerCase();
              final name = t.name.toLowerCase();
              final title = t.title.toLowerCase();
              final area = t.serviceArea.toLowerCase();
              final phone = t.phone.toLowerCase();
              return name.contains(q) ||
                  title.contains(q) ||
                  area.contains(q) ||
                  phone.contains(q);
            }
            return true;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.activeArtisanFleetTitle,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: context.themeTextPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      context.l10n.artisansCount('${technicians.length}'),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _artisanSearchController,
                onChanged: (val) => setState(() => _artisanSearch = val.trim()),
                style: TextStyle(color: context.themeTextPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: context.l10n.searchFleetHint,
                  hintStyle: TextStyle(
                    color: context.themeTextSecondary.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Icons.search,
                      color: context.themeTextSecondary, size: 18),
                  suffixIcon: _artisanSearch.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _artisanSearchController.clear();
                            setState(() => _artisanSearch = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: context.themeSurfaceLow,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.themeBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.themeBorder),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildArtisanFilterChip('all',
                        context.l10n.cdmFilterAllCount('${technicians.length}')),
                    const SizedBox(width: 8),
                    _buildArtisanFilterChip(
                        'active',
                        context.l10n.cdmFilterOnlineCount(
                            '${technicians.where((t) => !t.isBanned && t.online).length}')),
                    const SizedBox(width: 8),
                    _buildArtisanFilterChip(
                        'suspended',
                        context.l10n.cdmFilterSuspendedCount(
                            '${technicians.where((t) => t.isBanned).length}')),
                    const SizedBox(width: 8),
                    _buildArtisanFilterChip(
                        'offline',
                        context.l10n.cdmFilterOfflineCount(
                            '${technicians.where((t) => !t.isBanned && !t.online).length}')),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (technicians.isEmpty &&
                  snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.themeSurfaceLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.engineering_outlined,
                          size: 36, color: context.themeTextSecondary),
                      const SizedBox(height: 8),
                      Text(
                        _artisanSearch.isNotEmpty
                            ? context.l10n.cdmNoArtisansMatchSearch
                            : context.l10n.cdmNoArtisansInFilter,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: context.themeTextPrimary),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: filtered.map((t) {
                    return _buildArtisanCard(context, t, isMobile);
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArtisanFilterChip(String key, String label) {
    final isSelected = _artisanFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _artisanFilter = key),
      selectedColor: AppColors.primary,
      backgroundColor: context.themeSurfaceLow,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.black : context.themeTextSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? AppColors.primary : context.themeBorder,
        ),
      ),
    );
  }

  Widget _buildArtisanCard(BuildContext context, Technician t, bool isMobile) {
    final isBanned = t.isBanned;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeSurfaceLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isBanned
              ? AppColors.error.withValues(alpha: 0.5)
              : context.themeBorder,
          width: isBanned ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: isBanned
                    ? AppColors.error.withValues(alpha: 0.2)
                    : t.avatarColor,
                child: Text(
                  t.initials,
                  style: TextStyle(
                    color: isBanned ? AppColors.error : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  t.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: context.themeTextPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (t.nicVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified,
                                    size: 14, color: AppColors.primary),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isBanned
                                    ? AppColors.error
                                    : (t.online ? Colors.teal : AppColors.outline))
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: (isBanned
                                      ? AppColors.error
                                      : (t.online
                                          ? Colors.teal
                                          : AppColors.outline))
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            isBanned
                                ? context.l10n.cdmBadgeSuspended
                                : (t.online
                                    ? context.l10n.cdmBadgeOnline
                                    : context.l10n.cdmBadgeOffline),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: isBanned
                                  ? AppColors.error
                                  : (t.online ? Colors.teal : AppColors.outline),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Flexible(
                          flex: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              t.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.location_on_outlined,
                            size: 12, color: context.themeTextSecondary),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            t.serviceArea.isNotEmpty
                                ? t.serviceArea
                                : context.l10n.cdmSriLanka,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        const Icon(Icons.star, size: 13, color: Colors.amber),
                        Text(
                          '${t.rating}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: context.themeTextPrimary,
                          ),
                        ),
                        Text(
                          '(${context.l10n.nJobsCompleted(t.jobsCount)})',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.themeTextSecondary,
                          ),
                        ),
                        Text(
                          '· ${context.l10n.cdmBaseRate('${t.baseRateLkr}')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isBanned && t.banReason != null && t.banReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                context.l10n.cdmSuspensionReason(t.banReason!),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (t.phone.isNotEmpty)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.4)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.phone, size: 14),
                  label: Text(t.phone, style: const TextStyle(fontSize: 11)),
                  onPressed: () => MapLauncher.openPhoneCall(t.phone),
                ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.themeTextPrimary,
                  side: BorderSide(color: context.themeBorder),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.flag_outlined, size: 14),
                label: Text(context.l10n.cdmComplaints,
                    style: const TextStyle(fontSize: 11)),
                onPressed: () => _showProviderComplaintsModal(context, t),
              ),
              if (!isBanned)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.gavel, size: 14),
                  label: Text(context.l10n.cdmSuspend,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _confirmBanTechnician(context, t),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 14),
                  label: Text(context.l10n.cdmRestoreUnban,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () => _confirmUnbanTechnician(context, t),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                tooltip: context.l10n.cdmDeleteArtisanPermanently,
                onPressed: () => _confirmDeleteTechnician(context, t),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmBanTechnician(BuildContext context, Technician t) {
    final reasonController = TextEditingController(
      text: 'Administrative suspension due to policy violations',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              context.l10n.cdmSuspendName(t.name),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: context.themeTextPrimary,
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
                context.l10n.cdmSuspendConfirmBody,
                style: TextStyle(fontSize: 13, color: context.themeTextSecondary),
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.cdmReasonForSuspension,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: context.themeTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                minLines: 2,
                maxLines: 4,
                style: TextStyle(color: context.themeTextPrimary, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.themeSurfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: context.themeBorder),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(context.l10n.cancel,
                style: TextStyle(color: context.themeTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await TechnicianRepository().toggleBanStatus(
                t.id,
                true,
                reason: reasonController.text.trim(),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.cdmArtisanSuspended(t.name)),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text(context.l10n.cdmConfirmSuspension),
          ),
        ],
      ),
    );
  }

  void _confirmUnbanTechnician(BuildContext context, Technician t) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.teal),
            const SizedBox(width: 8),
            Text(
              context.l10n.cdmRestoreName(t.name),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: context.themeTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          context.l10n.cdmRestoreConfirmBody,
          style: TextStyle(fontSize: 13, color: context.themeTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(context.l10n.cancel,
                style: TextStyle(color: context.themeTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await TechnicianRepository().toggleBanStatus(t.id, false);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.cdmArtisanRestored(t.name)),
                    backgroundColor: Colors.teal,
                  ),
                );
              }
            },
            child: Text(context.l10n.cdmRestoreAccess),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTechnician(BuildContext context, Technician t) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.themeSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(
              context.l10n.cdmDeleteArtisan,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: context.themeTextPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          context.l10n.cdmDeleteArtisanConfirm(t.name),
          style: TextStyle(fontSize: 13, color: context.themeTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(context.l10n.cancel,
                style: TextStyle(color: context.themeTextSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await TechnicianRepository().deleteTechnician(t.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.l10n.cdmArtisanDeleted(t.name)),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text(context.l10n.cdmDeletePermanently),
          ),
        ],
      ),
    );
  }

  void _showProviderComplaintsModal(BuildContext context, Technician t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetCtx.themeBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(Icons.flag_outlined,
                        color: AppColors.error, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        sheetCtx.l10n.cdmComplaintsFor(t.name),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: sheetCtx.themeTextPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: StreamBuilder<List<Complaint>>(
                    stream:
                        ComplaintRepository().streamComplaintsForProvider(t.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }

                      final complaints = snapshot.data ?? [];
                      if (complaints.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  size: 40, color: Colors.teal),
                              const SizedBox(height: 10),
                              Text(
                                sheetCtx.l10n.cdmNoComplaintsFiled,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: sheetCtx.themeTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sheetCtx.l10n.cdmNoComplaintsDesc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: sheetCtx.themeTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: complaints.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final c = complaints[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: sheetCtx.themeSurfaceLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: sheetCtx.themeBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        c.reason,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: sheetCtx.themeTextPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: c.status == 'resolved'
                                            ? Colors.teal
                                                .withValues(alpha: 0.15)
                                            : AppColors.error
                                                .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        c.status.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: c.status == 'resolved'
                                              ? Colors.teal
                                              : AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sheetCtx.l10n.cdmByCustomer(c.customerName),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: sheetCtx.themeTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  c.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: sheetCtx.themeTextPrimary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileCategoryCard extends StatelessWidget {
  final CategoryRow c;
  final int registeredCount;
  final int onlineCount;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  const _MobileCategoryCard({
    required this.c,
    this.registeredCount = 0,
    this.onlineCount = 0,
    required this.onToggleStatus,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = c.status.toLowerCase() == 'active';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.themeBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.themeSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(c.icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizedData.getCategory(context, c.name),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: context.themeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.registeredOnlineCount(
                        '$registeredCount',
                        '$onlineCount',
                      ),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.themeAmberText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onToggleStatus,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? context.themeSuccessTint
                        : context.themeDangerTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive
                            ? Icons.check_circle_rounded
                            : Icons.pause_circle_outline,
                        size: 12,
                        color: isActive
                            ? context.themeSuccess
                            : context.themeDanger,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        LocalizedData.getStatus(context, c.status),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? context.themeSuccess
                              : context.themeDanger,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    size: 20, color: context.themeTextSecondary),
                padding: EdgeInsets.zero,
                onSelected: (val) {
                  if (val == 'toggle') onToggleStatus();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                            isActive
                                ? Icons.pause_outlined
                                : Icons.play_arrow_outlined,
                            size: 16),
                        const SizedBox(width: 8),
                        Text(isActive
                            ? context.l10n.cdmPauseCategory
                            : context.l10n.cdmActivateCategory),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline,
                            size: 16, color: AppColors.error),
                        const SizedBox(width: 8),
                        Text(context.l10n.deleteCategory,
                            style: const TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (c.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              c.description,
              style: TextStyle(
                  fontSize: 12, color: context.themeTextSecondary, height: 1.3),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.themeSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.gavel_rounded,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.dynamicBiddingBadge,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      color: context.themeTextPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    context.l10n.islandWideBadge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: context.isDark
                          ? AppColors.primary
                          : context.themeAmberText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String sub;
  final bool isSelected;
  final VoidCallback? onTap;

  const _MiniCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.sub,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? context.themeAmberTint
                : context.themeSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : context.themeBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : context.themeSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(icon,
                            size: 16,
                            color: isSelected
                                ? context.themeAmberText
                                : context.themeTextSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? context.themeAmberText
                              : context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        context.l10n.viewingBadge,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.themeTextPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sub,
                style: TextStyle(
                  fontSize: 11,
                  color: context.themeTextSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogMetricsBar extends StatelessWidget {
  final bool isMobile;
  final int selectedTab;
  final ValueChanged<int> onTabSelected;

  const _CatalogMetricsBar({
    required this.isMobile,
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CategoryRow>>(
      stream: CategoryRepository().streamCategoryRows(),
      builder: (context, catSnap) {
        final categories = catSnap.data ?? [];
        final activeCount =
            categories.where((c) => c.status.toLowerCase() == 'active').length;

        return StreamBuilder<List<Technician>>(
          stream: TechnicianRepository().streamTechnicians(),
          builder: (context, techSnap) {
            final technicians = techSnap.data ?? [];

            final cards = [
              _MiniCard(
                icon: Icons.category,
                value: context.l10n.categoriesCount('${categories.length}'),
                label: context.l10n.catalogDensityTitle,
                sub: categories.isEmpty
                    ? context.l10n.noCategoriesInDb
                    : context.l10n.activeTradeServicesPublished('$activeCount'),
                isSelected: selectedTab == 0,
                onTap: () => onTabSelected(0),
              ),
              _MiniCard(
                icon: Icons.engineering,
                value: context.l10n.artisansCount('${technicians.length}'),
                label: context.l10n.activeArtisanFleetTitle,
                sub: technicians.isEmpty
                    ? context.l10n.noActiveArtisansFleet
                    : context.l10n.vettedTechniciansAvailable('${technicians.length}'),
                isSelected: selectedTab == 1,
                onTap: () => onTabSelected(1),
              ),
            ];

            if (isMobile) {
              return Column(
                children: [
                  cards[0],
                  const SizedBox(height: 10),
                  cards[1],
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
              ],
            );
          },
        );
      },
    );
  }
}
