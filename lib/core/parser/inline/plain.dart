import 'package:petitparser/petitparser.dart';

import '../../ast.dart';

/// plain 構文パーサー
///
/// "&lt;plain&gt;…&lt;/plain&gt;" で囲まれた内容を解析
/// 内部はパースせず、TextNodeとしてそのまま扱う（パース無効化が目的）
///
/// mfm-js仕様:
/// - 開始タグ `<plain>` と終了タグ `</plain>` で囲む
/// - 内部の改行は許可される
/// - 内容はTextNodeとして扱われる（MFM構文は解釈されない）
class PlainParser {
  /// plain タグパーサー
  ///
  /// 内部はパースせず、TextNodeとしてそのまま扱う
  Parser<MfmNode> build() {
    final open = string('<plain>');
    final close = string('</plain>');
    final newline = char('\n');

    // 内容: </plain>が出現するまでの任意の文字（改行も含む）
    // pick(1)で実際の文字のみ取得し、flatten()で結合
    final content = ((newline.optional() & close).not() & any())
        .pick(1)
        .plus()
        .flatten();

    // seq5で型安全なシーケンスパース
    return seq5(
      open,
      newline.optional(),
      content,
      newline.optional(),
      close,
    ).map5((_, _, text, _, _) {
      // PlainNodeは子ノードとしてTextNodeのリストを持つ
      return PlainNode([TextNode(text)]);
    });
  }
}
