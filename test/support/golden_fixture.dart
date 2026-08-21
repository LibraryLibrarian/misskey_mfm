import 'dart:convert';
import 'dart:io';

const astGoldenSchemaVersion = 1;
const mfmJsCompatibilityCommit = '61c9dd10d29a054489a346629b0bb420659aa626';

typedef AstGoldenCase = ({
  String name,
  String parserMode,
  String input,
  int? nestLimit,
  AstGoldenDeviation? deviation,
  List<Object?> expected,
  String source,
});

typedef AstGoldenDeviation = ({int issue, String rationale});

const _approvedDeviationIssues = <String, int>{
  'issue-3-second-line-inline-wins-over-search': 3,
};

const _nodeTypes = <String>{
  'text',
  'inlineCode',
  'emojiCode',
  'unicodeEmoji',
  'hashtag',
  'mathBlock',
  'mathInline',
  'bold',
  'italic',
  'strike',
  'small',
  'quote',
  'center',
  'plain',
  'url',
  'link',
  'mention',
  'fn',
  'codeBlock',
  'search',
};

/// Loads and validates all version-controlled AST fixtures.
List<AstGoldenCase> loadAstGoldenFixtures({
  String directory = 'test/goldens',
}) {
  final fixtureDirectory = Directory(directory);
  if (!fixtureDirectory.existsSync()) {
    throw FormatException(
      'Golden fixture directory does not exist: $directory',
    );
  }

  final files =
      fixtureDirectory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .toList(growable: false)
        ..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) {
    throw FormatException('No JSON golden fixtures found in $directory');
  }

  final names = <String>{};
  final cases = <AstGoldenCase>[];
  for (final file in files) {
    final Object? document;
    try {
      document = jsonDecode(file.readAsStringSync());
    } on FormatException catch (error) {
      throw FormatException('${file.path}: invalid JSON: ${error.message}');
    }
    cases.addAll(
      parseAstGoldenFixture(document, source: file.path, knownNames: names),
    );
  }
  return cases;
}

/// Validates one decoded fixture and returns its cases.
///
/// [knownNames] can be shared across files to reject duplicate case names.
List<AstGoldenCase> parseAstGoldenFixture(
  Object? document, {
  String source = '<memory>',
  Set<String>? knownNames,
}) {
  final root = _object(document, source, r'$');
  _exactKeys(
    root,
    const {'schemaVersion', 'compatibilityBasis', 'cases'},
    source,
    r'$',
  );
  final schemaVersion = root['schemaVersion'];
  if (schemaVersion is! int || schemaVersion != astGoldenSchemaVersion) {
    throw FormatException(
      '$source: unsupported schemaVersion $schemaVersion; '
      'expected integer $astGoldenSchemaVersion',
    );
  }

  final basis = _object(
    root['compatibilityBasis'],
    source,
    'compatibilityBasis',
  );
  _exactKeys(
    basis,
    const {'implementation', 'branch', 'commit', 'expectations'},
    source,
    'compatibilityBasis',
  );
  if (_string(basis['implementation'], source, 'implementation') != 'mfm.js' ||
      _string(basis['branch'], source, 'branch') != 'develop' ||
      _string(basis['commit'], source, 'commit') != mfmJsCompatibilityCommit) {
    throw FormatException(
      '$source: compatibilityBasis must identify mfm.js develop '
      '$mfmJsCompatibilityCommit',
    );
  }
  _nonEmptyString(basis['expectations'], source, 'expectations');

  final rawCases = root['cases'];
  if (rawCases is! List<Object?> || rawCases.isEmpty) {
    throw FormatException('$source: cases must be a non-empty JSON array');
  }

  final names = knownNames ?? <String>{};
  final result = <AstGoldenCase>[];
  for (var index = 0; index < rawCases.length; index++) {
    final path = 'cases[$index]';
    final rawCase = _object(rawCases[index], source, path);
    final allowedKeys = <String>{
      'name',
      'parser',
      'input',
      'expected',
      if (rawCase.containsKey('nestLimit')) 'nestLimit',
      if (rawCase.containsKey('deviation')) 'deviation',
    };
    _exactKeys(rawCase, allowedKeys, source, path);

    final name = _nonEmptyString(rawCase['name'], source, '$path.name');
    if (!names.add(name)) {
      throw FormatException('$source: duplicate golden case name: $name');
    }

    final parserMode = _string(rawCase['parser'], source, '$path.parser');
    if (parserMode != 'full' && parserMode != 'simple') {
      throw FormatException(
        '$source: $path.parser must be "full" or "simple", got "$parserMode"',
      );
    }
    final input = _string(rawCase['input'], source, '$path.input');

    AstGoldenDeviation? deviation;
    final approvedIssue = _approvedDeviationIssues[name];
    if (rawCase.containsKey('deviation')) {
      final rawDeviation = _object(
        rawCase['deviation'],
        source,
        '$path.deviation',
      );
      _exactKeys(
        rawDeviation,
        const {'issue', 'rationale'},
        source,
        '$path.deviation',
      );
      final issue = rawDeviation['issue'];
      if (issue is! int || issue <= 0) {
        throw FormatException(
          '$source: $path.deviation.issue must be a positive integer',
        );
      }
      final rationale = _nonEmptyString(
        rawDeviation['rationale'],
        source,
        '$path.deviation.rationale',
      );
      if (approvedIssue == null || approvedIssue != issue) {
        throw FormatException(
          '$source: $path.deviation is not an approved project deviation',
        );
      }
      deviation = (issue: issue, rationale: rationale);
    } else if (approvedIssue != null) {
      throw FormatException(
        '$source: $path requires deviation provenance for issue '
        '#$approvedIssue',
      );
    }

    int? nestLimit;
    if (rawCase.containsKey('nestLimit')) {
      final value = rawCase['nestLimit'];
      if (value is! int || value < 0) {
        throw FormatException(
          '$source: $path.nestLimit must be a non-negative integer',
        );
      }
      if (parserMode == 'simple') {
        throw FormatException(
          '$source: $path.nestLimit is only valid for the full parser',
        );
      }
      nestLimit = value;
    }

    final expected = rawCase['expected'];
    if (expected is! List<Object?>) {
      throw FormatException('$source: $path.expected must be a JSON array');
    }
    for (var nodeIndex = 0; nodeIndex < expected.length; nodeIndex++) {
      _validateNode(expected[nodeIndex], source, '$path.expected[$nodeIndex]');
    }

    result.add((
      name: name,
      parserMode: parserMode,
      input: input,
      nestLimit: nestLimit,
      deviation: deviation,
      expected: expected,
      source: source,
    ));
  }
  return result;
}

