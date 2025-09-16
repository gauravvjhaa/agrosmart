import 'package:flutter/material.dart';

class AdminAuditScreen extends StatelessWidget {
  const AdminAuditScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final logs = List.generate(
      18,
      (i) => {
        'actor': i.isEven ? 'worker_01' : 'owner',
        'action': i.isEven
            ? 'Opened Zone ${i % 5 + 1}'
            : 'Changed AUTO threshold',
        'time': DateTime.now()
            .subtract(Duration(minutes: i * 13))
            .toIso8601String(),
      },
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Audit & Security')),
      body: ListView.separated(
        itemCount: logs.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (_, i) {
          final l = logs[i];
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(l['action'] as String),
            subtitle: Text('${l['actor']} • ${l['time']}'),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {},
            ),
          );
        },
      ),
    );
  }
}
