import 'package:flutter_test/flutter_test.dart';
import 'package:school_control/logic.dart';

const rules = Rules(
  passPercent: 50, maxFailedSecondRound: 2,
  excellent: 85, veryGood: 75, good: 65, ok: 50,
  maxW1: 20, maxE1: 30, maxW2: 20, maxE2: 30,
);

void main() {
  splitTests();
  test('طالب ناجح في كل المواد', () {
    final r = compute([
      SubjectScore('عربي', 20, 30, 20, 30),
      SubjectScore('رياضيات', 15, 25, 15, 25),
    ], rules);
    expect(r.status, 'ناجح');
    expect(r.rating, 'ممتاز');
  });

  test('رسوب في مادة واحدة يعني دوراً ثانياً', () {
    final r = compute([
      SubjectScore('عربي', 20, 30, 20, 30),
      SubjectScore('رياضيات', 5, 10, 5, 10),
    ], rules);
    expect(r.status, 'دور ثانٍ');
    expect(r.failed, ['رياضيات']);
  });

  test('بدون أي درجات يكون الطالب غائباً', () {
    final r = compute([SubjectScore('عربي', null, null, null, null)], rules);
    expect(r.status, 'غائب');
  });
}

void splitTests() {
  test('تقسيم متوازن للجان', () {
    expect(splitSizes(60, 25), [20, 20, 20]);
    expect(splitSizes(26, 25), [13, 13]);
    expect(splitSizes(0, 25), isEmpty);
  });
}
