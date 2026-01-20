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
    // mfm.js/test/parser.ts:799-803
    test('mfm-js互換テスト: basic', () {
      final result = fullParser.parse('#tag');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'tag');
    });

    // mfm.js/test/parser.ts:805-809
    test('mfm-js互換テスト: basic 2', () {
      final result = fullParser.parse('before #abc after');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'before ');
      expect(nodes[1], isA<HashtagNode>());
      expect((nodes[1] as HashtagNode).hashtag, 'abc');
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, ' after');
    });

    // mfm.js/test/parser.ts:811-815
    test('mfm-js互換テスト: with keycap number sign', () {
      final result = fullParser.parse('#️⃣abc123 #abc');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<UnicodeEmojiNode>());
      expect((nodes[0] as UnicodeEmojiNode).emoji, '#️⃣');
      expect(nodes[1], isA<TextNode>());
      expect((nodes[1] as TextNode).text, 'abc123 ');
      expect(nodes[2], isA<HashtagNode>());
      expect((nodes[2] as HashtagNode).hashtag, 'abc');
    });

    // mfm.js/test/parser.ts:817-822
    test('mfm-js互換テスト: with keycap number sign 2', () {
      final result = fullParser.parse('abc\n#️⃣abc');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, 'abc\n');
      expect(nodes[1], isA<UnicodeEmojiNode>());
      expect((nodes[1] as UnicodeEmojiNode).emoji, '#️⃣');
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, 'abc');
    });

    // mfm.js/test/parser.ts:824-832
    test(
      'mfm-js互換テスト: ignore a hashtag if the before char is neither a space nor an LF nor [^a-z0-9]i',
      () {
        var result = fullParser.parse('abc#abc');
        expect(result is Success, isTrue);
        var nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 1);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'abc#abc');

        result = fullParser.parse('あいう#abc');
        expect(result is Success, isTrue);
        nodes = (result as Success).value as List<MfmNode>;
        expect(nodes.length, 2);
        expect(nodes[0], isA<TextNode>());
        expect((nodes[0] as TextNode).text, 'あいう');
        expect(nodes[1], isA<HashtagNode>());
        expect((nodes[1] as HashtagNode).hashtag, 'abc');
      },
    );

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

    // mfm.js/test/parser.ts:882-886
    test('mfm-js互換テスト: allow including number', () {
      final result = fullParser.parse('#foo123');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'foo123');
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

    // mfm.js/test/parser.ts:918-922
    test('mfm-js互換テスト: disallow number only', () {
      final result = fullParser.parse('#123');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      // 数字のみのタグは無効なので、テキストとして扱われる
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
    });

    test('数字のみの長いタグも無効（#1234567890 → テキスト）', () {
      final result = fullParser.parse('#1234567890');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
    });
  });

  // mfm.js/test/parser.ts:834-880
  group('HashtagParser（禁止文字で分離）', () {
    test('mfm-js互換テスト: ピリオドで分離される', () {
      final result = fullParser.parse('#tag.rest');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect(nodes[0], isA<HashtagNode>());
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
      expect(nodes[1], isA<TextNode>());
      expect((nodes[1] as TextNode).text, '.rest');
    });

    test('mfm-js互換テスト: 感嘆符で分離される', () {
      final result = fullParser.parse('#tag!rest');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
      expect((nodes[1] as TextNode).text, '!rest');
    });

    test('mfm-js互換テスト: 疑問符で分離される', () {
      final result = fullParser.parse('#tag?rest');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
      expect((nodes[1] as TextNode).text, '?rest');
    });

    test('mfm-js互換テスト: コンマで分離される', () {
      final result = fullParser.parse('#tag,rest');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
      expect((nodes[1] as TextNode).text, ',rest');
    });

    test('mfm-js互換テスト: コロンで分離される', () {
      final result = fullParser.parse('#tag:rest');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
      expect((nodes[1] as TextNode).text, ':rest');
    });

    test('mfm-js互換テスト: スラッシュで分離される', () {
      final result = fullParser.parse('#tag/rest');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
      expect((nodes[1] as TextNode).text, '/rest');
    });

    test('mfm-js互換テスト: 半角スペースで分離される', () {
      final result = fullParser.parse('#tag rest');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
      expect((nodes[1] as TextNode).text, ' rest');
    });

    test('mfm-js互換テスト: 全角スペースで分離される', () {
      final result = fullParser.parse('#tag\u3000rest');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
      expect((nodes[1] as TextNode).text, '\u3000rest');
    });

    test('mfm-js互換テスト: 閉じ括弧で分離される', () {
      final result = fullParser.parse('#tag)rest');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
      expect((nodes[1] as TextNode).text, ')rest');
    });

    test('mfm-js互換テスト: シングルクォートで分離される', () {
      final result = fullParser.parse("#tag'rest");
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
      expect((nodes[1] as TextNode).text, "'rest");
    });

    test('mfm-js互換テスト: ダブルクォートで分離される', () {
      final result = fullParser.parse('#tag"rest');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
      expect((nodes[1] as TextNode).text, '"rest');
    });

    test('mfm-js互換テスト: 山括弧で分離される', () {
      final result = fullParser.parse('#tag<rest>');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
    });

    // mfm.js/test/parser.ts:864-868
    test('mfm-js互換テスト: ignore square bracket', () {
      final result = fullParser.parse('#Foo]');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect(nodes[0], isA<HashtagNode>());
      expect((nodes[0] as HashtagNode).hashtag, 'Foo');
      expect(nodes[1], isA<TextNode>());
      expect((nodes[1] as TextNode).text, ']');
    });

    test('mfm-js互換テスト: ハッシュ記号で分離される', () {
      // 直前文字が英数字の場合はハッシュタグとして認識されない
      // 'g' が直前にあるため '#rest' はハッシュタグにならない
      final result = fullParser.parse('#tag#rest');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect(nodes[0], isA<HashtagNode>());
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
      expect(nodes[1], isA<TextNode>());
      expect((nodes[1] as TextNode).text, '#rest');
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

  // mfm.js/test/parser.ts:888-928
  group('HashtagParser（括弧ネスト構造）', () {
    test('mfm-js互換テスト: 丸括弧ペアを含むタグを解析できる', () {
      final result = fullParser.parse('#tag(value)');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'tag(value)');
    });

    test('mfm-js互換テスト: 角括弧ペアを含むタグを解析できる', () {
      final result = fullParser.parse('#tag[value]');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'tag[value]');
    });

    test('mfm-js互換テスト: 鉤括弧ペアを含むタグを解析できる', () {
      final result = fullParser.parse('#tag「value」');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'tag「value」');
    });

    test('mfm-js互換テスト: 全角丸括弧ペアを含むタグを解析できる', () {
      final result = fullParser.parse('#tag（value）');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'tag（value）');
    });

    // mfm.js/test/parser.ts:906-910
    test('mfm-js互換テスト: with brackets "()" (space before)', () {
      final result = fullParser.parse('(bar #foo)');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, '(bar ');
      expect(nodes[1], isA<HashtagNode>());
      expect((nodes[1] as HashtagNode).hashtag, 'foo');
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, ')');
    });

    // mfm.js/test/parser.ts:912-916
    test('mfm-js互換テスト: with brackets "「」" (space before)', () {
      final result = fullParser.parse('「bar #foo」');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 3);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, '「bar ');
      expect(nodes[1], isA<HashtagNode>());
      expect((nodes[1] as HashtagNode).hashtag, 'foo');
      expect(nodes[2], isA<TextNode>());
      expect((nodes[2] as TextNode).text, '」');
    });

    test('mfm-js互換テスト: 括弧が閉じていない場合は括弧で分離される', () {
      final result = fullParser.parse('#tag(value');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect(nodes[0], isA<HashtagNode>());
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
      expect(nodes[1], isA<TextNode>());
      expect((nodes[1] as TextNode).text, '(value');
    });

    test('mfm-js互換テスト: 角括弧が閉じていない場合は分離される', () {
      final result = fullParser.parse('#tag[value');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
    });

    test('mfm-js互換テスト: 2重ネストも有効', () {
      // デフォルトのnestLimitは20なので2重ネストも有効
      final result = fullParser.parse('#tag(x(y)z)');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'tag(x(y)z)');
    });

    test('mfm-js互換テスト: nestLimit=1では2重ネストは無効', () {
      // nestLimit=1の場合は1重ネストまでしか許可されない
      final parserLimit1 = MfmParser().build(nestLimit: 1);
      final result = parserLimit1.parse('#tag(x(y)z)');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 2);
      expect(nodes[0], isA<HashtagNode>());
      expect((nodes[0] as HashtagNode).hashtag, 'tag');
    });

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

    test('mfm-js互換テスト: 混合括弧', () {
      final result = fullParser.parse('#foo(bar)');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'foo(bar)');
    });

    test('mfm-js互換テスト: nestLimit=2では2重ネストが有効', () {
      final parserNest2 = MfmParser().build(nestLimit: 2);
      final result = parserNest2.parse('#tag(x(y)z)');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'tag(x(y)z)');
    });

    test('mfm-js互換テスト: デフォルトのnestLimit=20では多重ネストが有効', () {
      // デフォルトでは20レベルまでネスト可能
      final result = fullParser.parse('#tag(x(y)z)');
      expect(result is Success, isTrue);
      final hashtag = getFirstHashtag(result);
      expect(hashtag, isNotNull);
      expect(hashtag!.hashtag, 'tag(x(y)z)');
    });

    // mfm.js/test/parser.ts:924-928
    test('mfm-js互換テスト: disallow number only (with brackets)', () {
      final result = fullParser.parse('(#123)');
      expect(result is Success, isTrue);
      final nodes = (result as Success).value as List<MfmNode>;
      expect(nodes.length, 1);
      expect(nodes[0], isA<TextNode>());
      expect((nodes[0] as TextNode).text, '(#123)');
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
