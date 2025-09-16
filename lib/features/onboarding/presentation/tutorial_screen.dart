import 'package:flutter/material.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});
  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _page = PageController();
  int idx = 0;
  final slides = const [
    _Slide(
      title: 'Hardware Overview',
      points: [
        'Capacitive soil-moisture + temperature sensors',
        'pH / EC probes for soil chemistry',
        'Arduino / ESP32 microcontrollers',
        'LoRa mesh modules for long range',
      ],
      icon: Icons.memory,
    ),
    _Slide(
      title: 'Real-time Dashboard',
      points: [
        'Zone moisture & temperature',
        'Color alerts for critical states',
        'Trends & historical graphs',
        'Predictive irrigation insights',
      ],
      icon: Icons.dashboard_customize,
    ),
    _Slide(
      title: 'Automation & Scheduling',
      points: [
        'AUTO mode thresholds',
        'Weather-aware optimization',
        'Machine learning predictions',
        'Smart water budgeting',
      ],
      icon: Icons.auto_mode,
    ),
    _Slide(
      title: 'Offline & Resilience',
      points: [
        'Local caching & sync',
        'Bluetooth local control',
        'SMS fallback alerts',
        'Graceful recovery',
      ],
      icon: Icons.offline_bolt,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutorial')),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _page,
              onPageChanged: (v) => setState(() => idx = v),
              itemCount: slides.length,
              itemBuilder: (_, i) => slides[i],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                for (int i = 0; i < slides.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 10,
                    width: i == idx ? 28 : 10,
                    decoration: BoxDecoration(
                      color: i == idx ? Colors.green : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    if (idx == slides.length - 1) {
                      Navigator.pop(context);
                    } else {
                      _page.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(idx == slides.length - 1 ? 'Done' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final String title;
  final List<String> points;
  final IconData icon;
  const _Slide({required this.title, required this.points, required this.icon});
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: points
          .map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e)),
                ],
              ),
            ),
          )
          .toList(),
    );
    return Padding(
      padding: const EdgeInsets.all(32),
      child: isWide
          ? Row(
              children: [
                Expanded(child: _iconSection()),
                const SizedBox(width: 32),
                Expanded(child: _textSection(content)),
              ],
            )
          : Column(
              children: [
                _iconSection(),
                const SizedBox(height: 24),
                _textSection(content),
              ],
            ),
    );
  }

  Widget _iconSection() => Hero(
    tag: title,
    child: CircleAvatar(
      radius: 70,
      backgroundColor: Colors.green.shade100,
      child: Icon(icon, size: 70, color: Colors.green.shade700),
    ),
  );
  Widget _textSection(Widget content) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      content,
    ],
  );
}
