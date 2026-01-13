import 'package:petitparser/petitparser.dart';
import '../../ast.dart';

/// ネスト状態
///
/// [depth]現在の深さ / [limit]上限（nullなら無制限）
class NestState {
  NestState({this.depth = 0, this.limit});
  int depth;
  final int? limit;
}

class _NestParser extends Parser<MfmNode> {
  _NestParser(this.inner, this.fallback, this.state);
  final Parser<MfmNode> inner;
  final Parser<MfmNode> fallback;
  final NestState? state;

  @override
  Result<MfmNode> parseOn(Context context) {
    final used = state ?? NestState();
    if (used.limit != null && used.depth >= used.limit!) {
      return fallback.parseOn(context);
    }
    used.depth++;
    final result = inner.parseOn(context);
    used.depth--;
    if (result is Success) return result;
    return fallback.parseOn(context);
  }

  @override
  Parser<MfmNode> copy() => _NestParser(inner, fallback, state);
}

/// ネスト可能合成（状態付き）
///
/// [inline]ネスト対象のパーサー
/// [state]ネスト状態（nullの場合は無制限）
/// [fallback]失敗時の代替（未指定は1文字テキスト）
Parser<MfmNode> nest(
  Parser<MfmNode> inline, {
  NestState? state,
  Parser<MfmNode>? fallback,
}) {
  final oneChar = any().map<MfmNode>(
    (dynamic c) => TextNode(c as String),
  );
  final fb = fallback ?? oneChar;
  return _NestParser(inline, fb, state);
}
