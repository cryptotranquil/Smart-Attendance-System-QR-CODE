import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'demo_data.dart';
import 'sign_in_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// Lecturer role shell: Today · Live class (redesign pages 5–6).
class LecturerTodayScreen extends StatefulWidget {
  const LecturerTodayScreen({super.key, required this.connected, this.userName, this.schoolId});

  final bool connected;
  final String? userName;
  final String? schoolId;

  @override
  State<LecturerTodayScreen> createState() => _LecturerTodayScreenState();
}

class _LecturerTodayScreenState extends State<LecturerTodayScreen> {
  int _tab = 0;

  String get _id => widget.schoolId ?? 'STF-0042';

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
            navItems: const ['Today', 'Live class'],
            currentIndex: _tab,
            onSelect: (i) => setState(() => _tab = i),
            userName: widget.userName ?? 'Dr. Reynolds',
            userMeta: _id,
            onSignOut: _signOut,
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                _TodayTab(onStartClass: () => setState(() => _tab = 1)),
                _LiveClassTab(onEnd: () => setState(() => _tab = 0)),
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
                BottomNavigationBarItem(icon: Icon(Icons.today_outlined), activeIcon: Icon(Icons.today), label: 'Today'),
                BottomNavigationBarItem(icon: Icon(Icons.cast_outlined), activeIcon: Icon(Icons.cast), label: 'Live class'),
              ],
            ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- page 5: Today

class _TodayTab extends StatelessWidget {
  const _TodayTab({required this.onStartClass});

  final VoidCallback onStartClass;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Today', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
              const SizedBox(height: 4),
              const Text('4 classes today', style: TextStyle(fontSize: 12.5, color: C.muted)),
              const SizedBox(height: 18),
              const SectionLabel('Up next'),

              // Hero UP NEXT card
              Container(
                decoration: BoxDecoration(
                  color: C.brand,
                  borderRadius: BorderRadius.circular(PulseTheme.radiusCard),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('10:00', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1)),
                        SizedBox(height: 2),
                        Text('Room 402', style: TextStyle(color: Color(0xFFB9C4D6), fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Pill('Up next', fg: Colors.white, bg: Color(0x22FFFFFF)),
                          SizedBox(height: 8),
                          Text('CS101 Algorithms', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                          SizedBox(height: 2),
                          Text('In person · 48 students', style: TextStyle(color: Color(0xFFB9C4D6), fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: C.brand,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: onStartClass,
                        child: const Text('Start class', style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              const SectionLabel('All your classes'),
              for (final item in demoLecturerToday) _LecturerClassRow.fromTuple(item),
            ],
          ),
        ),
      ),
    );
  }
}

class _LecturerClassRow extends StatelessWidget {
  const _LecturerClassRow({required this.time, required this.title, required this.meta, required this.state, required this.action});

  final String time;
  final String title;
  final String meta;
  final String state;
  final String action;

  static _LecturerClassRow fromTuple((String, String, String, String, String) item) =>
      _LecturerClassRow(time: item.$1, title: item.$2, meta: item.$3, state: item.$4, action: item.$5);

  @override
  Widget build(BuildContext context) {
    final isStart = state == 'start';
    final isDone = state == 'done';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 84,
              child: Text(time, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: C.muted, height: 1.35)),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(meta, style: const TextStyle(fontSize: 11, color: C.muted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isStart)
              SizedBox(height: 40, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: C.brand, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))), onPressed: () {}, child: const Text('Start', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)))),
            if (state == 'later')
              Pill(action, fg: C.muted, bg: C.bg, icon: Icons.lock_clock),
            if (isDone)
              const Pill('Finished', fg: C.success, bg: C.successSoft, icon: Icons.check_circle),
            if (!isDone) ...[
              const SizedBox(width: 8),
              const Pill('Cancel', fg: C.danger, bg: C.dangerSoft, icon: Icons.close),
            ],
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ page 6: Live class

class _LiveClassTab extends StatefulWidget {
  const _LiveClassTab({required this.onEnd});

  final VoidCallback onEnd;

  @override
  State<_LiveClassTab> createState() => _LiveClassTabState();
}

