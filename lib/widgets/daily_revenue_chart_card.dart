import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pharmacy_x/services/model/shift_sales_summary.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';

class DailyRevenueChartCard extends StatelessWidget {
  final List<DailyRevenuePoint> points;

  const DailyRevenueChartCard({
    super.key,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'No daily revenue data available',
          style: AppTextStyles.body,
        ),
      );
    }

    final maxRevenue = points
        .map((e) => e.actualRevenue)
        .reduce((a, b) => a > b ? a : b);

    final chartWidth = _calculateChartWidth(points.length);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Revenue Chart',
            style: AppTextStyles.title,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Swipe left and right to view all days',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: AppSpacing.lg),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: chartWidth,
              height: 340,
              child: BarChart(
                BarChartData(
                  maxY: maxRevenue == 0 ? 100 : maxRevenue * 1.28,
                  alignment: BarChartAlignment.spaceAround,
                  groupsSpace: 6,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _safeInterval(maxRevenue),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppColors.border,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }

                          final revenue = points[index].actualRevenue;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              _formatTopValue(revenue),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 54,
                        interval: _safeInterval(maxRevenue),
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              _formatAxisValue(value),
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }

                          final day = points[index].date.split('-').last;

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              day,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
  tooltipRoundedRadius: 10,
  tooltipPadding: const EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 8,
  ),
  fitInsideHorizontally: true,
  fitInsideVertically: true,
  getTooltipItem: (group, groupIndex, rod, rodIndex) {
    final point = points[group.x.toInt()];

    return BarTooltipItem(
      '${point.date}\n${point.actualRevenue.toStringAsFixed(0)} EGP',
      AppTextStyles.caption.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
    );
  },
),
                  ),
                  barGroups: _buildBars(points, maxRevenue),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: const [
              _LegendChip(
                label: 'Blue = Surplus / Balanced',
                color: AppColors.primary,
              ),
              _LegendChip(
                label: 'Red = Deficit',
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBars(
    List<DailyRevenuePoint> points,
    double maxRevenue,
  ) {
    return List.generate(points.length, (i) {
      final point = points[i];
      final isDeficit = point.difference < 0;

      return BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: point.actualRevenue,
            width: 28,
            borderRadius: BorderRadius.circular(7),
            color: isDeficit ? AppColors.error : AppColors.primary,
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxRevenue == 0 ? 100 : maxRevenue * 1.1,
              color: AppColors.surfaceSoft,
            ),
          ),
        ],
      );
    });
  }

  double _calculateChartWidth(int count) {
    if (count <= 6) return 560;
    return count * 64.0;
  }

  double _safeInterval(double maxRevenue) {
    if (maxRevenue <= 100) return 20;
    if (maxRevenue <= 500) return 100;
    if (maxRevenue <= 1000) return 200;
    if (maxRevenue <= 5000) return 500;
    if (maxRevenue <= 10000) return 1000;
    return 2000;
  }

  String _formatAxisValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toInt().toString();
  }

  String _formatTopValue(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}

class _LegendChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}