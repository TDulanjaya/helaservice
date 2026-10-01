import 'package:flutter/widgets.dart';

class LocalizedData {
  LocalizedData._();

  static const Map<String, Map<String, String>> categories = {
    'Electrical Services': {
      'en': 'Electrical Services',
      'si': 'විදුලි කාර්මික සේවා',
      'ta': 'மின்சார சேவைகள்',
    },
    'Electrical': {
      'en': 'Electrical',
      'si': 'විදුලි කාර්මික',
      'ta': 'மின்சாரம்',
    },
    'Plumbing & Sanitary': {
      'en': 'Plumbing & Sanitary',
      'si': 'ජලනල හා සනීපාරක්ෂක සේවා',
      'ta': 'பிளம்பிங் மற்றும் சுகாதார சேவைகள்',
    },
    'Plumbing': {
      'en': 'Plumbing',
      'si': 'ජලනල කාර්මික',
      'ta': 'பிளம்பிங்',
    },
    'AC & Refrigeration': {
      'en': 'AC & Refrigeration',
      'si': 'වායුසමීකරණ හා ශීතකරණ සේවා',
      'ta': 'ஏசி மற்றும் குளிரூட்டல் சேவைகள்',
    },
    'AC Repair': {
      'en': 'AC Repair',
      'si': 'වායුසමීකරණ අලුත්වැඩියාව',
      'ta': 'ஏசி பழுதுபார்ப்பு',
    },
    'Carpentry & Woodwork': {
      'en': 'Carpentry & Woodwork',
      'si': 'වඩුවැඩ සහ ලී වැඩ',
      'ta': 'மரவேலை சேவைகள்',
    },
    'Carpentry': {
      'en': 'Carpentry',
      'si': 'වඩුවැඩ',
      'ta': 'மரவேலை',
    },
    'Masonry & Construction': {
      'en': 'Masonry & Construction',
      'si': 'පෙදරේරු හා ඉදිකිරීම්',
      'ta': 'கொத்துவேலை மற்றும் கட்டுமானம்',
    },
    'Masonry': {
      'en': 'Masonry',
      'si': 'පෙදරේරු',
      'ta': 'கொத்துவேலை',
    },
    'Appliance Repair': {
      'en': 'Appliance Repair',
      'si': 'ගෘහ විදුලි උපකරණ අලුත්වැඩියාව',
      'ta': 'வீட்டு உபகரண பழுதுபார்ப்பு',
    },
    'House Painting': {
      'en': 'House Painting',
      'si': 'නිවාස තීන්ත ආලේපනය',
      'ta': 'வீட்டு பெயிண்டிங்',
    },
    'Roofing & Waterproofing': {
      'en': 'Roofing & Waterproofing',
      'si': 'වහල සෙවිලි සහ ජලරෝධක සේවා',
      'ta': 'கூரை மற்றும் நீர்ப்புகாப்பு சேவைகள்',
    },
  };

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

  static String getCategory(BuildContext context, String key) {
    final lang = Localizations.localeOf(context).languageCode;
    return categories[key]?[lang] ?? categories[key]?['en'] ?? key;
  }

  static String getDistrict(BuildContext context, String key) {
    final lang = Localizations.localeOf(context).languageCode;
    return districts[key]?[lang] ?? districts[key]?['en'] ?? key;
  }

  static String getStatus(BuildContext context, String status) {
    final lang = Localizations.localeOf(context).languageCode;
    switch (status.toLowerCase()) {
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
            : (lang == 'ta' ? 'நிராகரிக்கப்பட்டது' : 'Declined');
      default:
        return status;
    }
  }
}
