import 'nic_validator.dart';

enum NicGender { male, female }

class DecodedNic {
  final bool isValid;
  final DateTime? birthDate;
  final NicGender? gender;
  final int? age;
  final bool isUnder18;
  final String? errorMessage;
  final bool isOldFormat;

  const DecodedNic({
    required this.isValid,
    this.birthDate,
    this.gender,
    this.age,
    this.isUnder18 = false,
    this.errorMessage,
    this.isOldFormat = false,
  });

  String get genderString => gender == NicGender.female ? 'Female' : 'Male';

  String get summary {
    if (!isValid || birthDate == null) return 'Invalid NIC';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final dayStr = birthDate!.day.toString().padLeft(2, '0');
    final monthStr = months[birthDate!.month - 1];
    final yearStr = birthDate!.year.toString();
    final ageStr = age != null ? ' (Age $age)' : '';
    return 'Born $dayStr $monthStr $yearStr · $genderString$ageStr';
  }
}

class NicDecoder {
  NicDecoder._();

  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  // decode sri lankan nic number
  static DecodedNic decode(String? input, {DateTime? referenceDate}) {
    if (input == null || input.trim().isEmpty) {
      return const DecodedNic(isValid: false, errorMessage: 'NIC number is empty');
    }

    final cleaned = NicValidator.cleanNic(input);
    if (!NicValidator.isValidNic(cleaned)) {
      return const DecodedNic(isValid: false, errorMessage: 'Invalid NIC format');
    }

    final bool isOld = cleaned.length == 10;
    int year;
    int dayOfYear;

    if (isOld) {
      // old format: 2 digit year + 3 digit day
      final yearPart = int.tryParse(cleaned.substring(0, 2));
      final dayPart = int.tryParse(cleaned.substring(2, 5));
      if (yearPart == null || dayPart == null) {
        return const DecodedNic(isValid: false, errorMessage: 'Malformed old NIC digits');
      }
      year = 1900 + yearPart;
      dayOfYear = dayPart;
    } else {
      // new format: 4 digit year + 3 digit day
      final yearPart = int.tryParse(cleaned.substring(0, 4));
      final dayPart = int.tryParse(cleaned.substring(4, 7));
      if (yearPart == null || dayPart == null) {
        return const DecodedNic(isValid: false, errorMessage: 'Malformed new NIC digits');
      }
      year = yearPart;
      dayOfYear = dayPart;
    }

    // determine gender
    NicGender gender = NicGender.male;
    if (dayOfYear > 500) {
      gender = NicGender.female;
      dayOfYear -= 500;
    }

    // check valid day of year
    final leap = isLeapYear(year);
    final maxDays = leap ? 366 : 366; // sl registration system treats 366 as upper bound
    if (dayOfYear < 1 || dayOfYear > maxDays) {
      return const DecodedNic(isValid: false, errorMessage: 'Day of year out of range');
    }

    // map day of year to month and day
    final monthDays = [
      31,
      leap ? 29 : 28,
      31, 30, 31, 30, 31, 31, 30, 31, 30, 31
    ];

    int month = 1;
    int day = dayOfYear;
    for (int i = 0; i < monthDays.length; i++) {
      if (day <= monthDays[i]) {
        month = i + 1;
        break;
      }
      day -= monthDays[i];
    }

    // cap day to valid month range
    final standardMonthDays = [
      31,
      leap ? 29 : 28,
      31, 30, 31, 30, 31, 31, 30, 31, 30, 31
    ];
    if (day > standardMonthDays[month - 1]) {
      day = standardMonthDays[month - 1];
    }

    DateTime birthDate;
    try {
      birthDate = DateTime(year, month, day);
    } catch (_) {
      return const DecodedNic(isValid: false, errorMessage: 'Invalid birth date');
    }

    final now = referenceDate ?? DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    final isUnder18 = age < 18;

    return DecodedNic(
      isValid: true,
      birthDate: birthDate,
      gender: gender,
      age: age,
      isUnder18: isUnder18,
      isOldFormat: isOld,
    );
  }
}
