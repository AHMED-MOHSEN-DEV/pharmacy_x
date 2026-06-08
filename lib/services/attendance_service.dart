import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _logs =>
      _firestore.collection('attendancelogs');

  static CollectionReference<Map<String, dynamic>> get _schedules =>
      _firestore.collection('employee_schedules');

  static Future<Map<String, dynamic>?> getEmployeeSchedule(String employeeId) async {
    try {
      final doc = await _schedules.doc(employeeId).get();
      if (!doc.exists) return null;
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  static int _calculateLateMinutes({
    required DateTime now,
    required String startTime,
    required int graceMinutes,
  }) {
    final parts = startTime.split(':');
    final startHour = int.tryParse(parts[0]) ?? 9;
    final startMinute = int.tryParse(parts[1]) ?? 0;

    final scheduledStart = DateTime(
      now.year,
      now.month,
      now.day,
      startHour,
      startMinute,
    ).add(Duration(minutes: graceMinutes));

    if (!now.isAfter(scheduledStart)) return 0;
    return now.difference(scheduledStart).inMinutes;
  }

  static Future<String?> checkIn({
    required double lat,
    required double lng,
    required String employeeName,
    required String branchName,
    required bool isOutsideGeofence,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      final today = DateFormat('yyyy-MM-dd').format(now);

      final existing = await _logs
          .where('uid', isEqualTo: user.uid)
          .where('date', isEqualTo: today)
          .where('isOnline', isEqualTo: true)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        return existing.docs.first.id;
      }

      final schedule = await getEmployeeSchedule(user.uid);

      final startTime = (schedule?['startTime'] ?? '09:00').toString();
      final endTime = (schedule?['endTime'] ?? '17:00').toString();
      final graceMinutes = (schedule?['graceMinutes'] as num?)?.toInt() ?? 10;
      final scheduleBranch = (schedule?['branchName'] ?? branchName).toString();

      final lateMinutes = _calculateLateMinutes(
        now: now,
        startTime: startTime,
        graceMinutes: graceMinutes,
      );

      final isLate = lateMinutes > 0;

      final docRef = await _logs.add({
        'uid': user.uid,
        'employeeName': employeeName,
        'employeeEmail': user.email ?? '',
        'branchName': branchName,
        'scheduledBranchName': scheduleBranch,
        'scheduledStartTime': startTime,
        'scheduledEndTime': endTime,
        'graceMinutes': graceMinutes,
        'checkInTime': FieldValue.serverTimestamp(),
        'checkOutTime': null,
        'createdAt': FieldValue.serverTimestamp(),
        'date': today,
        'isOnline': true,
        'isLate': isLate,
        'lateMinutes': lateMinutes,
        'isOutsideGeofence': isOutsideGeofence,
        'latitude': lat,
        'longitude': lng,
        'workDurationMinutes': null,
      });

      return docRef.id;
    } catch (_) {
      return null;
    }
  }

  static Future<void> checkOut(String docId) async {
    try {
      final docRef = _logs.doc(docId);
      final snap = await docRef.get();
      if (!snap.exists) return;

      final data = snap.data();
      if (data == null) return;

      final checkInTs = data['checkInTime'] as Timestamp?;
      final checkIn = checkInTs?.toDate();
      final now = DateTime.now();

      int? workDurationMinutes;
      if (checkIn != null) {
        workDurationMinutes = now.difference(checkIn).inMinutes;
      }

      await docRef.update({
        'checkOutTime': FieldValue.serverTimestamp(),
        'isOnline': false,
        'workDurationMinutes': workDurationMinutes,
      });
    } catch (_) {}
  }

  static Future<DocumentSnapshot<Map<String, dynamic>>?> getTodayActiveLog() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final query = await _logs
          .where('uid', isEqualTo: user.uid)
          .where('date', isEqualTo: today)
          .where('isOnline', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return query.docs.first;
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteLog(String docId) async {
    try {
      await _logs.doc(docId).delete();
    } catch (_) {}
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getMyLogsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _logs.where('uid', isEqualTo: user.uid).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getLiveAttendanceStream() {
    return _logs.where('isOnline', isEqualTo: true).snapshots();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getTodayAttendanceStream() {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _logs.where('date', isEqualTo: today).snapshots();
  }
}