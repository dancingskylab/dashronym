/// Tokens produced by the core dashronym parser.
///
/// These are pure data objects that describe either plain text segments or
/// matched acronyms with their resolved descriptions. They are independent of
/// Flutter and can be consumed by different presentation layers.
sealed class DashronymToken {
  const DashronymToken();
}

/// A run of plain text that should be rendered as-is.
final class TextToken extends DashronymToken {
  /// Creates a text token containing [text].
  const TextToken(this.text);

  /// The literal text for this run.
  final String text;

  @override
  bool operator ==(Object other) => other is TextToken && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'TextToken($text)';
}

/// A matched acronym and its description.
final class AcronymToken extends DashronymToken {
  /// Creates an acronym token for [acronym] and its [description].
  const AcronymToken({required this.acronym, required this.description});

  /// The acronym that was matched in the source text.
  final String acronym;

  /// The description resolved from the registry.
  final String description;

  @override
  bool operator ==(Object other) =>
      other is AcronymToken &&
      other.acronym == acronym &&
      other.description == description;

  @override
  int get hashCode => Object.hash(acronym, description);

  @override
  String toString() =>
      'AcronymToken(acronym: $acronym, description: $description)';
}
