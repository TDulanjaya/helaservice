import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';

// in-memory representation of a picked certificate file
class PickedCertificateItem {
  final String id;
  final Uint8List bytes;
  final String name;
  final bool isPdf;
  final int sizeBytes;
  final TextEditingController titleController;
  String? uploadedKey;
  String? savedDocId;

  PickedCertificateItem({
    required this.id,
    required this.bytes,
    required this.name,
    required this.isPdf,
    required this.sizeBytes,
    String initialTitle = '',
    this.uploadedKey,
    this.savedDocId,
  }) : titleController = TextEditingController(text: initialTitle);

  void dispose() {
    titleController.dispose();
  }
}

class CertificateUploadSection extends StatefulWidget {
  final List<PickedCertificateItem> items;
  final ValueChanged<List<PickedCertificateItem>> onChanged;
  final int maxFiles;
  final int maxSizeBytes;

  const CertificateUploadSection({
    super.key,
    required this.items,
    required this.onChanged,
    this.maxFiles = 10,
    this.maxSizeBytes = 10 * 1024 * 1024, // 10 mb
  });

  @override
  State<CertificateUploadSection> createState() =>
      _CertificateUploadSectionState();
}

class _CertificateUploadSectionState extends State<CertificateUploadSection> {
  final ImagePicker _picker = ImagePicker();
  static const String _pendingCertSlotKey = 'pending_cert_picker_active';

  @override
  void initState() {
    super.initState();
    _recoverLostAndroidPhoto();
  }

  // recover camera photo taken before android process kill
  Future<void> _recoverLostAndroidPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final isActive = prefs.getBool(_pendingCertSlotKey) ?? false;
      final lost = await _picker.retrieveLostData();
      await prefs.remove(_pendingCertSlotKey);
      if (!isActive || lost.isEmpty) return;

