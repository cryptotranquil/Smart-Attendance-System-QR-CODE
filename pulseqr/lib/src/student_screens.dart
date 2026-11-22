import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'demo_data.dart';
import 'sign_in_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// Student role shell: Home · Check in · Excuses (redesign pages 2–4).
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key, required this.connected, this.userName, this.schoolId});

  final bool connected;
  final String? userName;
  final String? schoolId;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _tab = 0;

  String get _name => (widget.userName?.trim().split(' ').first) ?? 'Alex';
  String get _id => widget.schoolId ?? 'STU-99042';

  Future<void> _signOut() async {
    if (widget.connected) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => SignInScreen(connected: widget.connected)));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Scaffold(
      body: Column(
        children: [
          AppTopBar(
            navItems: const ['Home', 'Check in', 'Excuses'],
            currentIndex: _tab,
            onSelect: (i) => setState(() => _tab = i),
            userName: widget.userName ?? 'Alex Taylor',
            userMeta: _id,
            onSignOut: _signOut,
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _HomeTab(name: _name, onCheckIn: () => setState(() => _tab = 1), onExcuse: () => setState(() => _tab = 2)),
                const _CheckInTab(),
                const _ExcusesTab(),
              ],
            ),
          ),
          if (!wide)
            BottomNavigationBar(
              currentIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
              selectedItemColor: C.accent,
              unselectedItemColor: C.muted,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_outlined), activeIcon: Icon(Icons.qr_code_scanner), label: 'Check in'),
                BottomNavigationBarItem(icon: Icon(Icons.mail_outline), activeIcon: Icon(Icons.mail), label: 'Excuses'),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- page 2: Home

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.name, required this.onCheckIn, required this.onExcuse});

  final String name;
  final VoidCallback onCheckIn;
  final VoidCallback onExcuse;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Hi, $name', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
              const SizedBox(height: 4),
              const Text('Here is how your attendance looks this term.', style: TextStyle(fontSize: 13, color: C.muted)),
              const SizedBox(height: 16),

              // Open now
              Container(
                decoration: BoxDecoration(
                  color: C.brand,
                  borderRadius: BorderRadius.circular(PulseTheme.radiusCard),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, size: 40, color: Colors.white),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Pill('Open now', fg: Colors.white, bg: Color(0x22FFFFFF), icon: Icons.circle),
                          const SizedBox(height: 8),
                          const Text('CS101 Algorithms', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          const Text('Room 402 · Check-in closes in 7 minutes', style: TextStyle(color: Color(0xFFB9C4D6), fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: C.brand,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: onCheckIn,
                        child: const Text('Check in', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Key numbers
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SectionLabel('Overall attendance'),
                          Text('86%', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.2)),
                          SizedBox(height: 6),
                          Text('You need at least 75%', style: TextStyle(fontSize: 11.5, color: C.muted)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionLabel('Excuses left'),
                          const Text('1 of 2', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.2)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: onExcuse,
                            child: const Text(
                              'per course · Send an excuse',
                              style: TextStyle(fontSize: 11.5, color: C.accent, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (wide) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: _coursesCard()),
                    const SizedBox(width: 12),
                    Expanded(flex: 5, child: _todayCard()),
                  ],
                ),
              ] else ...[
                _coursesCard(),
                const SizedBox(height: 12),
                _todayCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _coursesCard() => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('My courses'),
            for (final course in demoCourses)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(child: Text('${course.code} ${course.title}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                              if (course.below) ...[
                                const SizedBox(width: 6),
                                const Pill('Below 75%', fg: C.danger, bg: C.dangerSoft),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: course.percent / 100,
                              minHeight: 6,
                              backgroundColor: C.bg,
                              valueColor: AlwaysStoppedAnimation<Color>(course.below ? C.danger : C.success),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            course.below
                                ? "${course.attended} of ${course.total} classes · You can't miss many more"
                                : "${course.attended} of ${course.total} classes",
                            style: TextStyle(fontSize: 10.5, color: course.below ? C.danger : C.muted, fontWeight: course.below ? FontWeight.w700 : FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('${course.percent}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
          ],
        ),
      );

  Widget _todayCard() => AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Today'),
            for (final item in demoToday)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 74,
                      child: Text(item.time, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: C.muted)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(item.place, style: const TextStyle(fontSize: 11, color: C.muted)),
                        ],
                      ),
                    ),
                    if (item.status == 'open')
                      const Pill('Open now', fg: C.success, bg: C.successSoft)
                    else
                      const Pill('Later', fg: C.muted, bg: C.bg),
                  ],
                ),
              ),
          ],
        ),
      );
}

