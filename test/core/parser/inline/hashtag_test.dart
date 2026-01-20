import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser/parser.dart';
import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  final fullParser = MfmParser().build();

  /// ヘルパー: フルパーサーの結果から最初のHashtagNodeを取得
  HashtagNode? getFirstHashtag(Result<List<MfmNode>> result) {
    if (result is! Success) return null;
    final nodes = result.value;
    for (final node in nodes) {
      if (node is HashtagNode) return node;
    }
    return null;
  }

  group('HashtagParser（ハッシュタグ）', () {
    test('日本語ハッシュタグを解析できる', () {
      final result = fullParser.parse('#タグ');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'タグ');
    });

    test('日本語と英数字の混合タグを解析できる', () {
      final result = fullParser.parse('#ミスキー2024');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'ミスキー2024');
    });

    test('数字を含むタグを解析できる', () {
      final result = fullParser.parse('#tag123');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'tag123');
    });

    test('アンダースコアを含むタグを解析できる', () {
      final result = fullParser.parse('#tag_name');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'tag_name');
    });

    test('ハイフンを含むタグを解析できる', () {
      final result = fullParser.parse('#tag-name');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'tag-name');
    });

    test('数字のみの長いタグも無効（#1234567890 → テキスト）', () {
      final result = fullParser.parse('#1234567890');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
    });
  });

  group('HashtagParser（直前文字ガード）', () {
    test('先頭からのハッシュタグは有効', () {
      final result = fullParser.parse('#tag');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
    });

    test('英数字の直後のハッシュタグは無効', () {
      final result = fullParser.parse('abc#tag');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // 英数字の直後なのでハッシュタグとして認識されない
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'abc#tag');
    });

    test('スペースの後のハッシュタグは有効', () {
      final result = fullParser.parse('text #tag');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'tag');
    });
  });

  group('HashtagParser（括弧ネスト構造）', () {
    test('括弧ペアの後も続けて解析できる（#tag(value)more）', () {
      final result = fullParser.parse('#tag(value)more');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'tag(value)more');
    });

    test('複数の括弧ペアを含むタグを解析できる（#tag(a)[b]）', () {
      final result = fullParser.parse('#tag(a)[b]');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'tag(a)[b]');
    });

    test('括弧内に禁止文字がある場合は禁止文字で分離（#tag(a.b) → #tag + text）', () {
      final result = fullParser.parse('#tag(a.b)');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
    });

    test('空の括弧ペアを含むタグを解析できる（#tag()）', () {
      final result = fullParser.parse('#tag()');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'tag()');
    });

    test('括弧のみのタグを解析できる（#()）', () {
      final result = fullParser.parse('#()');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, '()');
    });
  });

  group('HashtagParser（エッジケース）', () {
    test('絵文字を含むタグを解析できる', () {
      final result = fullParser.parse('#🎉party');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, '🎉party');
    });

    test('長いタグを解析できる', () {
      final result = fullParser.parse('#abcdefghijklmnopqrstuvwxyz1234567890');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'abcdefghijklmnopqrstuvwxyz1234567890');
    });

    test('1文字のタグを解析できる', () {
      final result = fullParser.parse('#a');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'a');
    });

    test('日本語1文字のタグを解析できる', () {
      final result = fullParser.parse('#あ');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'あ');
    });
  });

  group('HashtagParser（グローバル深度統合テスト）', () {
    test('fn内のハッシュタグの括弧ネストがグローバル深度に影響する', () {
      // $[fn #tag(value)] のような構造で、fnの中でdepth=1、括弧内でdepth=2
      final result = fullParser.parse(r'$[tada #tag(value)]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<FnNode>());

      // FnNodeの中にHashtagNodeがあるはず
      final fn = nodes[0] as FnNode;
      expect(fn.children.any((n) => n is HashtagNode), isTrue);
      final hashtag = fn.children.firstWhere((n) => n is HashtagNode);
      expect((hashtag as HashtagNode).hashtag, 'tag(value)');
    });

    test('深いネスト構造でnestLimitに達する場合', () {
      // nestLimit=2で、fn(depth=1) > hashtag括弧(depth=2) > 内部括弧(depth=3 >= limit)
      final parserLimit2 = MfmParser().build(nestLimit: 2);
      final result = parserLimit2.parse(r'$[tada #tag(x(y)z)]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<FnNode>());

      // fnの中でhashtag括弧のネストがlimitに達するため、2重ネストは無効
      final fn = nodes[0] as FnNode;
      final hashtag = fn.children.firstWhere((n) => n is HashtagNode);
      // depth=1(fn) + depth=1(括弧) = 2 >= limit(2) なので2重ネストは無効
      expect((hashtag as HashtagNode).hashtag, 'tag');
    });
  });
}
