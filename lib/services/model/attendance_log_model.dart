import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceLogModel {
  final String id;
  final String uid;
  final String employeeName;
  final String employeeEmail;
  final String branchName;
  final String date;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final bool isOnline;
  final bool isLate;
  final int lateMinutes;
  final double? latitude;
  final double? longitude;
  final int? workDurationMinutes;

  const AttendanceLogModel({
    required this.id,
    required this.uid,
    required this.employeeName,
    required this.employeeEmail,
    required this.branchName,
    required this.date,
    required this.checkInTime,
    required this.checkOutTime,
    required this.isOnline,
    required this.isLate,
    required this.lateMinutes,
    required this.latitude,
    required this.longitude,
    required this.workDurationMinutes,
  });

  factory AttendanceLogModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return AttendanceLogModel(
      id: doc.id,
      uid: (data['uid'] ?? '').toString(),
      employeeName: (data['employeeName'] ?? '').toString(),
      employeeEmail: (data['employeeEmail'] ?? '').toString(),
      branchName: (data['branchName'] ?? '').toString(),
      date: (data['date'] ?? '').toString(),
      checkInTime: data['checkInTime'] is Timestamp
          ? (data['checkInTime'] as Timestamp).toDate()
          : null,
      checkOutTime: data['checkOutTime'] is Timestamp
          ? (data['checkOutTime'] as Timestamp).toDate()
          : null,
      isOnline: data['isOnline'] == true,
      isLate: data['isLate'] == true,
      lateMinutes: (data['lateMinutes'] as num?)?.toInt() ?? 0,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      workDurationMinutes: (data['workDurationMinutes'] as num?)?.toInt(),
    );
  }
}