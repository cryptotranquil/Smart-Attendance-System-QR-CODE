import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const projectUrl = String.fromEnvironment('SUPABASE_URL');
const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final connected = projectUrl.isNotEmpty && publishableKey.isNotEmpty;
  if (connected) await Supabase.initialize(url: projectUrl, anonKey: publishableKey);
  runApp(PulseQr(connected: connected));
}

class PulseQr extends StatelessWidget {
  const PulseQr({super.key, this.connected = false});
  final bool connected;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PulseQR',
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: const Color(0xfff9f9ff),
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.black, primary: Colors.black)),
    home: connected ? const LiveSignIn() : const AuthPreview(),
  );
}

class LiveSignIn extends StatefulWidget {
  const LiveSignIn({super.key});
  @override
  State<LiveSignIn> createState() => _LiveSignInState();
}

class _LiveSignInState extends State<LiveSignIn> {
  final email = TextEditingController();
  final password = TextEditingController();
  final client = Supabase.instance.client;
  bool busy = false;
  String? role;
  String? error;

  Future<void> signIn() async {
    if (busy) return;
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'Enter your school email and password.');
      return;
    }
    setState(() { busy = true; error = null; });
    try {
      final result = await client.auth.signInWithPassword(email: email.text.trim(), password: password.text);
      final profile = await client.from('users').select('user_type,is_active').eq('id', result.user!.id).maybeSingle();
      final assigned = const {'student': 'Student', 'lecturer': 'Lecturer', 'admin': 'Admin'}[profile?['user_type']];
      if (profile?['is_active'] != true || assigned == null) {
        await client.auth.signOut();
        if (mounted) setState(() => error = 'No active school profile. Contact your school admin.');
        return;
      }
      if (mounted) setState(() { role = assigned; password.clear(); });
    } on AuthException {
      if (mounted) setState(() => error = 'Sign-in failed. Check your credentials and email confirmation.');
    } catch (_) {
      try { await client.auth.signOut(); } catch (_) {}
      if (mounted) setState(() => error = 'Could not load your school profile. Try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> signOut() async {
    if (busy) return;
    setState(() { busy = true; role = null; });
    try { await client.auth.signOut(); }
    catch (_) { if (mounted) setState(() => error = 'Could not complete sign-out.'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  @override
  void dispose() { email.dispose(); password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => role != null
    ? DesignPreview(initialRole: role!, onSignOut: signOut)
    : Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
        child: Card(elevation: 0, color: Colors.white, child: Padding(padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('PulseQR'), const SizedBox(height: 18),
            Text('Sign in', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'School email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: password, obscureText: true, onSubmitted: (_) => signIn(), decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
            const SizedBox(height: 16), FilledButton(onPressed: busy ? null : signIn, child: Text(busy ? 'Please wait…' : 'Sign in')),
            const Text('Use an existing school account. Sign-up and password recovery are not connected yet.'),
          ]),
        )),
      ),
    ))));
}

class AuthPreview extends StatefulWidget {
  const AuthPreview({super.key});
  @override
  State<AuthPreview> createState() => _AuthPreviewState();
}

class _AuthPreviewState extends State<AuthPreview> {
  String step = 'Sign in';
  String role = 'Student';
  final form = GlobalKey<FormState>();
  void go(String next) => setState(() => step = next);

  Widget field(String label, {bool secret = false, bool email = false, bool code = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(key: ValueKey('$step/$label'), obscureText: secret,
      keyboardType: email ? TextInputType.emailAddress : code ? TextInputType.number : null,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'Enter $label'.toLowerCase().replaceFirst('enter', 'Enter');
        if (email && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) return 'Enter a valid email address';
        if (code && !RegExp(r'^\d{6}$').hasMatch(text)) return 'Enter six digits';
        if (secret && step == 'Set password' && text.length < 8) return 'Use at least 8 characters';
        return null;
      },
    ),
  );

