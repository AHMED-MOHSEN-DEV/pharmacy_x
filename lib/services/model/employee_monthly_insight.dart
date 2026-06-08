class EmployeeMonthlyInsight {
  final String employeeId;
  final String employeeName;
  final String employeeEmail;
  final String monthKey;

  final int attendanceDays;
  final int lateCount;
  final int lateMinutesTotal;
  final int openAttendanceCount;

  final int shiftCount;
  final double totalSystemAmount;
  final double totalActualAmount;
  final double totalDifference;

  const EmployeeMonthlyInsight({
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.monthKey,
    required this.attendanceDays,
    required this.lateCount,
    required this.lateMinutesTotal,
    required this.openAttendanceCount,
    required this.shiftCount,
    required this.totalSystemAmount,
    required this.totalActualAmount,
    required this.totalDifference,
  });
}