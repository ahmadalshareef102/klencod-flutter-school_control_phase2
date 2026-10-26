import 'package:flutter/material.dart';
import '../db.dart';
import '../logic.dart';

class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key});
  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  int classId = 1;
  int? subjectId;
  List<Map<String, Object?>> classes = [], subjects = [], rows = [];

  List<(String, String, double)> cols = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await Db.get();
    final r = await Rules.load();
    cols = [
      ('t1_work', 'محصلة 1', r.maxW1),
      ('t1_exam', 'نصفي', r.maxE1),
      ('t2_work', 'محصلة 2', r.maxW2),
      ('t2_exam', 'نهائي', r.maxE2),
    ];
    classes = await d.query('classes');
    subjects =
        await d.query('subjects', where: 'class_id=?', whereArgs: [classId]);
    subjectId ??= subjects.first['id'] as int;
    if (!subjects.any((s) => s['id'] == subjectId)) {
      subjectId = subjects.first['id'] as int;
    }
    rows = await d.rawQuery('''
      SELECT s.id, s.name, s.seat_no, g.t1_work, g.t1_exam, g.t2_work, g.t2_exam
      FROM students s LEFT JOIN grades g
        ON g.student_id=s.id AND g.subject_id=?
      WHERE s.class_id=? ORDER BY s.seat_no, s.id''', [subjectId, classId]);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('رصد الدرجات')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: classId,
                  items: [
                    for (final c in classes)
                      DropdownMenuItem(
                          value: c['id'] as int,
                          child: Text(c['name'] as String))
                  ],
                  onChanged: (v) {
                    classId = v!;
                    subjectId = null;
                    _load();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: subjectId,
                  items: [
                    for (final s in subjects)
                      DropdownMenuItem(
                          value: s['id'] as int,
                          child: Text(s['name'] as String))
                  ],
                  onChanged: (v) {
                    subjectId = v;
                    _load();
                  },
                ),
              ),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              itemBuilder: (_, i) {
                final r = rows[i];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}. ${r['name']}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(children: [
                          for (final c in cols)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: TextFormField(
                                  key: ValueKey('${r['id']}-$subjectId-${c.$1}-${c.$3}'),
                                  initialValue: r[c.$1] == null
                                      ? ''
                                      : (r[c.$1] as num).toString(),
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    labelText: '${c.$2} /${c.$3.toInt()}',
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                  onChanged: (t) {
                                    final v = double.tryParse(t);
                                    if (t.isNotEmpty && (v == null || v > c.$3 || v < 0)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'الدرجة يجب أن تكون بين 0 و ${c.$3.toInt()}')));
                                      return;
                                    }
                                    Db.saveGrade(r['id'] as int, subjectId!, c.$1, v);
                                  },
                                ),
                              ),
                            ),
                        ]),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      );
}
