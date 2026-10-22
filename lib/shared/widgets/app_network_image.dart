import 'package:flutter/material.dart';
import '../../utils/media_url.dart';

// network image with auth headers
class AppNetworkImage extends StatefulWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final Color? color;
  final BlendMode? colorBlendMode;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.errorBuilder,
    this.loadingBuilder,
    this.color,
    this.colorBlendMode,
  });

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  Map<String, String>? _headers;
  bool _isLoadingHeaders = true;

  @override
  void initState() {
    super.initState();
    _initHeaders();
  }

  @override
  void didUpdateWidget(covariant AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _initHeaders();
    }
  }

  // load auth headers
  void _initHeaders() {
    if (!isAppMediaUrl(widget.url)) {
      _headers = null;
      _isLoadingHeaders = false;
      return;
    }

    _isLoadingHeaders = true;
    mediaHeaders().then((h) {
      if (mounted) {
        setState(() {
          _headers = h;
          _isLoadingHeaders = false;
        });
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _headers = null;
          _isLoadingHeaders = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingHeaders) {
      return widget.placeholder ??
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
    }

    return Image.network(
      widget.url,
      headers: _headers,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      color: widget.color,
      colorBlendMode: widget.colorBlendMode,
      errorBuilder: widget.errorBuilder ??
          (ctx, err, stack) =>
              widget.errorWidget ??
              const Center(
                child: Icon(Icons.broken_image, size: 28, color: Colors.grey),
              ),
      loadingBuilder: widget.loadingBuilder,
    );
  }
}
