import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app_theme.dart';
import '../../../models/reservation_model.dart';
import '../../../utils/booking_validator.dart';
import '../../../utils/date_id.dart';

/// Kalender mingguan (Senin–Minggu) dengan grid jam, tanpa package tambahan.
///
/// * Ketuk area kosong  -> [onSlotTap] (jam mulai yang diusulkan).
/// * Ketuk blok jadwal  -> [onReservationTap].
/// * Ketuk waktu lewat / di luar jam operasional -> [onBlockedTap].
class WeeklyCalendar extends StatelessWidget {
  const WeeklyCalendar({
    super.key,
    required this.weekStart,
    required this.hours,
    required this.reservations,
    required this.onSlotTap,
    required this.onReservationTap,
    this.onBlockedTap,
    this.now,
  });

  /// Hari Senin (jam 00:00) dari minggu yang ditampilkan.
  final DateTime weekStart;
  final OperationalHours hours;
  final List<ReservationModel> reservations;
  final ValueChanged<DateTime> onSlotTap;
  final ValueChanged<ReservationModel> onReservationTap;
  final ValueChanged<String>? onBlockedTap;

  /// Waktu "sekarang" (untuk pengujian). Default: DateTime.now().
  final DateTime? now;

  static const double gutter = 46;
  static const double hourHeight = 56;
  static const _todayTint = Color(0xFFF4FBFE);
  static const _unavailable = Color(0xFFEEF2F6);

  @override
  Widget build(BuildContext context) {
    final current = now ?? DateTime.now();
    final today = DateId.dateOnly(current);
    final firstHour = hours.firstHour;
    final totalHours = hours.lastHour - firstHour;
    final gridStartMin = firstHour * 60;
    final gridEndMin = hours.lastHour * 60;
    final bodyHeight = totalHours * hourHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final colW = (constraints.maxWidth - gutter) / 7;

        double yOf(int minuteOfDay) =>
            (minuteOfDay - gridStartMin) / 60 * hourHeight;

        final children = <Widget>[];

        // Garis & label jam.
        for (var i = 0; i <= totalHours; i++) {
          children.add(
            Positioned(
              top: i * hourHeight,
              left: gutter,
              right: 0,
              height: 1,
              child: const ColoredBox(color: AppTheme.outline),
            ),
          );
          if (i < totalHours) {
            children.add(
              Positioned(
                top: i * hourHeight + 2,
                left: 0,
                width: gutter - 6,
                child: Text(
                  DateId.hm(firstHour + i, 0),
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ),
            );
          }
        }

        // Kolom hari: area ketuk + penanda hari ini.
        for (var d = 0; d < 7; d++) {
          final day = DateId.addDays(weekStart, d);
          children.add(
            Positioned(
              left: gutter + d * colW,
              width: colW,
              top: 0,
              height: bodyHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) =>
                    _handleTap(day, details.localPosition.dy, current),
                child: ColoredBox(
                  color: DateId.isSameDay(day, today)
                      ? _todayTint
                      : Colors.transparent,
                ),
              ),
            ),
          );
        }

        // Pembatas vertikal antar hari.
        for (var d = 0; d <= 7; d++) {
          children.add(
            Positioned(
              left: gutter + d * colW,
              top: 0,
              height: bodyHeight,
              width: 1,
              child: const IgnorePointer(
                child: ColoredBox(color: AppTheme.outline),
              ),
            ),
          );
        }

        // Area tidak tersedia: waktu lewat & di luar jam operasional.
        for (var d = 0; d < 7; d++) {
          final day = DateId.addDays(weekStart, d);
          final left = gutter + d * colW + 1;
          final width = colW - 1;

          void shade(int fromMin, int toMin) {
            final from = math.max(fromMin, gridStartMin);
            final to = math.min(toMin, gridEndMin);
            if (to <= from) return;
            children.add(
              Positioned(
                left: left,
                width: width,
                top: yOf(from),
                height: yOf(to) - yOf(from),
                child: const IgnorePointer(
                  child: ColoredBox(color: _unavailable),
                ),
              ),
            );
          }

          if (hours.isDefined) {
            shade(gridStartMin, hours.startMinute);
            shade(hours.endMinute, gridEndMin);
          }
          if (day.isBefore(today)) {
            shade(gridStartMin, gridEndMin);
          } else if (DateId.isSameDay(day, today)) {
            shade(gridStartMin, current.hour * 60 + current.minute);
          }
        }

