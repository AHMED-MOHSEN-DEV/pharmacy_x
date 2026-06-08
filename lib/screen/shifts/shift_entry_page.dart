import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../widgets/responsive_field.dart';
import 'shifts_history_page.dart';

class ShiftEntryPage extends StatefulWidget {
  const ShiftEntryPage({super.key});

  @override
  State<ShiftEntryPage> createState() => _ShiftEntryPageState();
}

class _ShiftEntryPageState extends State<ShiftEntryPage> {
  final _formKey = GlobalKey<FormState>();

  final _systemAmountController = TextEditingController();
  final _actualAmountController = TextEditingController();
  final _shiftNumberController = TextEditingController();

  double _difference = 0;
  bool _loading = false;
  String _employeeName = 'Loading...';
  String _employeeEmail = '';

  @override
  void initState() {
    super.initState();
    _loadEmployeeData();
    _actualAmountController.addListener(_calculateDifference);
    _systemAmountController.addListener(_calculateDifference);
  }

  Future<void> _loadEmployeeData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() {
        _employeeName = 'Unknown';
        _employeeEmail = '';
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      if (!mounted) return;
      setState(() {
        _employeeName = (data?['name'] as String?)?.trim().isNotEmpty == true
            ? data!['name'].toString()
            : (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!
                : 'Unknown');

        _employeeEmail = (data?['email'] as String?)?.trim().isNotEmpty == true
            ? data!['email'].toString()
            : (user.email ?? '');
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _employeeName = user.displayName ?? 'Unknown';
        _employeeEmail = user.email ?? '';
      });
    }
  }

  void _calculateDifference() {
    final system = double.tryParse(_systemAmountController.text) ?? 0;
    final actual = double.tryParse(_actualAmountController.text) ?? 0;
    setState(() {
      _difference = actual - system;
    });
  }

  Future<void> _submitShift() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _loading = true);

      final user = FirebaseAuth.instance.currentUser;
      final now = DateTime.now();
      final businessDate = _getBusinessDate(now);

      final shiftNumber = _shiftNumberController.text.trim();
      final systemAmount = double.tryParse(_systemAmountController.text.trim());
      final actualAmount = double.tryParse(_actualAmountController.text.trim());

      if (systemAmount == null || actualAmount == null) {
        throw Exception('Invalid amount');
      }

      await FirebaseFirestore.instance.collection('shifts').add({
  'shiftNumber': shiftNumber,
  'systemAmount': systemAmount,
  'actualAmount': actualAmount,
  'difference': _difference,
  'employeeName': _employeeName,
  'employeeEmail': _employeeEmail,
  'employeeId': user?.uid ?? '',
  'date': DateFormat('yyyy-MM-dd').format(now),
  'time': DateFormat('HH:mm').format(now),
  'businessDate': DateFormat('yyyy-MM-dd').format(businessDate),
  'createdAt': FieldValue.serverTimestamp(),
});

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shift saved successfully'),
          backgroundColor: Color(0xFF059669),
        ),
      );

      _formKey.currentState!.reset();
      _systemAmountController.clear();
      _actualAmountController.clear();
      _shiftNumberController.clear();
      setState(() => _difference = 0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _systemAmountController.dispose();
    _actualAmountController.dispose();
    _shiftNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final inputFontSize = ResponsiveLayout.inputFontSize(context);
    final fieldPadding = ResponsiveLayout.fieldPadding(context);

    final inputDecoration = InputDecoration(
      isDense: isDesktop,
      contentPadding: fieldPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 10 : 14),
      ),
    );

    final textStyle = TextStyle(fontSize: inputFontSize);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Register Shift',
          style: TextStyle(fontSize: isDesktop ? 15 : 18),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ShiftsHistoryPage(),
              ),
            ),
            icon: Icon(
              Icons.history_rounded,
              size: isDesktop ? 18 : 22,
            ),
            label: Text(
              'History',
              style: TextStyle(fontSize: isDesktop ? 12 : 14),
            ),
          ),
        ],
      ),
      body: Align(
        alignment: isDesktop ? Alignment.topCenter : Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveLayout.cardMaxWidth(context),
          ),
          child: SingleChildScrollView(
            padding: ResponsiveLayout.pagePadding(context),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EmployeeInfoCard(
                    name: _employeeName,
                    email: _employeeEmail,
                    isDesktop: isDesktop,
                  ),

                  SizedBox(height: isDesktop ? 16 : 20),

                  _Label('Shift Number', isDesktop: isDesktop),
                  SizedBox(height: isDesktop ? 4 : 6),
                  TextFormField(
                    controller: _shiftNumberController,
                    style: textStyle,
                    decoration: inputDecoration.copyWith(
                      hintText: 'e.g. SH-001',
                      prefixIcon: Icon(
                        Icons.tag_rounded,
                        size: isDesktop ? 18 : 22,
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9\-]'),
                      ),
                    ],
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Enter shift number' : null,
                  ),

                  SizedBox(height: isDesktop ? 12 : 16),

                  _Label('System Amount (EGP)', isDesktop: isDesktop),
                  SizedBox(height: isDesktop ? 4 : 6),
                  TextFormField(
                    controller: _systemAmountController,
                    style: textStyle,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: inputDecoration.copyWith(
                      hintText: '0.00',
                      prefixIcon: Icon(
                        Icons.computer_rounded,
                        size: isDesktop ? 18 : 22,
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter system amount';
                      if (double.tryParse(v) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),

                  SizedBox(height: isDesktop ? 12 : 16),

                  _Label('Actual Amount (EGP)', isDesktop: isDesktop),
                  SizedBox(height: isDesktop ? 4 : 6),
                  TextFormField(
                    controller: _actualAmountController,
                    style: textStyle,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: inputDecoration.copyWith(
                      hintText: '0.00',
                      prefixIcon: Icon(
                        Icons.payments_outlined,
                        size: isDesktop ? 18 : 22,
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter actual amount';
                      if (double.tryParse(v) == null) return 'Enter a valid number';
                      return null;
                    },
                  ),

                  SizedBox(height: isDesktop ? 16 : 20),

                  _DifferenceCard(
                    difference: _difference,
                    isDesktop: isDesktop,
                  ),

                  SizedBox(height: isDesktop ? 20 : 24),

                  SizedBox(
                    width: double.infinity,
                    height: isDesktop ? 40 : 52,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _submitShift,
                      icon: _loading
                          ? SizedBox(
                              width: isDesktop ? 14 : 18,
                              height: isDesktop ? 14 : 18,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.save_rounded,
                              size: isDesktop ? 18 : 22,
                            ),
                      label: Text(
                        _loading ? 'Saving...' : 'Save Shift',
                        style: TextStyle(fontSize: isDesktop ? 13 : 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final bool isDesktop;

  const _Label(this.text, {required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: isDesktop ? 12 : 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }
}

class _EmployeeInfoCard extends StatelessWidget {
  final String name;
  final String email;
  final bool isDesktop;

  const _EmployeeInfoCard({
    required this.name,
    required this.email,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 12 : 16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isDesktop ? 18 : 22,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.15),
            child: Icon(
              Icons.person_rounded,
              size: isDesktop ? 18 : 22,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(width: isDesktop ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isDesktop ? 13 : 15,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isDesktop ? 11 : 13,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 8 : 10,
              vertical: isDesktop ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Shift Entry',
              style: TextStyle(
                fontSize: isDesktop ? 10 : 12,
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DifferenceCard extends StatelessWidget {
  final double difference;
  final bool isDesktop;

  const _DifferenceCard({
    required this.difference,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = difference > 0;
    final isZero = difference == 0;

    final color = isZero
        ? Colors.grey.shade500
        : isPositive
            ? const Color(0xFF059669)
            : const Color(0xFFDC2626);

    final bgColor = isZero
        ? Colors.grey.shade100
        : isPositive
            ? const Color(0xFFD1FAE5)
            : const Color(0xFFFEE2E2);

    final icon = isZero
        ? Icons.remove_circle_outline
        : isPositive
            ? Icons.arrow_upward_rounded
            : Icons.arrow_downward_rounded;

    final label = isZero ? 'No Difference' : isPositive ? 'Surplus' : 'Deficit';

    return Container(
      padding: EdgeInsets.all(isDesktop ? 14 : 18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: isDesktop ? 22 : 28),
          SizedBox(width: isDesktop ? 10 : 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Difference (Actual - System)',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: isDesktop ? 11 : 13,
                  ),
                ),
                SizedBox(height: isDesktop ? 2 : 4),
                Text(
                  '${isPositive ? '+' : ''}${difference.toStringAsFixed(2)} EGP',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: isDesktop ? 18 : 22,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 10 : 12,
              vertical: isDesktop ? 5 : 7,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: isDesktop ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
DateTime _getBusinessDate(DateTime now) {
  const cutoffHour = 4; // غيّرها لو عايز 5 أو 6

  if (now.hour < cutoffHour) {
    return now.subtract(const Duration(days: 1));
  }
  return now;
}