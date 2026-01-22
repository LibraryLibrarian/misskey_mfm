// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ast.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MfmNode {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MfmNode);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MfmNode()';
}


}

/// @nodoc
class $MfmNodeCopyWith<$Res>  {
$MfmNodeCopyWith(MfmNode _, $Res Function(MfmNode) __);
}


/// Adds pattern-matching-related methods to [MfmNode].
extension MfmNodePatterns on MfmNode {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TextNode value)?  text,TResult Function( InlineCodeNode value)?  inlineCode,TResult Function( EmojiCodeNode value)?  emojiCode,TResult Function( UnicodeEmojiNode value)?  unicodeEmoji,TResult Function( HashtagNode value)?  hashtag,TResult Function( MathBlockNode value)?  mathBlock,TResult Function( MathInlineNode value)?  mathInline,TResult Function( BoldNode value)?  bold,TResult Function( ItalicNode value)?  italic,TResult Function( StrikeNode value)?  strike,TResult Function( SmallNode value)?  small,TResult Function( QuoteNode value)?  quote,TResult Function( CenterNode value)?  center,TResult Function( PlainNode value)?  plain,TResult Function( UrlNode value)?  url,TResult Function( LinkNode value)?  link,TResult Function( MentionNode value)?  mention,TResult Function( FnNode value)?  fn,TResult Function( CodeBlockNode value)?  codeBlock,TResult Function( SearchNode value)?  search,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TextNode() when text != null:
return text(_that);case InlineCodeNode() when inlineCode != null:
return inlineCode(_that);case EmojiCodeNode() when emojiCode != null:
return emojiCode(_that);case UnicodeEmojiNode() when unicodeEmoji != null:
return unicodeEmoji(_that);case HashtagNode() when hashtag != null:
return hashtag(_that);case MathBlockNode() when mathBlock != null:
return mathBlock(_that);case MathInlineNode() when mathInline != null:
return mathInline(_that);case BoldNode() when bold != null:
return bold(_that);case ItalicNode() when italic != null:
return italic(_that);case StrikeNode() when strike != null:
return strike(_that);case SmallNode() when small != null:
return small(_that);case QuoteNode() when quote != null:
return quote(_that);case CenterNode() when center != null:
return center(_that);case PlainNode() when plain != null:
return plain(_that);case UrlNode() when url != null:
return url(_that);case LinkNode() when link != null:
return link(_that);case MentionNode() when mention != null:
return mention(_that);case FnNode() when fn != null:
return fn(_that);case CodeBlockNode() when codeBlock != null:
return codeBlock(_that);case SearchNode() when search != null:
return search(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TextNode value)  text,required TResult Function( InlineCodeNode value)  inlineCode,required TResult Function( EmojiCodeNode value)  emojiCode,required TResult Function( UnicodeEmojiNode value)  unicodeEmoji,required TResult Function( HashtagNode value)  hashtag,required TResult Function( MathBlockNode value)  mathBlock,required TResult Function( MathInlineNode value)  mathInline,required TResult Function( BoldNode value)  bold,required TResult Function( ItalicNode value)  italic,required TResult Function( StrikeNode value)  strike,required TResult Function( SmallNode value)  small,required TResult Function( QuoteNode value)  quote,required TResult Function( CenterNode value)  center,required TResult Function( PlainNode value)  plain,required TResult Function( UrlNode value)  url,required TResult Function( LinkNode value)  link,required TResult Function( MentionNode value)  mention,required TResult Function( FnNode value)  fn,required TResult Function( CodeBlockNode value)  codeBlock,required TResult Function( SearchNode value)  search,}){
final _that = this;
switch (_that) {
case TextNode():
return text(_that);case InlineCodeNode():
return inlineCode(_that);case EmojiCodeNode():
return emojiCode(_that);case UnicodeEmojiNode():
return unicodeEmoji(_that);case HashtagNode():
return hashtag(_that);case MathBlockNode():
return mathBlock(_that);case MathInlineNode():
return mathInline(_that);case BoldNode():
return bold(_that);case ItalicNode():
return italic(_that);case StrikeNode():
return strike(_that);case SmallNode():
return small(_that);case QuoteNode():
return quote(_that);case CenterNode():
return center(_that);case PlainNode():
return plain(_that);case UrlNode():
return url(_that);case LinkNode():
return link(_that);case MentionNode():
return mention(_that);case FnNode():
return fn(_that);case CodeBlockNode():
return codeBlock(_that);case SearchNode():
return search(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TextNode value)?  text,TResult? Function( InlineCodeNode value)?  inlineCode,TResult? Function( EmojiCodeNode value)?  emojiCode,TResult? Function( UnicodeEmojiNode value)?  unicodeEmoji,TResult? Function( HashtagNode value)?  hashtag,TResult? Function( MathBlockNode value)?  mathBlock,TResult? Function( MathInlineNode value)?  mathInline,TResult? Function( BoldNode value)?  bold,TResult? Function( ItalicNode value)?  italic,TResult? Function( StrikeNode value)?  strike,TResult? Function( SmallNode value)?  small,TResult? Function( QuoteNode value)?  quote,TResult? Function( CenterNode value)?  center,TResult? Function( PlainNode value)?  plain,TResult? Function( UrlNode value)?  url,TResult? Function( LinkNode value)?  link,TResult? Function( MentionNode value)?  mention,TResult? Function( FnNode value)?  fn,TResult? Function( CodeBlockNode value)?  codeBlock,TResult? Function( SearchNode value)?  search,}){
final _that = this;
switch (_that) {
case TextNode() when text != null:
return text(_that);case InlineCodeNode() when inlineCode != null:
return inlineCode(_that);case EmojiCodeNode() when emojiCode != null:
return emojiCode(_that);case UnicodeEmojiNode() when unicodeEmoji != null:
return unicodeEmoji(_that);case HashtagNode() when hashtag != null:
return hashtag(_that);case MathBlockNode() when mathBlock != null:
return mathBlock(_that);case MathInlineNode() when mathInline != null:
return mathInline(_that);case BoldNode() when bold != null:
return bold(_that);case ItalicNode() when italic != null:
return italic(_that);case StrikeNode() when strike != null:
return strike(_that);case SmallNode() when small != null:
return small(_that);case QuoteNode() when quote != null:
return quote(_that);case CenterNode() when center != null:
return center(_that);case PlainNode() when plain != null:
return plain(_that);case UrlNode() when url != null:
return url(_that);case LinkNode() when link != null:
return link(_that);case MentionNode() when mention != null:
return mention(_that);case FnNode() when fn != null:
return fn(_that);case CodeBlockNode() when codeBlock != null:
return codeBlock(_that);case SearchNode() when search != null:
return search(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  text,TResult Function( String code)?  inlineCode,TResult Function( String name)?  emojiCode,TResult Function( String emoji)?  unicodeEmoji,TResult Function( String hashtag)?  hashtag,TResult Function( String formula)?  mathBlock,TResult Function( String formula)?  mathInline,TResult Function( List<MfmNode> children)?  bold,TResult Function( List<MfmNode> children)?  italic,TResult Function( List<MfmNode> children)?  strike,TResult Function( List<MfmNode> children)?  small,TResult Function( List<MfmNode> children)?  quote,TResult Function( List<MfmNode> children)?  center,TResult Function( List<MfmNode> children)?  plain,TResult Function( String url,  bool brackets)?  url,TResult Function( bool silent,  String url,  List<MfmNode> children)?  link,TResult Function( String username,  String? host,  String acct)?  mention,TResult Function( String name,  Map<String, dynamic> args,  List<MfmNode> children)?  fn,TResult Function( String code,  String? language)?  codeBlock,TResult Function( String query,  String content)?  search,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TextNode() when text != null:
return text(_that.text);case InlineCodeNode() when inlineCode != null:
return inlineCode(_that.code);case EmojiCodeNode() when emojiCode != null:
return emojiCode(_that.name);case UnicodeEmojiNode() when unicodeEmoji != null:
return unicodeEmoji(_that.emoji);case HashtagNode() when hashtag != null:
return hashtag(_that.hashtag);case MathBlockNode() when mathBlock != null:
return mathBlock(_that.formula);case MathInlineNode() when mathInline != null:
return mathInline(_that.formula);case BoldNode() when bold != null:
return bold(_that.children);case ItalicNode() when italic != null:
return italic(_that.children);case StrikeNode() when strike != null:
return strike(_that.children);case SmallNode() when small != null:
return small(_that.children);case QuoteNode() when quote != null:
return quote(_that.children);case CenterNode() when center != null:
return center(_that.children);case PlainNode() when plain != null:
return plain(_that.children);case UrlNode() when url != null:
return url(_that.url,_that.brackets);case LinkNode() when link != null:
return link(_that.silent,_that.url,_that.children);case MentionNode() when mention != null:
return mention(_that.username,_that.host,_that.acct);case FnNode() when fn != null:
return fn(_that.name,_that.args,_that.children);case CodeBlockNode() when codeBlock != null:
return codeBlock(_that.code,_that.language);case SearchNode() when search != null:
return search(_that.query,_that.content);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  text,required TResult Function( String code)  inlineCode,required TResult Function( String name)  emojiCode,required TResult Function( String emoji)  unicodeEmoji,required TResult Function( String hashtag)  hashtag,required TResult Function( String formula)  mathBlock,required TResult Function( String formula)  mathInline,required TResult Function( List<MfmNode> children)  bold,required TResult Function( List<MfmNode> children)  italic,required TResult Function( List<MfmNode> children)  strike,required TResult Function( List<MfmNode> children)  small,required TResult Function( List<MfmNode> children)  quote,required TResult Function( List<MfmNode> children)  center,required TResult Function( List<MfmNode> children)  plain,required TResult Function( String url,  bool brackets)  url,required TResult Function( bool silent,  String url,  List<MfmNode> children)  link,required TResult Function( String username,  String? host,  String acct)  mention,required TResult Function( String name,  Map<String, dynamic> args,  List<MfmNode> children)  fn,required TResult Function( String code,  String? language)  codeBlock,required TResult Function( String query,  String content)  search,}) {final _that = this;
switch (_that) {
case TextNode():
return text(_that.text);case InlineCodeNode():
return inlineCode(_that.code);case EmojiCodeNode():
return emojiCode(_that.name);case UnicodeEmojiNode():
return unicodeEmoji(_that.emoji);case HashtagNode():
return hashtag(_that.hashtag);case MathBlockNode():
return mathBlock(_that.formula);case MathInlineNode():
return mathInline(_that.formula);case BoldNode():
return bold(_that.children);case ItalicNode():
return italic(_that.children);case StrikeNode():
return strike(_that.children);case SmallNode():
return small(_that.children);case QuoteNode():
return quote(_that.children);case CenterNode():
return center(_that.children);case PlainNode():
return plain(_that.children);case UrlNode():
return url(_that.url,_that.brackets);case LinkNode():
return link(_that.silent,_that.url,_that.children);case MentionNode():
return mention(_that.username,_that.host,_that.acct);case FnNode():
return fn(_that.name,_that.args,_that.children);case CodeBlockNode():
return codeBlock(_that.code,_that.language);case SearchNode():
return search(_that.query,_that.content);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  text,TResult? Function( String code)?  inlineCode,TResult? Function( String name)?  emojiCode,TResult? Function( String emoji)?  unicodeEmoji,TResult? Function( String hashtag)?  hashtag,TResult? Function( String formula)?  mathBlock,TResult? Function( String formula)?  mathInline,TResult? Function( List<MfmNode> children)?  bold,TResult? Function( List<MfmNode> children)?  italic,TResult? Function( List<MfmNode> children)?  strike,TResult? Function( List<MfmNode> children)?  small,TResult? Function( List<MfmNode> children)?  quote,TResult? Function( List<MfmNode> children)?  center,TResult? Function( List<MfmNode> children)?  plain,TResult? Function( String url,  bool brackets)?  url,TResult? Function( bool silent,  String url,  List<MfmNode> children)?  link,TResult? Function( String username,  String? host,  String acct)?  mention,TResult? Function( String name,  Map<String, dynamic> args,  List<MfmNode> children)?  fn,TResult? Function( String code,  String? language)?  codeBlock,TResult? Function( String query,  String content)?  search,}) {final _that = this;
switch (_that) {
case TextNode() when text != null:
return text(_that.text);case InlineCodeNode() when inlineCode != null:
return inlineCode(_that.code);case EmojiCodeNode() when emojiCode != null:
return emojiCode(_that.name);case UnicodeEmojiNode() when unicodeEmoji != null:
return unicodeEmoji(_that.emoji);case HashtagNode() when hashtag != null:
return hashtag(_that.hashtag);case MathBlockNode() when mathBlock != null:
return mathBlock(_that.formula);case MathInlineNode() when mathInline != null:
return mathInline(_that.formula);case BoldNode() when bold != null:
return bold(_that.children);case ItalicNode() when italic != null:
return italic(_that.children);case StrikeNode() when strike != null:
return strike(_that.children);case SmallNode() when small != null:
return small(_that.children);case QuoteNode() when quote != null:
return quote(_that.children);case CenterNode() when center != null:
return center(_that.children);case PlainNode() when plain != null:
return plain(_that.children);case UrlNode() when url != null:
return url(_that.url,_that.brackets);case LinkNode() when link != null:
return link(_that.silent,_that.url,_that.children);case MentionNode() when mention != null:
return mention(_that.username,_that.host,_that.acct);case FnNode() when fn != null:
return fn(_that.name,_that.args,_that.children);case CodeBlockNode() when codeBlock != null:
return codeBlock(_that.code,_that.language);case SearchNode() when search != null:
return search(_that.query,_that.content);case _:
  return null;

}
}

}

