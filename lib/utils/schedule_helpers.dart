import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleWindowResult {
  final String scheduleMode;
  final String? scheduledSlot;
  final DateTime? scheduledDate;
  final DateTime? scheduledStartAt;
  final DateTime? scheduledEndAt;
  final DateTime? expiresAt;
  final int? flexibleWindowDays;
  final String? errorMessage;
  final bool isValid;

  const ScheduleWindowResult({
    required this.scheduleMode,
    this.scheduledSlot,
    this.scheduledDate,
    this.scheduledStartAt,
    this.scheduledEndAt,
    this.expiresAt,
    this.flexibleWindowDays,
    this.errorMessage,
    required this.isValid,
  });

  factory ScheduleWindowResult.valid({
    required String scheduleMode,
    String? scheduledSlot,
    DateTime? scheduledDate,
    DateTime? scheduledStartAt,
    DateTime? scheduledEndAt,
    DateTime? expiresAt,
    int? flexibleWindowDays,
  }) {
    return ScheduleWindowResult(
      scheduleMode: scheduleMode,
      scheduledSlot: scheduledSlot,
      scheduledDate: scheduledDate,
      scheduledStartAt: scheduledStartAt,
      scheduledEndAt: scheduledEndAt,
      expiresAt: expiresAt,
      flexibleWindowDays: flexibleWindowDays,
      isValid: true,
    );
  }

  factory ScheduleWindowResult.error(String message,
      {String scheduleMode = 'today'}) {
    return ScheduleWindowResult(
      scheduleMode: scheduleMode,
      errorMessage: message,
      isValid: false,
    );
  }
}

class ScheduleHelpers {
  ScheduleHelpers._();

  // canonical modes
  static const String modeToday = 'today';
  static const String modeDate = 'date';
  static const String modeFlexible = 'flexible';

  // legacy mode aliases
  static const String modeAsap = 'asap';
  static const String modeDateOnly = 'date_only';
  static const String modeTimeRange = 'time_range';

  // slot constants
  static const String slotAnytime = 'anytime';
  static const String slotMorning = 'morning';
  static const String slotAfternoon = 'afternoon';
  static const String slotEvening = 'evening';
  static const String slotExact = 'exact';

  // normalize mode
  static String normalizeMode(String? mode) {
    if (mode == null || mode.isEmpty) {
      return modeToday;
    }
    final m = mode.trim().toLowerCase();
    if (m == modeAsap || m == modeToday) {
      return modeToday;
    }
    if (m == modeDateOnly || m == modeTimeRange || m == modeDate) {
      return modeDate;
    }
    if (m == modeFlexible) {
      return modeFlexible;
    }
    return modeToday;
  }

