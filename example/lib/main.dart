import 'package:dashronym/dashronym.dart';
import 'package:material_ui/material_ui.dart';

import 'material_theme.dart';

final acronyms = DashronymRegistry({
  'API': 'Application Programming Interface',
  'CLI': 'Command Line Interface',
  'SDK': 'Software Development Kit',
  'UI': 'User Interface',
});

void main() => runApp(const DashronymExampleApp());

class DashronymExampleApp extends StatelessWidget {
  const DashronymExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashronym example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      localizationsDelegates: const [
        DashronymLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      // Give every route a Material-styled Dashronym card. The builder runs
      // below AnimatedTheme, so the card follows light and dark mode.
      builder: (context, child) => DashronymThemeScope(
        data: dashronymThemeFromMaterial(
          Theme.of(context),
        ).copyWith(tooltipMaxWidth: 360),
        child: child!,
      ),
      home: DashronymScope(
        registry: acronyms,
        child: const ReleaseNotesPage(),
      ),
    );
  }
}

class ReleaseNotesPage extends StatelessWidget {
  const ReleaseNotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashronym example')),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              'Tap an underlined term for its definition.',
              style: textTheme.labelLarge?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _Section(
              title: "What's new",
              child: Text(
                'Version 4.2 rebuilds sync on top of our new SDK and talks '
                'directly to the same API that powers the UI you use every '
                'day.',
                style: textTheme.bodyLarge,
              ).dashronyms(),
            ),
            _Section(
              title: 'Rich text stays rich',
              child: Text.rich(
                TextSpan(
                  style: textTheme.bodyLarge,
                  children: const [
                    TextSpan(text: 'The '),
                    TextSpan(
                      text: 'SDK',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          ' now retries failed requests before they ever '
                          'reach your ',
                    ),
                    TextSpan(
                      text: 'UI',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
              ).dashronyms(),
            ),
            _Section(
              title: 'Marker-wrapped terms',
              child: const DashronymText(
                'Prefer the terminal? The same release ships from the (CLI).',
              ),
            ),
            _Section(
              title: 'Bring your own tooltip',
              child: DashronymText(
                'Something look wrong? Check the API status page first.',
                tooltipBuilder: (context, details) =>
                    _SupportTooltip(details: details),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportTooltip extends StatelessWidget {
  const _SupportTooltip({required this.details});

  final DashronymTooltipDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Definition for ${details.acronym}',
      child: Material(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.support_agent, color: colors.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    details.acronym,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close definition',
                    onPressed: details.hideTooltip,
                    icon: Icon(Icons.close, color: colors.onPrimaryContainer),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                details.description,
                style: TextStyle(color: colors.onPrimaryContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
