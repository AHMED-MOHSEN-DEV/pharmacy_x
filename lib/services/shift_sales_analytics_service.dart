import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharmacy_x/services/model/shift_sales_summary.dart';

class ShiftSalesAnalyticsService {
  final FirebaseFirestore _firestore;

  ShiftSalesAnalyticsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<ShiftSalesSummary> getMonthlySummary({
    required String monthKey, // مثال: 2026-04
  }) async {
    final snap = await _firestore
        .collection('shifts')
        .where('businessDate', isGreaterThanOrEqualTo: '$monthKey-01')
        .where('businessDate', isLessThan: '$monthKey-32')
        .get();

    final docs = snap.docs;

    double totalSystem = 0;
    double totalActual = 0;
    double totalDifference = 0;

    final Map<String, double> employeeDiffMap = {};
    final Map<String, double> dailyActualMap = {};
    final Map<String, double> dailySystemMap = {};
    final Map<String, double> dailyDifferenceMap = {};

    for (final doc in docs) {
      final data = doc.data();

      final system = (data['systemAmount'] as num?)?.toDouble() ?? 0;
      final actual = (data['actualAmount'] as num?)?.toDouble() ?? 0;
      final difference = (data['difference'] as num?)?.toDouble() ?? 0;
      final employeeName = (data['employeeName'] ?? 'Unknown').toString();
      final date = (data['businessDate'] ?? data['date'] ?? '').toString();

      totalSystem += system;
      totalActual += actual;
      totalDifference += difference;

      employeeDiffMap[employeeName] =
          (employeeDiffMap[employeeName] ?? 0) + difference;

      if (date.isNotEmpty) {
        dailyActualMap[date] = (dailyActualMap[date] ?? 0) + actual;
        dailySystemMap[date] = (dailySystemMap[date] ?? 0) + system;
        dailyDifferenceMap[date] = (dailyDifferenceMap[date] ?? 0) + difference;
      }
    }

    String topPerformerName = '-';
    double topPerformerDifference = 0;

    String biggestDeficitName = '-';
    double biggestDeficitDifference = 0;

    if (employeeDiffMap.isNotEmpty) {
      final sortedByBest = employeeDiffMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      topPerformerName = sortedByBest.first.key;
      topPerformerDifference = sortedByBest.first.value;

      final sortedByWorst = employeeDiffMap.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      biggestDeficitName = sortedByWorst.first.key;
      biggestDeficitDifference = sortedByWorst.first.value;
    }

    final sortedDates = dailyActualMap.keys.toList()..sort();

    final dailyTrend = sortedDates.map((date) {
      return DailyRevenuePoint(
        date: date,
        actualRevenue: dailyActualMap[date] ?? 0,
        systemRevenue: dailySystemMap[date] ?? 0,
        difference: dailyDifferenceMap[date] ?? 0,
      );
    }).toList();

    String trendDirection = 'Stable';
    double slope = 0;
    String bestDay = '-';
    double bestDayRevenue = 0;
    String worstDay = '-';
    double worstDayRevenue = 0;

    if (dailyTrend.isNotEmpty) {
      final bestPoint = dailyTrend.reduce(
        (a, b) => a.actualRevenue >= b.actualRevenue ? a : b,
      );
      final worstPoint = dailyTrend.reduce(
        (a, b) => a.actualRevenue <= b.actualRevenue ? a : b,
      );

      bestDay = bestPoint.date;
      bestDayRevenue = bestPoint.actualRevenue;

      worstDay = worstPoint.date;
      worstDayRevenue = worstPoint.actualRevenue;
    }

    if (dailyTrend.length >= 2) {
      final first = dailyTrend.first.actualRevenue;
      final last = dailyTrend.last.actualRevenue;

      slope = (last - first) / (dailyTrend.length - 1);

      if (slope > 0) {
        trendDirection = 'Upward';
      } else if (slope < 0) {
        trendDirection = 'Downward';
      } else {
        trendDirection = 'Stable';
      }
    }

    return ShiftSalesSummary(
      monthKey: monthKey,
      totalShifts: docs.length,
      totalSystemAmount: totalSystem,
      totalActualAmount: totalActual,
      totalDifference: totalDifference,
      topPerformerName: topPerformerName,
      topPerformerDifference: topPerformerDifference,
      biggestDeficitName: biggestDeficitName,
      biggestDeficitDifference: biggestDeficitDifference,
      dailyTrend: dailyTrend,
      trendDirection: trendDirection,
      slope: slope,
      bestDay: bestDay,
      bestDayRevenue: bestDayRevenue,
      worstDay: worstDay,
      worstDayRevenue: worstDayRevenue,
    );
  }
}