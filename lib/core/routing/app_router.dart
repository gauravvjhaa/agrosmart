import 'package:flutter/material.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/irrigation/presentation/irrigation_screen.dart'
    hide Zone;
import '../../features/crops/presentation/crop_calendar_screen.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/admin/presentation/admin_audit_screen.dart';
import '../../features/zones/presentation/zone_list_screen.dart';
import '../../features/zones/presentation/zone_detail_screen.dart';
import '../../features/automation/presentation/automation_policy_screen.dart';
import '../../features/onboarding/presentation/tutorial_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/support/presentation/remote_support_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../models/zone.dart'; // Added for type check

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/zones':
        return _page(const ZoneListScreen());
      case '/zone/detail':
        final arg = settings.arguments;
        if (arg is Zone) {
          return _page(ZoneDetailScreen(zone: arg));
        } else {
          return _errorPage('Invalid or missing Zone argument');
        }
      case '/irrigation':
        return _page(const IrrigationScreen());
      case '/crops':
        return _page(const CropCalendarScreen());
      case '/automation':
        return _page(const AutomationPolicyScreen());
      case '/community':
        return _page(const CommunityScreen());
      case '/admin/audit':
        return _page(const AdminAuditScreen());
      case '/tutorial':
        return _page(const TutorialScreen());
      case '/settings':
        return _page(const SettingsScreen());
      case '/support':
        return _page(const RemoteSupportScreen());
      case '/signup':
        return _page(const SignUpScreen());
      case '/':
      default:
        return _page(const DashboardScreen());
    }
  }

  static MaterialPageRoute _page(Widget child) =>
      MaterialPageRoute(builder: (_) => child);

  static MaterialPageRoute _errorPage(String message) => MaterialPageRoute(
    builder: (_) => Scaffold(
      appBar: AppBar(title: const Text('Routing Error')),
      body: Center(
        child: Text(message, style: const TextStyle(color: Colors.red)),
      ),
    ),
  );
}
