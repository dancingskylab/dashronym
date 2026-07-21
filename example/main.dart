import 'package:dashronym/dashronym.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Entry point for the demo application.
///
/// The showcase surfaces a sequence of sections that highlight:
/// * Shared defaults with no repeated per-widget configuration.
/// * Theme-based customization (animation tweaks, card styling).
/// * Full tooltip replacement via `tooltipBuilder`.
/// * Behaviour when content extends beyond the initial viewport.
void main() => runApp(const DashronymShowcase());

/// Demo application that showcases Dashronym inline glossary behavior.
///
/// Presents a series of sections covering default usage, theme customization,
/// custom tooltip builders, and long-scroll behaviour.
class DashronymShowcase extends StatelessWidget {
  const DashronymShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    // Define one portable glossary so every section reads the same rich data.
    final glossary = DashronymGlossary(
      name: 'Dashronym showcase',
      id: 'dev.dashronym.showcase',
      version: '1',
      locale: 'en',
      entries: [
        DashronymEntry(
          acronym: 'SDK',
          expansion: 'Software Development Kit',
          aliases: const ['DEVKIT'],
          tags: const ['software', 'tooling'],
        ),
        DashronymEntry(
          acronym: 'API',
          expansion: 'Application Programming Interface',
          definition: 'A defined interface used by software components.',
          tags: const ['software', 'integration'],
          source: 'https://en.wikipedia.org/wiki/API',
        ),
        DashronymEntry(
          acronym: 'CLI',
          expansion: 'Command Line Interface',
          tags: const ['tooling'],
        ),
        DashronymEntry(
          acronym: 'FFI',
          expansion: 'Foreign Function Interface',
          tags: const ['interop'],
        ),
        DashronymEntry(
          acronym: 'IDE',
          expansion: 'Integrated Development Environment',
          tags: const ['tooling'],
        ),
        DashronymEntry(
          acronym: 'LSP',
          expansion: 'Language Server Protocol',
          tags: const ['tooling', 'protocol'],
        ),
        DashronymEntry(
          acronym: 'UI',
          expansion: 'User Interface',
          tags: const ['design'],
        ),
        DashronymEntry(
          acronym: 'AOT',
          expansion: 'Ahead Of Time compilation',
          tags: const ['compiler'],
        ),
      ],
    );
    final registry = glossary.toRegistry();
    const config = DashronymConfig(
      enableBareAcronyms: true,
      acceptMarkers: ['()', '«»'],
    );

    // Example theme that focuses on animation behaviour.
    const animationTheme = DashronymTheme(
      tooltipFadeDuration: Duration(milliseconds: 220),
      tooltipScaleBegin: 0.92,
      tooltipScaleEnd: 1.05,
      tooltipScaleInCurve: Curves.easeOutBack,
      tooltipScaleOutCurve: Curves.easeIn,
    );

    // Example theme that focuses on card surface appearance.
    const themedSurface = DashronymTheme(
      underline: true,
      decorationThickness: 1.5,
      cardElevation: 10,
      cardIcon: Icons.book_outlined,
      cardCloseIcon: Icons.close_rounded,
      cardIconColor: Colors.deepPurple,
      cardTitleStyle: TextStyle(fontWeight: FontWeight.bold),
      tooltipOffset: Offset(0, 8),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        extensions: const [
          DashronymTheme(tooltipMaxWidth: 360),
        ],
      ),
      localizationsDelegates: const [
        DashronymLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: DashronymLocalizations.supportedLocales,
      home: DashronymScope(
        registry: registry,
        config: config,
        child: Builder(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('dashronym showcase')),
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AccessibleHeader(
                  title: 'Drop-in defaults',
                  subtitle:
                      'No theme overrides — demonstrates the base behaviour out of the box.',
                ),
                Text(
                  'Authors draft Flutter documentation as ordinary `Text` widgets, then call '
                  '`.dashronyms()` to transform tokens like SDK into tappable overlays.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).dashronyms(),
                const SizedBox(height: 12),
                Text(
                  'Scroll further down the page to verify off-screen acronyms continue to resolve '
                  'correctly once they re-enter the viewport. The default theme keeps typography '
                  'intact while the trigger underline signals interactive guidance.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 32),
                _AccessibleHeader(
                  title: 'Rich text and shared scope',
                  subtitle:
                      'Nested styles and existing spans are retained while the surrounding scope '
                      'supplies the glossary.',
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'A shared '),
                      TextSpan(
                        text: 'API',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.indigo,
                        ),
                      ),
                      const TextSpan(
                        text:
                            ' can be explained inside an authored rich-text tree.',
                      ),
                    ],
                  ),
                ).dashronyms(),