/// @nodoc


class TextNode extends MfmNode {
  const TextNode(this.text): super._();
  

 final  String text;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TextNodeCopyWith<TextNode> get copyWith => _$TextNodeCopyWithImpl<TextNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TextNode&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'MfmNode.text(text: $text)';
}


}

/// @nodoc
abstract mixin class $TextNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $TextNodeCopyWith(TextNode value, $Res Function(TextNode) _then) = _$TextNodeCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$TextNodeCopyWithImpl<$Res>
    implements $TextNodeCopyWith<$Res> {
  _$TextNodeCopyWithImpl(this._self, this._then);

  final TextNode _self;
  final $Res Function(TextNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(TextNode(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class InlineCodeNode extends MfmNode {
  const InlineCodeNode(this.code): super._();
  

 final  String code;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InlineCodeNodeCopyWith<InlineCodeNode> get copyWith => _$InlineCodeNodeCopyWithImpl<InlineCodeNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InlineCodeNode&&(identical(other.code, code) || other.code == code));
}


@override
int get hashCode => Object.hash(runtimeType,code);

@override
String toString() {
  return 'MfmNode.inlineCode(code: $code)';
}


}

/// @nodoc
abstract mixin class $InlineCodeNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $InlineCodeNodeCopyWith(InlineCodeNode value, $Res Function(InlineCodeNode) _then) = _$InlineCodeNodeCopyWithImpl;
@useResult
$Res call({
 String code
});




}
/// @nodoc
class _$InlineCodeNodeCopyWithImpl<$Res>
    implements $InlineCodeNodeCopyWith<$Res> {
  _$InlineCodeNodeCopyWithImpl(this._self, this._then);

  final InlineCodeNode _self;
  final $Res Function(InlineCodeNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? code = null,}) {
  return _then(InlineCodeNode(
null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class EmojiCodeNode extends MfmNode {
  const EmojiCodeNode(this.name): super._();
  

 final  String name;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmojiCodeNodeCopyWith<EmojiCodeNode> get copyWith => _$EmojiCodeNodeCopyWithImpl<EmojiCodeNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmojiCodeNode&&(identical(other.name, name) || other.name == name));
}


@override
int get hashCode => Object.hash(runtimeType,name);

@override
String toString() {
  return 'MfmNode.emojiCode(name: $name)';
}


}

/// @nodoc
abstract mixin class $EmojiCodeNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $EmojiCodeNodeCopyWith(EmojiCodeNode value, $Res Function(EmojiCodeNode) _then) = _$EmojiCodeNodeCopyWithImpl;
@useResult
$Res call({
 String name
});




}
/// @nodoc
class _$EmojiCodeNodeCopyWithImpl<$Res>
    implements $EmojiCodeNodeCopyWith<$Res> {
  _$EmojiCodeNodeCopyWithImpl(this._self, this._then);

  final EmojiCodeNode _self;
  final $Res Function(EmojiCodeNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,}) {
  return _then(EmojiCodeNode(
null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class UnicodeEmojiNode extends MfmNode {
  const UnicodeEmojiNode(this.emoji): super._();
  

 final  String emoji;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnicodeEmojiNodeCopyWith<UnicodeEmojiNode> get copyWith => _$UnicodeEmojiNodeCopyWithImpl<UnicodeEmojiNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnicodeEmojiNode&&(identical(other.emoji, emoji) || other.emoji == emoji));
}


@override
int get hashCode => Object.hash(runtimeType,emoji);

@override
String toString() {
  return 'MfmNode.unicodeEmoji(emoji: $emoji)';
}


}

/// @nodoc
abstract mixin class $UnicodeEmojiNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $UnicodeEmojiNodeCopyWith(UnicodeEmojiNode value, $Res Function(UnicodeEmojiNode) _then) = _$UnicodeEmojiNodeCopyWithImpl;
@useResult
$Res call({
 String emoji
});




}
/// @nodoc
class _$UnicodeEmojiNodeCopyWithImpl<$Res>
    implements $UnicodeEmojiNodeCopyWith<$Res> {
  _$UnicodeEmojiNodeCopyWithImpl(this._self, this._then);

  final UnicodeEmojiNode _self;
  final $Res Function(UnicodeEmojiNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? emoji = null,}) {
  return _then(UnicodeEmojiNode(
null == emoji ? _self.emoji : emoji // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class HashtagNode extends MfmNode {
  const HashtagNode(this.hashtag): super._();
  

 final  String hashtag;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HashtagNodeCopyWith<HashtagNode> get copyWith => _$HashtagNodeCopyWithImpl<HashtagNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HashtagNode&&(identical(other.hashtag, hashtag) || other.hashtag == hashtag));
}


@override
int get hashCode => Object.hash(runtimeType,hashtag);

@override
String toString() {
  return 'MfmNode.hashtag(hashtag: $hashtag)';
}


}

/// @nodoc
abstract mixin class $HashtagNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $HashtagNodeCopyWith(HashtagNode value, $Res Function(HashtagNode) _then) = _$HashtagNodeCopyWithImpl;
@useResult
$Res call({
 String hashtag
});




}
/// @nodoc
class _$HashtagNodeCopyWithImpl<$Res>
    implements $HashtagNodeCopyWith<$Res> {
  _$HashtagNodeCopyWithImpl(this._self, this._then);

  final HashtagNode _self;
  final $Res Function(HashtagNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? hashtag = null,}) {
  return _then(HashtagNode(
null == hashtag ? _self.hashtag : hashtag // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MathBlockNode extends MfmNode {
  const MathBlockNode(this.formula): super._();
  

 final  String formula;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MathBlockNodeCopyWith<MathBlockNode> get copyWith => _$MathBlockNodeCopyWithImpl<MathBlockNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MathBlockNode&&(identical(other.formula, formula) || other.formula == formula));
}


@override
int get hashCode => Object.hash(runtimeType,formula);

@override
String toString() {
  return 'MfmNode.mathBlock(formula: $formula)';
}


}

