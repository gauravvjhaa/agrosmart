import 'dart:ui';
import 'package:flutter/material.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String _language = 'English';
  String _role = 'Farmer';
  bool _showPassword = false;
  bool _agree = false;

  final _languages = const ['English', 'हिंदी', 'বাংলা', 'मराठी'];
  final _roles = const ['Farmer', 'Worker', 'Advisor', 'Admin'];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agree) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please accept the terms')));
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width < 600 ? double.infinity : 520.0;

    return Scaffold(
      body: Stack(
        children: [
          _gradientBackground(),
          Align(alignment: Alignment.topCenter, child: _decorativeHeader()),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: cardWidth,
                child: _glassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Hero(
                          tag: 'logo_signup',
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.white.withOpacity(.15),
                            child: const Icon(
                              Icons.agriculture,
                              size: 46,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Create Your AgroSmart Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fast onboarding • Multi-language • Role based',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(.75),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _sectionLabel('Personal'),
                        _gap(),
                        _fieldWrapper(
                          child: TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => v == null || v.trim().length < 2
                                ? 'Enter name'
                                : null,
                          ),
                        ),
                        _gap(),
                        _fieldWrapper(
                          child: TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (v) => v == null || v.trim().length < 6
                                ? 'Enter phone'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _sectionLabel('Preferences'),
                        _gap(),
                        _fieldWrapper(
                          child: DropdownButtonFormField<String>(
                            value: _language,
                            decoration: const InputDecoration(
                              labelText: 'Preferred Language',
                              prefixIcon: Icon(Icons.language),
                            ),
                            items: _languages
                                .map(
                                  (l) => DropdownMenuItem(
                                    value: l,
                                    child: Text(l),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _language = v!),
                          ),
                        ),
                        _gap(),
                        _fieldWrapper(
                          child: DropdownButtonFormField<String>(
                            value: _role,
                            decoration: const InputDecoration(
                              labelText: 'Primary Role',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            items: _roles
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(r),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => _role = v!),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _sectionLabel('Security'),
                        _gap(),
                        _fieldWrapper(
                          child: TextFormField(
                            controller: _password,
                            obscureText: !_showPassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                              ),
                            ),
                            validator: (v) => v == null || v.length < 4
                                ? 'Min 4 chars'
                                : null,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Checkbox(
                              value: _agree,
                              onChanged: (v) =>
                                  setState(() => _agree = v ?? false),
                              side: const BorderSide(color: Colors.white70),
                              activeColor: Colors.greenAccent,
                            ),
                            Expanded(
                              child: Text(
                                'I agree to the Terms & Privacy Policy',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Register'),
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Back to Login'),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientBackground() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xff0e8f52), Color(0xff1ea65d), Color(0xff6edc84)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  );

  Widget _decorativeHeader() => IgnorePointer(
    child: SizedBox(
      height: 180,
      width: double.infinity,
      child: CustomPaint(
        painter: _WavePainter(color: Colors.white.withOpacity(.08)),
      ),
    ),
  );

  Widget _glassCard({required Widget child}) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(.18)),
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(.22),
              Colors.white.withOpacity(.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.25),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
        child: child,
      ),
    ),
  );

  Widget _sectionLabel(String text) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        letterSpacing: .5,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );

  Widget _fieldWrapper({required Widget child}) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: Colors.white.withOpacity(.12),
      border: Border.all(color: Colors.white.withOpacity(.15)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          labelStyle: TextStyle(color: Colors.white70),
        ),
      ),
      child: child,
    ),
  );

  Widget _gap() => const SizedBox(height: 12);
}

class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()..moveTo(0, size.height * .55);
    p.quadraticBezierTo(
      size.width * .25,
      size.height * .40,
      size.width * .5,
      size.height * .55,
    );
    p.quadraticBezierTo(
      size.width * .75,
      size.height * .70,
      size.width,
      size.height * .55,
    );
    p.lineTo(size.width, 0);
    p.lineTo(0, 0);
    p.close();
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
