import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharmacy_x/services/model/employee_schedule_model.dart';

class EmployeeScheduleService {
  final FirebaseFirestore _firestore;

  EmployeeScheduleService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _schedules =>
      _firestore.collection('employee_schedules');

  Future<List<Map<String, dynamic>>> getEmployees() async {
    final snap = await _users.orderBy('name').get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'name': (data['name'] ?? 'Unknown').toString(),
        'email': (data['email'] ?? '').toString(),
      };
    }).toList();
  }

  Future<EmployeeScheduleModel?> getSchedule(String employeeId) async {
    final doc = await _schedules.doc(employeeId).get();
    if (!doc.exists) return null;
    return EmployeeScheduleModel.fromDoc(doc);
  }

  Future<void> saveSchedule(EmployeeScheduleModel schedule) async {
    await _schedules.doc(schedule.employeeId).set(schedule.toMap());
  }

  Stream<List<EmployeeScheduleModel>> getSchedulesStream() {
    return _schedules.snapshots().map(
      (snap) => snap.docs.map((doc) => EmployeeScheduleModel.fromDoc(doc)).toList(),
    );
  }
}