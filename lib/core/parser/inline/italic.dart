import 'package:petitparser/petitparser.dart';
import '../../ast.dart';
import '../common/utils.dart';
import '../core/seq_or_text.dart';
import '../core/nest.dart';
import '../core/guards.dart';

/// 斜体構文パーサー
///
/// "*"/"_"/"<i></i>" で囲まれた内容を解析する
class ItalicParser {
  /// 直前文字許可判定
  ///
  /// - null(先頭), 空白, 改行, または非英数字(正規表現 [^a-z0-9]i) の直後ならOK
  /// - 英数字直後はNG
  bool _allowPrev(String? ch) {
    if (ch == null) return true;
    if (ch == ' ' || ch == '\n') return true;
    final code = ch.codeUnitAt(0);
    // ASCII 英数字
    final bool isDigit = code >= 0x30 && code <= 0x39;
    final bool isUpper = code >= 0x41 && code <= 0x5A;
    final bool isLower = code >= 0x61 && code <= 0x7A;
    if (isDigit || isUpper || isLower) return false;
    return true;
  }

  /// 斜体ノードのパーサー（* ... *）
  Parser<MfmNode> build() {
    final Parser<MfmNode> inner = any()
        .starLazy(string('*'))
        .flatten()
        .map<MfmNode>((dynamic v) => TextNode(v as String));

    final core = (string('*') & inner & string('*')).map<MfmNode>((dynamic v) {
      final List<dynamic> parts = v as List<dynamic>;
      final MfmNode content = parts[1] as MfmNode;
      return ItalicNode(mergeAdjacentTextNodes([content]));
    });

    // 直前ガードを付与
    return withPrevCharGuard(core, _allowPrev);
  }

  /// 斜体ノードのパーサー（<i> ... </i>）
  Parser<MfmNode> buildTag() {
    final start = string('<i>');
    final end = string('</i>');
    final inner = (end.not() & any()).plus().flatten().map<MfmNode>(
      (dynamic v) => TextNode(v as String),
    );
    return (start & inner & end).map<MfmNode>((dynamic v) {
      final List<dynamic> parts = v as List<dynamic>;
      final MfmNode content = parts[1] as MfmNode;
      return ItalicNode(mergeAdjacentTextNodes([content]));
    });
  }

  /// 斜体ノードのパーサー（_ ... _）
  Parser<MfmNode> buildAlt2() {
    final Parser<MfmNode> inner = any()
        .starLazy(string('_'))
        .flatten()
        .map<MfmNode>((dynamic v) => TextNode(v as String));

    final core = (string('_') & inner & string('_')).map<MfmNode>((dynamic v) {
      final List<dynamic> parts = v as List<dynamic>;
      final MfmNode content = parts[1] as MfmNode;
      return ItalicNode(mergeAdjacentTextNodes([content]));
    });

    // ガード付きの完全一致
    final complete = withPrevCharGuard(core, _allowPrev);

    // フォールバック: '_'以降の全文字列をそのままテキストとして扱う（ガードなし）
    final fallback = (string('_') & any().star()).flatten().map<MfmNode>(
      (dynamic s) => TextNode(s as String),
    );

    return (complete | fallback).cast<MfmNode>();
  }

  /// ネスト可能な斜体ノードのパーサーを構築
  ///
  /// [inline] ネスト可能なインラインパーサー
  /// 戻り値: 斜体ノードを解析するパーサー
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline) {
    final start = string('*');
    final end = string('*');
    final parser = seqOrText(start, nest(inline), end).map<MfmNode>((
      dynamic v,
    ) {
      if (v is String) {
        return TextNode(v);
      }
      final List<dynamic> seq = v as List<dynamic>;
      final List<MfmNode> children = (seq[1] as List).cast<MfmNode>();
      return ItalicNode(mergeAdjacentTextNodes(children));
    });
    return withPrevCharGuard(parser, _allowPrev);
  }

  /// 斜体またはフォールバックのパーサー
  ///
  /// 斜体として解析できない場合は、先頭'*'以降の全文字列をテキストとして扱う
  Parser<MfmNode> buildWithFallback() {
    final completeItalic = build();

    // フォールバック: '*'以降の全文字列をそのまま返す
    final fallback = (string('*') & any().star()).flatten().map<MfmNode>(
      (dynamic s) => TextNode(s as String),
    );

    return (completeItalic | fallback).cast<MfmNode>();
  }

  /// 斜体ノードのパーサー（<i> ... </i>）: 再帰合成版
  ///
  /// [inline] ネスト可能なインラインパーサー
  Parser<MfmNode> buildTagWithInner(Parser<MfmNode> inline) {
    final start = string('<i>');
    final end = string('</i>');
    final parser = seqOrText(start, nest(inline), end).map<MfmNode>((
      dynamic v,
    ) {
      if (v is String) {
        return TextNode(v);
      }
      final List<dynamic> parts = v as List<dynamic>;
      final List<MfmNode> children = (parts[1] as List).cast<MfmNode>();
      return ItalicNode(mergeAdjacentTextNodes(children));
    });
    return parser;
  }
}
