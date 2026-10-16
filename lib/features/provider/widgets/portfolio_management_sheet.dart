import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/portfolio_item.dart';
import '../../../repositories/portfolio_repository.dart';
import '../../../services/category_service.dart';
import '../../../services/storage_service.dart';
import '../../../shared/widgets/photo_viewer_dialog.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';

class PortfolioManagementSheet extends StatefulWidget {
  final String providerId;

  const PortfolioManagementSheet({super.key, required this.providerId});

  static Future<void> show(BuildContext context, String providerId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PortfolioManagementSheet(providerId: providerId),
    );
  }

  @override
  State<PortfolioManagementSheet> createState() =>
      _PortfolioManagementSheetState();
}

class _PortfolioManagementSheetState extends State<PortfolioManagementSheet> {
  final PortfolioRepository _repo = PortfolioRepository();

  void _openAddItemDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _AddPortfolioItemModal(
        providerId: widget.providerId,
        onSuccess: () => Navigator.pop(sheetCtx),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PortfolioItem item) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(context.l10n.deletePortfolioConfirm),
        content: Text(item.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text(context.l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dlgCtx);
              await _repo.deletePortfolioItem(widget.providerId, item.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.deleteAccountConfirmAction),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.themeBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.collections_rounded,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.portfolioTitle,
                        style: const TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        context.l10n.portfolioSubtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _openAddItemDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: Text(
                    context.l10n.addPortfolioItem,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<PortfolioItem>>(
                stream: _repo.streamPortfolio(widget.providerId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.collections_outlined,
                              size: 48, color: context.themeMuted),
                          const SizedBox(height: 10),
                          Text(
                            context.l10n.noPortfolioItems,
                            style: TextStyle(
                              color: context.themeTextSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: context.themeSurfaceLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.themeBorder),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  GestureDetector(
                                    onTap: () => PhotoViewerDialog.show(
                                      context,
                                      photoUrl: item.photoUrl,
                                      title: item.title,
                                    ),
                                    child: Image.network(
                                      item.photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: context.themeSurface,
                                        child: const Icon(
                                            Icons.broken_image_rounded),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _confirmDelete(context, item),
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.65),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                  if (item.category.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      CategoryService.instance.nameOf(
                                          item.category,
                                          context: context),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ],
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
    );
  }
}

class _AddPortfolioItemModal extends StatefulWidget {
  final String providerId;
  final VoidCallback onSuccess;

  const _AddPortfolioItemModal({
    required this.providerId,
    required this.onSuccess,
  });

  @override
  State<_AddPortfolioItemModal> createState() => _AddPortfolioItemModalState();
}

class _AddPortfolioItemModalState extends State<_AddPortfolioItemModal> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isSaving = false;
  String _selectedCategory = '';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 82,
    );
    if (picked != null) {
      // load image bytes for preview
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.enterProjectTitle)),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.selectPhotoForShowcase)),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final bytes = await _selectedImage!.readAsBytes();
      final filename =
          'portfolio_${widget.providerId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final photoUrl =
          await StorageService.instance.uploadBytes(bytes, filename: filename);

      await PortfolioRepository().addPortfolioItem(
        providerId: widget.providerId,
        title: title,
        description: _descController.text.trim(),
        category: _selectedCategory,
        photoUrl: photoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.portfolioItemAdded),
            backgroundColor: AppColors.primary,
          ),
        );
        widget.onSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.failedToSaveShowcase(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.themeBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                context.l10n.addPortfolioItem,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: context.themeSurface,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (sheetCtx) => SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt_rounded,
                                color: AppColors.primary),
                            title: Text(context.l10n.takePhoto),
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library_rounded,
                                color: AppColors.primary),
                            title: Text(context.l10n.chooseFromGallery),
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: context.themeSurfaceLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedImage != null
                          ? AppColors.primary
                          : context.themeBorder,
                      width: 1.5,
                    ),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _selectedImageBytes == null
                                  ? const Center(
                                      child: Icon(Icons.image, size: 40),
                                    )
                                  : Image.memory(
                                      _selectedImageBytes!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                        child: Icon(Icons.image, size: 40),
                                      ),
                                    ),
                            ),
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.edit_rounded,
                                        color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      context.l10n.edit,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add_a_photo_rounded,
                                    color: AppColors.primary, size: 28),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.uploadPhoto,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.portfolioItemTitle,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: context.l10n.portfolioItemTitleHint,
                  filled: true,
                  fillColor: context.themeSurfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.themeBorder),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.portfolioItemDesc,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: context.l10n.portfolioItemDescHint,
                  filled: true,
                  fillColor: context.themeSurfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.themeBorder),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.categoryLabel,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue:
                    _selectedCategory.isNotEmpty ? _selectedCategory : null,
                hint: Text(context.l10n.selectCategoryPrompt),
                dropdownColor: context.themeSurface,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: context.themeSurfaceLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: context.themeBorder),
                  ),
                ),
                items: CategoryService.instance.allCategories.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.name),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedCategory = val ?? '');
                },
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: context.l10n.saveChanges,
                loading: _isSaving,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
