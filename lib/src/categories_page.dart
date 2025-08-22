import 'package:flutter/material.dart';
import 'search_page.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  static const _categories = <String>[
    'Nature','City','People','Animals','Food','Technology','Travel','Sports',
    'Art','Cars','Fashion','Music','Architecture','Beach','Mountains',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: _categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.6,
          ),
          itemBuilder: (_, i) {
            final label = _categories[i];
            return InkWell(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => SearchPage(initialQuery: label),
                ));
              },
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Center(
                  child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
