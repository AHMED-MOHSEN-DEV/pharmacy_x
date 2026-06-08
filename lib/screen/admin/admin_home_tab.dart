import 'package:flutter/material.dart';
import 'package:pharmacy_x/screen/admin/admin_employee_schedule_page.dart';
import 'package:pharmacy_x/screen/admin/ai_insights_page.dart';
import 'package:pharmacy_x/screen/admin/shift_sales_analytics_page.dart';
import 'package:pharmacy_x/screen/attendance/admin_attendance_page.dart';
import 'package:pharmacy_x/screen/attendance/employee_checkin_page.dart';
import 'package:pharmacy_x/screen/shifts/shift_entry_page.dart';
import 'package:pharmacy_x/screen/shifts/shifts_history_page.dart';
import 'package:pharmacy_x/theme/app_colors.dart';
import 'package:pharmacy_x/theme/app_radius.dart';
import 'package:pharmacy_x/theme/app_spacing.dart';
import 'package:pharmacy_x/theme/app_text_styles.dart';

class AdminHomeTab extends StatelessWidget {
  const AdminHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          120,
        ),
        children: const [
          _WelcomeCard(),
          SizedBox(height: AppSpacing.section),

          _SectionBlock(
            title: 'Analytics',
            child: _AnalyticsSection(),
          ),

          SizedBox(height: AppSpacing.section),

          _SectionBlock(
            title: 'Admin Tools',
            child: _AdminToolsSection(),
          ),

          SizedBox(height: AppSpacing.section),

          _SectionBlock(
            title: 'Shift Tools',
            child: _ShiftToolsSection(),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.teal, Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.local_hospital_rounded,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Welcome back, Admin',
            style: AppTextStyles.headline.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Manage staff, attendance, and shifts',
            style: AppTextStyles.body.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionBlock({
    required this.title,
    required this.child,
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
          _SectionTitle(title),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.title);
  }
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection();

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActionItem(
        title: 'Employee analysis',
        subtitle: 'Open employee analysis page',
        icon: Icons.analytics_rounded,
        color: const Color.fromARGB(255, 178, 168, 23),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AiInsightsPage()),
        ),
      ),
      _ActionItem(
        title: 'Shifts analysis',
        subtitle: 'Open shift analytics page',
        icon: Icons.query_stats_rounded,
        color: const Color.fromARGB(255, 178, 23, 23),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShiftSalesAnalyticsPage()),
        ),
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _ActionCard(item: items[i]),
          if (i < items.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _AdminToolsSection extends StatelessWidget {
  const _AdminToolsSection();

  @override
  Widget build(BuildContext context) {
    final items = [
      _ActionItem(
        title: 'Attendance',
        subtitle: 'Open employee attendance monitor',
        icon: Icons.people_alt_outlined,
        color: AppColors.primary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminAttendancePage()),
        ),
      ),
      _ActionItem(
        title: 'Check In',
        subtitle: 'Open employee check-in page',
        icon: Icons.fingerprint_rounded,
        color: AppColors.success,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeCheckInPage()),
        ),
      ),
      _ActionItem(
        title: 'Employee schedule',
        subtitle: 'Open employee schedule page',
        icon: Icons.calendar_today_rounded,
        color: const Color.fromARGB(255, 178, 23, 139),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminEmployeeSchedulePage()),
        ),
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _ActionCard(item: items[i]),
          if (i < items.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _ShiftToolsSection extends StatelessWidget {
  const _ShiftToolsSection();

  @override
  Widget build(BuildContext context) {
    final items = [
      _ShiftItem(
        title: 'Register Shift',
        subtitle: 'Review live and today logs',
        icon: Icons.add_circle_outline_rounded,
        color: AppColors.teal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShiftEntryPage()),
        ),
      ),
      _ShiftItem(
        title: 'Shift History',
        subtitle: 'View past shifts and schedules',
        icon: Icons.history_rounded,
        color: AppColors.primary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShiftsHistoryPage()),
        ),
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _ShiftCard(item: items[i]),
          if (i < items.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final _ActionItem item;

  const _ActionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: item.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: item.color.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(item.subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  final _ShiftItem item;

  const _ShiftCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: item.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: item.color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: item.color.withOpacity(0.18)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, color: item.color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTextStyles.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(item.subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class _ShiftItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ShiftItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}