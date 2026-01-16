import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../common/utils.dart';
import 'url.dart';

/// リンクパーサー
///
/// mfm-js仕様に準拠したMarkdownリンクを解析
///
/// - `[label](url)` - 通常リンク（silent=false）
/// - `?[label](url)` - サイレントリンク（silent=true）
/// - ラベル内は再帰的にインラインパースを適用
/// - ラベル内ではURL、リンク、メンションは無効（linkLabel状態）
class LinkParser {
  /// リンクパーサーを構築
  ///
  /// [labelInlineParser] はラベル内のインライン構文をパースするパーサー
  /// このパーサーにはURL、リンク、メンションを除外したものを渡す必要がある
  Parser<MfmNode> buildWithInner(Parser<MfmNode> labelInlineParser) {
    return _LinkParserImpl(labelInlineParser);
  }

  /// フォールバック付きリンクパーサー
  ///
  /// リンクとして解析できない場合は、開始文字をテキストとして扱う
  Parser<MfmNode> buildWithFallback(Parser<MfmNode> labelInlineParser) {
    final completeLink = buildWithInner(labelInlineParser);

    // フォールバック: `?[` または `[` で始まるがリンクとして解析できない場合
    final fallback = (string('?[') | char('[')).flatten().map(
      (dynamic s) => TextNode(s as String),
    );

    return (completeLink | fallback).cast<MfmNode>();
  }
}

/// リンクパーサーの実装
class _LinkParserImpl extends Parser<MfmNode> {
  _LinkParserImpl(this._labelInlineParser);

  final Parser<MfmNode> _labelInlineParser;

  /// URLパーサー（生URL）
  final Parser<MfmNode> _urlParser = UrlParser().build();

  /// URLパーサー（ブラケット付き）
  final Parser<MfmNode> _urlAltParser = UrlParser().buildAlt();

  @override
  Result<MfmNode> parseOn(Context context) {
    final buffer = context.buffer;
    var position = context.position;

    // サイレントリンクかどうかを判定
    bool silent;
    if (buffer.substring(position).startsWith('?[')) {
      silent = true;
      position += 2;
    } else if (position < buffer.length && buffer[position] == '[') {
      silent = false;
      position += 1;
    } else {
      return context.failure('expected [ or ?[');
    }

    // ラベル部分をパース（] まで）
    final labelNodes = <MfmNode>[];
    var labelContext = Context(buffer, position);

    while (labelContext.position < buffer.length) {
      final c = buffer[labelContext.position];

      // 閉じ括弧で終了
      if (c == ']') {
        break;
      }

      // 改行は許可しない
      if (c == '\n' || c == '\r') {
        return context.failure('newline in link label');
      }

      // インラインパーサーでラベル内容をパース
      final result = _labelInlineParser.parseOn(labelContext);
      if (result is Failure) {
        // パースできない場合は1文字をテキストとして追加
        labelNodes.add(TextNode(c));
        labelContext = Context(buffer, labelContext.position + 1);
      } else {
        labelNodes.add(result.value);
        labelContext = Context(buffer, result.position);
      }
    }

    position = labelContext.position;

    // `]` で閉じることを確認
    if (position >= buffer.length || buffer[position] != ']') {
      return context.failure('expected ]');
    }
    position++;

    // `(` が続くことを確認
    if (position >= buffer.length || buffer[position] != '(') {
      return context.failure('expected (');
    }
    position++;

    // URL部分をパース
    final urlContext = Context(buffer, position);

    // まずブラケット付きURLを試す
    var urlResult = _urlAltParser.parseOn(urlContext);
    if (urlResult is Failure) {
      // 次に生URLを試す
      urlResult = _urlParser.parseOn(urlContext);
    }

    if (urlResult is Failure) {
      return context.failure('invalid URL in link');
    }

    final urlNode = urlResult.value as UrlNode;
    position = urlResult.position;

    // `)` で閉じることを確認
    if (position >= buffer.length || buffer[position] != ')') {
      return context.failure('expected )');
    }
    position++;

    // ラベルが空の場合は無効
    if (labelNodes.isEmpty) {
      return context.failure('empty link label');
    }

    // 隣接するTextNodeをマージ
    final mergedLabel = mergeAdjacentTextNodes(labelNodes);

    return context.success(
      LinkNode(silent: silent, url: urlNode.url, children: mergedLabel),
      position,
    );
  }

  @override
  int fastParseOn(String buffer, int position) {
    final result = parseOn(Context(buffer, position));
    return result is Success ? result.position : -1;
  }

  @override
  Parser<MfmNode> copy() => _LinkParserImpl(_labelInlineParser);
}
