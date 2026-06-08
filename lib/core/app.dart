import 'package:flutter/material.dart';
import 'package:pharmacy_x/employee/employee_main_page.dart';
import 'package:pharmacy_x/screen/admin/admin_main_page.dart';
import 'package:pharmacy_x/screen/login.dart';
import 'package:pharmacy_x/screen/signup_page.dart';
import 'package:pharmacy_x/screen/splash_page.dart' show SplashPage;
import 'package:pharmacy_x/screen/welcome_page.dart';
import 'package:pharmacy_x/theme/app_theme.dart';
import 'app_router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.splash,
      routes: {
        AppRouter.splash: (_) => const SplashPage(),
        AppRouter.welcome: (_) => const WelcomePage(),
        AppRouter.login: (_) => const LoginPage(),
        AppRouter.signup: (_) => const SignupPage(),
        AppRouter.adminHome: (_) => const AdminMainPage(),
        AppRouter.employeeHome: (_) => const EmployeeMainPage(),  },
    );
  }
}

