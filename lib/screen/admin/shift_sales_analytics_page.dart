import 'package:flutter/material.dart';
import 'package:pharmacy_x/services/model/shift_sales_summary.dart';
import 'package:pharmacy_x/services/shift_sales_analytics_service.dart';
import 'package:pharmacy_x/widgets/daily_revenue_chart_card.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../widgets/responsive_field.dart';

class ShiftSalesAnalyticsPage extends StatefulWidget {
  const ShiftSalesAnalyticsPage({super.key});

  @override
  State<ShiftSalesAnalyticsPage> createState() => _ShiftSalesAnalyticsPageState();
}

class _ShiftSalesAnalyticsPageState extends State<ShiftSalesAnalyticsPage> {
  final ShiftSalesAnalyticsService _service = ShiftSalesAnalyticsService();

  late String _monthKey;
  Future<ShiftSalesSummary>? _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _load();
  }

  void _load() {
    _future = _service.getMonthlySummary(monthKey: _monthKey);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Shift Sales Analytics', style: AppTextStyles.title),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _load();
              });
            },
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.primary,
          ),
        ],
      ),
      body: FutureBuilder<ShiftSalesSummary>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load analytics',
                style: AppTextStyles.body,
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return Center(
              child: Text(
                'No analytics available',
                style: AppTextStyles.body,
              ),
            );
          }

          return Align(
            alignment: isDesktop ? Alignment.topCenter : Alignment.topLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 1100 : double.infinity,
              ),
              child: ListView(
                padding: EdgeInsets.all(
                  isDesktop ? AppSpacing.xxl : AppSpacing.lg,
                ),
                children: [
                  _HeaderCard(monthKey: data.monthKey),
                  const SizedBox(height: AppSpacing.lg),
                  GridView.count(
                    crossAxisCount: isDesktop ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: isDesktop ? 1.6 : 1.25,
                    children: [
                      _KpiCard(
                        label: 'Total Shifts',
                        value: '${data.totalShifts}',
                        color: AppColors.primary,
                        icon: Icons.inventory_2_outlined,
                      ),
                      _KpiCard(
                        label: 'System Amount',
                        value: data.totalSystemAmount.toStringAsFixed(2),
                        color: AppColors.teal,
                        icon: Icons.computer_rounded,
                      ),
                      _KpiCard(
                        label: 'Actual Amount',
                        value: data.totalActualAmount.toStringAsFixed(2),
                        color: AppColors.success,
                        icon: Icons.payments_outlined,
                      ),
                      _KpiCard(
                        label: 'Difference',
                        value: data.totalDifference.toStringAsFixed(2),
                        color: data.totalDifference >= 0
                            ? AppColors.success
                            : AppColors.error,
                        icon: Icons.show_chart_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.section),

DailyRevenueChartCard(points: data.dailyTrend),

const SizedBox(height: AppSpacing.section),

Center(
  child: Wrap(
    alignment: WrapAlignment.center,
    spacing: AppSpacing.md,
    runSpacing: AppSpacing.md,
    children: [
      _MiniInsightCard(
        title: 'Trend',
        value: data.trendDirection,
        color: data.trendDirection == 'Upward'
            ? AppColors.success
            : data.trendDirection == 'Downward'
                ? AppColors.error
                : AppColors.warning,
        icon: Icons.trending_up_rounded,
      ),
      _MiniInsightCard(
        title: 'Slope',
        value: data.slope.toStringAsFixed(2),
        color: AppColors.primary,
        icon: Icons.show_chart_rounded,
      ),
      _MiniInsightCard(
        title: 'Best Day',
        value: '${data.bestDay}\n${data.bestDayRevenue.toStringAsFixed(2)}',
        color: AppColors.success,
        icon: Icons.arrow_upward_rounded,
      ),
      _MiniInsightCard(
        title: 'Worst Day',
        value: '${data.worstDay}\n${data.worstDayRevenue.toStringAsFixed(2)}',
        color: AppColors.error,
        icon: Icons.arrow_downward_rounded,
      ),
    ],
  ),
),
                  const SizedBox(height: AppSpacing.section),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String monthKey;

  const _HeaderCard({required this.monthKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Shift Analytics', style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(monthKey, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTextStyles.headline.copyWith(color: color),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}


class _MiniInsightCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniInsightCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 170,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}