/// @nodoc
abstract mixin class $MathBlockNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $MathBlockNodeCopyWith(MathBlockNode value, $Res Function(MathBlockNode) _then) = _$MathBlockNodeCopyWithImpl;
@useResult
$Res call({
 String formula
});




}
/// @nodoc
class _$MathBlockNodeCopyWithImpl<$Res>
    implements $MathBlockNodeCopyWith<$Res> {
  _$MathBlockNodeCopyWithImpl(this._self, this._then);

  final MathBlockNode _self;
  final $Res Function(MathBlockNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? formula = null,}) {
  return _then(MathBlockNode(
null == formula ? _self.formula : formula // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class MathInlineNode extends MfmNode {
  const MathInlineNode(this.formula): super._();
  

 final  String formula;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MathInlineNodeCopyWith<MathInlineNode> get copyWith => _$MathInlineNodeCopyWithImpl<MathInlineNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MathInlineNode&&(identical(other.formula, formula) || other.formula == formula));
}


@override
int get hashCode => Object.hash(runtimeType,formula);

@override
String toString() {
  return 'MfmNode.mathInline(formula: $formula)';
}


}

/// @nodoc
abstract mixin class $MathInlineNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $MathInlineNodeCopyWith(MathInlineNode value, $Res Function(MathInlineNode) _then) = _$MathInlineNodeCopyWithImpl;
@useResult
$Res call({
 String formula
});




}
/// @nodoc
class _$MathInlineNodeCopyWithImpl<$Res>
    implements $MathInlineNodeCopyWith<$Res> {
  _$MathInlineNodeCopyWithImpl(this._self, this._then);

  final MathInlineNode _self;
  final $Res Function(MathInlineNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? formula = null,}) {
  return _then(MathInlineNode(
null == formula ? _self.formula : formula // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class BoldNode extends MfmNode {
  const BoldNode(final  List<MfmNode> children): _children = children,super._();
  

 final  List<MfmNode> _children;
 List<MfmNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BoldNodeCopyWith<BoldNode> get copyWith => _$BoldNodeCopyWithImpl<BoldNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BoldNode&&const DeepCollectionEquality().equals(other._children, _children));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'MfmNode.bold(children: $children)';
}


}

