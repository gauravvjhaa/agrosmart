import 'package:flutter/material.dart';

class RemoteSupportScreen extends StatelessWidget {
  const RemoteSupportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Remote Support')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Upload Diagnostic Bundle'),
              subtitle: const Text('Log files + configuration'),
              trailing: const Icon(Icons.cloud_upload),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Run Self-Test Suite'),
              subtitle: const Text('Sensors, valves, connectivity'),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Request Technician Callback'),
              subtitle: const Text('We will reach you  .'),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
