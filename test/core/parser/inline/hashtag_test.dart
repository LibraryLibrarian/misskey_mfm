import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser/inline/hashtag.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  group('HashtagParser（ハッシュタグ）', () {
    final parser = HashtagParser().build();

    test('基本的なハッシュタグを解析できる', () {
      final result = parser.parse('#tag');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<HashtagNode>());
      final hashtag = node as HashtagNode;
      expect(hashtag.hashtag, 'tag');
    });

    test('日本語ハッシュタグを解析できる', () {
      final result = parser.parse('#タグ');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'タグ');
    });

    test('日本語と英数字の混合タグを解析できる', () {
      final result = parser.parse('#ミスキー2024');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'ミスキー2024');
    });

    test('数字を含むタグを解析できる', () {
      final result = parser.parse('#tag123');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag123');
    });

    test('アンダースコアを含むタグを解析できる', () {
      final result = parser.parse('#tag_name');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag_name');
    });

    test('ハイフンを含むタグを解析できる', () {
      final result = parser.parse('#tag-name');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag-name');
    });

    test('数字のみのタグは無効（#123）', () {
      final result = parser.parse('#123');
      expect(result is Failure, isTrue);
    });

    test('数字のみの長いタグも無効（#1234567890）', () {
      final result = parser.parse('#1234567890');
      expect(result is Failure, isTrue);
    });
  });

  group('HashtagParser（禁止文字で分離）', () {
    final parser = HashtagParser().build();

    test('ピリオドで分離される（#tag.rest → #tag）', () {
      final result = parser.parse('#tag.rest');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag');
      // パース位置は #tag の直後（4文字目）で止まる
      expect((result as Success).position, 4);
    });

    test('感嘆符で分離される（#tag!rest → #tag）', () {
      final result = parser.parse('#tag!rest');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });

    test('疑問符で分離される（#tag?rest → #tag）', () {
      final result = parser.parse('#tag?rest');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });

    test('コンマで分離される（#tag,rest → #tag）', () {
      final result = parser.parse('#tag,rest');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });

    test('コロンで分離される（#tag:rest → #tag）', () {
      final result = parser.parse('#tag:rest');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });

    test('スラッシュで分離される（#tag/rest → #tag）', () {
      final result = parser.parse('#tag/rest');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });

    test('半角スペースで分離される（#tag rest → #tag）', () {
      final result = parser.parse('#tag rest');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });

    test('全角スペースで分離される（#tag\u3000rest → #tag）', () {
      final result = parser.parse('#tag\u3000rest');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });

    test('閉じ括弧で分離される（#tag)rest → #tag）', () {
      final result = parser.parse('#tag)rest');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });

    test('シングルクォートで分離される', () {
      final result = parser.parse("#tag'rest");
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });

    test('ダブルクォートで分離される', () {
      final result = parser.parse('#tag"rest');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });

    test('山括弧で分離される（#tag<rest> → #tag）', () {
      final result = parser.parse('#tag<rest>');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });

    test('ハッシュ記号で分離される（#tag#rest → #tag）', () {
      final result = parser.parse('#tag#rest');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });
  });

  group('HashtagParser（直前文字ガード）', () {
    final parser = HashtagParser().build();

    test('先頭からのハッシュタグは有効', () {
      final result = parser.parse('#tag');
      expect(result is Success, isTrue);
    });

    // 直前文字ガードのテストは統合テストで確認
  });

  group('HashtagParser（フォールバック付き）', () {
    final parser = HashtagParser().buildWithFallback();

    test('有効なハッシュタグを解析できる', () {
      final result = parser.parse('#tag');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<HashtagNode>());
    });

    test('数字のみの場合は#をテキストとして返す', () {
      final result = parser.parse('#123');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<TextNode>());
      expect((node as TextNode).text, '#');
    });

    test('タグ内容がない場合は#をテキストとして返す', () {
      final result = parser.parse('#');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<TextNode>());
      expect((node as TextNode).text, '#');
    });

    test('禁止文字で始まる場合は#をテキストとして返す', () {
      final result = parser.parse('# ');
      expect(result is Success, isTrue);
      final node = (result as Success).value as MfmNode;
      expect(node, isA<TextNode>());
      expect((node as TextNode).text, '#');
    });
  });

  group('HashtagParser（括弧ネスト構造）', () {
    final parser = HashtagParser().build();

    test('丸括弧ペアを含むタグを解析できる（#tag(value)）', () {
      final result = parser.parse('#tag(value)');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag(value)');
      expect((result as Success).position, 11);
    });

    test('角括弧ペアを含むタグを解析できる（#tag[value]）', () {
      final result = parser.parse('#tag[value]');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag[value]');
      expect((result as Success).position, 11);
    });

    test('鉤括弧ペアを含むタグを解析できる（#tag「value」）', () {
      final result = parser.parse('#tag「value」');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag「value」');
      // #(1) + tag(3) + 「(1) + value(5) + 」(1) = 11
      expect((result as Success).position, 11);
    });

    test('全角丸括弧ペアを含むタグを解析できる（#tag（value）', () {
      final result = parser.parse('#tag（value）');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag（value）');
      // #(1) + tag(3) + （(1) + value(5) + ）(1) = 11
      expect((result as Success).position, 11);
    });

    test('括弧が閉じていない場合は括弧で分離される（#tag(value → #tag）', () {
      final result = parser.parse('#tag(value');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });

    test('角括弧が閉じていない場合は分離される（#tag[value → #tag）', () {
      final result = parser.parse('#tag[value');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });

    test('2重ネストは無効（#tag(x(y)z) → #tag）', () {
      final result = parser.parse('#tag(x(y)z)');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      // 深度制限により、2重ネストは無効で #tag で終了
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });

    test('括弧ペアの後も続けて解析できる（#tag(value)more）', () {
      final result = parser.parse('#tag(value)more');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag(value)more');
      expect((result as Success).position, 15);
    });

    test('複数の括弧ペアを含むタグを解析できる（#tag(a)[b]）', () {
      final result = parser.parse('#tag(a)[b]');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag(a)[b]');
      expect((result as Success).position, 10);
    });

    test('括弧内に禁止文字がある場合は禁止文字で分離（#tag(a.b) → #tag）', () {
      final result = parser.parse('#tag(a.b)');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      // 括弧内でも禁止文字（.）により分離される
      // 閉じ括弧が見つからないため、開き括弧で終了
      expect(hashtag.hashtag, 'tag');
      expect((result as Success).position, 4);
    });

    test('空の括弧ペアを含むタグを解析できる（#tag()）', () {
      final result = parser.parse('#tag()');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag()');
      expect((result as Success).position, 6);
    });

    test('括弧のみのタグを解析できる（#()）', () {
      final result = parser.parse('#()');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, '()');
      expect((result as Success).position, 3);
    });

    test('mfm.js互換: 混合括弧（#foo(bar)）', () {
      final result = parser.parse('#foo(bar)');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'foo(bar)');
    });

    test('mfm.js互換: nestLimit=2では2重ネストが有効', () {
      final parserNest2 = HashtagParser().build(nestLimit: 2);
      final result = parserNest2.parse('#tag(x(y)z)');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'tag(x(y)z)');
    });
  });

  group('HashtagParser（エッジケース）', () {
    final parser = HashtagParser().build();

    test('絵文字を含むタグを解析できる', () {
      final result = parser.parse('#🎉party');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, '🎉party');
    });

    test('長いタグを解析できる', () {
      final result =
          parser.parse('#abcdefghijklmnopqrstuvwxyz1234567890');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'abcdefghijklmnopqrstuvwxyz1234567890');
    });

    test('1文字のタグを解析できる', () {
      final result = parser.parse('#a');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'a');
    });

    test('日本語1文字のタグを解析できる', () {
      final result = parser.parse('#あ');
      expect(result is Success, isTrue);
      final hashtag = (result as Success).value as HashtagNode;
      expect(hashtag.hashtag, 'あ');
    });
  });
}
