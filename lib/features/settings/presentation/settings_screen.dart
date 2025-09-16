import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    bool dark = false;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            value: dark,
            onChanged: (_) {},
            title: const Text('Dark Mode  '),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English / हिंदी'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.voice_chat),
            title: const Text('Voice Commands'),
            subtitle: const Text('Enable speech control'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Roles & Access'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