/// @nodoc
abstract mixin class $BoldNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $BoldNodeCopyWith(BoldNode value, $Res Function(BoldNode) _then) = _$BoldNodeCopyWithImpl;
@useResult
$Res call({
 List<MfmNode> children
});




}
/// @nodoc
class _$BoldNodeCopyWithImpl<$Res>
    implements $BoldNodeCopyWith<$Res> {
  _$BoldNodeCopyWithImpl(this._self, this._then);

  final BoldNode _self;
  final $Res Function(BoldNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,}) {
  return _then(BoldNode(
null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<MfmNode>,
  ));
}


}

/// @nodoc


class ItalicNode extends MfmNode {
  const ItalicNode(final  List<MfmNode> children): _children = children,super._();
  

 final  List<MfmNode> _children;
 List<MfmNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItalicNodeCopyWith<ItalicNode> get copyWith => _$ItalicNodeCopyWithImpl<ItalicNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ItalicNode&&const DeepCollectionEquality().equals(other._children, _children));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'MfmNode.italic(children: $children)';
}


}

/// @nodoc
abstract mixin class $ItalicNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $ItalicNodeCopyWith(ItalicNode value, $Res Function(ItalicNode) _then) = _$ItalicNodeCopyWithImpl;
@useResult
$Res call({
 List<MfmNode> children
});




}
/// @nodoc
class _$ItalicNodeCopyWithImpl<$Res>
    implements $ItalicNodeCopyWith<$Res> {
  _$ItalicNodeCopyWithImpl(this._self, this._then);

  final ItalicNode _self;
  final $Res Function(ItalicNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,}) {
  return _then(ItalicNode(
null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<MfmNode>,
  ));
}


}

