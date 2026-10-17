import 'package:flutter/widgets.dart';
import 'l10n_extension.dart';

class LocalizedData {
  LocalizedData._();

  static const Map<String, Map<String, String>> districts = {
    'Colombo': {'en': 'Colombo', 'si': 'කොළඹ', 'ta': 'கொழும்பு'},
    'Gampaha': {'en': 'Gampaha', 'si': 'ගම්පහ', 'ta': 'கம்பஹா'},
    'Kalutara': {'en': 'Kalutara', 'si': 'කළුතර', 'ta': 'களுத்துறை'},
    'Kandy': {'en': 'Kandy', 'si': 'මහනුවර', 'ta': 'கண்டி'},
    'Matale': {'en': 'Matale', 'si': 'මාතලේ', 'ta': 'மாத்தளை'},
    'Nuwara Eliya': {'en': 'Nuwara Eliya', 'si': 'නුවරඑළිය', 'ta': 'நுவரெலியா'},
    'Galle': {'en': 'Galle', 'si': 'ගාල්ල', 'ta': 'காலி'},
    'Matara': {'en': 'Matara', 'si': 'මාතර', 'ta': 'மாத்தறை'},
    'Hambantota': {
      'en': 'Hambantota',
      'si': 'හම්බන්තොට',
      'ta': 'அம்பாந்தோட்டை'
    },
    'Jaffna': {'en': 'Jaffna', 'si': 'යාපනය', 'ta': 'யாழ்ப்பாணம்'},
    'Kilinochchi': {
      'en': 'Kilinochchi',
      'si': 'කිලිනොච්චිය',
      'ta': 'கிளிநொச்சி'
    },
    'Mannar': {'en': 'Mannar', 'si': 'මන්නාරම', 'ta': 'மன்னார்'},
    'Vavuniya': {'en': 'Vavuniya', 'si': 'වවුනියාව', 'ta': 'வவுனியா'},
    'Mullaitivu': {'en': 'Mullaitivu', 'si': 'මුලතිව්', 'ta': 'முல்லைத்தீவு'},
    'Batticaloa': {'en': 'Batticaloa', 'si': 'මඩකලපුව', 'ta': 'மட்டக்களப்பு'},
    'Ampara': {'en': 'Ampara', 'si': 'අම්පාර', 'ta': 'அம்பாறை'},
    'Trincomalee': {
      'en': 'Trincomalee',
      'si': 'ත්‍රිකුණාමලය',
      'ta': 'திருகோணமலை'
    },
    'Kurunegala': {'en': 'Kurunegala', 'si': 'කුරුණෑගල', 'ta': 'குருநாகல்'},
    'Puttalam': {'en': 'Puttalam', 'si': 'පුත්තලම', 'ta': 'புத்தளம்'},
    'Anuradhapura': {
      'en': 'Anuradhapura',
      'si': 'අනුරාධපුරය',
      'ta': 'அனுராதபுரம்'
    },
    'Polonnaruwa': {
      'en': 'Polonnaruwa',
      'si': 'පොළොන්නරුව',
      'ta': 'பொலன்னறுவை'
    },
    'Badulla': {'en': 'Badulla', 'si': 'බදුල්ල', 'ta': 'பதுளை'},
    'Monaragala': {'en': 'Monaragala', 'si': 'මොණරාගල', 'ta': 'மொணராகலை'},
    'Ratnapura': {'en': 'Ratnapura', 'si': 'රත්නපුර', 'ta': 'இரத்தினபுரி'},
    'Kegalle': {'en': 'Kegalle', 'si': 'කෑගල්ල', 'ta': 'கேகாலை'},
  };

  // get translated district
  static String getDistrict(BuildContext context, String key) {
    if (key.trim().isEmpty) return key;
    final lang = Localizations.localeOf(context).languageCode;
    final trimmed = key.trim();
    final entry = districts[trimmed];
    if (entry != null && entry[lang] != null && entry[lang]!.isNotEmpty) {
      return entry[lang]!;
    }
    for (final e in districts.entries) {
      if (e.key.toLowerCase() == trimmed.toLowerCase()) {
        final val = e.value[lang];
        if (val != null && val.isNotEmpty) return val;
      }
    }
    return key;
  }

  static String getStatus(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return context.l10n.statusOpen;
      case 'assigned':
        return context.l10n.statusAssigned;
      case 'dispatched':
        return context.l10n.statusDispatched;
      case 'en_route':
      case 'en route':
        return context.l10n.statusEnRoute;
      case 'pending':
        return context.l10n.statusPending;
      case 'in_progress':
      case 'in progress':
      case 'ongoing':
        return context.l10n.statusInProgress;
      case 'completed':
        return context.l10n.statusCompleted;
      case 'cancelled':
      case 'canceled':
        return context.l10n.statusCancelled;
      case 'accepted':
        return context.l10n.statusAccepted;
      case 'rejected':
      case 'declined':
        return context.l10n.statusDeclined;
      case 'not_selected':
        return context.l10n.bidStatusNotSelected;
      case 'withdrawn':
        return context.l10n.bidStatusWithdrawn;
      case 'job_closed':
        return context.l10n.bidStatusJobClosed;
      default:
        return status;
    }
  }
}