// ------------------------------------------------------------ page 3: Check in

class _CheckInTab extends StatefulWidget {
  const _CheckInTab();

  @override
  State<_CheckInTab> createState() => _CheckInTabState();
}

class _CheckInTabState extends State<_CheckInTab> {
  bool _typed = false;
  bool _onCampus = true;
  final _codeController = TextEditingController();
  String? _result;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _checkIn() {
    final code = _codeController.text.replaceAll(' ', '');
    setState(() {
      if (!_onCampus) {
        _result = 'You\'re not on campus. Turn on location, walk outside for a moment and try again.';
      } else if (_typed && code.length != 6) {
        _result = 'The code changes every few minutes. Scan the one on screen now.';
      } else {
        _result = 'You\'re checked in to CS101 Algorithms.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final success = _result?.startsWith('You\'re checked in') ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Check in', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
              const SizedBox(height: 4),
              const Text('CS101 Algorithms · Room 402 · Closes in 7 minutes', style: TextStyle(fontSize: 12.5, color: C.muted)),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (_typed) ...[
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 34, letterSpacing: 14, fontWeight: FontWeight.w800),
                        decoration: InputDecoration(
                          hintText: '000 000',
                          hintStyle: const TextStyle(color: C.faint, fontSize: 34, letterSpacing: 14, fontWeight: FontWeight.w800),
                          filled: true,
                          fillColor: C.bg,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(PulseTheme.radiusField), borderSide: BorderSide.none),
                        ),
                      ),
                    ] else
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          color: C.bg,
                          borderRadius: BorderRadius.circular(PulseTheme.radiusCard),
                          border: Border.all(color: C.hairline),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.qr_code_scanner, size: 72, color: C.faint),
                            SizedBox(height: 12),
                            Text(
                              'Point your camera at the QR code\non your lecturer\'s screen.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, color: C.muted, height: 1.45),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => setState(() => _typed = !_typed),
                      child: Text(_typed ? 'Scan the QR instead' : 'Type a code instead',
                          style: const TextStyle(fontWeight: FontWeight.w800, color: C.accent)),
                    ),
                    const SizedBox(height: 6),
                    PrimaryButton(label: 'Check in', icon: Icons.check, onPressed: _checkIn),
                    if (_result != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: success ? C.successSoft : C.dangerSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(success ? Icons.check_circle : Icons.error_outline, size: 17, color: success ? C.success : C.danger),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_result!, style: TextStyle(fontSize: 12, height: 1.4, color: success ? C.success : C.danger, fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Row(
                  children: [
                    Icon(_onCampus ? Icons.location_on : Icons.location_off, color: _onCampus ? C.success : C.warn, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_onCampus ? 'You\'re on campus' : 'You\'re off campus',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                          const Text('Checked against the campus circle before every scan.', style: TextStyle(fontSize: 11, color: C.muted)),
                        ],
                      ),
                    ),
                    Switch(value: _onCampus, onChanged: (v) => setState(() => _onCampus = v), activeThumbColor: C.success),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const SectionLabel('If something goes wrong'),
              _helpRow(Icons.location_off, '\'You\'re not on campus\'', 'Turn on location, walk outside for a moment and try again.'),
              _helpRow(Icons.timer_off, '\'Code expired\'', 'The code changes every few minutes. Scan the one on screen now.'),
              _helpRow(Icons.lock_clock, '\'Check-in has closed\'', 'You can still send an excuse within 7 days.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpRow(IconData icon, String title, String body) => AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: C.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(body, style: const TextStyle(fontSize: 11.5, height: 1.4, color: C.muted)),
                ],
              ),
            ),
          ],
        ),
      );
}

