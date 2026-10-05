import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';

class SearchableSelectItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final List<String> searchTerms;

  const SearchableSelectItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.icon,
    this.searchTerms = const [],
  });
}

class SearchableSelectPicker<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final T? selectedValue;
  final List<SearchableSelectItem<T>> items;
  final ValueChanged<T> onSelected;
  final IconData? prefixIcon;
  final bool isDarkField;
  final String? modalTitle;
  final String? searchHint;

  const SearchableSelectPicker({
    super.key,
    required this.label,
    this.hint,
    required this.selectedValue,
    required this.items,
    required this.onSelected,
    this.prefixIcon,
    this.isDarkField = false,
    this.modalTitle,
    this.searchHint,
  });

  SearchableSelectItem<T>? get _selectedItem {
    try {
      return items.firstWhere((it) => it.value == selectedValue);
    } catch (_) {
      return null;
    }
  }

  void _openPicker(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final effectiveTitle = modalTitle ?? context.l10n.selectOption;
    final effectiveSearchHint = searchHint ?? '${context.l10n.topBarSearch}...';

    if (isDesktop) {
      showDialog(
        context: context,
        builder: (dialogCtx) => Dialog(
          backgroundColor: dialogCtx.themeSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: dialogCtx.themeBorder, width: 1.5),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
            child: _PickerSheetContent<T>(
              title: effectiveTitle,
              searchHint: effectiveSearchHint,
              items: items,
              selectedValue: selectedValue,
              onSelected: (val) {
                Navigator.of(dialogCtx).pop();
                onSelected(val);
              },
              isDialog: true,
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        backgroundColor: context.themeSurface,
        isScrollControlled: true,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetCtx) => FractionallySizedBox(
          heightFactor: 0.82,
          child: _PickerSheetContent<T>(
            title: effectiveTitle,
            searchHint: effectiveSearchHint,
            items: items,
            selectedValue: selectedValue,
            onSelected: (val) {
              Navigator.of(sheetCtx).pop();
              onSelected(val);
            },
            isDialog: false,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDarkField ? context.themeSurfaceLow : Colors.white;
    final item = _selectedItem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label.isNotEmpty) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.themeTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: () => _openPicker(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.themeBorder,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                if (prefixIcon != null) ...[
                  Icon(prefixIcon, size: 20, color: context.themeTextSecondary),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: item != null
                      ? Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: context.themeTextPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          hint ?? label,
                          style: TextStyle(
                            fontSize: 14.5,
                            color: context.themeTextSecondary.withValues(alpha: 0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: context.themeTextSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerSheetContent<T> extends StatefulWidget {
  final String title;
  final String searchHint;
  final List<SearchableSelectItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T> onSelected;
  final bool isDialog;

  const _PickerSheetContent({
    required this.title,
    required this.searchHint,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    required this.isDialog,
  });

  @override
  State<_PickerSheetContent<T>> createState() => _PickerSheetContentState<T>();
}

class _PickerSheetContentState<T> extends State<_PickerSheetContent<T>> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SearchableSelectItem<T>> get _filteredItems {
    if (_query.trim().isEmpty) return widget.items;
    final q = _query.trim().toLowerCase();
    return widget.items.where((it) {
      if (it.label.toLowerCase().contains(q)) return true;
      if (it.subtitle != null && it.subtitle!.toLowerCase().contains(q)) return true;
      for (final term in it.searchTerms) {
        if (term.toLowerCase().contains(q)) return true;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems;
    final isDark = context.isDark;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, widget.isDialog ? 20 : 6, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.themeTextPrimary,
                ),
              ),
              if (widget.isDialog)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // search bar
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _query = val),
            style: TextStyle(color: context.themeTextPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.searchHint,
              hintStyle: TextStyle(
                color: context.themeTextSecondary.withValues(alpha: 0.6),
                fontSize: 13.5,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: context.themeTextSecondary,
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? context.themeSurfaceLow : const Color(0xFFF6F7F9),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.themeBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.themeBorder),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(14)),
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 40,
                          color: context.themeTextSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          context.l10n.noMatchesFound,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (ctx, idx) {
                      final it = filtered[idx];
                      final isSelected = it.value == widget.selectedValue;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => widget.onSelected(it.value),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.4),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                if (it.icon != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withValues(alpha: 0.15)
                                          : (isDark ? context.themeSurfaceLow : const Color(0xFFF1F3F5)),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      it.icon,
                                      size: 16,
                                      color: isSelected ? AppColors.primary : context.themeTextSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it.label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected ? AppColors.primary : context.themeTextPrimary,
                                        ),
                                      ),
                                      if (it.subtitle != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          it.subtitle!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.themeTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
