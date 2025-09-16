import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/state/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _controller = TextEditingController(text: '');
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (_, c) {
          final wide = c.maxWidth > 800;
          final form = _formCard(context);
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xff0f9d58),
                  Color(0xff3fa46d),
                  Color(0xff9bd57a),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: wide ? 500 : double.infinity,
                padding: EdgeInsets.symmetric(horizontal: wide ? 0 : 24),
                child: form,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _formCard(BuildContext context) {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AgroSmart',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Username / Phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Login'),
              onPressed: () {
                ServiceLocator.get<AppState>().login(_controller.text);
              },
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/signup'),
              child: const Text('Create Account'),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/tutorial'),
              child: const Text('View Tutorial'),
            ),
          ],
        ),
      ),
    );
  }
}
