import 'package:petitparser/petitparser.dart';
import '../../ast.dart';

/// ネスト可能合成
///
/// 指定された [inline] パーサーを優先して実行し、
/// 失敗した場合は任意の1文字を `TextNode` として消費して前進する。
/// mfm.js の `nest` の簡易版。
Parser<MfmNode> nest(Parser<MfmNode> inline) {
  return (inline | any().map<MfmNode>((dynamic c) => TextNode(c as String)))
      .cast<MfmNode>();
}
