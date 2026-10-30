import '../models/technician.dart';

// provider pricing helper for rates and modes
class ProviderPricingHelper {
  ProviderPricingHelper._();

  static const String modeHour = 'hour';
  static const String modeDay = 'day';
  static const String modeJob = 'job';
  static const String modeVisit = 'visit';
  static const String modeTravel = 'travel';

  static const List<String> allModes = [
    modeHour,
    modeDay,
    modeJob,
    modeVisit,
    modeTravel,
  ];

  static const List<String> baseModes = [
    modeHour,
    modeDay,
    modeJob,
  ];

  static const int minHourlyRate = 1;
  static const int maxHourlyRate = 20000;
  static const int minDailyRate = 1;
  static const int maxDailyRate = 100000;
  static const int minPerKmRate = 1;
  static const int maxPerKmRate = 1000;
  static const int minVisitFee = 0;
  static const int maxVisitFee = 20000;

  static bool hasBasePricingMode(Iterable<String>? modes) {
    if (modes == null || modes.isEmpty) return false;
    return modes.any((m) => baseModes.contains(m));
  }

  // infer pricing modes from legacy rate fields if unset
  static List<String> resolvePricingModes({
    List<String>? pricingModes,
    int? hourlyRateLkr,
    int? dailyRateLkr,
    int? baseRateLkr,
    int? visitFeeLkr,
    int? perKmRateLkr,
  }) {
    if (pricingModes != null && pricingModes.isNotEmpty) {
      return List<String>.from(pricingModes);
    }

    final List<String> inferred = [];
    if ((hourlyRateLkr ?? 0) > 0) {
      inferred.add(modeHour);
    }
    if ((dailyRateLkr ?? 0) > 0) {
      inferred.add(modeDay);
    }
    if (inferred.isEmpty && (baseRateLkr ?? 0) > 0) {
      inferred.add(modeJob);
    }
    if (inferred.isEmpty) {
      inferred.add(modeJob);
    }

    if ((visitFeeLkr ?? 0) > 0) {
      inferred.add(modeVisit);
    }
    if ((perKmRateLkr ?? 0) > 0) {
      inferred.add(modeTravel);
    }

    return inferred;
  }

  // resolve inspection visit fee matching firestore rules exactly
  static int resolveVisitFee(dynamic source) {
    if (source == null) return 0;
    if (source is Technician) {
      final fee = source.visitFeeLkr;
      if (fee != null && fee > 0) return fee;
      return 0;
    }
    if (source is Map) {
      final fee = source['visitFeeLkr'];
      if (fee != null && fee is num && fee > 0) return fee.toInt();
      return 0;
    }
    return 0;
  }

  static int? resolveFixedPricePrefill({
    int? baseRateLkr,
  }) {
    if ((baseRateLkr ?? 0) > 0) return baseRateLkr;
    return null;
  }
}
