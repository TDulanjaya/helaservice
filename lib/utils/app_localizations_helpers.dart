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
    'Electrician': {
      'en': 'Electrician',
      'si': 'විදුලි කාර්මික',
      'ta': 'மின்சார பணியாளர்',
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
    'Plumber': {
      'en': 'Plumber',
      'si': 'ජලනල කාර්මික',
      'ta': 'பிளம்பர்',
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
    'AC Technician': {
      'en': 'AC Technician',
      'si': 'වායුසමීකරණ කාර්මික',
      'ta': 'ஏசி தொழில்நுட்ப வல்லுநர்',
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
    'Carpenter': {
      'en': 'Carpenter',
      'si': 'වඩු කාර්මික',
      'ta': 'தச்சர்',
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
    'Mason': {
      'en': 'Mason',
      'si': 'පෙදරේරු',
      'ta': 'கொத்தனார்',
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
    'Painting': {
      'en': 'Painting',
      'si': 'තීන්ත ආලේපනය',
      'ta': 'பெயிண்டிங்',
    },
    'Painter': {
      'en': 'Painter',
      'si': 'තීන්ත ආලේපක',
      'ta': 'பெயிண்டர்',
    },
    'Roofing & Waterproofing': {
      'en': 'Roofing & Waterproofing',
      'si': 'වහල සෙවිලි සහ ජලරෝධක සේවා',
      'ta': 'கூரை மற்றும் நீர்ப்புகாப்பு சேவைகள்',
    },
    'Roofing': {
      'en': 'Roofing',
      'si': 'වහල සෙවිලි',
      'ta': 'கூரை வேலை',
    },
    'Roofer': {
      'en': 'Roofer',
      'si': 'වහල කාර්මික',
      'ta': 'கூரை தொழில்நுட்ப வல்லுநர்',
    },
    'Welding': {
      'en': 'Welding',
      'si': 'පෑස්සුම් වැඩ',
      'ta': 'வெல்டிங்',
    },
    'Welder': {
      'en': 'Welder',
      'si': 'පෑස්සුම්කරු',
      'ta': 'வெல்டர்',
    },
    'Tile & Flooring': {
      'en': 'Tile & Flooring',
      'si': 'ටයිල් සහ බිම් ඇතුරුම්',
      'ta': 'டைல்ஸ் மற்றும் தரை வேலைகள்',
    },
    'Tiler': {
      'en': 'Tiler',
      'si': 'ටයිල් කාර්මික',
      'ta': 'டைல்ஸ் பதிப்பாளர்',
    },
    'Aluminium Work': {
      'en': 'Aluminium Work',
      'si': 'ඇලුමිනියම් වැඩ',
      'ta': 'அலுமினியம் வேலை',
    },
    'CCTV & Security': {
      'en': 'CCTV & Security',
      'si': 'සීසීටීවී සහ ආරක්ෂක පද්ධති',
      'ta': 'சிசிடிவி மற்றும் பாதுகாப்பு',
    },
    'Solar Systems': {
      'en': 'Solar Systems',
      'si': 'සූර්ය බලශක්ති පද්ධති',
      'ta': 'சூரிய சக்தி அமைப்புகள்',
    },
    'Gardening & Landscaping': {
      'en': 'Gardening & Landscaping',
      'si': 'වතු නඩත්තු සහ අලංකරණය',
      'ta': 'தோட்ட பராமரிப்பு',
    },
    'Gardener': {
      'en': 'Gardener',
      'si': 'වතු කම්කරු',
      'ta': 'தோட்டக்காரர்',
    },
    'Cleaning Services': {
      'en': 'Cleaning Services',
      'si': 'පිරිසිදු කිරීමේ සේවා',
      'ta': 'துப்புரவு சேவைகள்',
    },
    'Cleaner': {
      'en': 'Cleaner',
      'si': 'පිරිසිදු කරන්නා',
      'ta': 'துப்புரவாளர்',
    },
    'Mechanic': {
      'en': 'Mechanic',
      'si': 'කාර්මිකයා',
      'ta': 'மெக்கானிக்',
    },
    'Technician': {
      'en': 'Technician',
      'si': 'කාර්මික ශිල්පී',
      'ta': 'தொழில்நுட்ப வல்லுநர்',
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

  // get translated category
  static String getCategory(BuildContext context, String key) {
    if (key.trim().isEmpty) return key;
    final lang = Localizations.localeOf(context).languageCode;
    final trimmed = key.trim();
    final entry = categories[trimmed];
    if (entry != null && entry[lang] != null && entry[lang]!.isNotEmpty) {
      return entry[lang]!;
    }
    for (final e in categories.entries) {
      if (e.key.toLowerCase() == trimmed.toLowerCase()) {
        final val = e.value[lang];
        if (val != null && val.isNotEmpty) return val;
      }
    }

    // smart root-keyword fallback
    final lower = trimmed.toLowerCase();
    if (lower.contains('electr')) {
      return lang == 'si' ? 'විදුලි කාර්මික' : (lang == 'ta' ? 'மின்சார சேவைகள்' : 'Electrical');
    }
    if (lower.contains('plumb')) {
      return lang == 'si' ? 'ජලනල කාර්මික' : (lang == 'ta' ? 'பிளம்பிங்' : 'Plumbing');
    }
    if (lower.contains('carpent') || lower.contains('wood')) {
      return lang == 'si' ? 'වඩුවැඩ' : (lang == 'ta' ? 'மரவேலை' : 'Carpentry');
    }
    if (lower.contains('mason') || lower.contains('construct')) {
      return lang == 'si' ? 'පෙදරේරු' : (lang == 'ta' ? 'கொத்துவேலை' : 'Masonry');
    }
    if (lower.contains('paint')) {
      return lang == 'si' ? 'තීන්ත ආලේපනය' : (lang == 'ta' ? 'பெயிண்டிங்' : 'Painting');
    }
    if (lower.contains('roof')) {
      return lang == 'si' ? 'වහල සෙවිලි' : (lang == 'ta' ? 'கூரை வேலை' : 'Roofing');
    }
    if (lower.contains('appliance')) {
      return lang == 'si' ? 'ගෘහ උපකරණ' : (lang == 'ta' ? 'வீட்டு உபகரணங்கள்' : 'Appliance Repair');
    }
    if (lower.contains('ac') || lower.contains('air cond') || lower.contains('refrig')) {
      return lang == 'si' ? 'වායුසමීකරණ' : (lang == 'ta' ? 'ஏசி பழுதுபார்ப்பு' : 'AC & Refrigeration');
    }
    if (lower.contains('weld')) {
      return lang == 'si' ? 'පෑස්සුම් වැඩ' : (lang == 'ta' ? 'வெல்டிங்' : 'Welding');
    }
    if (lower.contains('tile') || lower.contains('floor')) {
      return lang == 'si' ? 'ටයිල් වැඩ' : (lang == 'ta' ? 'டைல்ஸ் வேலை' : 'Tiling');
    }
    if (lower.contains('cctv') || lower.contains('security')) {
      return lang == 'si' ? 'සීසීටීවී' : (lang == 'ta' ? 'சிசிடிவி' : 'CCTV');
    }
    if (lower.contains('solar')) {
      return lang == 'si' ? 'සූර්ය බලශක්ති' : (lang == 'ta' ? 'சூரிய சக்தி' : 'Solar');
    }
    if (lower.contains('clean')) {
      return lang == 'si' ? 'පිරිසිදු කිරීම්' : (lang == 'ta' ? 'துப்புரவு' : 'Cleaning');
    }
    if (lower.contains('garden')) {
      return lang == 'si' ? 'වතු නඩත්තු' : (lang == 'ta' ? 'தோட்ட பராமரிப்பு' : 'Gardening');
    }
    if (lower.contains('mechanic') || lower.contains('auto') || lower.contains('vehicle')) {
      return lang == 'si' ? 'මෝටර් රථ කාර්මික' : (lang == 'ta' ? 'வாகன பழுதுபார்ப்பு' : 'Mechanic');
    }

    return key;
  }

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
            : (lang == 'ta' ? 'வல்லுநர் நியமிக்கப்பட்டுள்ளார்' : 'Artisan Assigned');
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
            : (lang == 'ta' ? 'நிராகரிக்கப்பட்டது' : 'Declined');
      default:
        return status;
    }
  }
}