void _validateNode(Object? value, String source, String path) {
  final node = _object(value, source, path);
  _exactKeys(node, const {'type', 'props', 'children'}, source, path);
  final type = _string(node['type'], source, '$path.type');
  if (!_nodeTypes.contains(type)) {
    throw FormatException('$source: $path.type is unknown: $type');
  }
  final props = _object(node['props'], source, '$path.props');
  final children = node['children'];
  if (children is! List<Object?>) {
    throw FormatException('$source: $path.children must be a JSON array');
  }

  switch (type) {
    case 'text':
      _stringLeaf(props, children, 'text', source, path);
    case 'inlineCode':
      _stringLeaf(props, children, 'code', source, path);
    case 'emojiCode':
      _stringLeaf(props, children, 'name', source, path);
    case 'unicodeEmoji':
      _stringLeaf(props, children, 'emoji', source, path);
    case 'hashtag':
      _stringLeaf(props, children, 'hashtag', source, path);
    case 'mathBlock' || 'mathInline':
      _stringLeaf(props, children, 'formula', source, path);
    case 'bold' ||
        'italic' ||
        'strike' ||
        'small' ||
        'quote' ||
        'center' ||
        'plain':
      _exactKeys(props, const {}, source, '$path.props');
    case 'url':
      _exactKeys(props, const {'url', 'brackets'}, source, '$path.props');
      _string(props['url'], source, '$path.props.url');
      _bool(props['brackets'], source, '$path.props.brackets');
      _emptyChildren(children, source, path);
    case 'link':
      _exactKeys(props, const {'silent', 'url'}, source, '$path.props');
      _bool(props['silent'], source, '$path.props.silent');
      _string(props['url'], source, '$path.props.url');
    case 'mention':
      _exactKeys(
        props,
        const {'username', 'host', 'acct'},
        source,
        '$path.props',
      );
      _string(props['username'], source, '$path.props.username');
      final host = props['host'];
      if (host != null && host is! String) {
        throw FormatException(
          '$source: $path.props.host must be a string or null',
        );
      }
      _string(props['acct'], source, '$path.props.acct');
      _emptyChildren(children, source, path);
    case 'fn':
      _exactKeys(props, const {'name', 'args'}, source, '$path.props');
      _string(props['name'], source, '$path.props.name');
      final args = _object(props['args'], source, '$path.props.args');
      for (final entry in args.entries) {
        if (entry.value is! String && entry.value is! bool) {
          throw FormatException(
            '$source: $path.props.args.${entry.key} must be a string or bool',
          );
        }
      }
    case 'codeBlock':
      _exactKeys(
        props,
        const {'code', 'language'},
        source,
        '$path.props',
      );
      _string(props['code'], source, '$path.props.code');
      final language = props['language'];
      if (language != null && language is! String) {
        throw FormatException(
          '$source: $path.props.language must be a string or null',
        );
      }
      _emptyChildren(children, source, path);
    case 'search':
      _exactKeys(
        props,
        const {'query', 'content'},
        source,
        '$path.props',
      );
      _string(props['query'], source, '$path.props.query');
      _string(props['content'], source, '$path.props.content');
      _emptyChildren(children, source, path);
    default:
      // The known-type check above keeps this switch fail-closed.
      throw FormatException('$source: $path.type is unknown: $type');
  }

  for (var index = 0; index < children.length; index++) {
    _validateNode(children[index], source, '$path.children[$index]');
  }
}

void _stringLeaf(
  Map<String, Object?> props,
  List<Object?> children,
  String property,
  String source,
  String path,
) {
  _exactKeys(props, {property}, source, '$path.props');
  _string(props[property], source, '$path.props.$property');
  _emptyChildren(children, source, path);
}

void _emptyChildren(List<Object?> children, String source, String path) {
  if (children.isNotEmpty) {
    throw FormatException('$source: $path.children must be empty');
  }
}

Map<String, Object?> _object(Object? value, String source, String path) {
  if (value is! Map) {
    throw FormatException('$source: $path must be a JSON object');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$source: $path contains a non-string key');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

void _exactKeys(
  Map<String, Object?> value,
  Set<String> expected,
  String source,
  String path,
) {
  final actual = value.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw FormatException(
      '$source: $path keys must be ${expected.toList()..sort()}, '
      'got ${actual.toList()..sort()}',
    );
  }
}

String _string(Object? value, String source, String path) {
  if (value is! String) {
    throw FormatException('$source: $path must be a string');
  }
  return value;
}

bool _bool(Object? value, String source, String path) {
  if (value is! bool) {
    throw FormatException('$source: $path must be a bool');
  }
  return value;
}

String _nonEmptyString(Object? value, String source, String path) {
  final result = _string(value, source, path);
  if (result.trim().isEmpty) {
    throw FormatException('$source: $path must not be empty');
  }
  return result;
}
