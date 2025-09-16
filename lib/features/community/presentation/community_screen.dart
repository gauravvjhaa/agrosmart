import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community & Knowledge'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Forum'),
              Tab(text: 'Best Practices'),
              Tab(text: 'ROI Tool'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Forum Placeholder (UI Only)')),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Hilly Region Tips:\n• Contour bunding\n• Mulching moisture retention\n• Rainwater harvesting integration\n• Staggered planting for runoff control',
              ),
            ),
            Center(child: Text('ROI Calculator (Mock UI)')),
          ],
        ),
      ),
    );
  }
}
