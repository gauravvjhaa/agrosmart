import 'dart:ui';
import 'package:agrismart/features/dashboard/presentation/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  String _langCode = 'en';
  bool _isSigningInWithGoogle = false;

  // Google Sign-in instance
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  final Map<String, String> _codeToLabel = const {
    'en': 'English',
    'hi': 'Hindi',
    'ne': 'Nepali',
  };

  final Map<String, Map<String, String>> _i18n = const {
    'en': {
      'title': 'Welcome to AgroSmart',
      'subtitle': 'Log in to continue',
      'phone_number': 'Phone Number',
      'app_language': 'App Language',
      'phone_verification': 'Phone Verification',
      'send_otp': 'Send OTP',
      'sending_otp': 'Sending OTP...',
      'enter_otp': 'Enter OTP',
      'verify_login': 'Verify & Log In',
      'verifying': 'Verifying...',
      'resend_otp': 'Resend OTP',
      'resending': 'Resending...',
      'create_account': 'Create New Account',
      'or': 'OR',
      'google_login': 'Log in with Google',
      'google_signing': 'Signing in...',
      'no_account': 'Account not found. Please sign up first.',
      'otp_help': 'We will send a 6-digit code to your phone.',
    },
    'hi': {
      'title': 'एग्रोस्मार्ट में आपका स्वागत है',
      'subtitle': 'जारी रखने के लिए लॉग इन करें',
      'phone_number': 'फ़ोन नंबर',
      'app_language': 'ऐप भाषा',
      'phone_verification': 'फोन सत्यापन',
      'send_otp': 'OTP भेजें',
      'sending_otp': 'OTP भेजा जा रहा है...',
      'enter_otp': 'OTP दर्ज करें',
      'verify_login': 'सत्यापित करें और लॉग इन करें',
      'verifying': 'सत्यापित किया जा रहा है...',
      'resend_otp': 'OTP पुनः भेजें',
      'resending': 'पुनः भेजा जा रहा है...',
      'create_account': 'नया खाता बनाएं',
      'or': 'या',
      'google_login': 'गूगल से लॉग इन करें',
      'google_signing': 'साइन इन हो रहा है...',
      'no_account': 'खाता नहीं मिला। कृपया पहले साइन अप करें।',
      'otp_help': 'हम आपके फोन पर 6 अंकों का कोड भेजेंगे।',
    },
    'ne': {
      'title': 'एग्रोस्मार्ट मा स्वागत छ',
      'subtitle': 'जारी राख्न लग इन गर्नुहोस्',
      'phone_number': 'फोन नम्बर',
      'app_language': 'एप भाषा',
      'phone_verification': 'फोन प्रमाणीकरण',
      'send_otp': 'OTP पठाउनुहोस्',
      'sending_otp': 'OTP पठाइँदै...',
      'enter_otp': 'OTP प्रविष्ट गर्नुहोस्',
      'verify_login': 'प्रमाणित गरेर लग इन गर्नुहोस्',
      'verifying': 'प्रमाणित हुँदै...',
      'resend_otp': 'OTP पुन: पठाउनुहोस्',
      'resending': 'पुन: पठाइँदै...',
      'create_account': 'नयाँ खाता बनाउनुहोस्',
      'or': 'वा',
      'google_login': 'गूगल बाट लग इन गर्नुहोस्',
      'google_signing': 'साइन इन हुँदैछ...',
      'no_account': 'खाता भेटिएन। कृपया पहिले साइनअप गर्नुहोस्।',
      'otp_help': 'हामी तपाईंको फोनमा ६ अंकको कोड पठाउँछौं।',
    },
  };

  String _t(String key) => _i18n[_langCode]?[key] ?? key;

  // OTP + Firebase Auth
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _otp = TextEditingController();
  String? _verificationId;
  int? _resendToken;
  bool _sendingOtp = false;
  bool _verifying = false;

  @override
  void dispose() {
    _phone.dispose();
    _otp.dispose();
    super.dispose();
  }

  String _normalizePhone(String raw) {
    final p = raw.trim();
    if (p.isEmpty) return '';
    return p.startsWith('+') ? p : '+91$p';
  }

  // Check if user account exists in Firebase
  Future<bool> _checkAccountExists(String uid) async {
    final db = FirebaseDatabase.instance;
    final farmerRef = db.ref('farmers/$uid');
    final snapshot = await farmerRef.get();
    return snapshot.exists;
  }

  // Update last login timestamp
  Future<void> _updateLastLogin(String uid) async {
    final db = FirebaseDatabase.instance;
    final farmerRef = db.ref('farmers/$uid');
    await farmerRef.child('data').update({'lastLogin': ServerValue.timestamp});
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isSigningInWithGoogle = true);

    try {
      // Initialize GoogleSignIn
      await GoogleSignIn.instance.initialize();

      // Start the sign-in flow
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Check if account exists
        final accountExists = await _checkAccountExists(user.uid);
        if (!accountExists) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_t('no_account'))));
          setState(() => _isSigningInWithGoogle = false);
          return;
        }

        // Update last login
        await _updateLastLogin(user.uid);

        if (!mounted) return;

        // ✅ Navigate to DashboardScreen and remove LoginScreen from stack
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign in failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningInWithGoogle = false);
    }
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _normalizePhone(_phone.text);
    if (phone.isEmpty) return;
    setState(() => _sendingOtp = true);

    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (cred) async {
        try {
          final userCredential = await _auth.signInWithCredential(cred);
          final user = userCredential.user;

          if (user != null) {
            // Check if account exists
            final accountExists = await _checkAccountExists(user.uid);
            if (!accountExists) {
              if (!mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(_t('no_account'))));
              setState(() => _sendingOtp = false);
              return;
            }

            await _updateLastLogin(user.uid);
            if (!mounted) return;
            Navigator.pop(context, true);
          }
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_t('enter_otp'))));
        }
      },
      verificationFailed: (e) {
        setState(() => _sendingOtp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Verification failed')),
        );
      },
      codeSent: (verificationId, resendToken) {
        setState(() {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _sendingOtp = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_t('send_otp'))));
      },
      codeAutoRetrievalTimeout: (verificationId) {
        setState(() => _verificationId = verificationId);
      },
    );
  }

  Future<void> _verifyOtp() async {
    final vid = _verificationId;
    final code = _otp.text.trim();
    if (vid == null || code.isEmpty) return;

    setState(() => _verifying = true);
    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: vid,
        smsCode: code,
      );
      final userCredential = await _auth.signInWithCredential(cred);
      final user = userCredential.user;

      if (user != null) {
        // Check if account exists
        final accountExists = await _checkAccountExists(user.uid);
        if (!accountExists) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_t('no_account'))));
          setState(() => _verifying = false);
          return;
        }

        await _updateLastLogin(user.uid);
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Invalid OTP')));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width < 600 ? double.infinity : 520.0;

    return Scaffold(
      body: Stack(
        children: [
          _gradientBackground(),
          // Language chooser at top-right
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.25),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: PopupMenuButton<String>(
                    tooltip: 'Language',
                    initialValue: _langCode,
                    onSelected: (code) {
                      setState(() => _langCode = code);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'en', child: Text('English')),
                      PopupMenuItem(value: 'hi', child: Text('हिंदी')),
                      PopupMenuItem(value: 'ne', child: Text('नेपाली')),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.language, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            _codeToLabel[_langCode]!,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
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
                          tag: 'logo_login',
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(.15),
                            child: Icon(
                              Icons.agriculture,
                              size: 46,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _t('title'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _t('subtitle'),
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 24),

                        // Google sign-in button
                        ElevatedButton.icon(
                          onPressed: _isSigningInWithGoogle
                              ? null
                              : _signInWithGoogle,
                          icon: Image.asset(
                            'assets/google_logo.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.g_mobiledata),
                          ),
                          label: Text(
                            _isSigningInWithGoogle
                                ? _t('google_signing')
                                : _t('google_login'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  _t('or'),
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ),
                              Expanded(
                                child: Divider(color: Colors.grey.shade300),
                              ),
                            ],
                          ),
                        ),

                        // Phone field
                        _fieldWrapper(
                          child: TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: _t('phone_number'),
                              prefixIcon: const Icon(Icons.phone_outlined),
                            ),
                            validator: (v) =>
                                v == null || v.trim().length < 6 ? ' ' : null,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Phone verification section
                        Text(
                          _t('phone_verification'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _t('otp_help'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // OTP verification UI
                        if (_verificationId == null) ...[
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.sms),
                              label: Text(
                                _sendingOtp
                                    ? _t('sending_otp')
                                    : _t('send_otp'),
                              ),
                              onPressed: _sendingOtp ? null : _sendOtp,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          _fieldWrapper(
                            child: TextFormField(
                              controller: _otp,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: _t('enter_otp'),
                                prefixIcon: const Icon(Icons.pin),
                              ),
                              validator: (v) =>
                                  (v == null || v.length < 4) ? ' ' : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.verified),
                                  label: Text(
                                    _verifying
                                        ? _t('verifying')
                                        : _t('verify_login'),
                                  ),
                                  onPressed: _verifying ? null : _verifyOtp,
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _sendingOtp ? null : _sendOtp,
                                child: Text(
                                  _sendingOtp
                                      ? _t('resending')
                                      : _t('resend_otp'),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Create account link
                        TextButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/signup'),
                          child: Text(_t('create_account')),
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

  // White glass card
  Widget _glassCard({required Widget child}) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
        child: child,
      ),
    ),
  );

  Widget _fieldWrapper({required Widget child}) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: Colors.grey.shade100,
      border: Border.all(color: Colors.grey.shade300),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: child,
  );
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
