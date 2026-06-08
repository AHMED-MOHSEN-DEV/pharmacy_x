import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../services/attendance_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/responsive_field.dart';

class EmployeeCheckInPage extends StatefulWidget {
  const EmployeeCheckInPage({super.key});

  @override
  State<EmployeeCheckInPage> createState() => _EmployeeCheckInPageState();
}

class _EmployeeCheckInPageState extends State<EmployeeCheckInPage> {
  bool _loading = true;
  Position? _position;
  bool _isInsideGeofence = false;
  double _distanceMeters = 0;

  bool _isCheckedIn = false;
  String? _activeDocId;
  DateTime? _checkInTime;

  Timer? _durationTimer;
  String _liveDuration = '00:00:00';

  StreamSubscription<Position>? _positionSub;
  final MapController _mapController = MapController();

  bool _outsideWarningSent = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _checkExistingLog();
    await _fetchLocation();
    _startPositionStream();
  }

  Future<void> _checkExistingLog() async {
    final doc = await AttendanceService.getTodayActiveLog();
    if (doc != null && doc.exists && mounted) {
      final data = doc.data();
      final checkIn = data?['checkInTime'] is Timestamp
          ? (data!['checkInTime'] as Timestamp).toDate()
          : null;

      setState(() {
        _isCheckedIn = true;
        _activeDocId = doc.id;
        _checkInTime = checkIn;
      });

      _startDurationTimer();
    }
  }

  Future<void> _fetchLocation() async {
    final pos = await LocationService.getCurrentPosition();

    if (pos != null && mounted) {
      final nearest = LocationService.nearestBranch(pos.latitude, pos.longitude);

      final dist = nearest != null
          ? LocationService.distanceFromBranch(
              pos.latitude,
              pos.longitude,
              nearest,
            )
          : double.infinity;

      final inside = dist <= LocationService.geofenceRadius;

      setState(() {
        _position = pos;
        _distanceMeters = dist;
        _isInsideGeofence = inside;
        _loading = false;
      });

      try {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
      } catch (_) {}
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startPositionStream() {
    _positionSub = LocationService.getPositionStream().listen((pos) {
      if (!mounted) return;

      final nearest = LocationService.nearestBranch(pos.latitude, pos.longitude);

      final dist = nearest != null
          ? LocationService.distanceFromBranch(
              pos.latitude,
              pos.longitude,
              nearest,
            )
          : double.infinity;

      final inside = dist <= LocationService.geofenceRadius;

      setState(() {
        _position = pos;
        _distanceMeters = dist;
        _isInsideGeofence = inside;
      });

      if (_isCheckedIn && !inside && !_outsideWarningSent) {
        _outsideWarningSent = true;
        _showOutsideWarning();
      }

      if (inside && _outsideWarningSent) {
        _outsideWarningSent = false;
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_checkInTime == null || !mounted) return;

      final diff = DateTime.now().difference(_checkInTime!);
      final h = diff.inHours.toString().padLeft(2, '0');
      final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
      final s = (diff.inSeconds % 60).toString().padLeft(2, '0');

      setState(() => _liveDuration = '$h:$m:$s');
    });
  }

  void _showOutsideWarning() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚠️ You have left the pharmacy zone!',
          style: AppTextStyles.body.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        action: SnackBarAction(
          label: 'Check Out',
          onPressed: _doCheckOut,
          textColor: Colors.white,
        ),
      ),
    );
  }

  Future<String> _getEmployeeName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return 'Employee';

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      return doc.data()?['name'] ?? user.displayName ?? 'Employee';
    } catch (_) {
      return 'Employee';
    }
  }

  Future<void> _doCheckIn() async {
    if (_position == null) return;

    setState(() => _loading = true);

    final name = await _getEmployeeName();
    final branch = LocationService.nearestBranch(
      _position!.latitude,
      _position!.longitude,
    );

    final diff = branch == null
        ? 999999.0
        : LocationService.distanceFromBranch(
            _position!.latitude,
            _position!.longitude,
            branch,
          );

   final isOutsideGeofence = diff > LocationService.geofenceRadius;

final docId = await AttendanceService.checkIn(
  lat: _position!.latitude,
  lng: _position!.longitude,
  employeeName: name,
  branchName: branch?.name ?? 'Unknown Branch',
  isOutsideGeofence: isOutsideGeofence,
);

    if (docId != null && mounted) {
      final freshDoc = await FirebaseFirestore.instance
          .collection('attendancelogs')
          .doc(docId)
          .get();

      final data = freshDoc.data();
      final checkIn = data?['checkInTime'] is Timestamp
          ? (data!['checkInTime'] as Timestamp).toDate()
          : null;

      setState(() {
        _isCheckedIn = true;
        _activeDocId = docId;
        _checkInTime = checkIn ?? DateTime.now();
        _loading = false;
      });

      _startDurationTimer();
      _showSnack('✅ Checked in successfully!', AppColors.success);
    } else {
      if (mounted) setState(() => _loading = false);
      _showSnack('Failed to check in', AppColors.error);
    }
  }

  Future<void> _doCheckOut() async {
    if (_activeDocId == null) return;

    setState(() => _loading = true);

    await AttendanceService.checkOut(_activeDocId!);
    _durationTimer?.cancel();

    if (mounted) {
      setState(() {
        _isCheckedIn = false;
        _activeDocId = null;
        _checkInTime = null;
        _liveDuration = '00:00:00';
        _outsideWarningSent = false;
        _loading = false;
      });

      _showSnack('👋 Checked out. See you tomorrow!', AppColors.primary);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: AppTextStyles.body.copyWith(color: Colors.white),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Attendance Check-In', style: AppTextStyles.title),
      ),
      body: _loading && _position == null
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : isDesktop
              ? Row(
                  children: [
                    Expanded(flex: 2, child: _buildMap()),
                    SizedBox(width: 340, child: _buildControls(isDesktop: true)),
                  ],
                )
              : Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.42,
                      child: _buildMap(),
                    ),
                    Expanded(child: _buildControls(isDesktop: false)),
                  ],
                ),
    );
  }

  Widget _buildMap() {
    final hasBranches = LocationService.branches.isNotEmpty;

    final defaultCenter = hasBranches
        ? LatLng(
            LocationService.branches.first.lat,
            LocationService.branches.first.lng,
          )
        : const LatLng(30.0444, 31.2357);

    final currentLatLng = _position != null
        ? LatLng(_position!.latitude, _position!.longitude)
        : defaultCenter;

    final nearestBranch = _position != null
        ? LocationService.nearestBranch(_position!.latitude, _position!.longitude)
        : (hasBranches ? LocationService.branches.first : null);

    final branchCenter = nearestBranch != null
        ? LatLng(nearestBranch.lat, nearestBranch.lng)
        : defaultCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _position != null ? currentLatLng : branchCenter,
        initialZoom: 16,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.marwa.pharmacy',
        ),
        if (hasBranches)
          CircleLayer(
            circles: LocationService.branches.map((branch) {
              final isNearest =
                  nearestBranch != null && nearestBranch.name == branch.name;

              return CircleMarker(
                point: LatLng(branch.lat, branch.lng),
                radius: LocationService.geofenceRadius,
                useRadiusInMeter: true,
                color: (isNearest
                        ? (_isInsideGeofence ? AppColors.success : AppColors.error)
                        : AppColors.teal)
                    .withOpacity(0.12),
                borderColor: isNearest
                    ? (_isInsideGeofence ? AppColors.success : AppColors.error)
                    : AppColors.teal,
                borderStrokeWidth: isNearest ? 2.5 : 1.5,
              );
            }).toList(),
          ),
        MarkerLayer(
          markers: [
            if (hasBranches)
              ...LocationService.branches.map((branch) {
                final isNearest =
                    nearestBranch != null && nearestBranch.name == branch.name;

                return Marker(
                  point: LatLng(branch.lat, branch.lng),
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.local_hospital_rounded,
                    color: isNearest ? AppColors.teal : Colors.grey,
                    size: isNearest ? 38 : 32,
                  ),
                );
              }),
            if (_position != null)
              Marker(
                point: currentLatLng,
                width: 48,
                height: 48,
                child: Icon(
                  Icons.person_pin_circle_rounded,
                  color: _isInsideGeofence ? AppColors.success : AppColors.error,
                  size: 44,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildControls({required bool isDesktop}) {
    final pad = isDesktop ? AppSpacing.xl : AppSpacing.lg;

    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GeofenceStatusBadge(
            isInside: _isInsideGeofence,
            distance: _distanceMeters,
            isDesktop: isDesktop,
          ),
          SizedBox(height: isDesktop ? AppSpacing.lg : AppSpacing.xl),
          if (_isCheckedIn) ...[
            _DurationCard(
              duration: _liveDuration,
              checkInTime: _checkInTime,
              isDesktop: isDesktop,
            ),
            SizedBox(height: isDesktop ? AppSpacing.md : AppSpacing.lg),
          ],
          SizedBox(
            width: double.infinity,
            height: isDesktop ? 42 : 56,
            child: _isCheckedIn
                ? ElevatedButton.icon(
                    onPressed: _loading ? null : _doCheckOut,
                    icon: Icon(Icons.logout_rounded, size: isDesktop ? 18 : 22),
                    label: const Text('Check Out'),
                  )
                : ElevatedButton.icon(
                    onPressed: (_isInsideGeofence && !_loading) ? _doCheckIn : null,
                    icon: Icon(Icons.login_rounded, size: isDesktop ? 18 : 22),
                    label: Text(_isInsideGeofence ? 'Check In' : 'Outside Zone'),
                  ),
          ),
          SizedBox(height: isDesktop ? AppSpacing.md : AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: isDesktop ? 36 : 46,
            child: OutlinedButton.icon(
              onPressed: _fetchLocation,
              icon: Icon(Icons.my_location_rounded, size: isDesktop ? 16 : 20),
              label: const Text('Refresh Location'),
            ),
          ),
          SizedBox(height: isDesktop ? AppSpacing.xl : AppSpacing.section),
          Text('My Attendance History', style: AppTextStyles.title),
          SizedBox(height: isDesktop ? AppSpacing.sm : AppSpacing.md),
          _MyHistoryList(isDesktop: isDesktop),
        ],
      ),
    );
  }
}

