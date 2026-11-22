import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'demo_data.dart';
import 'sign_in_screen.dart';
import 'theme.dart';
import 'widgets.dart';

/// Admin role shell: People · Campus & timetable · Rules & activity (pages 7–9).
class AdminPeopleScreen extends StatefulWidget {
  const AdminPeopleScreen({super.key, required this.connected, this.userName, this.schoolId});

  final bool connected;
  final String? userName;
  final String? schoolId;

  @override
  State<AdminPeopleScreen> createState() => _AdminPeopleScreenState();
}

class _AdminPeopleScreenState extends State<AdminPeopleScreen> {
  int _tab = 0;

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
            navItems: const ['People', 'Campus & timetable', 'Rules & activity'],
            currentIndex: _tab,
            onSelect: (i) => setState(() => _tab = i),
            userName: widget.userName ?? 'Admin office',
            userMeta: widget.schoolId ?? 'ADM-001',
            onSignOut: _signOut,
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [
                _PeopleTab(),
                _CampusTab(),
                _RulesTab(),
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
                BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'People'),
                BottomNavigationBarItem(icon: Icon(Icons.place_outlined), activeIcon: Icon(Icons.place), label: 'Campus'),
                BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'Rules'),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- page 7: People

class _PeopleTab extends StatefulWidget {
  const _PeopleTab();

  @override
  State<_PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<_PeopleTab> {
  int _filter = 0; // 0 all, 1 students, 2 lecturers, 3 not signed up
  String _query = '';
  static const _filters = ['All', 'Students', 'Lecturers', 'Not signed up'];

  List<DemoPerson> get _visible {
    return demoPeople.where((p) {
      final matchesFilter = switch (_filter) {
        1 => p.role == 'Student',
        2 => p.role == 'Lecturer',
        3 => p.status == 'Not signed up',
        _ => true,
      };
      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty || p.name.toLowerCase().contains(q) || p.id.toLowerCase().contains(q);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final people = _visible;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('People', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
                        SizedBox(height: 4),
                        Text('Add students and lecturers by uploading a CSV list.', style: TextStyle(fontSize: 12.5, color: C.muted)),
                      ],
                    ),
                  ),
                  GhostButton(label: 'Download list', icon: Icons.download, onPressed: () => _toast('CSV template downloaded.')),
                  const SizedBox(width: 10),
                  PrimaryButton(label: 'Upload CSV', icon: Icons.upload_file, onPressed: () => _toast('Pick a CSV to import — preview lands before anything is saved.'), expand: false),
                ],
              ),
              const SizedBox(height: 18),

