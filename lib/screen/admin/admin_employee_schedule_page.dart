import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pharmacy_x/services/employee_schedule_service.dart';
import 'package:pharmacy_x/services/model/employee_schedule_model.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_radius.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../widgets/responsive_field.dart';

class AdminEmployeeSchedulePage extends StatefulWidget {
  const AdminEmployeeSchedulePage({super.key});

  @override
  State<AdminEmployeeSchedulePage> createState() => _AdminEmployeeSchedulePageState();
}

class _AdminEmployeeSchedulePageState extends State<AdminEmployeeSchedulePage> {
  final EmployeeScheduleService _service = EmployeeScheduleService();

  List<Map<String, dynamic>> _employees = [];
  String? _selectedEmployeeId;
  String _selectedEmployeeName = '';
  String _selectedEmployeeEmail = '';

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  final TextEditingController _branchController = TextEditingController();
  final TextEditingController _graceController = TextEditingController(text: '10');

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _loading = true);
    final employees = await _service.getEmployees();
    setState(() {
      _employees = employees;
      _loading = false;
    });
  }

  Future<void> _loadScheduleForEmployee(String employeeId) async {
    final employee = _employees.firstWhere((e) => e['id'] == employeeId);
    final schedule = await _service.getSchedule(employeeId);

    setState(() {
      _selectedEmployeeName = employee['name'];
      _selectedEmployeeEmail = employee['email'];

      if (schedule != null) {
        final startParts = schedule.startTime.split(':');
        final endParts = schedule.endTime.split(':');

        _startTime = TimeOfDay(
          hour: int.tryParse(startParts[0]) ?? 9,
          minute: int.tryParse(startParts[1]) ?? 0,
        );

        _endTime = TimeOfDay(
          hour: int.tryParse(endParts[0]) ?? 17,
          minute: int.tryParse(endParts[1]) ?? 0,
        );

        _branchController.text = schedule.branchName;
        _graceController.text = schedule.graceMinutes.toString();
      } else {
        _startTime = const TimeOfDay(hour: 9, minute: 0);
        _endTime = const TimeOfDay(hour: 17, minute: 0);
        _branchController.clear();
        _graceController.text = '10';
      }
    });
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _pickTime({
    required bool isStart,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_selectedEmployeeId == null) return;

    setState(() => _saving = true);

    final model = EmployeeScheduleModel(
      employeeId: _selectedEmployeeId!,
      employeeName: _selectedEmployeeName,
      employeeEmail: _selectedEmployeeEmail,
      branchName: _branchController.text.trim(),
      startTime: _formatTime(_startTime),
      endTime: _formatTime(_endTime),
      graceMinutes: int.tryParse(_graceController.text.trim()) ?? 10,
      updatedAt: null,
    );

    await _service.saveSchedule(model);

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Schedule saved successfully'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _branchController.dispose();
    _graceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Employee Schedules', style: AppTextStyles.title),
        actions: [
          IconButton(
            onPressed: _loadEmployees,
            icon: const Icon(Icons.refresh_rounded),
            color: AppColors.primary,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Align(
              alignment: isDesktop ? Alignment.topCenter : Alignment.topLeft,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 900 : double.infinity,
                ),
                child: ListView(
                  padding: EdgeInsets.all(isDesktop ? AppSpacing.xxl : AppSpacing.lg),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedEmployeeId,
                        decoration: const InputDecoration(
                          labelText: 'Select Employee',
                        ),
                        items: _employees.map((employee) {
                          return DropdownMenuItem<String>(
                            value: employee['id'],
                            child: Text(employee['name']),
                          );
                        }).toList(),
                       onChanged: (value) async {
                        if (value == null) return;

                        setState(() {
                       _selectedEmployeeId = value;
                                  });

                       await _loadScheduleForEmployee(value);
}
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_selectedEmployeeId != null)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selectedEmployeeName, style: AppTextStyles.bodyMedium),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _selectedEmployeeEmail.isEmpty
                                  ? 'No email'
                                  : _selectedEmployeeEmail,
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: _TimeTile(
                                    label: 'Start Time',
                                    value: _formatTime(_startTime),
                                    color: AppColors.primary,
                                    onTap: () => _pickTime(isStart: true),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _TimeTile(
                                    label: 'End Time',
                                    value: _formatTime(_endTime),
                                    color: AppColors.teal,
                                    onTap: () => _pickTime(isStart: false),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            TextField(
                              controller: _branchController,
                              decoration: const InputDecoration(
                                labelText: 'Branch Name',
                                hintText: 'e.g. Nasr City',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextField(
                              controller: _graceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Grace Minutes',
                                hintText: '10',
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _save,
                                icon: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_rounded),
                                label: Text(_saving ? 'Saving...' : 'Save Schedule'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(color: color)),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: AppTextStyles.bodyMedium.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}