// --------------------------------------------------------------- page 4: Excuses

class _ExcusesTab extends StatefulWidget {
  const _ExcusesTab();

  @override
  State<_ExcusesTab> createState() => _ExcusesTabState();
}

class _ExcusesTabState extends State<_ExcusesTab> {
  int _missed = 0;
  final _whatController = TextEditingController();
  final _detailsController = TextEditingController();
  final List<DemoExcuse> _mine = List.of(demoExcuses);
  bool _sent = false;

  @override
  void dispose() {
    _whatController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _send() {
    if (_whatController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tell us what happened first.')));
      return;
    }
    setState(() {
      _mine.insert(0, DemoExcuse(missedClasses[_missed].$1, 'Today', _whatController.text.trim(), 'Approved'));
      _sent = true;
      _whatController.clear();
      _detailsController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Excuses', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Expanded(child: Text('Missed a class? Tell us why within 7 days.', style: TextStyle(fontSize: 12.5, color: C.muted))),
                  const SizedBox(width: 8),
                  const Pill('1 of 2 automatic excuses left', fg: C.accent, bg: C.infoSoft),
                ],
              ),
              const SizedBox(height: 16),

              const SectionLabel('1 · Which class did you miss?'),
              for (var i = 0; i < missedClasses.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _missed = i),
                    borderRadius: BorderRadius.circular(PulseTheme.radiusField),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _missed == i ? C.infoSoft : C.card,
                        borderRadius: BorderRadius.circular(PulseTheme.radiusField),
                        border: Border.all(color: _missed == i ? C.accent : C.hairline, width: _missed == i ? 1.6 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(_missed == i ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              size: 18, color: _missed == i ? C.accent : C.faint),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(missedClasses[i].$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                                Text(missedClasses[i].$2, style: const TextStyle(fontSize: 11, color: C.muted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),

              const SectionLabel('2 · What happened?'),
              TextField(
                controller: _whatController,
                decoration: _field(hint: 'I was sick'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _detailsController,
                maxLines: 2,
                decoration: _field(hint: 'More details (optional)'),
              ),
              const SizedBox(height: 8),

              const SectionLabel('3 · Add proof'),
              InkWell(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Proof upload lands with the file-picker milestone.'))),
                borderRadius: BorderRadius.circular(PulseTheme.radiusField),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    border: Border.all(color: C.hairline),
                    borderRadius: BorderRadius.circular(PulseTheme.radiusField),
                    color: C.card,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.upload_file, color: C.muted),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tap to add a photo or PDF', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                            Text('A doctor\'s note, letter or ticket · up to 10 MB', style: TextStyle(fontSize: 11, color: C.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: C.infoSoft, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: C.accent),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have 1 automatic excuse left for this course. It will be accepted straight away.',
                        style: TextStyle(fontSize: 11.5, height: 1.4, color: C.accent, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(label: 'Send excuse', icon: Icons.send, onPressed: _send),
              if (_sent) ...[
                const SizedBox(height: 10),
                const Text('Sent. Your excuse was accepted automatically.', style: TextStyle(fontSize: 12, color: C.success, fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 20),

              const SectionLabel('My excuses'),
              AppCard(
                child: Column(
                  children: [
                    for (final excuse in _mine)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(excuse.course, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                  Text('${excuse.date} · ${excuse.reason}', style: const TextStyle(fontSize: 11.5, color: C.muted)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusPill(excuse.status),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'After your 2 automatic excuses, the lecturer decides.',
                style: TextStyle(fontSize: 11, color: C.faint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _field({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: C.faint, fontSize: 13.5),
        filled: true,
        fillColor: C.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(PulseTheme.radiusField), borderSide: const BorderSide(color: C.hairline)),
      );
}