              // Stats
              LayoutBuilder(
                builder: (context, constraints) {
                  final cards = [
                    ('Students', '1,420', Icons.school_outlined),
                    ('Lecturers', '68', Icons.cast_for_education_outlined),
                    ('Not signed up yet', '212', Icons.person_add_alt_1_outlined),
                  ];
                  final compact = constraints.maxWidth < 640;
                  return Row(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(cards[i].$3, size: 17, color: C.faint),
                                const SizedBox(height: 8),
                                Text(cards[i].$2, style: TextStyle(fontSize: compact ? 24 : 30, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                                const SizedBox(height: 2),
                                SectionLabel(cards[i].$1),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),

              // Filter tabs + search
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      for (var i = 0; i < _filters.length; i++)
                        GestureDetector(
                          onTap: () => setState(() => _filter = i),
                          child: Pill(
                            _filters[i],
                            fg: _filter == i ? Colors.white : C.muted,
                            bg: _filter == i ? C.brand : C.bg,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                    width: 260,
                    height: 38,
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Search name or ID',
                        hintStyle: const TextStyle(color: C.faint, fontSize: 12.5),
                        prefixIcon: const Icon(Icons.search, size: 17, color: C.faint),
                        filled: true,
                        fillColor: C.card,
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: C.hairline)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Table
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Column(
                  children: [
                    const _PeopleHeaderRow(),
                    const Divider(height: 1, color: C.hairline),
                    for (final person in people) ...[
                      _PeopleRow(person: person),
                      const Divider(height: 1, color: C.hairline),
                    ],
                    if (people.isEmpty) const Padding(padding: EdgeInsets.all(22), child: Text('Nobody matches that filter yet.', style: TextStyle(color: C.muted, fontSize: 12.5))),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Text('1–${people.length} of 1,488 people', style: const TextStyle(fontSize: 11.5, color: C.muted, fontWeight: FontWeight.w600)),
                          const Spacer(),
                          _PageDot(label: '‹'),
                          const SizedBox(width: 6),
                          _PageDot(label: '1', active: true),
                          const SizedBox(width: 6),
                          _PageDot(label: '2'),
                          const SizedBox(width: 6),
                          _PageDot(label: '248'),
                          const SizedBox(width: 6),
                          _PageDot(label: '›'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _PeopleHeaderRow extends StatelessWidget {
  const _PeopleHeaderRow();

  static const _cols = [('Name', 3), ('ID', 2), ('Role', 1), ('Department', 2), ('Status', 2), ('Actions', 1)];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            for (final (label, flex) in _cols)
              Expanded(
                flex: flex,
                child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: C.faint)),
              ),
          ],
        ),
      );
}

class _PeopleRow extends StatelessWidget {
  const _PeopleRow({required this.person});
  final DemoPerson person;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(person.name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
            Expanded(flex: 2, child: Text(person.id, style: const TextStyle(fontSize: 12, color: C.muted))),
            Expanded(flex: 1, child: Text(person.role, style: const TextStyle(fontSize: 12))),
            Expanded(flex: 2, child: Text(person.department, style: const TextStyle(fontSize: 12, color: C.muted))),
            Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: StatusPill(person.status))),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Edit ${person.name} — coming with the people manager milestone.'))),
                  child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: C.accent)),
                ),
              ),
            ),
          ],
        ),
      );
}

class _PageDot extends StatelessWidget {
  const _PageDot({required this.label, this.active = false});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? C.brand : C.bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: active ? Colors.white : C.muted)),
      );
}

// ---------------------------------------------------------- page 8: Campus

class _CampusTab extends StatefulWidget {
  const _CampusTab();

  @override
  State<_CampusTab> createState() => _CampusTabState();
}

