// ---------------------------------------------------------------- models

class DemoCourse {
  const DemoCourse(this.code, this.title, this.percent, this.attended, this.total, {this.below = false});
  final String code;
  final String title;
  final int percent;
  final int attended;
  final int total;
  final bool below;
}

class TodayItem {
  const TodayItem(this.time, this.title, this.place, this.meta, this.status);
  final String time;
  final String title;
  final String place;
  final String meta;
  final String status; // 'open' | 'later' | 'done'
}

class DemoExcuse {
  const DemoExcuse(this.course, this.date, this.reason, this.status);
  final String course;
  final String date;
  final String reason;
  final String status; // 'Approved' | 'With lecturer' | 'Declined'
}

class DemoPerson {
  const DemoPerson(this.name, this.id, this.role, this.department, this.status);
  final String name;
  final String id;
  final String role;
  final String department;
  final String status; // 'Active' | 'Not signed up' | 'Suspended'
}

class DemoActivity {
  const DemoActivity(this.when, this.title, this.ref, this.kind);
  final String when;
  final String title;
  final String ref;
  final String kind; // 'refused' | 'change' | 'info'
}

// ------------------------------------------------------------ demo dataset

const demoCourses = <DemoCourse>[
  DemoCourse('CS101', 'Algorithms', 92, 11, 12),
  DemoCourse('DB202', 'Databases', 85, 10, 12),
  DemoCourse('NW310', 'Networks', 96, 12, 12),
  DemoCourse('HC105', 'Human-Computer Interaction', 72, 8, 11, below: true),
];

const demoToday = <TodayItem>[
  TodayItem('10:00 – 11:30', 'CS101 Algorithms', 'Room 402', 'Open now', 'open'),
  TodayItem('13:15 – 14:45', 'DB202 Databases', 'Online · you will type a code', 'Later', 'later'),
  TodayItem('15:30 – 17:00', 'NW310 Networks', 'Lab 108', 'Later', 'later'),
];

const demoExcuses = <DemoExcuse>[
  DemoExcuse('HC105 Human-Computer Interaction', '19 Oct', 'I was sick', 'Approved'),
  DemoExcuse('DB202 Databases', '28 Sep', 'Family emergency', 'With lecturer'),
];

const missedClasses = [
  ('CS101 Algorithms', 'Wednesday 10:00 · 5 days left to send'),
  ('DB202 Databases', 'Monday 13:15 · 2 days left to send'),
];

const demoPeople = <DemoPerson>[
  DemoPerson('Amina Al-Mansoor', 'STU-88210', 'Student', 'Computing', 'Active'),
  DemoPerson('Dr. Elena Vance', 'STF-0042', 'Lecturer', 'Computing', 'Active'),
  DemoPerson('Kai Takahashi', 'STU-99041', 'Student', 'Engineering', 'Active'),
  DemoPerson('Jonas Davies', 'STU-70192', 'Student', 'Economics', 'Not signed up'),
  DemoPerson("Prof. Marcus O'Connor", 'STF-0021', 'Lecturer', 'Bioengineering', 'Active'),
  DemoPerson('Sara Osei', 'STU-08720', 'Student', 'Design', 'Suspended'),
];

const demoTimetable = [
  ('CS101 Algorithms', 'Dr. Reynolds', 'Mon & Wed · 10:00', 'Room 402', 'In person'),
  ('DB202 Databases', 'Dr. Vance', 'Mon · 13:15', 'Online', 'Online'),
  ('NW310 Networks', 'Prof. O\'Connor', 'Tue · 15:30', 'Lab 108', 'In person'),
  ('HC105 Human-Computer Interaction', 'Dr. Lindqvist', 'Thu · 08:00', 'Studio 1', 'In person'),
];

const demoActivity = <DemoActivity>[
  DemoActivity('Today 10:12', 'Check-in refused: outside campus', 'Marcus Vance · CS101', 'refused'),
  DemoActivity('Today 10:04', 'Check-in refused: code had expired', 'Elena Rostova · NW310', 'refused'),
  DemoActivity('Today 09:40', 'Class cancelled: power cut', 'Dr. Reynolds · NW310', 'change'),
  DemoActivity('Today 09:15', 'Excuse accepted automatically', 'Alex Taylor · HC105', 'change'),
  DemoActivity('Yesterday 16:30', 'Rule changed: check-in stays open for 15 min (was 10)', 'Admin office', 'change'),
  DemoActivity('Yesterday 11:02', 'Check-in refused: outside campus', 'Tariq Al-Mansoor · CS101', 'refused'),
];

const demoRecentCheckins = [
  ('Amara Mensah', '10:04', 'Present'),
  ('Kwame Chen', '10:03', 'Present'),
  ('Sara Osei', '10:02', 'Present'),
  ('Tariq Larsson', '10:18', 'Late'),
  ('Elena Novak', '10:01', 'Present'),
];

const demoLecturerToday = [
  ('10:00 – 11:30', 'CS101 Algorithms', 'Room 402 · In person · 48 students', 'start', 'Start'),
  ('13:15 – 14:45', 'DB202 Databases', 'Online · 52 students', 'later', 'Opens at 13:00'),
  ('15:30 – 17:00', 'NW310 Networks', 'Lab 108 · 35 students', 'later', 'Opens at 15:15'),
  ('08:00 – 09:00', 'HC105 Human-Computer Interaction', 'Studio 1 · 41 of 44 attended', 'done', 'Finished'),
];
