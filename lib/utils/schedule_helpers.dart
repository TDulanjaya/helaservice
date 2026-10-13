import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'l10n_extension.dart';

class ScheduleWindowResult {
  final String scheduleMode; // 'asap', 'date_only', 'time_range'
  final DateTime? scheduledDate; // 00:00 of that day
  final DateTime? scheduledStartAt;
  final DateTime? scheduledEndAt;
  final String? errorMessage;
  final bool isValid;

  const ScheduleWindowResult({
    required this.scheduleMode,
    this.scheduledDate,
    this.scheduledStartAt,
    this.scheduledEndAt,
    this.errorMessage,
    required this.isValid,
  });

  factory ScheduleWindowResult.valid({
    required String scheduleMode,
    DateTime? scheduledDate,
    DateTime? scheduledStartAt,
    DateTime? scheduledEndAt,
  }) {
    return ScheduleWindowResult(
      scheduleMode: scheduleMode,
      scheduledDate: scheduledDate,
      scheduledStartAt: scheduledStartAt,
      scheduledEndAt: scheduledEndAt,
      isValid: true,
    );
  }

  factory ScheduleWindowResult.error(String message) {
    return ScheduleWindowResult(
      scheduleMode: 'asap',
      errorMessage: message,
      isValid: false,
    );
  }
}

class ScheduleHelpers {
  ScheduleHelpers._();

  static const String modeAsap = 'asap';
  static const String modeDateOnly = 'date_only';
  static const String modeTimeRange = 'time_range';

  /// Checks if a date is today in local time
  static bool isToday(DateTime date, [DateTime? nowOverride]) {
    final now = nowOverride ?? DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Can "today" be chosen for date_only?
  /// If now is past 19:00 (less than 1 hour remains before 20:00), today cannot be chosen.
  static bool canChooseTodayForDateOnly([DateTime? nowOverride]) {
    final now = nowOverride ?? DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day, 19, 0);
    return now.isBefore(cutoff);
  }

