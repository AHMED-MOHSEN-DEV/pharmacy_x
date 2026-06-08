import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pharmacy_x/screen/attendance/employee_checkin_page.dart';
import 'package:pharmacy_x/screen/shifts/shift_entry_page.dart';
import 'package:pharmacy_x/screen/shifts/shifts_history_page.dart';
import 'package:pharmacy_x/theme/app_colors.dart';
import 'package:pharmacy_x/theme/app_radius.dart';
import 'package:pharmacy_x/theme/app_spacing.dart';
import 'package:pharmacy_x/theme/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmployeeHomeTab extends StatelessWidget {
  const EmployeeHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      appBar: const _EmployeeAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          120,
        ),
        children: const [
          _WelcomeCard(),
          SizedBox(height: AppSpacing.md),
          _SectionTitle('Quick Actions'),
          SizedBox(height: AppSpacing.md),
          _EmployeeActionList(),
          SizedBox(height: AppSpacing.md),
          _SectionTitle('Shifts'),
          SizedBox(height: AppSpacing.md),
          _ShiftActionsColumn(),
        ],
      ),
    );
  }
}

// APP BAR

class _EmployeeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _EmployeeAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Employee Dashboard', style: AppTextStyles.title),
    
      
    );
  }
}

// WELCOME CARD

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  Future<String> _loadName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Employee';

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data()?['name'] ?? user.displayName ?? 'Employee';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _loadName(),
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'Employee';

        return Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.waving_hand_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Welcome back',
                style: AppTextStyles.headline.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                name,
                style: AppTextStyles.body.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Track your attendance and manage your shifts quickly.',
                style: AppTextStyles.body.copyWith(color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }
}

// SECTION TITLE

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.title);
  }
}

// QUICK ACTIONS

class _EmployeeActionList extends StatelessWidget {
  const _EmployeeActionList();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionItem(
        title: 'Check In',
        icon: Icons.fingerprint_rounded,
        color: AppColors.success,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmployeeCheckInPage()),
        ),
      ),
    ];

    return Column(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          _ActionCard(item: actions[i]),
          if (i < actions.length - 1) const SizedBox(height: AppSpacing.md),
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
                    Text('Open module', style: AppTextStyles.caption),
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
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

// SHIFT ACTIONS

class _ShiftActionsColumn extends StatelessWidget {
  const _ShiftActionsColumn();

  @override
  Widget build(BuildContext context) {
    final items = [
      _ShiftItem(
        title: 'Register Shift',
        subtitle: 'Enter your shift amounts and notes',
        icon: Icons.add_circle_outline_rounded,
        color: AppColors.teal,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ShiftEntryPage()),
        ),
      ),
      _ShiftItem(
        title: 'Shifts History',
        subtitle: 'View your recorded shifts',
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