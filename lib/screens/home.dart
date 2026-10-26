import 'package:flutter/material.dart';
import '../db.dart';
import 'students.dart';
import 'grades.dart';
import 'results.dart';
import 'committees.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final items = <(String, IconData, Widget)>[
      ('الطلاب والقيد', Icons.groups, const StudentsScreen()),
      ('اللجان والجلوس', Icons.event_seat, const CommitteesScreen()),
      ('رصد الدرجات', Icons.edit_note, const GradesScreen()),
      ('النتائج', Icons.fact_check, const ResultsScreen()),
      ('الإعدادات', Icons.settings, const SettingsScreen()),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('الكنترول المدرسي')),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          for (final it in items)
            Card(
              child: InkWell(
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => it.$3)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(it.$2, size: 48),
                    const SizedBox(height: 8),
                    Text(it.$1, style: const TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // (العنوان، [(المفتاح، التسمية)])
  static const sections = <(String, List<(String, String)>)>[
    ('بيانات المدرسة', [('school', 'اسم المدرسة'), ('year', 'العام الدراسي')]),
    ('سقوف الدرجات لكل مادة', [
      ('max_t1_work', 'المحصلة الأولى'),
      ('max_t1_exam', 'اختبار نصف العام'),
      ('max_t2_work', 'المحصلة الثانية'),
      ('max_t2_exam', 'الاختبار النهائي'),
    ]),
    ('اللجان', [('committee_capacity', 'سعة اللجنة (عدد الطلاب)')]),
    ('قواعد النجاح', [
      ('min_percent', 'نسبة النجاح في المادة %'),
      ('max_failed_second_round', 'أقصى عدد مواد للدور الثاني'),
    ]),
    ('حدود التقديرات (نسبة مئوية دنيا)', [
      ('r_excellent', 'ممتاز من'),
      ('r_verygood', 'جيد جداً من'),
      ('r_good', 'جيد من'),
      ('r_ok', 'مقبول من'),
    ]),
  ];
  final ctrls = <String, TextEditingController>{};
  bool sep = true;

  @override
  void initState() {
    super.initState();
    Db.setting('separate_gender').then((v) => setState(() => sep = v == '1'));
    for (final sec in sections) {
      for (final f in sec.$2) {
        ctrls[f.$1] = TextEditingController();
        Db.setting(f.$1).then((v) => setState(() => ctrls[f.$1]!.text = v));
      }
    }
  }

  Future<void> _reset() async {
    for (final e in Db.defaults.entries) {
      if (e.key == 'school') continue;
      await Db.setSetting(e.key, e.value);
      ctrls[e.key]?.text = e.value;
    }
    sep = Db.defaults['separate_gender'] == '1';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الإعدادات'), actions: [
          IconButton(
              tooltip: 'استعادة الافتراضي',
              icon: const Icon(Icons.restore),
              onPressed: _reset),
        ]),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          for (final sec in sections) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(sec.$1,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            for (final f in sec.$2)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: ctrls[f.$1],
                  keyboardType: f.$1 == 'school' || f.$1 == 'year'
                      ? TextInputType.text
                      : TextInputType.number,
                  decoration: InputDecoration(
                      labelText: f.$2, border: const OutlineInputBorder()),
                  onChanged: (v) => Db.setSetting(f.$1, v.trim()),
                ),
              ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('فصل الذكور عن الإناث في اللجان'),
            value: sep,
            onChanged: (v) {
              setState(() => sep = v);
              Db.setSetting('separate_gender', v ? '1' : '0');
            },
          ),
          const Text(
              'تُطبَّق التغييرات فوراً على الرصد والنتائج. طابق القيم مع لوائح الوزارة.'),
        ]),
      );
}
