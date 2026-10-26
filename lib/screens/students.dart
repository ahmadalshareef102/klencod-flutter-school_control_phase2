import 'package:flutter/material.dart';
import '../db.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  int classId = 1;
  List<Map<String, Object?>> classes = [], students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await Db.get();
    classes = await d.query('classes');
    students = await d.query('students',
        where: 'class_id=?', whereArgs: [classId], orderBy: 'seat_no, id');
    if (mounted) setState(() {});
  }

  Future<void> _add() async {
    final name = TextEditingController();
    var gender = 'ذكر';
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('إضافة طالب'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'الاسم الرباعي')),
            DropdownButton<String>(
              value: gender,
              items: const ['ذكر', 'أنثى']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) => set(() => gender = v!),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                if (name.text.trim().isEmpty) return;
                final d = await Db.get();
                await d.insert('students', {
                  'name': name.text.trim(),
                  'gender': gender,
                  'class_id': classId,
                });
                if (c.mounted) Navigator.pop(c);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    await Db.assignSeats(classId);
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الطلاب والقيد')),
        floatingActionButton:
            FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
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
          Text('العدد: ${students.length}'),
          Expanded(
            child: ListView.builder(
              itemCount: students.length,
              itemBuilder: (_, i) {
                final s = students[i];
                return ListTile(
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(s['name'] as String),
                  subtitle: Text('${s['gender']} • رقم الجلوس: ${s['seat_no'] ?? '-'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final d = await Db.get();
                      await d.delete('students',
                          where: 'id=?', whereArgs: [s['id']]);
                      await d.delete('grades',
                          where: 'student_id=?', whereArgs: [s['id']]);
                      await Db.assignSeats(classId);
                      _load();
                    },
                  ),
                );
              },
            ),
          ),
        ]),
      );
}