        // Blok jadwal.
        for (final r in reservations) {
          for (var d = 0; d < 7; d++) {
            final day = DateId.addDays(weekStart, d);
            final segStart = _max(
              r.startTime,
              DateTime(day.year, day.month, day.day, firstHour),
            );
            final segEnd = _min(
              r.endTime,
              DateTime(day.year, day.month, day.day, hours.lastHour),
            );
            if (!segEnd.isAfter(segStart)) continue;
            final top = yOf(segStart.hour * 60 + segStart.minute);
            final height = math.max(
              yOf(segEnd.hour * 60 + segEnd.minute) - top,
              20.0,
            );
            children.add(
              Positioned(
                left: gutter + d * colW + 2,
                width: colW - 3,
                top: top,
                height: height,
                child: _ReservationBlock(
                  reservation: r,
                  onTap: () => onReservationTap(r),
                ),
              ),
            );
          }
        }

        // Garis waktu sekarang.
        final todayIndex = today.difference(weekStart).inDays;
        final nowMin = current.hour * 60 + current.minute;
        if (todayIndex >= 0 &&
            todayIndex < 7 &&
            nowMin >= gridStartMin &&
            nowMin <= gridEndMin) {
          children.add(
            Positioned(
              left: gutter + todayIndex * colW,
              width: colW,
              top: yOf(nowMin) - 1,
              height: 2,
              child: const IgnorePointer(
                child: ColoredBox(color: AppTheme.danger),
              ),
            ),
          );
        }

        return Column(
          children: [
            _DayHeader(weekStart: weekStart, today: today, colWidth: colW),
            const Divider(height: 1, color: AppTheme.outline),
            Expanded(
              child: SingleChildScrollView(
                child: SizedBox(
                  height: bodyHeight,
                  child: Stack(children: children),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleTap(DateTime day, double dy, DateTime current) {
    final lastIndex = hours.lastHour - hours.firstHour - 1;
    final hourIndex = math.min(
      math.max((dy / hourHeight).floor(), 0),
      lastIndex,
    );
    final slotStartMin = (hours.firstHour + hourIndex) * 60;
    final slotEndMin = slotStartMin + 60;
    final nowMin = current.hour * 60 + current.minute;
    final isToday = DateId.isSameDay(day, current);

    if (day.isBefore(DateId.dateOnly(current)) ||
        (isToday && slotEndMin <= nowMin)) {
      onBlockedTap?.call('Waktu tersebut sudah lewat.');
      return;
    }
    if (hours.isDefined &&
        (slotEndMin <= hours.startMinute || slotStartMin >= hours.endMinute)) {
      onBlockedTap?.call(
        'Di luar jam operasional laboratorium (${hours.label}).',
      );
      return;
    }

    var startMin = math.max(
      slotStartMin,
      hours.isDefined ? hours.startMinute : 0,
    );
    if (isToday && startMin < nowMin) {
      // Slot jam berjalan: usulkan kelipatan 30 menit berikutnya.
      startMin = ((nowMin + 29) ~/ 30) * 30;
      if (hours.isDefined && startMin >= hours.endMinute) {
        onBlockedTap?.call('Jam operasional hari ini sudah berakhir.');
        return;
      }
    }
    onSlotTap(
      DateTime(day.year, day.month, day.day, startMin ~/ 60, startMin % 60),
    );
  }

  static DateTime _max(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
  static DateTime _min(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.weekStart,
    required this.today,
    required this.colWidth,
  });

  final DateTime weekStart;
  final DateTime today;
  final double colWidth;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        const SizedBox(width: WeeklyCalendar.gutter),
        for (var d = 0; d < 7; d++)
          SizedBox(
            width: colWidth,
            child: _DayCell(
              day: DateId.addDays(weekStart, d),
              isToday: DateId.isSameDay(DateId.addDays(weekStart, d), today),
            ),
          ),
      ],
    ),
  );
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.isToday});

  final DateTime day;
  final bool isToday;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        DateId.dayShort(day),
        style: TextStyle(
          fontSize: 12,
          color: isToday ? AppTheme.deep : AppTheme.muted,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      const SizedBox(height: 4),
      Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isToday ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isToday ? Colors.white : AppTheme.ink,
          ),
        ),
      ),
    ],
  );
}

class _ReservationBlock extends StatelessWidget {
  const _ReservationBlock({required this.reservation, required this.onTap});

  final ReservationModel reservation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = reservation;
    final isBlock = r.type == 'maintenance_block';
    final isPending = r.status == 'pending';
    final Color bg;
    final Color border;
    if (isPending) {
      bg = AppTheme.warningSoft;
      border = AppTheme.warning;
    } else if (isBlock) {
      bg = const Color(0xFFE2E8F0);
      border = AppTheme.muted;
    } else {
      bg = AppTheme.successSoft;
      border = AppTheme.success;
    }
    return Semantics(
      button: true,
      label:
          '${r.title}, ${DateId.range(r.startTime, r.endTime)}, ${isPending
              ? 'menunggu persetujuan'
              : isBlock
              ? 'diblokir'
              : 'disetujui'}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: border),
          ),
          child: ClipRect(
            child: Text(
              r.title.isEmpty ? 'Terisi' : r.title,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
                height: 1.15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