  void submit() {
    if (!(form.currentState?.validate() ?? false)) return;
    switch (step) {
      case 'Sign up': go('Verify email'); break;
      case 'Verify email': go('Set password'); break;
      case 'Set password': go('Sign in');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sign-up preview complete. No account was created.'))); break;
      case 'Reset password': go('Sign in');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reset preview complete. No email was sent.'))); break;
      default: Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DesignPreview(initialRole: role)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final signingIn = step == 'Sign in';
    final signingUp = step == 'Sign up';
    return Scaffold(body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(24), child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 440),
        child: Card(elevation: 0, color: Colors.white, child: Padding(padding: const EdgeInsets.all(24),
          child: Form(key: form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Row(children: [Icon(Icons.qr_code_2), SizedBox(width: 8), Text('PulseQR', style: TextStyle(fontWeight: FontWeight.w800))]),
            const SizedBox(height: 24), Text(step, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8), Text(switch (step) {
              'Sign up' => 'Claim your school account using your student or staff ID.',
              'Verify email' => 'In the live app, you’ll receive a code by email. For this preview, enter any six digits.',
              'Set password' => 'Choose a password for your school account.',
              'Reset password' => 'Enter the school email linked to your account.',
              _ => 'Use your school email to sign in. Your account determines your role in the live app.',
            }), const SizedBox(height: 20),
            if (signingIn) ...[
              DropdownButtonFormField<String>(value: role, decoration: const InputDecoration(labelText: 'Preview as', border: OutlineInputBorder()),
                items: ['Student', 'Lecturer', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (r) => setState(() => role = r!)), const SizedBox(height: 14),
            ],
            if (signingUp) field('Student or staff ID'),
            if (signingIn || signingUp || step == 'Reset password') field('School email', email: true),
            if (signingIn || step == 'Set password') field('Password', secret: true),
            if (step == 'Verify email') field('Verification code', code: true),
            FilledButton(onPressed: submit, child: Text(switch (step) {
              'Sign in' => 'Preview sign in', 'Sign up' => 'Continue', 'Verify email' => 'Verify code',
              'Reset password' => 'Preview reset request', _ => 'Set password',
            })),
            if (signingIn) ...[
              TextButton(onPressed: () => go('Reset password'), child: const Text('Forgot password?')),
              TextButton(onPressed: () => go('Sign up'), child: const Text('Sign up as a student or lecturer')),
              const Text('Admin accounts are provisioned by the school.', textAlign: TextAlign.center),
              TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DesignPreview(initialRole: role))), child: const Text('Explore preview without signing in')),
            ] else TextButton(onPressed: () => go('Sign in'), child: const Text('Back to sign in')),
            const SizedBox(height: 12), const Text('Design preview · No accounts, emails, or passwords are sent or saved.', textAlign: TextAlign.center),
          ])),
        )),
      ),
    ))));
  }
}

class DesignPreview extends StatefulWidget {
  const DesignPreview({super.key, this.initialRole = 'Student', this.onSignOut});
  final VoidCallback? onSignOut;
  final String initialRole;
  @override
  State<DesignPreview> createState() => _DesignPreviewState();
}

class _DesignPreviewState extends State<DesignPreview> {
  late String role = widget.initialRole;
  int page = 0;
  static const routes = {
    'Student': ['Home', 'Scan', 'Courses', 'Timetable', 'Profile'],
    'Lecturer': ['Home', 'Courses', 'Timetable', 'Reports', 'Profile'],
    'Admin': ['Dashboard', 'Users', 'Academics', 'Timetable', 'Policies', 'Audit log'],
  };
  static const icons = {'Home': Icons.home_outlined, 'Dashboard': Icons.dashboard_outlined,
    'Scan': Icons.qr_code_scanner, 'Courses': Icons.school_outlined,
    'Timetable': Icons.calendar_today_outlined, 'Profile': Icons.person_outline,
    'Reports': Icons.bar_chart, 'Users': Icons.group_outlined, 'Academics': Icons.school_outlined,
    'Policies': Icons.tune, 'Audit log': Icons.history};
  int day = 3;
  bool qrMode = true;
  bool live = false;
  bool roster = false;

