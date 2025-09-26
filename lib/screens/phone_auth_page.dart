// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../auth/phone_auth_service.dart';

// class PhoneAuthPage extends StatefulWidget {
//   const PhoneAuthPage({super.key});

//   @override
//   State<PhoneAuthPage> createState() => _PhoneAuthPageState();
// }

// class _PhoneAuthPageState extends State<PhoneAuthPage> {
//   final _phoneCtrl = TextEditingController();
//   final _otpCtrl = TextEditingController();
//   final _service = PhoneAuthService();

//   String? _verificationId;
//   bool _sending = false;
//   bool _verifying = false;

//   @override
//   void dispose() {
//     _phoneCtrl.dispose();
//     _otpCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _sendOtp({bool resend = false}) async {
//     final phone = _phoneCtrl.text.trim();
//     if (phone.isEmpty) return;
//     setState(() => _sending = true);

//     await _service.start(
//       phoneNumber: phone,
//       onAutoVerified: (cred) async {
//         try {
//           await _service.signInWithCredential(cred);
//           if (mounted) Navigator.of(context).pop(true);
//         } catch (e) {
//           if (!mounted) return;
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(const SnackBar(content: Text('Auto sign-in failed')));
//         }
//       },
//       onCodeSent: (vid) {
//         setState(() {
//           _verificationId = vid;
//           _sending = false;
//         });
//       },
//       onFailed: (e) {
//         setState(() => _sending = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.message ?? 'Verification failed')),
//         );
//       },
//     );
//   }

//   Future<void> _verifyOtp() async {
//     final code = _otpCtrl.text.trim();
//     final vid = _verificationId;
//     if (vid == null || code.isEmpty) return;

//     setState(() => _verifying = true);
//     try {
//       await _service.signInWithSmsCode(verificationId: vid, smsCode: code);
//       if (mounted) Navigator.of(context).pop(true);
//     } on FirebaseAuthException catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(e.message ?? 'Invalid code')));
//     } finally {
//       if (mounted) setState(() => _verifying = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final hasSent = _verificationId != null;

//     return Scaffold(
//       appBar: AppBar(title: const Text('Phone Login')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             if (!hasSent) ...[
//               TextField(
//                 controller: _phoneCtrl,
//                 keyboardType: TextInputType.phone,
//                 decoration: const InputDecoration(
//                   labelText: 'Phone number (+91...)',
//                 ),
//               ),
//               const SizedBox(height: 12),
//               ElevatedButton(
//                 onPressed: _sending ? null : _sendOtp,
//                 child: _sending
//                     ? const SizedBox(
//                         width: 18,
//                         height: 18,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : const Text('Send OTP'),
//               ),
//             ] else ...[
//               TextField(
//                 controller: _otpCtrl,
//                 keyboardType: TextInputType.number,
//                 decoration: const InputDecoration(labelText: 'Enter OTP'),
//               ),
//               const SizedBox(height: 12),
//               ElevatedButton(
//                 onPressed: _verifying ? null : _verifyOtp,
//                 child: _verifying
//                     ? const SizedBox(
//                         width: 18,
//                         height: 18,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : const Text('Verify'),
//               ),
//               TextButton(
//                 onPressed: _sending ? null : _sendOtp,
//                 child: _sending
//                     ? const Text('Resending...')
//                     : const Text('Resend OTP'),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
