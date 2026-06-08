import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/attendance_service.dart';
import '../../widgets/responsive_field.dart';

class AdminAttendancePage extends StatelessWidget {
  const AdminAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Attendance Monitor',
            style: TextStyle(fontSize: isDesktop ? 15 : 18),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: TabBar(
              tabs: const [
                Tab(
                  icon: Icon(Icons.circle, color: Color(0xFF059669), size: 10),
                  text: 'Live',
                ),
                Tab(
                  icon: Icon(Icons.calendar_today_rounded),
                  text: 'Today',
                ),
              ],
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 12 : 14,
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _LiveTab(isDesktop: isDesktop),
            _TodayTab(isDesktop: isDesktop),
          ],
        ),
      ),
    );
  }
}

class _LiveTab extends StatelessWidget {
  final bool isDesktop;

  const _LiveTab({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AttendanceService.getLiveAttendanceStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load live attendance'));
        }

        final docs = (snapshot.data?.docs ?? [])
            .where((d) {
              final data = d.data();
              return data['uid'] != null &&
                  data['employeeName'] != null &&
                  data['isOnline'] == true;
            })
            .toList();

        return Align(
          alignment: isDesktop ? Alignment.topCenter : Alignment.topLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 900 : double.infinity,
            ),
            child: ListView(
              padding: EdgeInsets.all(isDesktop ? 20 : 16),
              children: [
                _OnlineBanner(count: docs.length, isDesktop: isDesktop),
                SizedBox(height: isDesktop ? 16 : 20),
                if (docs.isEmpty)
                  Center(
                    child: Column(
                      children: [
                        SizedBox(height: isDesktop ? 40 : 60),
                        Icon(
                          Icons.people_outline,
                          size: isDesktop ? 42 : 56,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No employees are currently online',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: isDesktop ? 13 : 15,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...docs.map(
                    (doc) => Padding(
                      padding: EdgeInsets.only(bottom: isDesktop ? 8 : 10),
                      child: _LiveEmployeeCard(
                        
                        data: doc.data(),
                        isDesktop: isDesktop,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OnlineBanner extends StatelessWidget {
  final int count;
  final bool isDesktop;

  const _OnlineBanner({
    required this.count,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 14 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
        ),
        borderRadius: BorderRadius.circular(isDesktop ? 14 : 20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Currently Online',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isDesktop ? 12 : 14,
                  ),
                ),
                SizedBox(height: isDesktop ? 4 : 6),
                Text(
                  '$count ${count == 1 ? 'employee' : 'employees'}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isDesktop ? 22 : 28,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(isDesktop ? 12 : 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_alt_rounded,
              color: Colors.white,
              size: isDesktop ? 24 : 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveEmployeeCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDesktop;

  const _LiveEmployeeCard({
    required this.data,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['employeeName'] ?? 'Unknown').toString();
    final email = (data['employeeEmail'] ?? '').toString();
    final branchName = (data['branchName'] ?? 'Unknown Branch').toString();

    final checkIn = data['checkInTime'] is Timestamp
        ? (data['checkInTime'] as Timestamp).toDate()
        : null;

    final checkInStr =
        checkIn != null ? DateFormat('hh:mm a').format(checkIn) : '--';

    String duration = '--';
    if (checkIn != null) {
      final diff = DateTime.now().difference(checkIn);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      duration = '${h}h ${m}m';
    }

    return Container(
      padding: EdgeInsets.all(isDesktop ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 16),
        border: Border.all(
          color: const Color(0xFF059669).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 8 : 10,
            height: isDesktop ? 8 : 10,
            margin: EdgeInsets.only(right: isDesktop ? 10 : 12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF059669),
            ),
          ),
          CircleAvatar(
            radius: isDesktop ? 18 : 22,
            backgroundColor: const Color(0xFF059669).withOpacity(0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: const Color(0xFF059669),
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 14 : 16,
              ),
            ),
          ),
          SizedBox(width: isDesktop ? 10 : 12),
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
                      fontSize: isDesktop ? 11 : 12,
                    ),
                  ),
                Text(
                  branchName,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: isDesktop ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                checkInStr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 13 : 15,
                  color: const Color(0xFF059669),
                ),
              ),
              Text(
                duration,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: isDesktop ? 11 : 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayTab extends StatelessWidget {
  final bool isDesktop;

  const _TodayTab({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AttendanceService.getTodayAttendanceStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Failed to load today attendance'));
        }

        final docs = (snapshot.data?.docs ?? [])
            .where((d) {
              final data = d.data();
              return data['uid'] != null && data['employeeName'] != null;
            })
            .toList();

        final onlineCount =
            docs.where((d) => d.data()['isOnline'] == true).length;
        final offlineCount =
            docs.where((d) => d.data()['isOnline'] != true).length;

        return Align(
          alignment: isDesktop ? Alignment.topCenter : Alignment.topLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 900 : double.infinity,
            ),
            child: ListView(
              padding: EdgeInsets.all(isDesktop ? 20 : 16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total',
                        value: '${docs.length}',
                        icon: Icons.people_outline,
                        color: const Color(0xFF2563EB),
                        isDesktop: isDesktop,
                      ),
                    ),
                    
                    SizedBox(width: isDesktop ? 10 : 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Online',
                        value: '$onlineCount',
                        icon: Icons.circle,
                        color: const Color(0xFF059669),
                        isDesktop: isDesktop,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 10 : 12),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Checked Out',
                        value: '$offlineCount',
                        icon: Icons.logout_rounded,
                        color: const Color(0xFFF59E0B),
                        isDesktop: isDesktop,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 16 : 20),
                if (docs.isEmpty)
                  Center(
                    child: Text(
                      'No attendance records today',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: isDesktop ? 13 : 15,
                      ),
                    ),
                  )
                else
                  ...docs.map(
                    (doc) => Padding(
                      padding: EdgeInsets.only(bottom: isDesktop ? 8 : 10),
                      child: _TodayRecordCard(
                        docId: doc.id,
                        data: doc.data(),
                        isDesktop: isDesktop,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDesktop;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isDesktop ? 12 : 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: isDesktop ? 18 : 22),
          SizedBox(height: isDesktop ? 6 : 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 22 : 26,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: isDesktop ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayRecordCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDesktop;
  final String docId;

  const _TodayRecordCard({
    required this.docId,
    required this.data,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['employeeName'] ?? 'Unknown').toString();
    final branchName = (data['branchName'] ?? 'Unknown Branch').toString();
    final isOnline = data['isOnline'] == true;
    final isLate = data['isLate'] == true;
    final lateMinutes = (data['lateMinutes'] as num?)?.toInt() ?? 0;

    final checkIn = data['checkInTime'] is Timestamp
        ? (data['checkInTime'] as Timestamp).toDate()
        : null;

    final checkOut = data['checkOutTime'] is Timestamp
        ? (data['checkOutTime'] as Timestamp).toDate()
        : null;

    final minutes = (data['workDurationMinutes'] as num?)?.toInt();

    final checkInStr =
        checkIn != null ? DateFormat('hh:mm a').format(checkIn) : '--';

    final checkOutStr = checkOut != null
        ? DateFormat('hh:mm a').format(checkOut)
        : isOnline
            ? 'Active'
            : '--';

    final durationStr = minutes != null
        ? '${minutes ~/ 60}h ${minutes % 60}m'
        : isOnline
            ? 'Active'
            : '--';

    return Container(
      padding: EdgeInsets.all(isDesktop ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 12 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: isDesktop ? 18 : 22,
            backgroundColor: isOnline
                ? const Color(0xFF059669).withOpacity(0.12)
                : Colors.grey.withOpacity(0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isDesktop ? 14 : 16,
                color: isOnline
                    ? const Color(0xFF059669)
                    : Colors.grey.shade600,
              ),
            ),
          ),
          SizedBox(width: isDesktop ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isDesktop ? 13 : 14,
                        ),
                      ),
                    ),
                    if (isLate)
                      _StatusChip(
                        label: lateMinutes > 0 ? 'Late ${lateMinutes}m' : 'Late',
                        color: const Color(0xFFF59E0B),
                        isDesktop: isDesktop,
                      )
                    else
                      _StatusChip(
                        label: 'On Time',
                        color: const Color(0xFF2563EB),
                        isDesktop: isDesktop,
                      ),
                    if (isOnline) ...[
                      const SizedBox(width: 6),
                      _StatusChip(
                        label: 'Online',
                        color: const Color(0xFF059669),
                        isDesktop: isDesktop,
                      ),
                    ],
                  ],
                ),
                SizedBox(height: isDesktop ? 3 : 4),
                Text(
                  branchName,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: isDesktop ? 11 : 12,
                  ),
                ),
                Text(
                  'In: $checkInStr  Out: $checkOutStr',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: isDesktop ? 11 : 12,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                durationStr,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isDesktop ? 13 : 15,
                  color: isOnline
                      ? const Color(0xFF059669)
                      : Colors.grey.shade700,
                ),
              ),
              SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Delete Record"),
                      content: const Text(
                        "Are you sure you want to delete this record?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await AttendanceService.deleteLog(docId);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                    size: isDesktop ? 18 : 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDesktop;

  const _StatusChip({
    required this.label,
    required this.color,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 6 : 8,
        vertical: isDesktop ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: isDesktop ? 9 : 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}