  Widget panel(Widget child) => Card(
    color: Colors.white, elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0xffdce2f3))),
    child: Padding(padding: const EdgeInsets.all(18), child: child),
  );

  Widget row(IconData icon, String title, String detail, [Widget? action]) => panel(
    ListTile(contentPadding: EdgeInsets.zero, leading: Icon(icon), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(detail), trailing: action),
  );

  Widget heading(String title) => Padding(padding: const EdgeInsets.only(top: 18, bottom: 8), child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)));

  Widget metrics(Map<String, String> values) => Wrap(spacing: 8, runSpacing: 8, children: values.entries.map((e) => SizedBox(width: 150, child: panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(e.key), const SizedBox(height: 8), Text(e.value, style: Theme.of(context).textTheme.headlineMedium)])))).toList());

  List<Widget> schedule() => [
    if (day == 3) ...[
      row(Icons.schedule, 'CSC 201 · Data Structures', '10:00–11:30 · Room B12 · In person',
        role == 'Lecturer' ? FilledButton(onPressed: () => setState(() => live = true), child: Text(live ? 'View live' : 'Start session')) : null),
      row(Icons.videocam_outlined, 'CSC 304 · Distributed Systems', '14:00–15:30 · Online'),
    ] else if (day == 1) row(Icons.location_on_outlined, 'CSC 210 · Computer Networks', '09:00–10:30 · Lab 2 · In person')
      else row(Icons.event_available_outlined, 'No classes scheduled', 'Choose another day to see its classes.'),
  ];

  List<Widget> screen(String title) {
    switch (title) {
      case 'Home':
        if (role == 'Lecturer') return [
          if (live) ...[
            heading('Live attendance session'),
            panel(Column(children: [const Text('CSC 201  /  IN PERSON'), const SizedBox(height: 16),
              const Icon(Icons.qr_code_2, size: 200, semanticLabel: 'Illustrative QR, not scannable'),
              const Text('Illustrative QR · no active session'), const SizedBox(height: 10),
              const Text('24 of 32 marked · Refresh in 12:48'), const SizedBox(height: 16),
              Wrap(spacing: 8, children: [OutlinedButton(onPressed: () => setState(() => roster = !roster), child: Text(roster ? 'Hide attendance' : 'Live attendance')), FilledButton(onPressed: () => setState(() { live = false; roster = false; }), child: const Text('Close preview'))]),
            ])),
            if (roster) ...[heading('Live attendance verification'), row(Icons.check_circle_outline, 'Student A', 'Present · 10:02'), row(Icons.flag_outlined, 'Student B', 'Late · 10:17 · Location flagged')],
          ] else ...[
            const Text('Lecturer Control Hub'), metrics({'Today’s classes': '2', 'Live sessions': '0'}), heading('Today’s class schedule'),
            row(Icons.schedule, 'CSC 201 · Data Structures', '10:00–11:30 · Room B12 · In person', FilledButton(onPressed: () => setState(() => live = true), child: const Text('Start session'))),
            row(Icons.videocam_outlined, 'CSC 304 · Distributed Systems', '14:00–15:30 · Online'),
            heading('Attendance verification'), row(Icons.groups_outlined, 'Physical headcount', 'Compare scans with the number of students in the room.'), row(Icons.flag_outlined, 'Geofence flags', 'Flagged check-ins appear here during a session.'),
          ],
        ];
        return [const Text('Thursday, 19 November'), heading('Today’s classes'),
          row(Icons.qr_code_scanner, 'CSC 201 · Data Structures', 'Live now · Room B12', FilledButton(onPressed: () => setState(() => page = 1), child: const Text('Check in'))),
          row(Icons.videocam_outlined, 'CSC 304 · Distributed Systems', '14:00–15:30 · Online'),
          heading('Attendance overview'), metrics({'Overall': '86%', 'Minimum': '75%'}),
        ];
      case 'Scan':
        return [const Text('Use the code displayed by your lecturer.'), const SizedBox(height: 16),
          SegmentedButton<bool>(segments: const [ButtonSegment(value: true, label: Text('Scan QR'), icon: Icon(Icons.qr_code_scanner)), ButtonSegment(value: false, label: Text('Enter code'), icon: Icon(Icons.pin_outlined))], selected: {qrMode}, onSelectionChanged: (value) => setState(() => qrMode = value.single)),
          const SizedBox(height: 12), panel(Column(children: [
            if (qrMode) Container(height: 220, width: double.infinity, decoration: BoxDecoration(color: const Color(0xff151c27), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 110, semanticLabel: 'Camera viewfinder placeholder'))
            else const SizedBox(width: 240, child: TextField(maxLength: 6, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Six-digit class code', border: OutlineInputBorder()))),
            const SizedBox(height: 12), Text(qrMode ? 'Camera not connected in this preview.' : 'Check-in is not connected in this preview.'),
          ])),
        ];
      case 'Timetable':
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return [const Text('16–22 November 2026'), const SizedBox(height: 12),
          if (role == 'Admin' && MediaQuery.sizeOf(context).width >= 850)
            panel(Table(border: TableBorder.all(color: const Color(0xffdce2f3)), children: [
              TableRow(children: days.map((d) => Padding(padding: const EdgeInsets.all(8), child: Text(d))).toList()),
              TableRow(children: List.generate(7, (i) => Padding(padding: const EdgeInsets.all(8), child: Text(i == 3 ? '10:00  CSC 201\nRoom B12' : i == 1 ? '09:00  CSC 210\nLab 2' : '—')))),
            ]))
          else Wrap(spacing: 6, children: List.generate(days.length, (i) => ChoiceChip(label: Text('${days[i]} ${16+i}'), selected: day == i, onSelected: (_) => setState(() => day = i)))),
          heading('Classes'), ...schedule(),
        ];
      case 'Courses': return [heading('Attendance & policy registry'), row(Icons.school_outlined, 'CSC 201 · Data Structures', '88% attendance · 75% minimum'), row(Icons.school_outlined, 'CSC 304 · Distributed Systems', '84% attendance · 75% minimum')];
      case 'Reports': return [metrics({'Average attendance': '86%', 'Below minimum': '4'}), row(Icons.bar_chart, 'CSC 201 · Course report', '32 enrolled · 4 below minimum')];
      case 'Dashboard': return [const Text('School operations overview'), heading('Session activity'), metrics({'Open': '2', 'Cancelled': '1', 'Not held': '0'}), heading('Quick links'), row(Icons.calendar_today_outlined, 'Weekly timetable', 'Review scheduled classes and venues', OutlinedButton(onPressed: () => setState(() => page = 3), child: const Text('View')))];
      case 'Users': return [heading('User directory'), row(Icons.upload_file, 'CSV import', 'Upload → Preview → Confirm · layout preview only'), row(Icons.person_outline, 'Sample student', 'Student · Active'), row(Icons.person_outline, 'Sample lecturer', 'Lecturer · Active')];
      case 'Academics': return [row(Icons.account_tree_outlined, 'Departments and programmes', 'Computing · Computer Science'), row(Icons.school_outlined, 'Courses and enrolments', 'CSC 201 · Data Structures'), row(Icons.location_on_outlined, 'Venues and geofences', 'Room B12 · 75 m radius')];
      case 'Policies': return [row(Icons.percent, 'Attendance minimum', '75%'), row(Icons.timer_outlined, 'Late threshold', '15 minutes after opening'), row(Icons.refresh, 'Code refresh interval', '15 minutes')];
      case 'Audit log': return [row(Icons.edit_note, 'Attendance corrected', 'CSC 201 · Sample lecturer · 11:15'), row(Icons.event_busy, 'Session cancelled', 'CSC 210 · Venue unavailable · 09:20')];
      default: return [row(Icons.person_outline, '$role preview', 'Sample account · Not signed in')];
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = routes[role]!;
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final title = labels[page];
    final destinations = labels.map((label) => NavigationDestination(icon: Icon(icons[label]), label: label)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('PulseQR', style: TextStyle(fontWeight: FontWeight.w800)), actions: [
        if (widget.onSignOut != null) TextButton(onPressed: widget.onSignOut, child: const Text('Sign out')) else DropdownButton<String>(value: role, items: routes.keys.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (r) => setState(() { role = r!; page = 0; day = 3; live = false; roster = false; })), const SizedBox(width: 16),
      ]),
      bottomNavigationBar: wide ? null : NavigationBar(destinations: destinations, selectedIndex: page, onDestinationSelected: (i) => setState(() => page = i)),
      body: Row(children: [
        if (wide) NavigationRail(extended: true, destinations: labels.map((label) => NavigationRailDestination(icon: Icon(icons[label]), label: Text(label))).toList(), selectedIndex: page, onDestinationSelected: (i) => setState(() => page = i)),
        Expanded(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 980), child: ListView(padding: const EdgeInsets.all(24), children: [
          Text('DESIGN PREVIEW  /  ${role.toUpperCase()}', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 12), Text(title, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 24),
          ...screen(title),
        ]))))
      ]),
    );
  }
}