class _GeofenceStatusBadge extends StatelessWidget {
  final bool isInside;
  final double distance;
  final bool isDesktop;

  const _GeofenceStatusBadge({
    required this.isInside,
    required this.distance,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final color = isInside ? AppColors.success : AppColors.error;
    final bg = isInside
        ? AppColors.success.withOpacity(0.10)
        : AppColors.error.withOpacity(0.08);

    return Container(
      padding: EdgeInsets.all(isDesktop ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isInside
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              color: color,
              size: isDesktop ? 20 : 24,
            ),
          ),
          SizedBox(width: isDesktop ? AppSpacing.md : AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isInside ? 'Inside Pharmacy Zone' : 'Outside Pharmacy Zone',
                  style: AppTextStyles.bodyMedium.copyWith(color: color),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  distance.isFinite
                      ? '${distance.toStringAsFixed(0)} m from pharmacy'
                      : 'Branch location unavailable',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationCard extends StatelessWidget {
  final String duration;
  final DateTime? checkInTime;
  final bool isDesktop;

  const _DurationCard({
    required this.duration,
    required this.checkInTime,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final checkInStr =
        checkInTime != null ? DateFormat('hh:mm a').format(checkInTime!) : '--';

    return Container(
      padding: EdgeInsets.all(isDesktop ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Time at Work',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
                SizedBox(height: isDesktop ? AppSpacing.xs : AppSpacing.sm),
                Text(
                  duration,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: isDesktop ? 24 : 30,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Check-in',
                style: AppTextStyles.caption.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                checkInStr,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: isDesktop ? 16 : 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyHistoryList extends StatelessWidget {
  final bool isDesktop;

  const _MyHistoryList({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AttendanceService.getMyLogsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.warning.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.warning,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'History unavailable — check Firestore index or rules.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 36,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('No history yet', style: AppTextStyles.caption),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, __) =>
              SizedBox(height: isDesktop ? AppSpacing.sm : AppSpacing.md),
          itemBuilder: (_, i) {
            final data = docs[i].data();
            return _HistoryTile(data: data, isDesktop: isDesktop);
          },
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDesktop;

  const _HistoryTile({
    required this.data,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    final date = (data['date'] ?? '-').toString();
    final branchName = (data['branchName'] ?? 'Unknown Branch').toString();
    final isLate = data['isLate'] == true;

    final checkIn = data['checkInTime'] is Timestamp
        ? (data['checkInTime'] as Timestamp).toDate()
        : null;

    final checkOut = data['checkOutTime'] is Timestamp
        ? (data['checkOutTime'] as Timestamp).toDate()
        : null;

    final isOnline = data['isOnline'] == true;
    final minutes = data['workDurationMinutes'] as int?;

    final checkInStr =
        checkIn != null ? DateFormat('hh:mm a').format(checkIn) : '--';

    final checkOutStr =
        checkOut != null ? DateFormat('hh:mm a').format(checkOut) : '--';

    final durationStr = minutes != null
        ? '${minutes ~/ 60}h ${minutes % 60}m'
        : isOnline
            ? 'Active'
            : '--';

    return Container(
      padding: EdgeInsets.all(isDesktop ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 8 : 10,
            height: isDesktop ? 8 : 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? AppColors.success : AppColors.textLight,
            ),
          ),
          SizedBox(width: isDesktop ? AppSpacing.md : AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        date,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: isDesktop ? 12 : 14,
                        ),
                      ),
                    ),
                    if (isLate)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          'Late',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                            fontSize: isDesktop ? 9 : 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  branchName,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: isDesktop ? 10 : 12,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'In: $checkInStr  Out: $checkOutStr',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: isDesktop ? 10 : 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            durationStr,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: isDesktop ? 12 : 14,
              color: isOnline ? AppColors.success : AppColors.textSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}