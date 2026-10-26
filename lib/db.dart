import 'logic.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class Db {
  static Database? _db;

  static const basicSubjects = [
    'القرآن الكريم', 'التربية الإسلامية', 'اللغة العربية',
    'اللغة الإنجليزية', 'الرياضيات', 'العلوم', 'الاجتماعيات',
    'السلوك والمواظبة',
  ];
  static const secSubjects = [
    'القرآن الكريم', 'التربية الإسلامية', 'اللغة العربية',
    'اللغة الإنجليزية', 'الرياضيات', 'الفيزياء', 'الكيمياء', 'الأحياء',
    'السلوك والمواظبة',
  ];
  static const classNames = [
    'الأول أساسي', 'الثاني أساسي', 'الثالث أساسي', 'الرابع أساسي',
    'الخامس أساسي', 'السادس أساسي', 'السابع أساسي', 'الثامن أساسي',
    'التاسع أساسي', 'الأول الثانوي', 'الثاني الثانوي علمي',
    'الثالث الثانوي علمي',
  ];

  static Future<Database> get() async {
    if (_db != null) return _db!;
    final path = p.join(await getDatabasesPath(), 'control.db');
    _db = await openDatabase(path,
        version: 2, onCreate: _create, onUpgrade: _upgrade);
    return _db!;
  }

  static Future<void> _upgrade(Database d, int oldV, int newV) async {
    if (oldV < 2) {
      await d.execute('ALTER TABLE students ADD COLUMN committee_no INTEGER');
    }
  }

  static Future<void> _create(Database d, int v) async {
    await d.execute('CREATE TABLE settings(k TEXT PRIMARY KEY, v TEXT)');
    await d.execute(
        'CREATE TABLE classes(id INTEGER PRIMARY KEY, name TEXT, seat_start INTEGER)');
    await d.execute(
        'CREATE TABLE subjects(id INTEGER PRIMARY KEY AUTOINCREMENT, class_id INTEGER, name TEXT)');
    await d.execute('''CREATE TABLE students(
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, gender TEXT,
      class_id INTEGER, seat_no INTEGER, committee_no INTEGER,
      status TEXT DEFAULT 'مستجد')''');
    await d.execute('''CREATE TABLE grades(
      student_id INTEGER, subject_id INTEGER,
      t1_work REAL, t1_exam REAL, t2_work REAL, t2_exam REAL,
      PRIMARY KEY(student_id, subject_id))''');
    final defaults = {
      'school': '', 'year': '1446هـ / 2024-2025م',
      'min_percent': '50', 'max_failed_second_round': '2',
    };
    for (final e in defaults.entries) {
      await d.insert('settings', {'k': e.key, 'v': e.value});
    }
    for (var i = 0; i < classNames.length; i++) {
      final id = i + 1;
      await d.insert('classes',
          {'id': id, 'name': classNames[i], 'seat_start': id * 1000 + 1});
      final subs = id >= 10 ? secSubjects : basicSubjects;
      for (final s in subs) {
        await d.insert('subjects', {'class_id': id, 'name': s});
      }
    }
  }

  /// القيم الافتراضية لجميع الإعدادات (تُستخدم إن لم تُحفظ قيمة).
  static const defaults = {
    'school': '', 'year': '1446هـ / 2024-2025م',
    'min_percent': '50', 'max_failed_second_round': '2',
    'max_t1_work': '20', 'max_t1_exam': '30',
    'max_t2_work': '20', 'max_t2_exam': '30',
    'committee_capacity': '25', 'separate_gender': '1',
    'r_excellent': '85', 'r_verygood': '75', 'r_good': '65', 'r_ok': '50',
  };

  static Future<String> setting(String k) async {
    final d = await get();
    final r = await d.query('settings', where: 'k=?', whereArgs: [k]);
    return r.isEmpty ? (defaults[k] ?? '') : r.first['v'] as String;
  }

  static Future<void> setSetting(String k, String v) async {
    final d = await get();
    await d.insert('settings', {'k': k, 'v': v},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<void> saveGrade(int sid, int subId, String col, double? val) async {
    final d = await get();
    await d.insert('grades', {'student_id': sid, 'subject_id': subId},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await d.update('grades', {col: val},
        where: 'student_id=? AND subject_id=?', whereArgs: [sid, subId]);
  }

  /// يعيد ترقيم الجلوس للصف تسلسلياً بحسب ترتيب القيد.
  static Future<void> assignSeats(int classId) async {
    final d = await get();
    final start = (await d.query('classes', where: 'id=?', whereArgs: [classId]))
        .first['seat_start'] as int;
    final st = await d.query('students',
        where: 'class_id=?', whereArgs: [classId], orderBy: 'id');
    for (var i = 0; i < st.length; i++) {
      await d.update('students', {'seat_no': start + i},
          where: 'id=?', whereArgs: [st[i]['id']]);
    }
  }

  /// توزيع الطلاب على اللجان لجميع الصفوف بترقيم متسلسل.
  /// يعيد عدد اللجان الناتجة.
  static Future<int> distributeCommittees(int capacity, bool separate) async {
    final d = await get();
    final classes = await d.query('classes', orderBy: 'id');
    var counter = 0;
    await d.update('students', {'committee_no': null});
    for (final c in classes) {
      final cid = c['id'] as int;
      await assignSeats(cid);
      final st = await d.query('students',
          where: 'class_id=?', whereArgs: [cid], orderBy: 'seat_no, id');
      if (st.isEmpty) continue;
      final groups = separate
          ? [
              st.where((s) => s['gender'] != 'أنثى').toList(),
              st.where((s) => s['gender'] == 'أنثى').toList(),
            ]
          : [st];
      for (final g in groups) {
        var i = 0;
        for (final size in splitSizes(g.length, capacity)) {
          counter++;
          for (var k = 0; k < size; k++) {
            await d.update('students', {'committee_no': counter},
                where: 'id=?', whereArgs: [g[i++]['id']]);
          }
        }
      }
    }
    return counter;
  }
}
