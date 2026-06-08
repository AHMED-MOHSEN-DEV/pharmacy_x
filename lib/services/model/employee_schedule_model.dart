import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeScheduleModel {
  final String employeeId;
  final String employeeName;
  final String employeeEmail;
  final String branchName;
  final String startTime;
  final String endTime;
  final int graceMinutes;
  final DateTime? updatedAt;

  const EmployeeScheduleModel({
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.branchName,
    required this.startTime,
    required this.endTime,
    required this.graceMinutes,
    required this.updatedAt,
  });

  factory EmployeeScheduleModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return EmployeeScheduleModel(
      employeeId: doc.id,
      employeeName: (data['employeeName'] ?? '').toString(),
      employeeEmail: (data['employeeEmail'] ?? '').toString(),
      branchName: (data['branchName'] ?? '').toString(),
      startTime: (data['startTime'] ?? '09:00').toString(),
      endTime: (data['endTime'] ?? '17:00').toString(),
      graceMinutes: (data['graceMinutes'] as num?)?.toInt() ?? 10,
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'employeeName': employeeName,
      'employeeEmail': employeeEmail,
      'branchName': branchName,
      'startTime': startTime,
      'endTime': endTime,
      'graceMinutes': graceMinutes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}