class _CampusTabState extends State<_CampusTab> {
  double _radius = 300;
  bool _savedCampus = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Campus & timetable', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
              const SizedBox(height: 4),
              const Text('Where the geofence is, and what runs when.', style: TextStyle(fontSize: 12.5, color: C.muted)),
              const SizedBox(height: 18),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Campus area
                  Expanded(
                    flex: 5,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionLabel('Campus area'),
                          const Text('On-campus checks use this circle.', style: TextStyle(fontSize: 11.5, color: C.muted)),
                          const SizedBox(height: 14),
                          Container(
                            height: 170,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(PulseTheme.radiusField),
                              gradient: const RadialGradient(
                                colors: [Color(0xFFDCE7FB), Color(0xFFF4F6FA)],
                                center: Alignment(-0.2, 0.1),
                                radius: 0.9,
                              ),
                              border: Border.all(color: C.hairline),
                            ),
                            child: Stack(
                              children: [
                                Center(
                                  child: Container(
                                    width: 92 + (_radius - 100) / 4,
                                    height: 92 + (_radius - 100) / 4,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0x22155EEF),
                                      border: Border.all(color: C.accent, width: 1.6),
                                    ),
                                  ),
                                ),
                                const Center(child: Icon(Icons.location_on, size: 26, color: C.accent)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Radius', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: C.muted)),
                              const Spacer(),
                              _RadiusButton(icon: Icons.remove, onTap: _radius > 100 ? () => setState(() => _radius -= 50) : null),
                              SizedBox(width: 64, child: Text('${_radius.toInt()} m', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))),
                              _RadiusButton(icon: Icons.add, onTap: _radius < 800 ? () => setState(() => _radius += 50) : null),
                            ],
                          ),
                          const SizedBox(height: 12),
                          PrimaryButton(
                            label: _savedCampus ? 'Campus area saved' : 'Save campus area',
                            icon: _savedCampus ? Icons.check : Icons.save_outlined,
                            onPressed: () => setState(() => _savedCampus = true),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // No-class days
                  Expanded(
                    flex: 4,
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionLabel('No-class days'),
                          const Text('Cancelled automatically. Students are told.', style: TextStyle(fontSize: 11.5, color: C.muted)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(border: Border.all(color: C.warn, width: 1.4), borderRadius: BorderRadius.circular(PulseTheme.radiusField), color: C.warnSoft),
                            child: Row(
                              children: [
                                const Icon(Icons.beach_access, color: C.warn, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text('Exam break · 14–18 December', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                                      SizedBox(height: 2),
                                      Text('Whole school', style: TextStyle(fontSize: 10.5, color: C.warn, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                                TextButton(onPressed: () {}, child: const Text('Remove', style: TextStyle(color: C.warn, fontWeight: FontWeight.w800, fontSize: 11.5))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          GhostButton(label: 'Add a no-class day', icon: Icons.add, expand: true, onPressed: () => _toast('Pick the dates and who it applies to — saved as a no-class day.')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Timetable
              Row(
                children: [
                  const Expanded(child: SectionLabel('Timetable')),
                  GhostButton(label: 'Add class', icon: Icons.add, onPressed: () => _toast('Pick a course, room and time — then publish.')),
                ],
              ),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Column(
                  children: [
                    const _TimetableHeaderRow(),
                    const Divider(height: 1, color: C.hairline),
                    for (final row in demoTimetable) ...[
                      _TimetableRow(row: row),
                      const Divider(height: 1, color: C.hairline),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _RadiusButton extends StatelessWidget {
  const _RadiusButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkResponse(
        onTap: onTap,
        radius: 18,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.hairline), color: onTap == null ? C.bg : C.card),
          child: Icon(icon, size: 14, color: onTap == null ? C.faint : C.ink),
        ),
      );
}

class _TimetableHeaderRow extends StatelessWidget {
  const _TimetableHeaderRow();
  static const _cols = [('Class', 4), ('Lecturer', 3), ('When', 3), ('Room', 2), ('Type', 2), ('', 1)];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            for (final (label, flex) in _cols)
              Expanded(flex: flex, child: Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: C.faint))),
          ],
        ),
      );
}

class _TimetableRow extends StatelessWidget {
  const _TimetableRow({required this.row});
  final (String, String, String, String, String) row;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(flex: 4, child: Text(row.$1, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
            Expanded(flex: 3, child: Text(row.$2, style: const TextStyle(fontSize: 12, color: C.muted))),
            Expanded(flex: 3, child: Text(row.$3, style: const TextStyle(fontSize: 12))),
            Expanded(flex: 2, child: Text(row.$4, style: const TextStyle(fontSize: 12, color: C.muted))),
            Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Pill(row.$5, fg: row.$5 == 'Online' ? C.accent : C.muted, bg: row.$5 == 'Online' ? C.infoSoft : C.bg))),
            Expanded(
              flex: 1,
              child: TextButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit class — timetable editor lands with the next milestone.'))),
                child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: C.accent)),
              ),
            ),
          ],
        ),
      );
}

// ----------------------------------------------------- page 9: Rules + activity

class _RulesTab extends StatefulWidget {
  const _RulesTab();

  @override
  State<_RulesTab> createState() => _RulesTabState();
}

class _RulesTabState extends State<_RulesTab> {
  int _minAttendance = 75;
  int _lateAfter = 15;
  int _checkinOpen = 15;
  int _codeInterval = 15;
  int _excuseWindow = 7;
  int _autoExcuses = 2;
  int _lateCancel = 2;
  int _activityFilter = 0; // 0 all, 1 refused, 2 changes
  bool _saved = false;

