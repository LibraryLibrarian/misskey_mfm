import 'package:misskey_mfm/core/ast.dart';
import 'package:misskey_mfm/core/parser.dart';

void main() {
  final parser = MfmParser().build();
  final inputs = <String>[
    '**bold**',
    'foo**bar**baz',
    '**a **b** c**',
    '**abc',
  ];

  for (final input in inputs) {
    final result = parser.parse(input);
    print('INPUT: $input');
    if (result.isSuccess) {
      final nodes = result.value as List<MfmNode>;
      for (final node in nodes) {
        print('  - ${_describe(node)}');
      }
    } else {
      print('  ERROR: ${result.message} at ${result.position}');
    }
  }
}

String _describe(MfmNode node, [int depth = 0]) {
  final indent = '  ' * depth;
  if (node is TextNode) {
    return '${indent}Text("${node.text}")';
  }
  if (node is BoldNode) {
    final children = node.children.map((c) => _describe(c, depth + 1)).join('\n');
    return '${indent}Bold[\n$children\n$indent]';
  }
  return '${indent}${node.runtimeType}';
}
