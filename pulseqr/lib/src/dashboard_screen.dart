import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_screen.dart';
import 'pulse_qr_theme.dart';

/// Post-sign-in landing screen. Sample metrics are shown until live
/// attendance sync lands; sign-out is fully functional.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.role,
    required this.connected,
    this.userName,
    this.schoolId,
  });

  final String role;
  final bool connected;
  final String? userName;
  final String? schoolId;

  bool get _isStudent => role == 'student';
  bool get _isAdmin => role == 'admin';

  String get _displayName {
    final name = userName?.trim();
    if (name != null && name.isNotEmpty) return name.split(' ').first;
    return switch (role) {
      'lecturer' => 'Lecturer',
      'admin' => 'Administrator',
      _ => 'Student',
    };
  }

  String get _roleLabel => switch (role) {
        'lecturer' => 'Lecturer',
        'admin' => 'Administrator',
        _ => 'Student',
      };

  static const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const _months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

  String get _today {
    final now = DateTime.now();
    return '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]} ${now.year}';
  }

  Future<void> _signOut(BuildContext context) async {
    if (connected) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {
        // Best effort — return to the auth screen regardless.
      }
    }
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PulseQrAuthScreen(connected: connected)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 860;
    final metrics = _isAdmin
        ? const [
            _Metric(label: 'ACTIVE PROFILES', value: '5', note: '3 claimed · 2 roster-only', dark: true),
            _Metric(label: 'COURSES THIS TERM', value: '12', note: 'Across 4 faculties'),
            _Metric(label: 'OPEN ALERTS', value: '1', note: 'Roster mismatch review'),
          ]
        : _isStudent
            ? const [
                _Metric(label: 'ATTENDANCE RATE', value: '94.2%', note: '+2.1% vs last term', dark: true),
                _Metric(label: 'SESSIONS THIS TERM', value: '28', note: '26 attended · 2 excused'),
                _Metric(label: 'UNREAD ALERTS', value: '3', note: 'Incl. 1 timetable change'),
              ]
            : const [
                _Metric(label: 'SESSIONS TAUGHT', value: '24', note: 'This term', dark: true),
                _Metric(label: 'AVG ATTENDANCE', value: '88%', note: 'Across your courses'),
                _Metric(label: 'UNREAD ALERTS', value: '2', note: 'Roster verification pending'),
              ];

    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1060),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildGreeting(),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            for (final metric in metrics)
                              SizedBox(
                                width: wide ? 330 : double.infinity,
                                child: _MetricCard(metric: metric),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (wide)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 7, child: _buildSessionsPanel()),
                              const SizedBox(width: 16),
                              Expanded(flex: 5, child: _buildQrPanel()),
                            ],
                          )
                        else ...[
                          _buildQrPanel(),
                          const SizedBox(height: 16),
                          _buildSessionsPanel(),
                        ],
                        const SizedBox(height: 14),
                        const Text(
                          'Sample metrics shown · live attendance sync lands with the next milestone. Roster, roles and sign-in are live.',
                          style: TextStyle(fontSize: 10.5, color: PulseQrColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: PulseQrColors.surface,
        border: Border(bottom: BorderSide(color: PulseQrColors.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: PulseQrColors.ink, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.qr_code_2, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 9),
          const Text(
            'PulseQR',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: PulseQrColors.onSurface),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Telemetry',
            onPressed: () {},
            icon: const Icon(Icons.sensors, size: 19, color: PulseQrColors.onSurfaceVariant),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout, size: 19, color: PulseQrColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_roleLabel.toUpperCase()} DASHBOARD',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5, color: PulseQrColors.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(
          'Welcome back, $_displayName',
          style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: PulseQrColors.onSurface),
        ),
        const SizedBox(height: 4),
        Text(
          [if (schoolId != null) schoolId!, _today].join(' · '),
          style: const TextStyle(fontSize: 12, color: PulseQrColors.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _buildSessionsPanel() {
    final sessions = _isStudent
        ? const [
            ('CS 304', 'Distributed Systems', 'Today · 10:30–12:00 · Lab B'),
            ('CS 311', 'Database Internals', 'Today · 14:00–15:30 · Hall 2'),
            ('MATH 210', 'Linear Algebra', 'Tomorrow · 08:00–09:30 · Room 14'),
          ]
        : _isAdmin
            ? const [
                ('SYSTEM', 'Roster sync completed', 'Today · 06:00 · 5 profiles verified'),
                ('AUDIT', 'Nightly backup', 'Today · 02:00 · Success'),
                ('REVIEW', '2 roster entries unclaimed', 'Requires registrar follow-up'),
              ]
            : const [
                ('CS 304', 'Distributed Systems · Group A', 'Today · 10:30 · Lab B · 38 enrolled'),
                ('CS 311', 'Database Internals', 'Today · 14:00 · Hall 2 · 64 enrolled'),
                ('CS 402', 'Capstone Seminar', 'Friday · 09:00 · Online'),
              ];

    return Container(
      decoration: BoxDecoration(
        color: PulseQrColors.containerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PulseQrColors.hairline),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UPCOMING SESSIONS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: PulseQrColors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          for (final (code, title, meta) in sessions)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: PulseQrColors.hairline)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(color: PulseQrColors.containerLow, borderRadius: BorderRadius.circular(12)),
                    alignment: Alignment.center,
                    child: Text(
                      code.length > 4 ? code.substring(0, 2) : code,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: PulseQrColors.onSurface),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: PulseQrColors.onSurface)),
                        const SizedBox(height: 2),
                        Text(meta, style: const TextStyle(fontSize: 11, color: PulseQrColors.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, size: 18, color: PulseQrColors.onSurfaceVariant),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQrPanel() {
    return Container(
      decoration: BoxDecoration(color: PulseQrColors.ink, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _isStudent ? Icons.qr_code_scanner : (_isAdmin ? Icons.hub_outlined : Icons.qr_code_2),
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: 14),
          Text(
            _isStudent ? 'Scan to check in' : (_isAdmin ? 'System overview' : 'Open a session'),
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.3, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            _isStudent
                ? 'Point your camera at the rotating QR shown by your lecturer. Location is verified automatically.'
                : _isAdmin
                    ? 'Roster health, backup status and alert queues for the verification protocol.'
                    : 'Start a geofenced session and project the rotating QR for your class.',
            style: const TextStyle(fontSize: 12, height: 1.45, color: Color(0xFFB9BEC9)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0x55FFFFFF)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {},
            child: Text(_isStudent ? 'Open scanner' : (_isAdmin ? 'View telemetry' : 'Start session')),
          ),
        ],
      ),
    );
  }
}

class _Metric {
  const _Metric({required this.label, required this.value, required this.note, this.dark = false});

  final String label;
  final String value;
  final String note;
  final bool dark;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    final dark = metric.dark;
    final labelColor = dark ? const Color(0xFF9AA0AB) : PulseQrColors.onSurfaceVariant;
    final valueColor = dark ? Colors.white : PulseQrColors.onSurface;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? PulseQrColors.ink : PulseQrColors.containerLowest,
        borderRadius: BorderRadius.circular(20),
        border: dark ? null : Border.all(color: PulseQrColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metric.label,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: labelColor),
          ),
          const SizedBox(height: 10),
          Text(
            metric.value,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: valueColor),
          ),
          const SizedBox(height: 6),
          Text(metric.note, style: TextStyle(fontSize: 10.5, color: labelColor)),
        ],
      ),
    );
  }
}
