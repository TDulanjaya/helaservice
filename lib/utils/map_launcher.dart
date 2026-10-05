import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncher {
  MapLauncher._();

  // open maps navigation
  static Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? destinationTitle,
  }) async {
    // validate coordinates
    if (latitude.isNaN || longitude.isNaN) return false;
    if (latitude == 0.0 && longitude == 0.0) return false;
    if (latitude < -90.0 || latitude > 90.0) return false;
    if (longitude < -180.0 || longitude > 180.0) return false;

    final title = Uri.encodeComponent(destinationTitle ?? 'Service Location');

    if (kIsWeb) {
      final webUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
      );
      try {
        return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (_) {
        return false;
      }
    }

    if (Platform.isAndroid) {
      try {
        final googleMapsIntent = Uri.parse('google.navigation:q=$latitude,$longitude&mode=d');
        if (await canLaunchUrl(googleMapsIntent)) {
          return await launchUrl(googleMapsIntent, mode: LaunchMode.externalApplication);
        }

        final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude($title)');
        if (await canLaunchUrl(geoUri)) {
          return await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('[MapLauncher] Intent error: $e');
      }
    } else if (Platform.isIOS) {
      try {
        final appleMapsUri = Uri.parse('maps:?daddr=$latitude,$longitude&q=$title');
        if (await canLaunchUrl(appleMapsUri)) {
          return await launchUrl(appleMapsUri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('[MapLauncher] Apple maps error: $e');
      }
    }

    // fallback to google maps web
    try {
      final fallbackUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
      );
      return await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  // open phone dialer
  static Future<bool> openPhoneCall(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) return false;

    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-()]'), '');
    if (cleaned.startsWith('0') && cleaned.length == 10) {
      cleaned = '+94${cleaned.substring(1)}';
    } else if (cleaned.startsWith('94') && !cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }

    final sanitized = cleaned.replaceAll(RegExp(r'[^\d+]'), '');
    if (sanitized.length < 5) return false;

    final uri = Uri.parse('tel:$sanitized');
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('[MapLauncher] Phone dialer error: $e');
      return false;
    }
  }
}
