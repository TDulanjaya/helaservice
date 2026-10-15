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

  static int? resolveVisitFee({
    required List<String> modes,
    int? visitFeeLkr,
    int? baseRateLkr,
  }) {
    if (!modes.contains(modeVisit)) return null;
    if (visitFeeLkr != null && visitFeeLkr >= 0) return visitFeeLkr;
    if ((baseRateLkr ?? 0) > 0) return baseRateLkr;
    return null;
  }

  static int? resolveFixedPricePrefill({
    int? baseRateLkr,
  }) {
    if ((baseRateLkr ?? 0) > 0) return baseRateLkr;
    return null;
  }
}