      final files = lost.files;
      final file = lost.file ??
          ((files != null && files.isNotEmpty) ? files.first : null);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;
      _addFileFromBytes(
        filename: file.name.isNotEmpty
            ? file.name
            : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
        bytes: bytes,
      );
    } catch (e) {
      debugPrint('[CertUpload] recover photo error: $e');
    }
  }

  void _addFileFromBytes({required String filename, required Uint8List bytes}) {
    if (widget.items.length >= widget.maxFiles) {
      _showMessage(context.l10n.certUploadMaxFilesError, isError: true);
      return;
    }

    if (bytes.length > widget.maxSizeBytes) {
      _showMessage(
        context.l10n.certUploadFileTooLargeError(filename),
        isError: true,
      );
      return;
    }

    final ext = filename.split('.').last.toLowerCase();
    const allowed = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];
    if (!allowed.contains(ext)) {
      _showMessage(
        context.l10n.certUploadUnsupportedTypeError(filename),
        isError: true,
      );
      return;
    }

    final isPdf = ext == 'pdf';
    final id =
        '${DateTime.now().microsecondsSinceEpoch}_${widget.items.length}';
    final newItem = PickedCertificateItem(
      id: id,
      bytes: bytes,
      name: filename,
      isPdf: isPdf,
      sizeBytes: bytes.length,
    );

    final updated = List<PickedCertificateItem>.from(widget.items)
      ..add(newItem);
    widget.onChanged(updated);
  }

  void _removeItem(int index) {
    if (index >= 0 && index < widget.items.length) {
      final removed = widget.items[index];
      final updated = List<PickedCertificateItem>.from(widget.items)
        ..removeAt(index);
      removed.dispose();
      widget.onChanged(updated);
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? AppColors.error : AppColors.primary,
      ),
    );
  }

  Future<void> _handleTakePhoto() async {
    Navigator.of(context).pop();
    if (widget.items.length >= widget.maxFiles) {
      _showMessage(context.l10n.certUploadMaxFilesError, isError: true);
      return;
    }

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_pendingCertSlotKey, true);
      }

      final picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 88,
      );

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_pendingCertSlotKey);
      }

      if (picked != null) {
        final bytes = await picked.readAsBytes();
        if (!mounted) return;
        _addFileFromBytes(
          filename: picked.name.isNotEmpty
              ? picked.name
              : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
          bytes: bytes,
        );
      }
    } catch (e) {
      debugPrint('[CertUpload] take photo error: $e');
    }
  }

  Future<void> _handleChooseFiles() async {
    Navigator.of(context).pop();
    if (widget.items.length >= widget.maxFiles) {
      _showMessage(context.l10n.certUploadMaxFilesError, isError: true);
      return;
    }

    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );

      if (pickedFiles.isEmpty) return;
      if (!mounted) return;

      int addedCount = 0;
      for (final f in pickedFiles) {
        if (widget.items.length + addedCount >= widget.maxFiles) {
          _showMessage(context.l10n.certUploadMaxFilesError, isError: true);
          break;
        }

        final ext = (f.extension ?? f.name.split('.').last).toLowerCase();
        const allowed = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];
        if (!allowed.contains(ext)) {
          _showMessage(
            context.l10n.certUploadUnsupportedTypeError(f.name),
            isError: true,
          );
          continue;
        }

        // check file size before reading bytes into memory
        final fileLength = f.lengthSync() ?? await f.length() ?? 0;
        if (!mounted) return;
        if (fileLength > widget.maxSizeBytes) {
          _showMessage(
            context.l10n.certUploadFileTooLargeError(f.name),
            isError: true,
          );
          continue;
        }

        final bytes = await f.readAsBytes();
        if (!mounted) return;

        if (bytes.length > widget.maxSizeBytes) {
          _showMessage(
            context.l10n.certUploadFileTooLargeError(f.name),
            isError: true,
          );
          continue;
        }

        final isPdf = ext == 'pdf';
        final id =
            '${DateTime.now().microsecondsSinceEpoch}_${widget.items.length + addedCount}';
        final newItem = PickedCertificateItem(
          id: id,
          bytes: bytes,
          name: f.name,
          isPdf: isPdf,
          sizeBytes: bytes.length,
        );
        widget.items.add(newItem);
        addedCount++;
      }

      if (addedCount > 0) {
        widget.onChanged(List<PickedCertificateItem>.from(widget.items));
      }
    } catch (e) {
      debugPrint('[CertUpload] pick files error: $e');
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.themeBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  ctx.l10n.certUploadButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    ctx.l10n.takeProfilePhoto,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: _handleTakePhoto,
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.folder_open_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    ctx.l10n.certUploadChooseFiles,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onTap: _handleChooseFiles,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.l10n.certUploadSectionTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: context.themeTextPrimary,
                ),
              ),
            ),
            if (widget.items.isNotEmpty)
              Text(
                '${widget.items.length}/${widget.maxFiles}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.themeTextSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.certUploadSectionHint,
          style: TextStyle(
            fontSize: 12,
            color: context.themeTextSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // upload trigger button
        InkWell(
          onTap:
              widget.items.length < widget.maxFiles ? _showSourceSheet : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.themeSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.items.length < widget.maxFiles
                    ? AppColors.primary.withValues(alpha: 0.45)
                    : context.themeBorder,
                style: BorderStyle.solid,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upload_file_rounded,
                  color: widget.items.length < widget.maxFiles
                      ? AppColors.primary
                      : context.themeTextSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.certUploadButton,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: widget.items.length < widget.maxFiles
                        ? AppColors.primary
                        : context.themeTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // picked items list
        if (widget.items.isNotEmpty) ...[
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.themeSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.themeBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // thumbnail or pdf badge
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 54,
                        height: 54,
                        color: context.themeSoft,
                        child: item.isPdf
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.picture_as_pdf_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 26,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'PDF',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: context.themeTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Image.memory(
                                item.bytes,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.broken_image_outlined,
                                  size: 24,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // details & title input
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: context.themeTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextField(
                            controller: item.titleController,
                            maxLength: 80,
                            style: const TextStyle(fontSize: 12.5),
                            decoration: InputDecoration(
                              isDense: true,
                              counterText: '',
                              hintText: context.l10n.certUploadTitleHint,
                              hintStyle: TextStyle(
                                fontSize: 11.5,
                                color: context.themeTextSecondary,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: context.themeBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: context.themeBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                  width: 1.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // remove button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      tooltip: context.l10n.cancel,
                      color: context.themeTextSecondary,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _removeItem(index),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
