import '../../ast.dart';

/// 隣接するTextNodeをマージして、より整理されたツリーを作成する
///
/// パーサーが生成したノードリストにおいて、連続するTextNodeを
/// 1つのTextNodeにまとめることで、ASTをより扱いやすくする
///
/// [nodes] マージ対象のノードリスト
///
/// 戻り値: マージされたノードリスト
List<MfmNode> mergeAdjacentTextNodes(Iterable<MfmNode> nodes) {
  final List<MfmNode> result = <MfmNode>[];
  final StringBuffer buffer = StringBuffer();

  /// バッファに蓄積されたテキストをTextNodeとして追加し、バッファをクリアする
  void flush() {
    if (buffer.isNotEmpty) {
      result.add(TextNode(buffer.toString()));
      buffer.clear();
    }
  }

  for (final MfmNode node in nodes) {
    if (node is TextNode) {
      buffer.write(node.text);
    } else {
      flush();
      result.add(node);
    }
  }
  flush();
  return result;
}
