import 'package:flutter/widgets.dart';

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
      'ta': 'கிளிநොச்சி'
    },
    'Mannar': {'en': 'Mannar', 'si': 'මන්නාරම', 'ta': 'மன்னார்'},
    'Vavuniya': {'en': 'Vavuniya', 'si': 'වවුනියාව', 'ta': 'வவுனியா'},
    'Mullaitivu': {'en': 'Mullaitivu', 'si': 'මුලතිව්', 'ta': 'මුல்லைத்தீவு'},
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
    final lang = Localizations.localeOf(context).languageCode;
    switch (status.toLowerCase()) {
      case 'open':
        return lang == 'si'
            ? 'මිල කැඳවීම් සඳහා විවෘතයි'
            : (lang == 'ta' ? 'விலைப்புள்ளிகளுக்கு திறந்துள்ளது' : 'Open for Quotes');
      case 'assigned':
        return lang == 'si'
            ? 'ශිල්පියෙකු පත් කර ඇත'
            : (lang == 'ta' ? 'වல்லுநர் நியமிக்கப்பட்டுள்ளார்' : 'Artisan Assigned');
      case 'dispatched':
        return lang == 'si'
            ? 'පිටත්ව ඇත'
            : (lang == 'ta' ? 'புறப்பட்டுவிட்டது' : 'Dispatched');
      case 'en_route':
      case 'en route':
        return lang == 'si'
            ? 'පැමිණෙමින් සිටී'
            : (lang == 'ta' ? 'வருகை தருகிறார்' : 'En Route');
      case 'pending':
        return lang == 'si'
            ? 'තහවුරු කිරීමට ඇත'
            : (lang == 'ta' ? 'நிலுவையில் உள்ளது' : 'Pending');
      case 'in_progress':
      case 'in progress':
      case 'ongoing':
        return lang == 'si'
            ? 'ක්‍රියාත්මකයි'
            : (lang == 'ta' ? 'செயலில் உள்ளது' : 'In Progress');
      case 'completed':
        return lang == 'si'
            ? 'සම්පූර්ණයි'
            : (lang == 'ta' ? 'முடிந்தது' : 'Completed');
      case 'cancelled':
      case 'canceled':
        return lang == 'si'
            ? 'අවලංගුයි'
            : (lang == 'ta' ? 'ரத்து செய்யப்பட்டது' : 'Cancelled');
      case 'accepted':
        return lang == 'si'
            ? 'පිළිගන්නා ලදී'
            : (lang == 'ta' ? 'ஏற்றுக்கொள்ளப்பட்டது' : 'Accepted');
      case 'rejected':
      case 'declined':
        return lang == 'si'
            ? 'ප්‍රතික්ෂේපිතයි'
            : (lang == 'ta' ? 'நිරாகரிக்கப்பட்டது' : 'Declined');
      default:
        return status;
    }
  }
}
