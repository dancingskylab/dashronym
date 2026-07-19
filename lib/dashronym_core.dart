/// Portable, pure-Dart glossary models and matching configuration.
///
/// This library has no Flutter API in its import graph, so Flutter-SDK projects
/// can reuse glossary documents and registries in non-UI layers. The package
/// itself still declares a Flutter SDK dependency; the portable layer is ready
/// to be extracted into a standalone Dart package if that distribution is
/// needed later.
library;

export 'src/acronym_entry.dart';
export 'src/config.dart';
export 'src/glossary.dart';
export 'src/registry.dart';