  static const _activityFilters = ['All', 'Refused check-ins', 'Changes'];

  List<DemoActivity> get _activity {
    if (_activityFilter == 1) return demoActivity.where((a) => a.kind == 'refused').toList();
    if (_activityFilter == 2) return demoActivity.where((a) => a.kind == 'change').toList();
    return demoActivity;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;

    final rules = AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionLabel('Rules')),
              GhostButton(
                label: _saved ? 'Saved' : 'Save changes',
                icon: _saved ? Icons.check : Icons.save_outlined,
                onPressed: () => setState(() => _saved = true),
              ),
            ],
          ),
          StepperRow(title: 'Minimum attendance', subtitle: 'Below this, students cannot sit the exam', value: _minAttendance, unit: '%', min: 50, max: 100, onChanged: (v) => setState(() { _minAttendance = v; _saved = false; })),
          const Divider(height: 1, color: C.hairline),
          StepperRow(title: 'Late after', subtitle: 'Minutes after the start before you count as late', value: _lateAfter, unit: 'min', min: 0, max: 60, onChanged: (v) => setState(() { _lateAfter = v; _saved = false; })),
          const Divider(height: 1, color: C.hairline),
          StepperRow(title: 'Check-in stays open', subtitle: 'How long after the start students can check in', value: _checkinOpen, unit: 'min', min: 5, max: 60, onChanged: (v) => setState(() { _checkinOpen = v; _saved = false; })),
          const Divider(height: 1, color: C.hairline),
          StepperRow(title: 'Class code changes every', subtitle: 'Keeps screenshots useless', value: _codeInterval, unit: 'min', min: 10, max: 20, onChanged: (v) => setState(() { _codeInterval = v; _saved = false; })),
          const Divider(height: 1, color: C.hairline),
          StepperRow(title: 'Time to send an excuse', subtitle: 'Days after a missed class', value: _excuseWindow, unit: 'days', min: 1, max: 30, onChanged: (v) => setState(() { _excuseWindow = v; _saved = false; })),
          const Divider(height: 1, color: C.hairline),
          StepperRow(title: 'Automatic excuses', subtitle: 'Accepted straight away, per course, per term', value: _autoExcuses, unit: 'per course', min: 0, max: 5, onChanged: (v) => setState(() { _autoExcuses = v; _saved = false; })),
          const Divider(height: 1, color: C.hairline),
          StepperRow(title: 'Late cancellation', subtitle: 'Cancelling inside this window counts against the lecturer', value: _lateCancel, unit: 'hours', min: 0, max: 48, onChanged: (v) => setState(() { _lateCancel = v; _saved = false; })),
        ],
      ),
    );

    final activity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: SectionLabel('Activity')),
            for (var i = 0; i < _activityFilters.length; i++)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _activityFilter = i),
                  child: Pill(_activityFilters[i], fg: _activityFilter == i ? Colors.white : C.muted, bg: _activityFilter == i ? C.brand : C.bg),
                ),
              ),
          ],
        ),
        for (final item in _activity)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(switch (item.kind) {
                    'refused' => Icons.no_accounts_outlined,
                    'change' => Icons.edit_note_outlined,
                    _ => Icons.info_outline,
                  }, size: 18, color: item.kind == 'refused' ? C.danger : C.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, height: 1.35)),
                        const SizedBox(height: 2),
                        Text('${item.when} · ${item.ref}', style: const TextStyle(fontSize: 10.5, color: C.faint)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: wide ? 1100 : 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Rules & activity', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.7)),
              const SizedBox(height: 4),
              const Text('The numbers every check-in and excuse runs on — and what changed.', style: TextStyle(fontSize: 12.5, color: C.muted)),
              const SizedBox(height: 18),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Expanded(flex: 6, child: rules), const SizedBox(width: 14), Expanded(flex: 5, child: activity)],
                )
              else ...[rules, const SizedBox(height: 14), activity],
            ],
          ),
        ),
      ),
    );
  }
}
