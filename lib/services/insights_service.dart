import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharmacy_x/services/model/attendance_log_model.dart';
import 'package:pharmacy_x/services/model/employee_monthly_insight.dart';
import 'package:pharmacy_x/services/model/shift_record_model.dart';


class InsightsService {
  final FirebaseFirestore _firestore;

  InsightsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<EmployeeMonthlyInsight>> getMonthlyInsights({
    required String monthKey, // مثال: 2026-04
  }) async {
    final attendanceSnap = await _firestore
        .collection('attendancelogs')
        .where('date', isGreaterThanOrEqualTo: '$monthKey-01')
        .where('date', isLessThan: '$monthKey-32')
        .get();

    final shiftsSnap = await _firestore
        .collection('shifts')
        .where('date', isGreaterThanOrEqualTo: '$monthKey-01')
        .where('date', isLessThan: '$monthKey-32')
        .get();

    final attendanceLogs = attendanceSnap.docs
        .map((doc) => AttendanceLogModel.fromDoc(doc))
        .toList();

    final shiftRecords = shiftsSnap.docs
        .map((doc) => ShiftRecordModel.fromDoc(doc))
        .toList();

    final Map<String, List<AttendanceLogModel>> attendanceByEmployee = {};
    final Map<String, List<ShiftRecordModel>> shiftsByEmployee = {};

    for (final log in attendanceLogs) {
      attendanceByEmployee.putIfAbsent(log.uid, () => []).add(log);
    }

    for (final shift in shiftRecords) {
      shiftsByEmployee.putIfAbsent(shift.employeeId, () => []).add(shift);
    }

    final allEmployeeIds = {
      ...attendanceByEmployee.keys,
      ...shiftsByEmployee.keys,
    };

    return allEmployeeIds.map((employeeId) {
      final logs = attendanceByEmployee[employeeId] ?? [];
      final shifts = shiftsByEmployee[employeeId] ?? [];

      final employeeName = logs.isNotEmpty
          ? logs.first.employeeName
          : shifts.isNotEmpty
              ? shifts.first.employeeName
              : 'Unknown';

      final employeeEmail = logs.isNotEmpty
          ? logs.first.employeeEmail
          : shifts.isNotEmpty
              ? shifts.first.employeeEmail
              : '';

      return EmployeeMonthlyInsight(
        employeeId: employeeId,
        employeeName: employeeName,
        employeeEmail: employeeEmail,
        monthKey: monthKey,
        attendanceDays: logs.length,
        lateCount: logs.where((e) => e.isLate).length,
        lateMinutesTotal: logs.fold(0, (sum, e) => sum + e.lateMinutes),
        openAttendanceCount: logs.where((e) => e.isOnline).length,
        shiftCount: shifts.length,
        totalSystemAmount:
            shifts.fold(0, (sum, e) => sum + e.systemAmount),
        totalActualAmount:
            shifts.fold(0, (sum, e) => sum + e.actualAmount),
        totalDifference:
            shifts.fold(0, (sum, e) => sum + e.difference),
      );
    }).toList();
  }
}