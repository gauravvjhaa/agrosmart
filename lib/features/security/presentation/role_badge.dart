import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/services/auth_service.dart';

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = ServiceLocator.get<AuthService>();
    return Chip(
      label: Text(auth.currentRole.name.toUpperCase()),
      backgroundColor: Colors.teal.shade100,
    );
  }
}