  /// Rounds a DateTime up to the next 15-minute boundary.
  static DateTime roundUpToNext15Minutes(DateTime dt) {
    if (dt.minute % 15 == 0 && dt.second == 0 && dt.millisecond == 0) {
      return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute);
    }
    final nextMinutes = ((dt.minute / 15).floor() + 1) * 15;
    return DateTime(dt.year, dt.month, dt.day, dt.hour, 0)
        .add(Duration(minutes: nextMinutes));
  }

  /// Computes schedule window for 'asap', 'date_only', or 'time_range'
  static ScheduleWindowResult computeScheduleWindow({
    required String mode,
    DateTime? date,
    TimeOfDay? fromTime,
    TimeOfDay? toTime,
    DateTime? nowOverride,
  }) {
    final now = nowOverride ?? DateTime.now();

    if (mode == modeAsap) {
      return ScheduleWindowResult.valid(scheduleMode: modeAsap);
    }

    if (date == null) {
      return ScheduleWindowResult.error('Date is required.');
    }

    final localDate = DateTime(date.year, date.month, date.day);

    if (localDate.isBefore(DateTime(now.year, now.month, now.day))) {
      return ScheduleWindowResult.error('Date cannot be in the past.');
    }

    if (localDate.isAfter(DateTime(now.year, now.month, now.day).add(const Duration(days: 60)))) {
      return ScheduleWindowResult.error('Date cannot be more than 60 days ahead.');
    }

    if (mode == modeDateOnly) {
      final endAt = DateTime(localDate.year, localDate.month, localDate.day, 20, 0);
      DateTime startAt;

      if (isToday(localDate, now)) {
        if (now.hour < 8) {
          startAt = DateTime(localDate.year, localDate.month, localDate.day, 8, 0);
        } else {
          startAt = roundUpToNext15Minutes(now);
          if (endAt.difference(startAt).inMinutes < 60) {
            return ScheduleWindowResult.error(
              'Less than 1 hour remains before 20:00 today. Please select a future date.',
            );
          }
        }
      } else {
        startAt = DateTime(localDate.year, localDate.month, localDate.day, 8, 0);
      }

      return ScheduleWindowResult.valid(
        scheduleMode: modeDateOnly,
        scheduledDate: localDate,
        scheduledStartAt: startAt,
        scheduledEndAt: endAt,
      );
    }

    if (mode == modeTimeRange) {
      if (fromTime == null || toTime == null) {
        return ScheduleWindowResult.error('Start and end times are required.');
      }

      final startAt = DateTime(
        localDate.year,
        localDate.month,
        localDate.day,
        fromTime.hour,
        fromTime.minute,
      );
      final endAt = DateTime(
        localDate.year,
        localDate.month,
        localDate.day,
        toTime.hour,
        toTime.minute,
      );

      if (!endAt.isAfter(startAt)) {
        return ScheduleWindowResult.error('End time must be after start time.');
      }

      final diffMinutes = endAt.difference(startAt).inMinutes;
      if (diffMinutes < 60) {
        return ScheduleWindowResult.error('Time range must be at least 1 hour.');
      }
      if (diffMinutes > 720) {
        return ScheduleWindowResult.error('Time range cannot exceed 12 hours.');
      }

      // Start not more than 15 minutes in past
      if (startAt.isBefore(now.subtract(const Duration(minutes: 15)))) {
        return ScheduleWindowResult.error('Start time cannot be in the past.');
      }

      return ScheduleWindowResult.valid(
        scheduleMode: modeTimeRange,
        scheduledDate: localDate,
        scheduledStartAt: startAt,
        scheduledEndAt: endAt,
      );
    }

    return ScheduleWindowResult.error('Unsupported schedule mode: $mode');
  }

  /// Legacy helper for slot-based backward compatibility
  static DateTime computeLegacyScheduledStartAt(DateTime date, String? slot) {
    int hour = 8;
    final s = (slot ?? '').toLowerCase();
    if (s.contains('morning') || s.contains('උදෑසන') || s.contains('காலை')) {
      hour = 8;
    } else if (s.contains('afternoon') || s.contains('දහවල්') || s.contains('மதியம்')) {
      hour = 12;
    } else if (s.contains('evening') || s.contains('සවස') || s.contains('மாலை')) {
      hour = 16;
    } else {
      final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(s);
      if (match != null) {
        int parsedHour = int.tryParse(match.group(1)!) ?? 8;
        if (s.contains('pm') && parsedHour < 12) parsedHour += 12;
        hour = parsedHour;
      } else if (date.hour != 0) {
        return date;
      }
    }
    return DateTime(date.year, date.month, date.day, hour, 0);
  }

  /// Formats schedule display according to current locale (en/si/ta)
  /// e.g. "Mon 20 Oct · 2:00 PM – 5:00 PM" or "Mon 20 Oct · any time"
  static String formatScheduleDisplay(
    BuildContext context, {
    String? scheduleMode,
    DateTime? scheduledDate,
    DateTime? scheduledStartAt,
    DateTime? scheduledEndAt,
    String? legacySlot,
    String? fallbackTime,
  }) {
    final locale = Localizations.localeOf(context).languageCode;

    if (scheduleMode == modeAsap) {
      return context.l10n.bookingTypeAsap;
    }

    if (scheduledDate != null) {
      final dateStr = DateFormat.yMMMd(locale).format(scheduledDate);

      if (scheduleMode == modeDateOnly) {
        return '$dateStr · ${context.l10n.scheduleAnyTime}';
      }

      if (scheduleMode == modeTimeRange && scheduledStartAt != null && scheduledEndAt != null) {
        final startStr = DateFormat.jm(locale).format(scheduledStartAt);
        final endStr = DateFormat.jm(locale).format(scheduledEndAt);
        return '$dateStr · $startStr – $endStr';
      }

      // Legacy fallback with slot
      if (legacySlot != null && legacySlot.isNotEmpty) {
        final s = legacySlot.toLowerCase();
        String slotLabel = legacySlot;
        if (s.contains('morning') || s.contains('8:00') || s.contains('උදෑසන') || s.contains('காலை')) {
          slotLabel = context.l10n.slotMorning;
        } else if (s.contains('afternoon') || s.contains('12:00') || s.contains('දහවල්') || s.contains('மதியம்')) {
          slotLabel = context.l10n.slotAfternoon;
        } else if (s.contains('evening') || s.contains('4:00') || s.contains('සවස') || s.contains('மாலை')) {
          slotLabel = context.l10n.slotEvening;
        }
        return '$dateStr · $slotLabel';
      }

      if (scheduledStartAt != null && scheduledEndAt != null) {
        final startStr = DateFormat.jm(locale).format(scheduledStartAt);
        final endStr = DateFormat.jm(locale).format(scheduledEndAt);
        return '$dateStr · $startStr – $endStr';
      }

      return dateStr;
    }

    if (fallbackTime != null && fallbackTime.isNotEmpty) {
      return fallbackTime;
    }

    return context.l10n.bookingTypeAsap;
  }

  /// Checks if schedule window is outside working hours (default 8:00 - 18:00)
  static bool isWindowOutsideWorkingHours({
    DateTime? scheduledStartAt,
    DateTime? scheduledEndAt,
    int workStartHour = 8,
    int workEndHour = 18,
  }) {
    if (scheduledStartAt == null || scheduledEndAt == null) return false;
    if (scheduledStartAt.hour < workStartHour) return true;
    if (scheduledEndAt.hour > workEndHour ||
        (scheduledEndAt.hour == workEndHour && scheduledEndAt.minute > 0)) {
      return true;
    }
    return false;
  }
}
