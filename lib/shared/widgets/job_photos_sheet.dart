import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/booking.dart';
import '../../repositories/booking_repository.dart';
import '../../services/storage_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/l10n_extension.dart';
import 'photo_viewer_dialog.dart';

class JobPhotosSheet extends StatefulWidget {
  final Booking booking;
  final bool isProvider;

  const JobPhotosSheet({
    super.key,
    required this.booking,
    required this.isProvider,
  });

  static Future<void> show(BuildContext context,
      {required Booking booking, required bool isProvider}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobPhotosSheet(booking: booking, isProvider: isProvider),
    );
  }

  @override
  State<JobPhotosSheet> createState() => _JobPhotosSheetState();
}

class _JobPhotosSheetState extends State<JobPhotosSheet> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  String _uploadingSection = '';

  Future<void> _pickAndUploadPhoto(bool isBefore) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.themeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary),
                title: Text(context.l10n.takePhoto),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: AppColors.primary),
                title: Text(context.l10n.chooseFromGallery),
                onTap: () => Navigator.pop(sheetCtx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );

    if (picked == null) return;

    setState(() {
      _isUploading = true;
      _uploadingSection = isBefore ? 'before' : 'after';
    });

    try {
      final bytes = await picked.readAsBytes();
      final filename =
          'job_${widget.booking.id}_${isBefore ? 'before' : 'after'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final photoUrl = await StorageService.instance
          .uploadBytes(bytes, filename: filename);

      if (isBefore) {
        await BookingRepository().addBeforePhoto(
          bookingId: widget.booking.id,
          photoUrl: photoUrl,
        );
      } else {
        await BookingRepository().addAfterPhoto(
          bookingId: widget.booking.id,
          photoUrl: photoUrl,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.photoUploadedSuccess),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.l10n.failedToUploadImage}: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadingSection = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Booking?>(
      stream: BookingRepository().streamBookingById(widget.booking.id),
      builder: (context, snapshot) {
        final currentBooking = snapshot.data ?? widget.booking;
        final beforeList = currentBooking.beforePhotos;
        final afterList = currentBooking.afterPhotos;
        final canUpload = widget.isProvider &&
            (currentBooking.status == 'in_progress' ||
                currentBooking.status == 'completed');

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                      child: const Icon(Icons.photo_library_rounded,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.jobPhotos,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            context.l10n.jobPhotosSubtitle,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      _buildPhotoSection(
                        context,
                        title: context.l10n.beforePhotos,
                        photos: beforeList,
                        canAdd: canUpload,
                        isUploading: _isUploading && _uploadingSection == 'before',
                        emptyLabel: context.l10n.noBeforePhotos,
                        onAdd: () => _pickAndUploadPhoto(true),
                        badgeColor: Colors.amber,
                      ),
                      const SizedBox(height: 20),
                      _buildPhotoSection(
                        context,
                        title: context.l10n.afterPhotos,
                        photos: afterList,
                        canAdd: canUpload,
                        isUploading: _isUploading && _uploadingSection == 'after',
                        emptyLabel: context.l10n.noAfterPhotos,
                        onAdd: () => _pickAndUploadPhoto(false),
                        badgeColor: const Color(0xFF22C55E),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoSection(
    BuildContext context, {
    required String title,
    required List<String> photos,
    required bool canAdd,
    required bool isUploading,
    required String emptyLabel,
    required VoidCallback onAdd,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.themeSurfaceLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
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
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${photos.length})',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.themeTextSecondary,
                    ),
                  ),
                ],
              ),
              if (canAdd)
                InkWell(
                  onTap: isUploading ? null : onAdd,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isUploading)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(Icons.add_a_photo_rounded,
                              size: 14, color: AppColors.primary),
                        const SizedBox(width: 5),
                        Text(
                          isUploading
                              ? context.l10n.uploadingImage
                              : context.l10n.photo,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (photos.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.photo_outlined,
                        size: 32, color: context.themeMuted),
                    const SizedBox(height: 6),
                    Text(
                      emptyLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.themeTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, idx) {
                  final photoUrl = photos[idx];
                  return GestureDetector(
                    onTap: () => PhotoViewerDialog.show(
                      context,
                      photoUrl: photoUrl,
                      title: '$title #${idx + 1}',
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          Image.network(
                            photoUrl,
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(
                                width: 110,
                                height: 110,
                                color: context.themeSurface,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stack) => Container(
                              width: 110,
                              height: 110,
                              color: context.themeSurface,
                              child: const Icon(Icons.broken_image_rounded),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.fullscreen_rounded,
                                color: Colors.white,
                                size: 14,
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
      ),
    );
  }
}
