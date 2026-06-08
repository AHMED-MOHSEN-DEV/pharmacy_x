import 'package:flutter/material.dart';
import 'package:pharmacy_x/services/model/employee_monthly_insight.dart';
import 'package:pharmacy_x/services/insights_service.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../widgets/responsive_field.dart';

class AiInsightsPage extends StatefulWidget {
  const AiInsightsPage({super.key});

  @override
  State<AiInsightsPage> createState() => _AiInsightsPageState();
}

class _AiInsightsPageState extends State<AiInsightsPage> {
  final InsightsService _service = InsightsService();

  late String _monthKey;
  Future<List<EmployeeMonthlyInsight>>? _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    _load();
  }

  void _load() {
    _future = _service.getMonthlyInsights(monthKey: _monthKey);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('AI Insights', style: AppTextStyles.title),
      ),
      body: FutureBuilder<List<EmployeeMonthlyInsight>>(
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
                'Failed to load insights',
                style: AppTextStyles.body,
              ),
            );
          }

          final items = snapshot.data ?? [];

          final totalEmployees = items.length;
          final totalLate = items.fold<int>(0, (sum, e) => sum + e.lateCount);
          final totalOpen = items.fold<int>(0, (sum, e) => sum + e.openAttendanceCount);
          final totalDifference = items.fold<double>(0, (sum, e) => sum + e.totalDifference);

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
                  _FilterHeader(
                    monthKey: _monthKey,
                    onRefresh: () {
                      setState(() {
                        _load();
                      });
                    },
                  ),
                  SizedBox(height: isDesktop ? AppSpacing.lg : AppSpacing.xl),
                  GridView.count(
                    crossAxisCount: isDesktop ? 4 : 2,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: isDesktop ? 1.6 : 1.3,
                    children: [
                      _KpiCard(
                        label: 'Employees',
                        value: '$totalEmployees',
                        icon: Icons.people_outline_rounded,
                        color: AppColors.primary,
                      ),
                      _KpiCard(
                        label: 'Late Count',
                        value: '$totalLate',
                        icon: Icons.access_time_rounded,
                        color: AppColors.warning,
                      ),
                      _KpiCard(
                        label: 'Open Logs',
                        value: '$totalOpen',
                        icon: Icons.pending_actions_rounded,
                        color: AppColors.teal,
                      ),
                      _KpiCard(
                        label: 'Difference',
                        value: totalDifference.toStringAsFixed(2),
                        icon: Icons.payments_outlined,
                        color: totalDifference == 0
                            ? AppColors.textSecondary
                            : totalDifference > 0
                                ? AppColors.success
                                : AppColors.error,
                      ),
                    ],
                  ),
                  SizedBox(height: isDesktop ? AppSpacing.xl : AppSpacing.section),
                  Text('Employees Overview', style: AppTextStyles.title),
                  SizedBox(height: isDesktop ? AppSpacing.sm : AppSpacing.md),
                  if (items.isEmpty)
                    _EmptyState()
                  else
                    ...items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _EmployeeInsightCard(item: item),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterHeader extends StatelessWidget {
  final String monthKey;
  final VoidCallback onRefresh;

  const _FilterHeader({
    required this.monthKey,
    required this.onRefresh,
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Insights', style: AppTextStyles.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(monthKey, style: AppTextStyles.caption),
              ],
            ),
          ),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
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

class _EmployeeInsightCard extends StatelessWidget {
  final EmployeeMonthlyInsight item;

  const _EmployeeInsightCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final diffColor = item.totalDifference == 0
        ? AppColors.textSecondary
        : item.totalDifference > 0
            ? AppColors.success
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withOpacity(0.10),
                child: Text(
                  item.employeeName.isNotEmpty
                      ? item.employeeName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.employeeName, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.employeeEmail.isEmpty ? 'No email' : item.employeeEmail,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              _MiniBadge(
                label: '${item.attendanceDays} days',
                color: AppColors.teal,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _MiniBadge(
                label: 'Late: ${item.lateCount}',
                color: AppColors.warning,
              ),
              _MiniBadge(
                label: 'Open: ${item.openAttendanceCount}',
                color: AppColors.primary,
              ),
              _MiniBadge(
                label: 'Shifts: ${item.shiftCount}',
                color: AppColors.teal,
              ),
              _MiniBadge(
                label: 'Diff: ${item.totalDifference.toStringAsFixed(2)}',
                color: diffColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.section),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.insights_outlined,
            size: 42,
            color: AppColors.textLight,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('No insights available', style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No records found for this month.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}