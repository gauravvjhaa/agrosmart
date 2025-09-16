import 'package:flutter/material.dart';

class AuditLogEntryWidget extends StatelessWidget {
  final String actor;
  final String action;
  final DateTime ts;
  const AuditLogEntryWidget({
    super.key,
    required this.actor,
    required this.action,
    required this.ts,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.history),
      title: Text(action),
      subtitle: Text('$actor • ${ts.toIso8601String()}'),
    );
  }
}
