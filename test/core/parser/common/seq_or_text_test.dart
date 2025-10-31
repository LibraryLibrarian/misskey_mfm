import 'package:test/test.dart';
import 'package:petitparser/petitparser.dart';
import 'package:misskey_mfm/core/parser.dart';

void main() {
  group('seqOrText（コア合成）', () {
    // 単純な start/inner/end を使った検証
    final start = string('*');
    final end = string('*');
    final inner = any().starLazy(end).flatten();

    test('完全一致ならシーケンスとして成功', () {
      final parser = seqOrText(start, inner, end);
      final result = parser.parse('*abc*');
      expect(result is Success, isTrue);
    });

    test('endが無い場合はフォールバックでテキスト', () {
      final parser = seqOrText(start, inner, end);
      final result = parser.parse('*abc');
      expect(result is Success, isTrue);
      expect(result.value is String, isTrue);
      expect(result.value as String, '*abc');
    });
  });
}
