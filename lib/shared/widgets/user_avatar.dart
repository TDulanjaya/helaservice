import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/profile_image_service.dart';
import '../../theme/app_theme.dart';

class UserAvatar extends StatefulWidget {
  final String? uid;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final bool editable;
  final ValueChanged<Uint8List?>? onImageChanged;

  static const List<Color> avatarPalette = [
    Color(0xFF245851), // Teal green
    Color(0xFF6E3F27), // Warm brown
    Color(0xFF395CA6), // Slate blue
    Color(0xFF6A346C), // Plum purple
    Color(0xFF8B590E), // Amber brown
    Color(0xFF2B5B75), // Ocean blue
    Color(0xFF8A3B2C), // Crimson brick
    Color(0xFF3F613B), // Forest olive
    Color(0xFF4B4668), // Deep indigo
    Color(0xFF7A4A28), // Bronze
  ];

  // Pick color by user id
  static Color computeBackgroundColor(String? uid) {
    if (uid == null || uid.isEmpty) {
      return avatarPalette[0];
    }
    int hash = 0;
    for (int i = 0; i < uid.length; i++) {
      hash = (hash * 31 + uid.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return avatarPalette[hash % avatarPalette.length];
  }

  // Initials from name or email
  static String computeInitials({String? displayName, String? email}) {
    final name = (displayName ?? '').trim();
    if (name.isNotEmpty) {
      final parts =
          name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        final firstChar = parts[0].characters.first.toUpperCase();
        final secondChar = parts[1].characters.first.toUpperCase();
        return '$firstChar$secondChar';
      } else if (parts.length == 1) {
        return parts[0].characters.first.toUpperCase();
      }
    }

    final cleanEmail = (email ?? '').trim();
    if (cleanEmail.isNotEmpty) {
      return cleanEmail.characters.first.toUpperCase();
    }

    return '?';
  }

  const UserAvatar({
    super.key,
    this.uid,
    this.displayName = '',
    this.email,
    this.photoUrl,
    this.radius = 24,
    this.backgroundColor,
    this.textColor,
    this.editable = false,
    this.onImageChanged,
  });

  @override
  State<UserAvatar> createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  final ProfileImageService _imageService = ProfileImageService();
  bool _isUploading = false;
  Uint8List? _cachedBytes;

  @override
  void initState() {
    super.initState();
    _loadInitialImage();
  }

  @override
  void didUpdateWidget(covariant UserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) {
      _loadInitialImage();
    }
  }

  void _loadInitialImage() {
    final uid = widget.uid;
    if (uid != null && uid.isNotEmpty) {
      _cachedBytes = _imageService.getCachedImage(uid);
      if (_cachedBytes == null && !_imageService.hasInCache(uid)) {
        _imageService.getImage(uid).then((bytes) {
          if (mounted && bytes != null) {
            setState(() => _cachedBytes = bytes);
          }
        });
      }
    }
  }

  String get _initials => UserAvatar.computeInitials(
        displayName: widget.displayName,
        email: widget.email,
      );

  Future<void> _handlePick(ImageSource source) async {
    Navigator.of(context).pop();
    setState(() => _isUploading = true);

    try {
      final bytes = await _imageService.pickAndUpload(source);
      if (bytes != null && mounted) {
        setState(() => _cachedBytes = bytes);
        widget.onImageChanged?.call(bytes);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _handleRemove() async {
    Navigator.of(context).pop();
    setState(() => _isUploading = true);

    try {
      await _imageService.remove(targetUid: widget.uid);
      if (mounted) {
        setState(() => _cachedBytes = null);
        widget.onImageChanged?.call(null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture removed.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showEditSheet() {
    final hasDp = _cachedBytes != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
                title: const Text('Take photo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => _handlePick(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => _handlePick(ImageSource.gallery),
              ),
              if (hasDp)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Remove photo', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                  onTap: _handleRemove,
                ),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarContent(Uint8List? dpBytes) {
    final double diameter = widget.radius * 2;

    // Show photo if available
    if (dpBytes != null && dpBytes.isNotEmpty) {
      return Image.memory(
        dpBytes,
        width: diameter,
        height: diameter,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(diameter),
      );
    }

    // Fallback to initials
    return _buildFallback(diameter);
  }

  Widget _buildFallback(double diameter) {
    final bg = widget.backgroundColor ?? UserAvatar.computeBackgroundColor(widget.uid);
    return Container(
      width: diameter,
      height: diameter,
      color: bg,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: widget.textColor ?? Colors.white,
          fontSize: widget.radius * 0.78,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double diameter = widget.radius * 2;
    final currentAuthUid = FirebaseAuth.instance.currentUser?.uid;
    final isCurrentUser = widget.uid != null && widget.uid == currentAuthUid;

    Widget avatarCore;

    // Watch photo for current user
    if (widget.editable && isCurrentUser) {
      avatarCore = StreamBuilder<Uint8List?>(
        stream: _imageService.watchImage(widget.uid!),
        initialData: _cachedBytes,
        builder: (context, snapshot) {
          final bytes = snapshot.data ?? _cachedBytes;
          return _buildAvatarContent(bytes);
        },
      );
    } else {
      avatarCore = _buildAvatarContent(_cachedBytes);
    }

    Widget avatar = ClipOval(
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: Stack(
          alignment: Alignment.center,
          children: [
            avatarCore,
            if (_isUploading)
              Container(
                width: diameter,
                height: diameter,
                color: Colors.black45,
                child: Center(
                  child: SizedBox(
                    width: widget.radius * 0.8,
                    height: widget.radius * 0.8,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!widget.editable) {
      return avatar;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: context.themeSurface,
                width: 2,
              ),
            ),
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                onTap: _isUploading ? null : _showEditSheet,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: EdgeInsets.all(widget.radius * 0.18),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: widget.radius * 0.46,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );

  }
}
