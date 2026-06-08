class DailyRevenuePoint {
  final String date;
  final double actualRevenue;
  final double systemRevenue;
  final double difference;

  const DailyRevenuePoint({
    required this.date,
    required this.actualRevenue,
    required this.systemRevenue,
    required this.difference,
  });
}

class ShiftSalesSummary {
  final String monthKey;
  final int totalShifts;
  final double totalSystemAmount;
  final double totalActualAmount;
  final double totalDifference;

  final String topPerformerName;
  final double topPerformerDifference;

  final String biggestDeficitName;
  final double biggestDeficitDifference;

  final List<DailyRevenuePoint> dailyTrend;
  final String trendDirection;
  final double slope;
  final String bestDay;
  final double bestDayRevenue;
  final String worstDay;
  final double worstDayRevenue;

  const ShiftSalesSummary({
    required this.monthKey,
    required this.totalShifts,
    required this.totalSystemAmount,
    required this.totalActualAmount,
    required this.totalDifference,
    required this.topPerformerName,
    required this.topPerformerDifference,
    required this.biggestDeficitName,
    required this.biggestDeficitDifference,
    required this.dailyTrend,
    required this.trendDirection,
    required this.slope,
    required this.bestDay,
    required this.bestDayRevenue,
    required this.worstDay,
    required this.worstDayRevenue,
  });
}