                const SizedBox(height: 32),
                _AccessibleHeader(
                  title: 'Customized animations',
                  subtitle:
                      'Tweaked fade + scale curves and durations via DashronymTheme.',
                ),
                DashronymText(
                  'Hover over «CLI» or «IDE» to see a playful scale animation produced by custom '
                  'curves.',
                  theme: animationTheme,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'These animation settings still respect screen readers and keyboard interaction, so '
                  'users tabbing between elements experience the same reveal without jitter.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 32),
                _AccessibleHeader(
                  title: 'Customized tooltip surface',
                  subtitle:
                      'Card sizing, elevation, iconography, offsets, and built-in edge gutters.',
                ),
                DashronymText(
                  'Design teams can adjust underline styling, tooltip width, and icons without '
                  'rewriting any logic. Tap «FFI» or «LSP» to see the modified surface.',
                  theme: themedSurface,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Try rotating or resizing the window: the tooltip recalibrates safe areas, keeps an '
                  '8 px gutter on both sides, and remains visible on phones, tablets, and desktops.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const SizedBox(height: 32),
                _AccessibleHeader(
                  title: 'Custom tooltip builder',
                  subtitle:
                      'Supply your own widget while reusing overlay lifecycle, focus, and semantics.',
                ),
                DashronymText(
                  'Our (UI) flow embraces localization and accessibility.',
                  theme: themedSurface,
                  style: Theme.of(context).textTheme.bodyMedium,
                  tooltipBuilder: (context, details) => Semantics(
                    container: true,
                    label:
                        '${details.acronym} glossary card. Activate the close button to dismiss.',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Card(
                        margin: EdgeInsets.zero,
                        color: Colors.indigo.shade50,
                        child: ListTile(
                          title: Text(details.acronym),
                          subtitle: Text(
                            [
                              details.entry?.definition ?? details.description,
                              if (details.entry?.tags case final tags?
                                  when tags.isNotEmpty)
                                'Tags: ${tags.join(', ')}',
                            ].join('\n'),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: DashronymLocalizations.of(
                              context,
                            ).closeButtonTooltip(details.acronym),
                            onPressed: details.hideTooltip,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                _AccessibleHeader(
                  title: 'Standalone widget',
                  subtitle:
                      'DashronymText offers the same parsing pipeline without the extension helper.',
                ),
                DashronymText(
                  'Use DashronymText inside reusable components to highlight (AOT) flows and '
                  '(SDK) distribution strategies.',
                  theme: const DashronymTheme(underline: false),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                Semantics(
                  header: true,
                  child: Text(
                    'Long-form content demo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 8),
                DashronymText(
                  'Below is a block of prose that exceeds the initial viewport height so you can test '
                  'scrolling behaviour. Hover and keyboard interactions should continue to operate '
                  'even after you scroll away and back. The tooling references we use later—such as '
                  'the Integrated Development Environment «IDE», the command-line interface «CLI», '
                  'and Ahead Of Time (AOT) compilation—should feel natural in the narrative.',
                  theme: themedSurface,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                DashronymText(
                  'When modern Flutter teams build cross-platform experiences, they often pair an IDE '
                  'setup with automated CLI pipelines. That combination allows them to iterate '
                  'quickly while keeping release artifacts deterministic. With dashronym in place, '
                  'onboarding docs for new engineers can reference the same glossary inline without '
                  'forcing readers to jump between pages. The same reviewed registry can power '
                  'short labels, long-form articles, and reusable components without duplicating '
                  'glossary definitions throughout the widget tree.',
                  theme: themedSurface,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                DashronymText(
                  'Continue scrolling to confirm that overlays collapse when dismissed and do not '
                  'linger off-screen. The accessibility enhancements—debounced announcements, '
                  'focus-based toggling, and single overlay enforcement—remain active regardless of '
                  'how far down the article you travel. Edge-aware positioning now keeps tooltips off '
                  'both sides of the viewport, even with custom builders.',
                  theme: themedSurface,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Simple helper widget that renders section headings.
///
/// Using a widget instead of raw code keeps the example compact and ensures
/// consistent spacing and semantics across sections.
class _AccessibleHeader extends StatelessWidget {
  const _AccessibleHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