/// @nodoc


class StrikeNode extends MfmNode {
  const StrikeNode(final  List<MfmNode> children): _children = children,super._();
  

 final  List<MfmNode> _children;
 List<MfmNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StrikeNodeCopyWith<StrikeNode> get copyWith => _$StrikeNodeCopyWithImpl<StrikeNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StrikeNode&&const DeepCollectionEquality().equals(other._children, _children));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'MfmNode.strike(children: $children)';
}


}

/// @nodoc
abstract mixin class $StrikeNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $StrikeNodeCopyWith(StrikeNode value, $Res Function(StrikeNode) _then) = _$StrikeNodeCopyWithImpl;
@useResult
$Res call({
 List<MfmNode> children
});




}
/// @nodoc
class _$StrikeNodeCopyWithImpl<$Res>
    implements $StrikeNodeCopyWith<$Res> {
  _$StrikeNodeCopyWithImpl(this._self, this._then);

  final StrikeNode _self;
  final $Res Function(StrikeNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,}) {
  return _then(StrikeNode(
null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<MfmNode>,
  ));
}


}

/// @nodoc


class SmallNode extends MfmNode {
  const SmallNode(final  List<MfmNode> children): _children = children,super._();
  

 final  List<MfmNode> _children;
 List<MfmNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SmallNodeCopyWith<SmallNode> get copyWith => _$SmallNodeCopyWithImpl<SmallNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SmallNode&&const DeepCollectionEquality().equals(other._children, _children));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'MfmNode.small(children: $children)';
}


}