  // checks if date is today in local time
  static bool isToday(DateTime date, [DateTime? nowOverride]) {
    final now = nowOverride ?? DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // cutoff time for same day bookings
  static bool canChooseToday([DateTime? nowOverride]) {
    final now = nowOverride ?? DateTime.now();
    return now.hour < 20;
  }

  // legacy alias
  static bool canChooseTodayForDateOnly([DateTime? nowOverride]) =>
      canChooseToday(nowOverride);

  // checks if slot has ended for today
  static bool isSlotAvailableToday(String slot, [DateTime? nowOverride]) {
    final now = nowOverride ?? DateTime.now();
    if (now.hour >= 20) {
      return false;
    }
    switch (slot) {
      case slotMorning:
        return now.hour < 12;
      case slotAfternoon:
        return now.hour < 16;
      case slotEvening:
      case slotAnytime:
        return now.hour < 20;
      case slotExact:
        return now.hour < 19;
      default:
        return true;
    }
  }

  // round up to next 15 minutes
  static DateTime roundUpToNext15Minutes(DateTime dt) {
    if (dt.minute % 15 == 0 && dt.second == 0 && dt.millisecond == 0) {
      return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
    }
    final nextMinutes = ((dt.minute / 15).floor() + 1) * 15;
    return DateTime(dt.year, dt.month, dt.day, dt.hour, 0)
        .add(Duration(minutes: nextMinutes));
  }

  // end of calendar day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  // legacy fallback expires at
  static DateTime computeLegacyExpiresAt(
      {DateTime? scheduledDate, DateTime? createdAt}) {
    if (scheduledDate != null) {
      return endOfDay(scheduledDate);
    }
    if (createdAt != null) {
      return createdAt.add(const Duration(days: 7));
    }
    return DateTime.now().add(const Duration(days: 7));
  }

  // legacy helper for booking repository slot start computation
  static DateTime computeLegacyScheduledStartAt(DateTime date, String? slot) {
    int hour = 8;
    final s = (slot ?? '').toLowerCase();
    if (s.contains('morning') || s.contains('උදෑසන') || s.contains('காலை')) {
      hour = 8;
    } else if (s.contains('afternoon') ||
        s.contains('දහවල්') ||
        s.contains('மதியம்')) {
      hour = 12;
    } else if (s.contains('evening') ||
        s.contains('සවස') ||
        s.contains('மாலை')) {
      hour = 16;
    } else {
      final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(s);
      if (match != null) {
        int parsedHour = int.tryParse(match.group(1)!) ?? 8;
        if (s.contains('pm') && parsedHour < 12) {
          parsedHour += 12;
        }
        hour = parsedHour;
      } else if (date.hour != 0) {
        return date;
      }
    }
    return DateTime(date.year, date.month, date.day, hour, 0);
  }

  // check if job is for today
  static bool isTodayJob({
    required String? scheduleMode,
    DateTime? scheduledDate,
    DateTime? scheduledStartAt,
  }) {
    final norm = normalizeMode(scheduleMode);
    if (norm == modeToday) {
      return true;
    }
    if (scheduledDate != null && isToday(scheduledDate)) {
      return true;
    }
    if (scheduledStartAt != null && isToday(scheduledStartAt)) {
      return true;
    }
    return false;
  }

  // date and flexible jobs use base location
  static bool usesBaseLocation({
    required String? scheduleMode,
    DateTime? scheduledDate,
    DateTime? scheduledStartAt,
  }) {
    return !isTodayJob(
      scheduleMode: scheduleMode,
      scheduledDate: scheduledDate,
      scheduledStartAt: scheduledStartAt,
    );
  }

  // check if two time windows overlap
  static bool windowsOverlap({
    required DateTime start1,
    required DateTime end1,
    required DateTime start2,
    required DateTime end2,
  }) {
    return start1.isBefore(end2) && start2.isBefore(end1);
  }

  // resolve booking window for clash detection
  static ({DateTime startAt, DateTime endAt}) getBookingWindow(
      dynamic booking) {
    if (booking.scheduledStartAt != null && booking.scheduledEndAt != null) {
      return (
        startAt: booking.scheduledStartAt as DateTime,
        endAt: booking.scheduledEndAt as DateTime
      );
    }
    final date = (booking.scheduledDate as DateTime?) ??
        (booking.createdAt as DateTime?) ??
        DateTime.now();
    final localDate = DateTime(date.year, date.month, date.day);
    final slot = (booking.scheduledSlot as String?) ?? slotAnytime;
    switch (slot) {
      case slotMorning:
        return (
          startAt:
              DateTime(localDate.year, localDate.month, localDate.day, 8, 0),
          endAt:
              DateTime(localDate.year, localDate.month, localDate.day, 12, 0),
        );
      case slotAfternoon:
        return (
          startAt:
              DateTime(localDate.year, localDate.month, localDate.day, 12, 0),
          endAt:
              DateTime(localDate.year, localDate.month, localDate.day, 16, 0),
        );
      case slotEvening:
        return (
          startAt:
              DateTime(localDate.year, localDate.month, localDate.day, 16, 0),
          endAt:
              DateTime(localDate.year, localDate.month, localDate.day, 20, 0),
        );
      case slotAnytime:
      default:
        return (
          startAt:
              DateTime(localDate.year, localDate.month, localDate.day, 8, 0),
          endAt:
              DateTime(localDate.year, localDate.month, localDate.day, 20, 0),
        );
    }
  }

  // compute schedule window and expiry
  static ScheduleWindowResult computeScheduleWindow({
    required String mode,
    String slot = slotAnytime,
    DateTime? date,
    TimeOfDay? fromTime,
    TimeOfDay? toTime,
    int flexibleDays = 7,
    DateTime? nowOverride,
  }) {
    final now = nowOverride ?? DateTime.now();
    final norm = normalizeMode(mode);

    if (norm == modeToday) {
      if (!canChooseToday(now)) {
        return ScheduleWindowResult.error(
          'After 20:00, please pick a specific day.',
          scheduleMode: modeToday,
        );
      }

      final todayDate = DateTime(now.year, now.month, now.day);
      final expiresAt = endOfDay(todayDate);

      DateTime startAt;
      DateTime endAt;

      switch (slot) {
        case slotMorning:
          if (!isSlotAvailableToday(slotMorning, now)) {
            return ScheduleWindowResult.error(
              'Morning slot has already ended today.',
              scheduleMode: modeToday,
            );
          }
          startAt = now.hour < 8
              ? DateTime(todayDate.year, todayDate.month, todayDate.day, 8, 0)
              : roundUpToNext15Minutes(now);
          endAt =
              DateTime(todayDate.year, todayDate.month, todayDate.day, 12, 0);
          break;

        case slotAfternoon:
          if (!isSlotAvailableToday(slotAfternoon, now)) {
            return ScheduleWindowResult.error(
              'Afternoon slot has already ended today.',
              scheduleMode: modeToday,
            );
          }
          startAt = now.hour < 12
              ? DateTime(todayDate.year, todayDate.month, todayDate.day, 12, 0)
              : roundUpToNext15Minutes(now);
          endAt =
              DateTime(todayDate.year, todayDate.month, todayDate.day, 16, 0);
          break;

        case slotEvening:
          if (!isSlotAvailableToday(slotEvening, now)) {
            return ScheduleWindowResult.error(
              'Evening slot has already ended today.',
              scheduleMode: modeToday,
            );
          }
          startAt = now.hour < 16
              ? DateTime(todayDate.year, todayDate.month, todayDate.day, 16, 0)
              : roundUpToNext15Minutes(now);
          endAt =
              DateTime(todayDate.year, todayDate.month, todayDate.day, 20, 0);
          break;

        case slotAnytime:
        default:
          startAt = now.hour < 8
              ? DateTime(todayDate.year, todayDate.month, todayDate.day, 8, 0)
              : roundUpToNext15Minutes(now);
          endAt =
              DateTime(todayDate.year, todayDate.month, todayDate.day, 20, 0);
          if (endAt.difference(startAt).inMinutes < 60) {
            return ScheduleWindowResult.error(
              'Less than 1 hour remains before 20:00 today. Please pick a specific day.',
              scheduleMode: modeToday,
            );
          }
          break;
      }

      return ScheduleWindowResult.valid(
        scheduleMode: modeToday,
        scheduledSlot: slot,
        scheduledDate: todayDate,
        scheduledStartAt: startAt,
        scheduledEndAt: endAt,
        expiresAt: expiresAt,
      );
    }

    if (norm == modeDate) {
      if (date == null) {
        return ScheduleWindowResult.error('Date is required.',
            scheduleMode: modeDate);
      }

      final localDate = DateTime(date.year, date.month, date.day);
      final todayZero = DateTime(now.year, now.month, now.day);

      if (localDate.isBefore(todayZero)) {
        return ScheduleWindowResult.error('Date cannot be in the past.',
            scheduleMode: modeDate);
      }

      if (localDate.isAfter(todayZero.add(const Duration(days: 60)))) {
        return ScheduleWindowResult.error(
            'Date cannot be more than 60 days ahead.',
            scheduleMode: modeDate);
      }

      final expiresAt = endOfDay(localDate);

      if (slot == slotExact) {
        if (fromTime == null || toTime == null) {
          return ScheduleWindowResult.error('Start and end times are required.',
              scheduleMode: modeDate);
        }

        final startAt = DateTime(localDate.year, localDate.month, localDate.day,
            fromTime.hour, fromTime.minute);
        final endAt = DateTime(localDate.year, localDate.month, localDate.day,
            toTime.hour, toTime.minute);

        if (!endAt.isAfter(startAt)) {
          return ScheduleWindowResult.error(
              'End time must be after start time.',
              scheduleMode: modeDate);
        }

        final diffMinutes = endAt.difference(startAt).inMinutes;
        if (diffMinutes < 60) {
          return ScheduleWindowResult.error(
              'Time range must be at least 1 hour.',
              scheduleMode: modeDate);
        }
        if (diffMinutes > 720) {
          return ScheduleWindowResult.error(
              'Time range cannot exceed 12 hours.',
              scheduleMode: modeDate);
        }

        if (startAt.isBefore(now.subtract(const Duration(minutes: 15)))) {
          return ScheduleWindowResult.error('Start time cannot be in the past.',
              scheduleMode: modeDate);
        }

        return ScheduleWindowResult.valid(
          scheduleMode: modeDate,
          scheduledSlot: slotExact,
          scheduledDate: localDate,
          scheduledStartAt: startAt,
          scheduledEndAt: endAt,
          expiresAt: expiresAt,
        );
      }

      DateTime startAt;
      DateTime endAt;

      switch (slot) {
        case slotMorning:
          startAt =
              DateTime(localDate.year, localDate.month, localDate.day, 8, 0);
          endAt =
              DateTime(localDate.year, localDate.month, localDate.day, 12, 0);
          break;
        case slotAfternoon:
          startAt =
              DateTime(localDate.year, localDate.month, localDate.day, 12, 0);
          endAt =
              DateTime(localDate.year, localDate.month, localDate.day, 16, 0);
          break;
        case slotEvening:
          startAt =
              DateTime(localDate.year, localDate.month, localDate.day, 16, 0);
          endAt =
              DateTime(localDate.year, localDate.month, localDate.day, 20, 0);
          break;
        case slotAnytime:
        default:
          startAt =
              DateTime(localDate.year, localDate.month, localDate.day, 8, 0);
          endAt =
              DateTime(localDate.year, localDate.month, localDate.day, 20, 0);
          break;
      }

      return ScheduleWindowResult.valid(
        scheduleMode: modeDate,
        scheduledSlot: slot,
        scheduledDate: localDate,
        scheduledStartAt: startAt,
        scheduledEndAt: endAt,
        expiresAt: expiresAt,
      );
    }

    if (norm == modeFlexible) {
      final days = (flexibleDays == 3 || flexibleDays == 14) ? flexibleDays : 7;
      final startAt = now;
      final endAt = endOfDay(
          DateTime(now.year, now.month, now.day).add(Duration(days: days)));

      return ScheduleWindowResult.valid(
        scheduleMode: modeFlexible,
        scheduledSlot: slotAnytime,
        scheduledDate: DateTime(now.year, now.month, now.day),
        scheduledStartAt: startAt,
        scheduledEndAt: endAt,
        expiresAt: endAt,
        flexibleWindowDays: days,
      );
    }

    return ScheduleWindowResult.error('Unsupported schedule mode: $mode');
  }

  // format badge label
  static String scheduleLabel({
    required String? scheduleMode,
    String? scheduledSlot,
    DateTime? scheduledDate,
    DateTime? scheduledStartAt,
    DateTime? scheduledEndAt,
    int? flexibleWindowDays,
    BuildContext? context,
    String? localeCode,
  }) {
    final lang = localeCode ??
        (context != null ? Localizations.localeOf(context).languageCode : 'en');
    final norm = normalizeMode(scheduleMode);

    String slotText(String? slot) {
      final s = (slot ?? slotAnytime).toLowerCase();
      if (s == slotMorning) {
        if (lang == 'si') {
          return 'උදෑසන';
        }
        if (lang == 'ta') {
          return 'காலை';
        }
        return 'Morning';
      }
      if (s == slotAfternoon) {
        if (lang == 'si') {
          return 'දහවල්';
        }
        if (lang == 'ta') {
          return 'மதியம்';
        }
        return 'Afternoon';
      }
      if (s == slotEvening) {
        if (lang == 'si') {
          return 'සවස';
        }
        if (lang == 'ta') {
          return 'மாலை';
        }
        return 'Evening';
      }
      if (s == slotExact &&
          scheduledStartAt != null &&
          scheduledEndAt != null) {
        final startFmt = DateFormat.jm(lang).format(scheduledStartAt);
        final endFmt = DateFormat.jm(lang).format(scheduledEndAt);
        return '$startFmt - $endFmt';
      }
      if (lang == 'si') {
        return 'ඕනෑම වේලාවක';
      }
      if (lang == 'ta') {
        return 'எந்த நேரமும்';
      }
      return 'Anytime';
    }

    if (norm == modeToday) {
      final slotLabel = slotText(scheduledSlot);
      if (lang == 'si') {
        return 'අද · $slotLabel';
      }
      if (lang == 'ta') {
        return 'இன்று · $slotLabel';
      }
      return 'Today · $slotLabel';
    }

    if (norm == modeDate) {
      final date = scheduledDate ?? scheduledStartAt ?? DateTime.now();
      final dateStr = DateFormat('E d MMM', lang).format(date);
      final slotLabel = slotText(scheduledSlot);
      return '$dateStr · $slotLabel';
    }

    if (norm == modeFlexible) {
      final days = flexibleWindowDays ?? 7;
      String windowLabel;
      if (days <= 3) {
        if (lang == 'si') {
          windowLabel = 'දින 3ක් තුළ';
        } else if (lang == 'ta') {
          windowLabel = '3 நாட்களுக்குள்';
        } else {
          windowLabel = 'within 3 days';
        }
      } else if (days <= 7) {
        if (lang == 'si') {
          windowLabel = 'සතියක් තුළ';
        } else if (lang == 'ta') {
          windowLabel = 'ஒரு வாரத்திற்குள்';
        } else {
          windowLabel = 'within a week';
        }
      } else {
        if (lang == 'si') {
          windowLabel = 'සති 2ක් තුළ';
        } else if (lang == 'ta') {
          windowLabel = '2 வாரங்களுக்குள்';
        } else {
          windowLabel = 'within 2 weeks';
        }
      }

      if (lang == 'si') {
        return 'නම්‍යශීලී · $windowLabel';
      }
      if (lang == 'ta') {
        return 'நெகிழ்வானது · $windowLabel';
      }
      return 'Flexible · $windowLabel';
    }

    return 'Today · ${slotText(scheduledSlot)}';
  }

  // legacy wrapper for formatScheduleDisplay
  static String formatScheduleDisplay(
    BuildContext context, {
    String? scheduleMode,
    DateTime? scheduledDate,
    DateTime? scheduledStartAt,
    DateTime? scheduledEndAt,
    String? legacySlot,
    String? fallbackTime,
  }) {
    final norm = normalizeMode(scheduleMode);
    if (norm == modeToday && (scheduledSlotToSlot(legacySlot) == null)) {
      return scheduleLabel(
        scheduleMode: modeToday,
        scheduledSlot: slotAnytime,
        context: context,
      );
    }

    return scheduleLabel(
      scheduleMode: scheduleMode,
      scheduledSlot: scheduledSlotToSlot(legacySlot),
      scheduledDate: scheduledDate,
      scheduledStartAt: scheduledStartAt,
      scheduledEndAt: scheduledEndAt,
      context: context,
    );
  }

  static String? scheduledSlotToSlot(String? legacySlot) {
    if (legacySlot == null || legacySlot.isEmpty) {
      return null;
    }
    final s = legacySlot.toLowerCase();
    if (s.contains('morning') || s.contains('උදෑසන') || s.contains('காலை')) {
      return slotMorning;
    }
    if (s.contains('afternoon') ||
        s.contains('දහවල්') ||
        s.contains('மதியம்')) {
      return slotAfternoon;
    }
    if (s.contains('evening') || s.contains('සවස') || s.contains('மாலை')) {
      return slotEvening;
    }
    if (s.contains('anytime') || s.contains('ඕනෑම') || s.contains('எந்த')) {
      return slotAnytime;
    }
    if (s.contains('-') || s.contains('–')) {
      return slotExact;
    }
    return legacySlot;
  }

  static bool isWindowOutsideWorkingHours({
    DateTime? scheduledStartAt,
    DateTime? scheduledEndAt,
    int workStartHour = 8,
    int workEndHour = 18,
  }) {
    if (scheduledStartAt == null || scheduledEndAt == null) {
      return false;
    }
    if (scheduledStartAt.hour < workStartHour) {
      return true;
    }
    if (scheduledEndAt.hour > workEndHour ||
        (scheduledEndAt.hour == workEndHour && scheduledEndAt.minute > 0)) {
      return true;
    }
    return false;
  }

  static String formatDate(DateTime date,
      {String? localeCode, BuildContext? context}) {
    final lang = localeCode ??
        (context != null ? Localizations.localeOf(context).languageCode : 'en');
    return DateFormat('E, d MMM', lang).format(date);
  }

  static String slotLabel(String slot, [BuildContext? context]) {
    final lang =
        context != null ? Localizations.localeOf(context).languageCode : 'en';
    final s = slot.toLowerCase();
    if (s == slotMorning) {
      if (lang == 'si') return 'උදෑසන';
      if (lang == 'ta') return 'காலை';
      return 'Morning';
    }
    if (s == slotAfternoon) {
      if (lang == 'si') return 'දහවල්';
      if (lang == 'ta') return 'மதியம்';
      return 'Afternoon';
    }
    if (s == slotEvening) {
      if (lang == 'si') return 'සවස';
      if (lang == 'ta') return 'மாலை';
      return 'Evening';
    }
    if (s == slotExact) {
      if (lang == 'si') return 'නියමිත වේලාව';
      if (lang == 'ta') return 'குறிப்பிட்ட நேரம்';
      return 'Exact Time';
    }
    if (lang == 'si') return 'ඕනෑම වේලාවක';
    if (lang == 'ta') return 'எந்த நேரமும்';
    return 'Anytime';
  }
}
