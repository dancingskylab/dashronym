/// Tokens produced by the core dashronym parser.
///
/// These are pure data objects that describe either plain text segments or
/// matched acronyms with their resolved descriptions. They are independent of
/// Flutter and can be consumed by different presentation layers.
sealed class const DashronymToken();

/// A run of plain text that should be rendered as-is.
final class const DashronymTextToken(
  /// The literal text for this run.
  final String text,
) extends DashronymToken {
  /// Creates a text token containing [text].
  this;

  @override
  bool operator ==(Object other) =>
      other is DashronymTextToken && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'DashronymTextToken($text)';
}

/// A matched acronym and its description.
final class const DashronymMatchToken({
  /// The acronym that was matched in the source text.
  required final String acronym,

  /// The description resolved from the registry.
  required final String description,
}) extends DashronymToken {
  /// Creates an acronym token for [acronym] and its [description].
  this;

  @override
  bool operator ==(Object other) =>
      other is DashronymMatchToken &&
      other.acronym == acronym &&
      other.description == description;

  @override
  int get hashCode => Object.hash(acronym, description);

  @override
  String toString() =>
      'DashronymMatchToken(acronym: $acronym, description: $description)';
}