/// @nodoc
abstract mixin class $SmallNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $SmallNodeCopyWith(SmallNode value, $Res Function(SmallNode) _then) = _$SmallNodeCopyWithImpl;
@useResult
$Res call({
 List<MfmNode> children
});




}
/// @nodoc
class _$SmallNodeCopyWithImpl<$Res>
    implements $SmallNodeCopyWith<$Res> {
  _$SmallNodeCopyWithImpl(this._self, this._then);

  final SmallNode _self;
  final $Res Function(SmallNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,}) {
  return _then(SmallNode(
null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<MfmNode>,
  ));
}


}

/// @nodoc


class QuoteNode extends MfmNode {
  const QuoteNode(final  List<MfmNode> children): _children = children,super._();
  

 final  List<MfmNode> _children;
 List<MfmNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuoteNodeCopyWith<QuoteNode> get copyWith => _$QuoteNodeCopyWithImpl<QuoteNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuoteNode&&const DeepCollectionEquality().equals(other._children, _children));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'MfmNode.quote(children: $children)';
}


}

/// @nodoc
abstract mixin class $QuoteNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $QuoteNodeCopyWith(QuoteNode value, $Res Function(QuoteNode) _then) = _$QuoteNodeCopyWithImpl;
@useResult
$Res call({
 List<MfmNode> children
});




}
/// @nodoc
class _$QuoteNodeCopyWithImpl<$Res>
    implements $QuoteNodeCopyWith<$Res> {
  _$QuoteNodeCopyWithImpl(this._self, this._then);

  final QuoteNode _self;
  final $Res Function(QuoteNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,}) {
  return _then(QuoteNode(
null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<MfmNode>,
  ));
}


}

/// @nodoc


class CenterNode extends MfmNode {
  const CenterNode(final  List<MfmNode> children): _children = children,super._();
  

 final  List<MfmNode> _children;
 List<MfmNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CenterNodeCopyWith<CenterNode> get copyWith => _$CenterNodeCopyWithImpl<CenterNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CenterNode&&const DeepCollectionEquality().equals(other._children, _children));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'MfmNode.center(children: $children)';
}


}

/// @nodoc
abstract mixin class $CenterNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $CenterNodeCopyWith(CenterNode value, $Res Function(CenterNode) _then) = _$CenterNodeCopyWithImpl;
@useResult
$Res call({
 List<MfmNode> children
});




}
/// @nodoc
class _$CenterNodeCopyWithImpl<$Res>
    implements $CenterNodeCopyWith<$Res> {
  _$CenterNodeCopyWithImpl(this._self, this._then);

  final CenterNode _self;
  final $Res Function(CenterNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,}) {
  return _then(CenterNode(
null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<MfmNode>,
  ));
}


}

/// @nodoc


class PlainNode extends MfmNode {
  const PlainNode(final  List<MfmNode> children): _children = children,super._();
  

 final  List<MfmNode> _children;
 List<MfmNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlainNodeCopyWith<PlainNode> get copyWith => _$PlainNodeCopyWithImpl<PlainNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlainNode&&const DeepCollectionEquality().equals(other._children, _children));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'MfmNode.plain(children: $children)';
}


}

/// @nodoc
abstract mixin class $PlainNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $PlainNodeCopyWith(PlainNode value, $Res Function(PlainNode) _then) = _$PlainNodeCopyWithImpl;
@useResult
$Res call({
 List<MfmNode> children
});




}
/// @nodoc
class _$PlainNodeCopyWithImpl<$Res>
    implements $PlainNodeCopyWith<$Res> {
  _$PlainNodeCopyWithImpl(this._self, this._then);

  final PlainNode _self;
  final $Res Function(PlainNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? children = null,}) {
  return _then(PlainNode(
null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<MfmNode>,
  ));
}


}

/// @nodoc


