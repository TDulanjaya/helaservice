class AppConfig {
  AppConfig._();

  static const String stadiaMapsKey =
      String.fromEnvironment('STADIA_MAPS_KEY', defaultValue: '');

  static bool get hasStadiaMapsKey => stadiaMapsKey.isNotEmpty;
}

