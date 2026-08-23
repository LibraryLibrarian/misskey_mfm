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
  late final Parser<String> _fnName = pattern('a-zA-Z0-9_').plusString();

  /// 引数キーパーサー
  late final Parser<String> _argKey = pattern('a-zA-Z0-9_').plusString();

  /// 引数値パーサー
  late final Parser<String> _argValue = pattern('a-zA-Z0-9_.-').plusString();

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
  /// パースに失敗した場合は最後に成功した構文要素までをテキストとしてフォールバック
  /// [state] ネスト状態（共有される）
  Parser<MfmNode> buildWithInner(Parser<MfmNode> inline, {NestState? state}) {
    final start = string(r'$[');
    final fnEnd = char(']');

    // 内容パーサー: ] が来るまで再帰的にインラインをパース
    final content = seq2(
      fnEnd.not(),
      nest(inline, state: state),
    ).map((result) => result.$2).plus();

    return _FnSequenceParser(
      start,
      _fnName,
      _argsParser.optional(),
      char(' '),
      content,
      fnEnd,
    );
  }
}

/// mfm.jsの`seqOrText`と同じlatestIndex semanticsをfnの6要素へ適用する。
///
/// 各要素が成功した時点だけ消費位置を確定し、次の要素が失敗した場合は
/// fn開始位置から最後に確定した位置までを単一のTextNodeとして返す。
final class _FnSequenceParser extends Parser<MfmNode> {
  _FnSequenceParser(
    this.start,
    this.name,
    this.args,
    this.space,
    this.content,
    this.end,
  );

  Parser<String> start;
  Parser<String> name;
  Parser<Map<String, dynamic>?> args;
  Parser<String> space;
  Parser<List<MfmNode>> content;
  Parser<String> end;

  @override
  Result<MfmNode> parseOn(Context context) {
    final startResult = start.parseOn(context);
    if (startResult is Failure) return startResult;

    final nameResult = name.parseOn(startResult);
    if (nameResult is Failure) {
      return _fallback(context, startResult.position, nameResult);
    }

    final argsResult = args.parseOn(nameResult);
    if (argsResult is Failure) {
      return _fallback(context, nameResult.position, argsResult);
    }

    final spaceResult = space.parseOn(argsResult);
    if (spaceResult is Failure) {
      return _fallback(context, argsResult.position, spaceResult);
    }

    final contentResult = content.parseOn(spaceResult);
    if (contentResult is Failure) {
      return _fallback(context, spaceResult.position, contentResult);
    }

    final endResult = end.parseOn(contentResult);
    if (endResult is Failure) {
      return _fallback(context, contentResult.position, endResult);
    }

    return endResult.success<MfmNode>(
      FnNode(
        name: nameResult.value,
        args: argsResult.value ?? <String, dynamic>{},
        children: mergeAdjacentTextNodes(contentResult.value),
      ),
    );
  }

  Result<MfmNode> _fallback(
    Context context,
    int latestPosition,
    Failure failure,
  ) {
    if (latestPosition == context.position) return failure;

    return context.success<MfmNode>(
      TextNode(context.buffer.substring(context.position, latestPosition)),
      latestPosition,
    );
  }

  @override
  List<Parser> get children => [start, name, args, space, content, end];

  @override
  void replace(Parser source, Parser target) {
    super.replace(source, target);
    if (start == source) start = target as Parser<String>;
    if (name == source) name = target as Parser<String>;
    if (args == source) args = target as Parser<Map<String, dynamic>?>;
    if (space == source) space = target as Parser<String>;
    if (content == source) content = target as Parser<List<MfmNode>>;
    if (end == source) end = target as Parser<String>;
  }

  @override
  Parser<MfmNode> copy() =>
      _FnSequenceParser(start, name, args, space, content, end);
}
