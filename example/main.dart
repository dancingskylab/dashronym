import 'package:dashronym/dashronym.dart';
import 'package:flutter/material.dart';

void main() {
  final acronyms = DashronymRegistry({
    'API': 'Application Programming Interface',
    'CLI': 'Command Line Interface',
    'SDK': 'Software Development Kit',
    'UI': 'User Interface',
  });
  runApp(GlossaryApp(registry: acronyms));
}

class GlossaryApp extends StatelessWidget {
  const GlossaryApp({super.key, required this.registry});

  final DashronymRegistry registry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashronym example',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        extensions: const [
          DashronymTheme(
            acronymStyle: TextStyle(color: Colors.indigo),
            tooltipMaxWidth: 360,
          ),
        ],
      ),
      home: DashronymScope(
        registry: registry,
        child: const GlossaryPage(),
      ),
    );
  }
}

class GlossaryPage extends StatelessWidget {
  const GlossaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashronym')),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Dashronym adds definitions for terms such as SDK and API '
              'without changing how you write ordinary Flutter text.',
              style: Theme.of(context).textTheme.bodyLarge,
            ).dashronyms(),
            const SizedBox(height: 24),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'It also works with '),
                  TextSpan(
                    text: 'rich text',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const TextSpan(text: ' used in your UI.'),
                ],
              ),
            ).dashronyms(),
            const SizedBox(height: 24),
            const DashronymText(
              'Marker-wrapped terms work too: try the (CLI).',
            ),
            const SizedBox(height: 32),
            Text(
              'Custom definition card',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            DashronymText(
              'Tap API to open an application-owned surface.',
              tooltipBuilder: (context, details) => Semantics(
                container: true,
                label: 'Definition for ${details.acronym}',
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    title: Text(details.acronym),
                    subtitle: Text(details.description),
                    trailing: IconButton(
                      tooltip: 'Close definition',
                      onPressed: details.hideTooltip,
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
