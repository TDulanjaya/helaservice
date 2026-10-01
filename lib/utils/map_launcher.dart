import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class MapLauncher {
  MapLauncher._();

  /// Opens navigation in Google Maps or Apple Maps.
  static Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? destinationTitle,
  }) async {
    final title = Uri.encodeComponent(destinationTitle ?? 'Customer Location');

    if (kIsWeb) {
      final webUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
      );
      return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }

    if (Platform.isAndroid) {
      final googleMapsIntent = Uri.parse('google.navigation:q=$latitude,$longitude&mode=d');
      if (await canLaunchUrl(googleMapsIntent)) {
        return await launchUrl(googleMapsIntent, mode: LaunchMode.externalApplication);
      }

      final geoUri = Uri.parse('geo:$latitude,$longitude?q=$latitude,$longitude($title)');
      if (await canLaunchUrl(geoUri)) {
        return await launchUrl(geoUri, mode: LaunchMode.externalApplication);
      }
    } else if (Platform.isIOS) {
      final appleMapsUri = Uri.parse('maps:?daddr=$latitude,$longitude&q=$title');
      if (await canLaunchUrl(appleMapsUri)) {
        return await launchUrl(appleMapsUri, mode: LaunchMode.externalApplication);
      }
    }

    final fallbackUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );
    return await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
  }

  /// Opens the phone dialer with the given number.
  static Future<bool> openPhoneCall(String phoneNumber) async {
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
