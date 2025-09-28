import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});
  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _page = PageController();
  int idx = 0;
  String _language = 'English';
  bool _loadingLanguage = true;

  // Translation maps - fixed structure
  final Map<String, Map<String, dynamic>> _translations = {
    'English': {
      'slides': [
        {
          'title': 'Hardware Overview',
          'points': [
            'Capacitive soil-moisture + temperature sensors',
            'pH / EC probes for soil chemistry',
            'Arduino / ESP32 microcontrollers',
            'LoRa mesh modules for long range',
          ],
          'icon': Icons.memory,
        },
        {
          'title': 'Real-time Dashboard',
          'points': [
            'Zone moisture & temperature',
            'Color alerts for critical states',
            'Trends & historical graphs',
            'Predictive irrigation insights',
          ],
          'icon': Icons.dashboard_customize,
        },
        {
          'title': 'Automation & Scheduling',
          'points': [
            'AUTO mode thresholds',
            'Weather-aware optimization',
            'Machine learning predictions',
            'Smart water budgeting',
          ],
          'icon': Icons.auto_mode,
        },
        {
          'title': 'Offline & Resilience',
          'points': [
            'Local caching & sync',
            'Bluetooth local control',
            'SMS fallback alerts',
            'Graceful recovery',
          ],
          'icon': Icons.offline_bolt,
        },
      ],
      'ui_strings': {'next': 'Next', 'done': 'Done', 'tutorial': 'Tutorial'},
    },
    'Hindi': {
      'slides': [
        {
          'title': 'हार्डवेयर अवलोकन',
          'points': [
            'कैपेसिटिव मिट्टी-नमी + तापमान सेंसर',
            'मृदा रसायन के लिए pH / EC प्रोब',
            'Arduino / ESP32 माइक्रोकंट्रोलर',
            'लंबी दूरी के लिए LoRa मेश मॉड्यूल',
          ],
          'icon': Icons.memory,
        },
        {
          'title': 'रीयल-टाइम डैशबोर्ड',
          'points': [
            'ज़ोन नमी और तापमान',
            'महत्वपूर्ण स्थितियों के लिए रंग अलर्ट',
            'ट्रेंड्स और ऐतिहासिक ग्राफ़',
            'भविष्य कहनेवाला सिंचाई अंतर्दृष्टि',
          ],
          'icon': Icons.dashboard_customize,
        },
        {
          'title': 'ऑटोमेशन और शेड्यूलिंग',
          'points': [
            'AUTO मोड थ्रेशोल्ड',
            'मौसम-जागरूक अनुकूलन',
            'मशीन लर्निंग भविष्यवाणियां',
            'स्मार्ट जल बजटिंग',
          ],
          'icon': Icons.auto_mode,
        },
        {
          'title': 'ऑफलाइन और लचीलापन',
          'points': [
            'स्थानीय कैशिंग और सिंक',
            'ब्लूटूथ स्थानीय नियंत्रण',
            'SMS फॉलबैक अलर्ट',
            'सुगम पुनर्प्राप्ति',
          ],
          'icon': Icons.offline_bolt,
        },
      ],
      'ui_strings': {'next': 'आगे', 'done': 'पूर्ण', 'tutorial': 'ट्यूटोरियल'},
    },
    'Nepali': {
      'slides': [
        {
          'title': 'हार्डवेयर अवलोकन',
          'points': [
            'क्यापासिटिभ माटो-नमी + तापमान सेंसर',
            'माटो रसायनको लागि pH / EC प्रोबहरू',
            'Arduino / ESP32 माइक्रोकन्ट्रोलर',
            'लामो दूरीको लागि LoRa मेश मोड्युलहरू',
          ],
          'icon': Icons.memory,
        },
        {
          'title': 'रीयल-टाइम ड्यासबोर्ड',
          'points': [
            'क्षेत्रको नमी र तापक्रम',
            'महत्वपूर्ण अवस्थाका लागि रंग सचेतक',
            'प्रवृत्ति र ऐतिहासिक ग्राफहरू',
            'भविष्यवाणी सिँचाई अन्तर्दृष्टि',
          ],
          'icon': Icons.dashboard_customize,
        },
        {
          'title': 'स्वचालन र तालिका',
          'points': [
            'AUTO मोड थ्रेशोल्ड',
            'मौसम-जागरूक अनुकूलन',
            'मेसिन लर्निंग भविष्यवाणीहरू',
            'स्मार्ट पानी बजेटिंग',
          ],
          'icon': Icons.auto_mode,
        },
        {
          'title': 'अफलाइन र लचिलोपन',
          'points': [
            'स्थानीय क्याशिंग र सिंक',
            'ब्लुटुथ स्थानीय नियन्त्रण',
            'SMS फलब्याक सचेतक',
            'सहज पुनर्प्राप्ति',
          ],
          'icon': Icons.offline_bolt,
        },
      ],
      'ui_strings': {
        'next': 'अर्को',
        'done': 'सम्पन्न',
        'tutorial': 'ट्यूटोरियल',
      },
    },
  };

  List<Map<String, dynamic>> get slides {
    final langData = _translations[_language];
    if (langData != null && langData['slides'] is List) {
      return List<Map<String, dynamic>>.from(langData['slides'] as List);
    }
    // Fallback to English
    return List<Map<String, dynamic>>.from(
      _translations['English']!['slides'] as List,
    );
  }

  String t(String key) {
    final langData = _translations[_language];
    if (langData != null &&
        langData['ui_strings'] is Map<String, dynamic> &&
        (langData['ui_strings'] as Map<String, dynamic>).containsKey(key)) {
      return (langData['ui_strings'] as Map<String, dynamic>)[key] as String;
    }
    // Fallback to English
    return (_translations['English']!['ui_strings']
            as Map<String, dynamic>)[key]
        as String;
  }

  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
  }

  Future<void> _loadUserLanguage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final snapshot = await FirebaseDatabase.instance
            .ref('farmers/${user.uid}/preferences/language')
            .get();

        if (snapshot.exists && snapshot.value != null) {
          setState(() {
            _language = snapshot.value.toString();
            _loadingLanguage = false;
          });
        } else {
          setState(() {
            _loadingLanguage = false;
          });
        }
      } else {
        setState(() {
          _loadingLanguage = false;
        });
      }
    } catch (e) {
      setState(() {
        _loadingLanguage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLanguage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tutorial')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(t('tutorial'))),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _page,
              onPageChanged: (v) => setState(() => idx = v),
              itemCount: slides.length,
              itemBuilder: (_, i) => _Slide(
                title: slides[i]['title'] as String,
                points: List<String>.from(slides[i]['points'] as List),
                icon: slides[i]['icon'] as IconData,
              ),
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
                  child: Text(idx == slides.length - 1 ? t('done') : t('next')),
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
