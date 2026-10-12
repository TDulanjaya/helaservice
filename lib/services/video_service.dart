import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

class ProcessedVideoResult {
  final File compressedFile;
  final File thumbnailFile;
  final int durationSec;

  const ProcessedVideoResult({
    required this.compressedFile,
    required this.thumbnailFile,
    required this.durationSec,
  });
}

class VideoService {
  VideoService._();
  static final VideoService instance = VideoService._();

  // compress video <= 120s and make thumbnail
  Future<ProcessedVideoResult> processJobVideo(File rawVideoFile) async {
    try {
      final info = await VideoCompress.getMediaInfo(rawVideoFile.path);
      final rawDurationMs = info.duration ?? 0;
      final durationSec = (rawDurationMs / 1000).round();

      if (durationSec > 120) {
        throw Exception('Video length is $durationSec seconds. Maximum allowed duration is 120 seconds (2 minutes).');
      }

      // make thumbnail
      final thumbFile = await VideoCompress.getFileThumbnail(
        rawVideoFile.path,
        quality: 80,
      );

      // compress to 720p
      final mediaInfo = await VideoCompress.compressVideo(
        rawVideoFile.path,
        quality: VideoQuality.Res1280x720Quality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (mediaInfo == null || mediaInfo.file == null) {
        throw Exception('Failed to compress video');
      }

      final finalDurationSec = durationSec > 0
          ? durationSec
          : ((mediaInfo.duration ?? 0) / 1000).round();

      return ProcessedVideoResult(
        compressedFile: mediaInfo.file!,
        thumbnailFile: thumbFile,
        durationSec: finalDurationSec > 0 ? finalDurationSec : 1,
      );
    } catch (e) {
      debugPrint('[VideoService] Processing failed: $e');
      rethrow;
    }
  }

  /// Clean up video compression temporary caches.
  Future<void> cleanCache() async {
    try {
      await VideoCompress.deleteAllCache();
    } catch (e) {
      debugPrint('[VideoService] Cache clean error: $e');
    }
  }
}
