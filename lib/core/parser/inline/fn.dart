import 'package:petitparser/petitparser.dart';

import '../../ast.dart';
import '../common/utils.dart';
import '../core/nest.dart';

/// MFM関数パーサー
///
/// `$[name content]` または `$[name.args content]` 形式の構文を解析
///
/// 例:
/// - `$[shake 🍮]` → FnNode(name: "shake", args: {}, children: [...])
/// - `$[spin.speed=2s text]` → FnNode(name: "spin", args: {speed: "2s"}, ...)
/// - `$[flip.h,v content]` → FnNode(name: "flip", args: {h: true, v: true})
class FnParser {
  /// 関数名パーサー: [a-z0-9_]+（大文字小文字区別なし）
  late final Parser<String> _fnName = pattern('a-zA-Z0-9_').plus().flatten();

  /// 引数キーパーサー
  late final Parser<String> _argKey = pattern('a-zA-Z0-9_').plus().flatten();

  /// 引数値パーサー
  late final Parser<String> _argValue = pattern(
    'a-zA-Z0-9_.-',
  ).plus().flatten();

  /// 単一引数パーサー: key または key=value形式
  ///
  /// 戻り値: `MapEntry<String, dynamic>`
  /// - keyのみ: MapEntry(key, true)
  /// - key=value: MapEntry(key, value)
  late final Parser<MapEntry<String, dynamic>> _singleArg = () {
    // key=value 形式
    final keyValue = seq3(
      _argKey,
      char('='),
      _argValue,
    ).map((result) => MapEntry<String, dynamic>(result.$1, result.$3));

    // key のみ（boolean true）
    final keyOnly = _argKey.map((k) => MapEntry<String, dynamic>(k, true));

    return (keyValue | keyOnly).cast<MapEntry<String, dynamic>>();
  }();

  /// 引数リストパーサー: .key1,key2=value 形式
  ///
  /// `.`で開始し、`,`区切りで複数の引数を受け付ける
  late final Parser<Map<String, dynamic>> _argsParser = () {
    // 追加引数（,で始まる）
    final additionalArg = seq2(
      char(','),
      _singleArg,
    ).map((result) => result.$2);

    return seq3(char('.'), _singleArg, additionalArg.star()).map((result) {
      final firstArg = result.$2;
      final additionalArgs = result.$3;
      return Map<String, dynamic>.fromEntries([firstArg, ...additionalArgs]);
    });
  }();

  /// fnパーサー（再帰インライン対応版）
  ///
  /// `$[name.args content]` 形式を解析し、FnNodeを生成
  /// パースに失敗した場合は `$[` をテキストとしてフォールバック
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline) {
    final start = string(r'$[');
    final fnEnd = char(']');

    // 内容パーサー: ] が来るまで再帰的にインラインをパース
    final content = seq2(
      fnEnd.not(),
      nest(inline),
    ).map((result) => result.$2).plus();

    // 正常系: $[ + name + args? + space + content + ]
    final complete =
        seq2(
          seq2(
            seq2(start, _fnName),
            seq2(_argsParser.optional(), char(' ')),
          ),
          seq2(content, fnEnd),
        ).map<MfmNode>((result) {
          final name = result.$1.$1.$2;
          final argsMap = result.$1.$2.$1 ?? <String, dynamic>{};
          final children = result.$2.$1;
          return FnNode(
            name: name,
            args: argsMap,
            children: mergeAdjacentTextNodes(children),
          );
        });

    // フォールバック: $[ のみをテキストとして返す
    final fallback = start.map<MfmNode>(TextNode.new);

    return (complete | fallback).cast<MfmNode>();
  }
}
