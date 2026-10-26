import 'package:flutter/material.dart';
import '../db.dart';
import '../logic.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  int classId = 1;
  List<Map<String, Object?>> classes = [];
  List<(Map<String, Object?>, StudentResult)> results = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await Db.get();
    classes = await d.query('classes');
    final rules = await Rules.load();
    final subjects =
        await d.query('subjects', where: 'class_id=?', whereArgs: [classId]);
    final students = await d.query('students',
        where: 'class_id=?', whereArgs: [classId], orderBy: 'seat_no');
    final out = <(Map<String, Object?>, StudentResult)>[];
    for (final s in students) {
      final scores = <SubjectScore>[];
      for (final sub in subjects) {
        final g = await d.query('grades',
            where: 'student_id=? AND subject_id=?',
            whereArgs: [s['id'], sub['id']]);
        final m = g.isEmpty ? <String, Object?>{} : g.first;
        double? n(String k) => (m[k] as num?)?.toDouble();
        scores.add(SubjectScore(sub['name'] as String, n('t1_work'),
            n('t1_exam'), n('t2_work'), n('t2_exam')));
      }
      out.add((s, compute(scores, rules)));
    }
    // الترتيب بحسب المجموع تنازلياً
    out.sort((a, b) => b.$2.total.compareTo(a.$2.total));
    results = out;
    if (mounted) setState(() {});
  }

  Color _color(String s) => s == 'ناجح'
      ? Colors.green
      : s == 'راسب'
          ? Colors.red
          : Colors.orange;

  @override
  Widget build(BuildContext context) {
    final pass = results.where((r) => r.$2.status == 'ناجح').length;
    return Scaffold(
      appBar: AppBar(title: const Text('النتائج')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButton<int>(
            isExpanded: true,
            value: classId,
            items: [
              for (final c in classes)
                DropdownMenuItem(
                    value: c['id'] as int, child: Text(c['name'] as String))
            ],
            onChanged: (v) {
              classId = v!;
              _load();
            },
          ),
        ),
        Text('الإجمالي: ${results.length} • ناجحون: $pass'),
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (_, i) {
              final s = results[i].$1, r = results[i].$2;
              return ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(s['name'] as String),
                subtitle: Text(
                    '${r.total.toStringAsFixed(0)} / ${r.max.toStringAsFixed(0)}'
                    ' • ${r.percent.toStringAsFixed(1)}% • ${r.rating}'
                    '${r.failed.isEmpty ? '' : '\nراسب في: ${r.failed.join('، ')}'}'),
                trailing: Text(r.status,
                    style: TextStyle(
                        color: _color(r.status), fontWeight: FontWeight.bold)),
              );
            },
          ),
        ),
      ]),
    );
  }
}
