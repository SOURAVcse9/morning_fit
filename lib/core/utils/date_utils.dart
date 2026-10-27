import 'package:intl/intl.dart';

final DateFormat _keyFmt = DateFormat('yyyy-MM-dd');

/// Local calendar-day key (yyyy-MM-dd) for an absolute timestamp.
String localDateKey(DateTime t) => _keyFmt.format(t.toLocal());

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime monthStart(DateTime d) => DateTime(d.year, d.month);
DateTime nextMonthStart(DateTime d) => DateTime(d.year, d.month + 1);
int daysInMonth(DateTime d) => nextMonthStart(d).difference(monthStart(d)).inDays;