class UrlNode extends MfmNode {
  const UrlNode({required this.url, this.brackets = false}): super._();
  

/// The URL string.
///
/// URL文字列
 final  String url;
/// Whether this uses bracket format (`<url>`).
///
/// ブラケット形式（&lt;url&gt;）かどうか
@JsonKey() final  bool brackets;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UrlNodeCopyWith<UrlNode> get copyWith => _$UrlNodeCopyWithImpl<UrlNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UrlNode&&(identical(other.url, url) || other.url == url)&&(identical(other.brackets, brackets) || other.brackets == brackets));
}


@override
int get hashCode => Object.hash(runtimeType,url,brackets);

@override
String toString() {
  return 'MfmNode.url(url: $url, brackets: $brackets)';
}


}

/// @nodoc
abstract mixin class $UrlNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $UrlNodeCopyWith(UrlNode value, $Res Function(UrlNode) _then) = _$UrlNodeCopyWithImpl;
@useResult
$Res call({
 String url, bool brackets
});




}
/// @nodoc
class _$UrlNodeCopyWithImpl<$Res>
    implements $UrlNodeCopyWith<$Res> {
  _$UrlNodeCopyWithImpl(this._self, this._then);

  final UrlNode _self;
  final $Res Function(UrlNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? url = null,Object? brackets = null,}) {
  return _then(UrlNode(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,brackets: null == brackets ? _self.brackets : brackets // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class LinkNode extends MfmNode {
  const LinkNode({required this.silent, required this.url, required final  List<MfmNode> children}): _children = children,super._();
  

/// Whether this is a silent link (has `?` prefix).
///
/// サイレントリンクかどうか（?プレフィックスの有無）
 final  bool silent;
/// The destination URL.
///
/// リンク先URL
 final  String url;
/// List of child nodes (link text).
///
/// 子ノードのリスト（リンクテキスト）
 final  List<MfmNode> _children;
/// List of child nodes (link text).
///
/// 子ノードのリスト（リンクテキスト）
 List<MfmNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LinkNodeCopyWith<LinkNode> get copyWith => _$LinkNodeCopyWithImpl<LinkNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LinkNode&&(identical(other.silent, silent) || other.silent == silent)&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other._children, _children));
}


@override
int get hashCode => Object.hash(runtimeType,silent,url,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'MfmNode.link(silent: $silent, url: $url, children: $children)';
}


}

/// @nodoc
abstract mixin class $LinkNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $LinkNodeCopyWith(LinkNode value, $Res Function(LinkNode) _then) = _$LinkNodeCopyWithImpl;
@useResult
$Res call({
 bool silent, String url, List<MfmNode> children
});




}
/// @nodoc
class _$LinkNodeCopyWithImpl<$Res>
    implements $LinkNodeCopyWith<$Res> {
  _$LinkNodeCopyWithImpl(this._self, this._then);

  final LinkNode _self;
  final $Res Function(LinkNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? silent = null,Object? url = null,Object? children = null,}) {
  return _then(LinkNode(
silent: null == silent ? _self.silent : silent // ignore: cast_nullable_to_non_nullable
as bool,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<MfmNode>,
  ));
}


}

/// @nodoc


class MentionNode extends MfmNode {
  const MentionNode({required this.username, this.host, required this.acct}): super._();
  

/// The username.
///
/// ユーザー名
 final  String username;
/// The host (optional, for remote users).
///
/// ホスト（省略可、リモートユーザー用）
 final  String? host;
/// The full account identifier (e.g., `@user` or `@user@host`).
///
/// 完全なアカウント識別子（例: `@user` または `@user@host`）
 final  String acct;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MentionNodeCopyWith<MentionNode> get copyWith => _$MentionNodeCopyWithImpl<MentionNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MentionNode&&(identical(other.username, username) || other.username == username)&&(identical(other.host, host) || other.host == host)&&(identical(other.acct, acct) || other.acct == acct));
}


@override
int get hashCode => Object.hash(runtimeType,username,host,acct);

@override
String toString() {
  return 'MfmNode.mention(username: $username, host: $host, acct: $acct)';
}


}

