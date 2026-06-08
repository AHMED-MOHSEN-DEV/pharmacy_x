import 'package:flutter/material.dart';
import 'package:pharmacy_x/core/app_router.dart';
import 'package:pharmacy_x/employee/employee_home_tab.dart';
import 'package:pharmacy_x/employee/employee_profile_tab.dart';
import 'package:pharmacy_x/services/auth_service.dart';
import 'package:pharmacy_x/widgets/floating_bottom_nav.dart';
import 'package:pharmacy_x/widgets/responsive_field.dart';

class EmployeeMainPage extends StatefulWidget {
  const EmployeeMainPage({super.key});

  @override
  State<EmployeeMainPage> createState() => _EmployeeMainPageState();
}

class _EmployeeMainPageState extends State<EmployeeMainPage> {
  int _currentIndex = 0;

  final _titles = ['Home', 'My Profile'];

  final _pages = const [
    EmployeeHomeTab(),
    EmployeeProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: TextStyle(fontSize: isDesktop ? 15 : 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: Icon(Icons.logout_rounded, size: isDesktop ? 18 : 22),
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRouter.welcome,
                (route) => false,
              );
            },
          ),
        ],
      ),
      extendBody: true,
      body: _pages[_currentIndex],
      bottomNavigationBar: FloatingBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}