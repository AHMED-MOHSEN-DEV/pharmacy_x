import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftRecordModel {
  final String id;
  final String employeeId;
  final String employeeName;
  final String employeeEmail;
  final String shiftNumber;
  final String date;
  final String time;
  final double systemAmount;
  final double actualAmount;
  final double difference;
  final DateTime? createdAt;

  const ShiftRecordModel({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.shiftNumber,
    required this.date,
    required this.time,
    required this.systemAmount,
    required this.actualAmount,
    required this.difference,
    required this.createdAt,
  });

  factory ShiftRecordModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};

    return ShiftRecordModel(
      id: doc.id,
      employeeId: (data['employeeId'] ?? '').toString(),
      employeeName: (data['employeeName'] ?? '').toString(),
      employeeEmail: (data['employeeEmail'] ?? '').toString(),
      shiftNumber: (data['shiftNumber'] ?? '').toString(),
      date: (data['date'] ?? '').toString(),
      time: (data['time'] ?? '').toString(),
      systemAmount: (data['systemAmount'] as num?)?.toDouble() ?? 0,
      actualAmount: (data['actualAmount'] as num?)?.toDouble() ?? 0,
      difference: (data['difference'] as num?)?.toDouble() ?? 0,
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}