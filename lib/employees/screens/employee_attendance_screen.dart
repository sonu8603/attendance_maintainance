import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../provider/employee_profile_provider.dart';
import '../provider/attendance_provider.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return profileAsync.when(
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) {
        final employeeId = profile?['employeeId'] ?? '';
        return _AttendanceContent(
            employeeId: employeeId, profile: profile ?? {});
      },
    );
  }
}

class _AttendanceContent extends ConsumerStatefulWidget {
  final String employeeId;
  final Map<String, dynamic> profile;

  const _AttendanceContent(
      {required this.employeeId, required this.profile});

  @override
  ConsumerState<_AttendanceContent> createState() =>
      _AttendanceContentState();
}

class _AttendanceContentState
    extends ConsumerState<_AttendanceContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TodayTab(profile: widget.profile, employeeId: widget.employeeId),
          _HistoryTab(employeeId: widget.employeeId),
        ],
      ),
    );
  }
}

// ── Tab 1: Today — Check In / Check Out ──
class _TodayTab extends ConsumerWidget {
  final Map<String, dynamic> profile;
  final String employeeId;

  const _TodayTab({required this.profile, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayAttendanceProvider(employeeId));
    final attendanceState = ref.watch(employeeAttendanceNotifierProvider);

    return todayAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (todayRecord) {
        final hasCheckedIn = todayRecord != null;
        final hasCheckedOut = todayRecord?['checkOut'] != null;
        final checkInTime = todayRecord?['checkIn'];
        final checkOutTime = todayRecord?['checkOut'];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              // Status card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: hasCheckedOut
                        ? [Colors.grey.shade400, Colors.grey.shade600]
                        : hasCheckedIn
                        ? [Colors.green.shade400, Colors.green.shade700]
                        : [Colors.indigo.shade400, Colors.indigo.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(
                      hasCheckedOut
                          ? Icons.check_circle
                          : hasCheckedIn
                          ? Icons.access_time
                          : Icons.fingerprint,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hasCheckedOut
                          ? 'Work Complete!'
                          : hasCheckedIn
                          ? 'You are Checked In'
                          : 'Not Checked In Yet',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getTodayDate(),
                      style: const TextStyle(
                          fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Check in / Check out time cards
              if (hasCheckedIn) ...[
                Row(
                  children: [
                    Expanded(
                      child: _TimeCard(
                        label: 'Check In',
                        time: checkInTime != null
                            ? _formatTimestamp(checkInTime)
                            : '--:--',
                        icon: Icons.login,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeCard(
                        label: 'Check Out',
                        time: checkOutTime != null
                            ? _formatTimestamp(checkOutTime)
                            : '--:--',
                        icon: Icons.logout,
                        color: hasCheckedOut
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Check In / Check Out Button
              if (!hasCheckedOut)
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton.icon(
                    onPressed: attendanceState.isLoading
                        ? null
                        : () => _handleAttendance(
                        context, ref, hasCheckedIn),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      hasCheckedIn ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: attendanceState.isLoading
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                        : Icon(
                        hasCheckedIn ? Icons.logout : Icons.login),
                    label: Text(
                      attendanceState.isLoading
                          ? 'Please wait...'
                          : hasCheckedIn
                          ? 'Check Out'
                          : 'Check In',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

              if (hasCheckedOut)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Aaj ka attendance complete!',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),

              // Site info
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Site Info',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    _InfoRow(
                        icon: Icons.location_city,
                        label: 'Site',
                      value: profile['siteName'] ?? profile['siteId'] ?? 'Not assigned'),
                    _InfoRow(
                        icon: Icons.badge,
                        label: 'Employee ID',
                        value: profile['employeeId'] ?? ''),
                    _InfoRow(
                        icon: Icons.work,
                        label: 'Role',
                        value: profile['role'] ?? ''),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleAttendance(
      BuildContext context,
      WidgetRef ref,
      bool hasCheckedIn,
      ) async {

    try {

      // STEP 1: current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentLat = position.latitude;
      final currentLng = position.longitude;

      // STEP 2: employee siteId
      final siteId = profile['siteId'];

      if (siteId == null || siteId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No site assigned'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // STEP 3: fetch site data
      final siteDoc = await FirebaseFirestore.instance
          .collection('sites')
          .doc(siteId)
          .get();

      if (!siteDoc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Site not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final siteData = siteDoc.data()!;

      final siteLat = siteData['latitude'];
      final siteLng = siteData['longitude'];

      // STEP 4: distance calculate
      double distance = Geolocator.distanceBetween(
        currentLat,
        currentLng,
        siteLat,
        siteLng,
      );

      print('DISTANCE: $distance');

      // STEP 5: check radius
      if (distance > 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are not at work location'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // STEP 6: attendance mark
      bool success;

      if (!hasCheckedIn) {

        success = await ref
            .read(employeeAttendanceNotifierProvider.notifier)
            .checkIn(
          employeeId: profile['employeeId'] ?? '',
          employeeName: profile['name'] ?? '',
          role: profile['role'] ?? 'employee',
          siteId: profile['siteId'] ?? '',
          siteName: profile['siteName'] ?? '',
          supervisorId: profile['supervisorId'] ?? '',
          latitude: currentLat,
          longitude: currentLng,
        );

      } else {

        success = await ref
            .read(employeeAttendanceNotifierProvider.notifier)
            .checkOut(
          employeeId: profile['employeeId'] ?? '',
          latitude: currentLat,
          longitude: currentLng,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? hasCheckedIn
                  ? 'Check out successful!'
                  : 'Check in successful!'
                  : 'Failed. Try again.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }

    } catch (e) {

      print('LOCATION ERROR: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getTodayDate() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '--:--';
    try {
      final dt = (timestamp as dynamic).toDate() as DateTime;
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (e) {
      return '--:--';
    }
  }
}

// ── Tab 2: History ──
class _HistoryTab extends ConsumerWidget {
  final String employeeId;
  const _HistoryTab({required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(myAttendanceProvider(employeeId));

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (records) {
        if (records.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No attendance records yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final record = records[index];
            final date = record['date'] ?? '';
            final status = record['status'] ?? 'present';
            final checkIn = record['checkIn'];
            final checkOut = record['checkOut'];
            final workHours = record['workHours'] ?? 0.0;

            Color statusColor = Colors.green;
            if (status == 'absent') statusColor = Colors.red;
            if (status == 'late') statusColor = Colors.orange;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Date box
                  Container(
                    width: 50,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Text(
                          date.length >= 10 ? date.substring(8) : date,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: statusColor),
                        ),
                        Text(
                          _getMonthAbbr(date),
                          style: TextStyle(
                              fontSize: 10, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(status.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor)),
                            ),
                            if (workHours > 0) ...[
                              const SizedBox(width: 8),
                              Text('${workHours}h',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ]
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.login,
                                size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimestamp(checkIn),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.logout,
                                size: 12, color: Colors.red),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimestamp(checkOut),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getMonthAbbr(String date) {
    if (date.length < 7) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final m = int.tryParse(date.substring(5, 7)) ?? 1;
    return months[m - 1];
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '--:--';
    try {
      final dt = (timestamp as dynamic).toDate() as DateTime;
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (e) {
      return '--:--';
    }
  }
}

// ── Helper Widgets ──
class _TimeCard extends StatelessWidget {
  final String label;
  final String time;
  final IconData icon;
  final Color color;

  const _TimeCard({
    required this.label,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(time,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}