import 'package:misskey_mfm_parser/core/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('seqOrText（コア合成）', () {
    // 単純な start/inner/end を使った検証
    final start = string('*');
    final end = string('*');
    final inner = any().starLazy(end).flatten();

    test('完全一致ならSeqOrTextSuccessとして成功', () {
      final parser = seqOrText<String>(start, inner, end);
      final result = parser.parse('*abc*');
      expect(result is Success, isTrue);
      expect(result.value, isA<SeqOrTextSuccess<String>>());

      final success = result.value as SeqOrTextSuccess<String>;
      expect(success.children, hasLength(1));
      expect(success.children.first, 'abc');
    });

    test('endが無い場合はSeqOrTextFallbackでテキスト', () {
      final parser = seqOrText<String>(start, inner, end);
      final result = parser.parse('*abc');
      expect(result is Success, isTrue);
      expect(result.value, isA<SeqOrTextFallback<String>>());

      final fallback = result.value as SeqOrTextFallback<String>;
      expect(fallback.text, '*abc');
    });

    test('switch式でパターンマッチできること', () {
      final parser = seqOrText<String>(start, inner, end);

      // 成功ケース
      final successResult = parser.parse('*hello*');
      final successMessage = switch (successResult.value) {
        SeqOrTextSuccess(:final children) => 'Success: ${children.join()}',
        SeqOrTextFallback(:final text) => 'Fallback: $text',
      };
      expect(successMessage, 'Success: hello');

      // フォールバックケース
      final fallbackResult = parser.parse('*world');
      final fallbackMessage = switch (fallbackResult.value) {
        SeqOrTextSuccess(:final children) => 'Success: ${children.join()}',
        SeqOrTextFallback(:final text) => 'Fallback: $text',
      };
      expect(fallbackMessage, 'Fallback: *world');
    });

    test('複数の内部要素を正しく収集できること', () {
      // 各文字を個別に収集するパーサー
      final charParser = any();
      final multiParser = seqOrText<String>(start, charParser, end);
      final result = multiParser.parse('*abc*');

      expect(result is Success, isTrue);
      expect(result.value, isA<SeqOrTextSuccess<String>>());

      final success = result.value as SeqOrTextSuccess<String>;
      expect(success.children, ['a', 'b', 'c']);
    });

    test('startのみマッチ時もフォールバックとして成功', () {
      final parser = seqOrText<String>(start, inner, end);
      final result = parser.parse('*');
      expect(result is Success, isTrue);
      expect(result.value, isA<SeqOrTextFallback<String>>());

      final fallback = result.value as SeqOrTextFallback<String>;
      expect(fallback.text, '*');
    });
  });
}
