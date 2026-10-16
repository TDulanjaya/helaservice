import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../models/job_request.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/l10n_extension.dart';

// gallery for job request photos and video preview
class JobMediaGallery extends StatelessWidget {
  final List<JobMediaItem> photos;
  final JobVideoItem? video;
  final List<String>? legacyPhotoUrls;
  final List<String>? photoUrls;
  final String? videoUrl;
  final double height;
  final bool showHeader;

  const JobMediaGallery({
    super.key,
    this.photos = const [],
    this.video,
    this.legacyPhotoUrls,
    this.photoUrls,
    this.videoUrl,
    this.height = 76,
    this.showHeader = true,
  });

  factory JobMediaGallery.fromRequest(JobRequest request,
      {double height = 76, bool showHeader = true}) {
    return JobMediaGallery(
      photos: request.photos,
      video: request.video,
      legacyPhotoUrls: request.photoUrls,
      height: height,
      showHeader: showHeader,
    );
  }

  List<String> get _allPhotoUrls {
    if (photoUrls != null && photoUrls!.isNotEmpty) {
      return photoUrls!.where((u) => u.isNotEmpty).toList();
    }
    final urls = photos.map((p) => p.url).where((u) => u.isNotEmpty).toList();
    if (urls.isEmpty && legacyPhotoUrls != null) {
      urls.addAll(legacyPhotoUrls!.where((u) => u.isNotEmpty));
    }
    return urls;
  }

  String? get _resolvedVideoUrl {
    if (videoUrl != null && videoUrl!.isNotEmpty) return videoUrl;
    if (video != null && video!.url.isNotEmpty) return video!.url;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final urls = _allPhotoUrls;
    final vidUrl = _resolvedVideoUrl;
    final hasVideo = vidUrl != null && vidUrl.isNotEmpty;

    if (urls.isEmpty && !hasVideo) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasVideo) ...[
          _buildVideoThumbnail(
            context,
            url: vidUrl,
            thumbUrl: video?.thumbUrl,
            durationSec: video?.durationSec,
          ),
          if (urls.isNotEmpty) const SizedBox(height: 12),
        ],
        if (urls.isNotEmpty) _buildPhotosRow(context, urls),
      ],
    );
  }

  Widget _buildVideoThumbnail(
    BuildContext context, {
    required String url,
    String? thumbUrl,
    int? durationSec,
  }) {
    return GestureDetector(
      onTap: () => _openVideoPlayer(context, url),
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          image: thumbUrl != null && thumbUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(thumbUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 38,
              ),
            ),
            if (durationSec != null && durationSec > 0)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${durationSec ~/ 60}:${(durationSec % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.videoClip,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotosRow(BuildContext context, List<String> urls) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, index) {
          final url = urls[index];
          return GestureDetector(
            onTap: () => _openPhotoViewer(context, urls, index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 90,
                height: 90,
                color: AppColors.surfaceLow,
                child: _buildPhotoThumb(url),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoThumb(String url) {
    if (url.startsWith('data:')) {
      try {
        final bytes = base64Decode(url.split(',').last);
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, size: 28, color: Colors.grey),
          ),
        );
      } catch (_) {
        return const Center(
            child: Icon(Icons.broken_image, size: 28, color: Colors.grey));
      }
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image, size: 28, color: Colors.grey),
      ),
    );
  }

  void _openPhotoViewer(
      BuildContext context, List<String> urls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _FullScreenPhotoViewer(urls: urls, initialIndex: initialIndex),
      ),
    );
  }

  void _openVideoPlayer(BuildContext context, String videoUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenVideoPlayer(videoUrl: videoUrl),
      ),
    );
  }
}

// full-screen swipe and pinch zoom photo viewer
class _FullScreenPhotoViewer extends StatefulWidget {
  final List<String> urls;
  final int initialIndex;

  const _FullScreenPhotoViewer({
    required this.urls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenPhotoViewer> createState() => _FullScreenPhotoViewerState();
}

class _FullScreenPhotoViewerState extends State<_FullScreenPhotoViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_currentIndex + 1} / ${widget.urls.length}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (ctx, i) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: widget.urls[i].startsWith('data:')
                  ? Image.memory(
                      Uint8List.fromList(
                          base64Decode(widget.urls[i].split(',').last)),
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image,
                            size: 48, color: Colors.white54),
                      ),
                    )
                  : Image.network(
                      widget.urls[i],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image,
                            size: 48, color: Colors.white54),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

// full-screen video player using video_player
class _FullScreenVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _FullScreenVideoPlayer({required this.videoUrl});

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.play();
        }
      }).catchError((e) {
        if (mounted) {
          setState(() => _error = e.toString());
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title:
            Text(context.l10n.jobVideo, style: const TextStyle(fontSize: 15)),
      ),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.failedToPlayVideo,
                  style: const TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
            : !_isInitialized
                ? const CircularProgressIndicator(color: AppColors.primary)
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        VideoPlayer(_controller),
                        _buildControls(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      color: Colors.black38,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _controller.value.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
          ),
          Expanded(
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