/// @nodoc
abstract mixin class $MentionNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $MentionNodeCopyWith(MentionNode value, $Res Function(MentionNode) _then) = _$MentionNodeCopyWithImpl;
@useResult
$Res call({
 String username, String? host, String acct
});




}
/// @nodoc
class _$MentionNodeCopyWithImpl<$Res>
    implements $MentionNodeCopyWith<$Res> {
  _$MentionNodeCopyWithImpl(this._self, this._then);

  final MentionNode _self;
  final $Res Function(MentionNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? username = null,Object? host = freezed,Object? acct = null,}) {
  return _then(MentionNode(
username: null == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String?,acct: null == acct ? _self.acct : acct // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class FnNode extends MfmNode {
  const FnNode({required this.name, required final  Map<String, dynamic> args, required final  List<MfmNode> children}): _args = args,_children = children,super._();
  

/// The function name (e.g., tada, shake, spin).
///
/// 関数名（tada, shake, spin等）
 final  String name;
/// Arguments map (key: String value or true).
///
/// Example: {speed: "2s", h: true, v: true}
///
/// 引数マップ（key: String値またはtrue）
///
/// 例: {speed: "2s", h: true, v: true}
 final  Map<String, dynamic> _args;
/// Arguments map (key: String value or true).
///
/// Example: {speed: "2s", h: true, v: true}
///
/// 引数マップ（key: String値またはtrue）
///
/// 例: {speed: "2s", h: true, v: true}
 Map<String, dynamic> get args {
  if (_args is EqualUnmodifiableMapView) return _args;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_args);
}

/// List of child nodes (content to apply the function to).
///
/// 子ノードのリスト（関数に適用される内容）
 final  List<MfmNode> _children;
/// List of child nodes (content to apply the function to).
///
/// 子ノードのリスト（関数に適用される内容）
 List<MfmNode> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FnNodeCopyWith<FnNode> get copyWith => _$FnNodeCopyWithImpl<FnNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FnNode&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._args, _args)&&const DeepCollectionEquality().equals(other._children, _children));
}


@override
int get hashCode => Object.hash(runtimeType,name,const DeepCollectionEquality().hash(_args),const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'MfmNode.fn(name: $name, args: $args, children: $children)';
}


}

/// @nodoc
abstract mixin class $FnNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $FnNodeCopyWith(FnNode value, $Res Function(FnNode) _then) = _$FnNodeCopyWithImpl;
@useResult
$Res call({
 String name, Map<String, dynamic> args, List<MfmNode> children
});




}
/// @nodoc
class _$FnNodeCopyWithImpl<$Res>
    implements $FnNodeCopyWith<$Res> {
  _$FnNodeCopyWithImpl(this._self, this._then);

  final FnNode _self;
  final $Res Function(FnNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? name = null,Object? args = null,Object? children = null,}) {
  return _then(FnNode(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,args: null == args ? _self._args : args // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<MfmNode>,
  ));
}


}

/// @nodoc


class CodeBlockNode extends MfmNode {
  const CodeBlockNode({required this.code, this.language}): super._();
  

/// The code content (supports multiple lines).
///
/// コード内容（複数行対応）
 final  String code;
/// The language (optional).
///
/// 言語（省略可）
 final  String? language;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CodeBlockNodeCopyWith<CodeBlockNode> get copyWith => _$CodeBlockNodeCopyWithImpl<CodeBlockNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CodeBlockNode&&(identical(other.code, code) || other.code == code)&&(identical(other.language, language) || other.language == language));
}


@override
int get hashCode => Object.hash(runtimeType,code,language);

@override
String toString() {
  return 'MfmNode.codeBlock(code: $code, language: $language)';
}


}

/// @nodoc
abstract mixin class $CodeBlockNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $CodeBlockNodeCopyWith(CodeBlockNode value, $Res Function(CodeBlockNode) _then) = _$CodeBlockNodeCopyWithImpl;
@useResult
$Res call({
 String code, String? language
});




}
/// @nodoc
class _$CodeBlockNodeCopyWithImpl<$Res>
    implements $CodeBlockNodeCopyWith<$Res> {
  _$CodeBlockNodeCopyWithImpl(this._self, this._then);

  final CodeBlockNode _self;
  final $Res Function(CodeBlockNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? code = null,Object? language = freezed,}) {
  return _then(CodeBlockNode(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,language: freezed == language ? _self.language : language // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class SearchNode extends MfmNode {
  const SearchNode({required this.query, required this.content}): super._();
  

/// The search query (keyword part).
///
/// 検索クエリ（検索キーワード部分）
 final  String query;
/// The original input text (query + space + search button).
///
/// 元の入力テキスト全体（クエリ + スペース + 検索ボタン）
 final  String content;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchNodeCopyWith<SearchNode> get copyWith => _$SearchNodeCopyWithImpl<SearchNode>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchNode&&(identical(other.query, query) || other.query == query)&&(identical(other.content, content) || other.content == content));
}


@override
int get hashCode => Object.hash(runtimeType,query,content);

@override
String toString() {
  return 'MfmNode.search(query: $query, content: $content)';
}


}

/// @nodoc
abstract mixin class $SearchNodeCopyWith<$Res> implements $MfmNodeCopyWith<$Res> {
  factory $SearchNodeCopyWith(SearchNode value, $Res Function(SearchNode) _then) = _$SearchNodeCopyWithImpl;
@useResult
$Res call({
 String query, String content
});




}
/// @nodoc
class _$SearchNodeCopyWithImpl<$Res>
    implements $SearchNodeCopyWith<$Res> {
  _$SearchNodeCopyWithImpl(this._self, this._then);

  final SearchNode _self;
  final $Res Function(SearchNode) _then;

/// Create a copy of MfmNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? query = null,Object? content = null,}) {
  return _then(SearchNode(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