class _LiveClassTabState extends State<_LiveClassTab> {
  // 12:40 countdown, ticking down each second.
  int _secondsLeft = 12 * 60 + 40;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) _secondsLeft--;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdown {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final feed = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('Checked in'),
        AppCard(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Text('38', style: TextStyle(fontSize: 46, fontWeight: FontWeight.w800, letterSpacing: -1.5)),
                  SizedBox(width: 6),
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('of 48', style: TextStyle(fontSize: 15, color: C.muted, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(
                  value: 38 / 48,
                  minHeight: 10,
                  backgroundColor: C.bg,
                  valueColor: AlwaysStoppedAnimation<Color>(C.success),
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Check-in stays open for 7 more minutes', style: TextStyle(fontSize: 11, color: C.muted)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const SectionLabel('Live feed'),
        AppCard(
          child: Column(
            children: [
              for (final entry in demoRecentCheckins)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: C.bg,
                        child: Text(entry.$1.substring(0, 1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: C.muted)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(entry.$1, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                      Text(entry.$2, style: const TextStyle(fontSize: 11, color: C.muted)),
                      const SizedBox(width: 10),
                      Pill(entry.$3, fg: entry.$3 == 'Late' ? C.warn : C.success, bg: entry.$3 == 'Late' ? C.warnSoft : C.successSoft),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    final qrPanel = AppCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          const SectionLabel('Show this to your class'),
          const SizedBox(height: 4),
          // QR stand-in: deterministic pattern that looks like a QR code.
          Container(
            width: 210,
            height: 210,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: C.hairline)),
            child: const _DemoQr(),
          ),
          const SizedBox(height: 16),
          const Text('794 281', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: 12)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.refresh, size: 14, color: C.muted),
              const SizedBox(width: 6),
              Text('New code in $_countdown', style: const TextStyle(fontSize: 12, color: C.muted, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Full screen', icon: Icons.fullscreen, onPressed: () {}, expand: false),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('CS101 Algorithms · Room 402', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                  GhostButton(label: 'Cancel class', icon: Icons.close, onPressed: () => _confirmCancel(context), danger: true),
                  const SizedBox(width: 10),
                  PrimaryButton(label: 'End class', icon: Icons.stop_circle_outlined, onPressed: widget.onEnd, expand: false),
                ],
              ),
              const SizedBox(height: 16),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(flex: 5, child: qrPanel), const SizedBox(width: 14), Expanded(flex: 6, child: feed)],
                )
              else ...[
                qrPanel,
                const SizedBox(height: 14),
                feed,
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this class?'),
        content: const Text('Everyone gets an automatic excuse and is told you cancelled CS101. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Keep class')),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onEnd();
            },
            child: const Text('Cancel class', style: TextStyle(color: C.danger, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

/// Deterministic pseudo-QR pattern so the live screen reads as a scannable
/// asset without shipping a QR dependency; wired to a real generator when
/// `qr_flutter` is added.
class _DemoQr extends StatelessWidget {
  const _DemoQr();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 182, height: 182, child: CustomPaint(painter: _QrPainter()));
  }
}

class _QrPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFF101828);
    final cell = size.width / 21;
    var seed = 794281;
    int next() {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      return seed;
    }

    void finder(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x, y, cell * 7, cell * 7), paint);
      canvas.drawRect(Rect.fromLTWH(x + cell, y + cell, cell * 5, cell * 5), Paint()..color = Colors.white);
      canvas.drawRect(Rect.fromLTWH(x + cell * 2, y + cell * 2, cell * 3, cell * 3), paint);
    }

    for (var r = 0; r < 21; r++) {
      for (var c = 0; c < 21; c++) {
        final inFinder = (r < 8 && c < 8) || (r < 8 && c > 12) || (r > 12 && c < 8);
        if (inFinder) continue;
        if (next() % 3 == 0) {
          canvas.drawRect(Rect.fromLTWH(c * cell, r * cell, cell, cell), paint);
        }
      }
    }
    finder(0, 0);
    finder(size.width - cell * 7, 0);
    finder(0, size.height - cell * 7);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
