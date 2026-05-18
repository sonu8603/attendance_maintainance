// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import '../../../route.dart';
// import 'waiting_aproval_screen.dart';
//
// class PhoneVerificationScreen extends StatefulWidget {
//   final String name;
//   final String lastName;
//   final String address;
//   final String requestedRole;
//   final String photoURL;
//   final String email;
//   final String uid;
//
//   const PhoneVerificationScreen({
//     super.key,
//     required this.name,
//     required this.lastName,
//     required this.address,
//     required this.requestedRole,
//     required this.photoURL,
//     required this.email,
//     required this.uid,
//   });
//
//   @override
//   State<PhoneVerificationScreen> createState() =>
//       _PhoneVerificationScreenState();
// }
//
// class _PhoneVerificationScreenState
//     extends State<PhoneVerificationScreen> {
//   final phoneController = TextEditingController();
//   final otpController = TextEditingController();
//
//   bool _otpSent = false;
//   bool _isLoading = false;
//   String? _verificationId;
//
//   // Step 1 — OTP bhejo
//   Future<void> _sendOtp() async {
//     final phone = phoneController.text.trim();
//     if (phone.length < 10) {
//       _showSnack('Valid phone number enter karo');
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     await FirebaseAuth.instance.verifyPhoneNumber(
//       phoneNumber: '+91$phone', // India code — change karo agar alag country
//       timeout: const Duration(seconds: 60),
//
//       // ✅ Auto-retrieved OTP (real device pe)
//       verificationCompleted: (PhoneAuthCredential credential) async {
//         await _saveAndNavigate(phone, credential);
//       },
//
//       // ❌ Verification fail hua
//       verificationFailed: (FirebaseAuthException e) {
//         setState(() => _isLoading = false);
//         _showSnack('OTP failed: ${e.message}');
//       },
//
//       // ✅ OTP SMS bheja gaya
//       codeSent: (String verificationId, int? resendToken) {
//         setState(() {
//           _verificationId = verificationId;
//           _otpSent = true;
//           _isLoading = false;
//         });
//         _showSnack('OTP sent successfully!');
//       },
//
//       codeAutoRetrievalTimeout: (String verificationId) {
//         _verificationId = verificationId;
//       },
//     );
//   }
//
//   // Step 2 — OTP verify karo aur save karo
//   Future<void> _verifyOtp() async {
//     if (_verificationId == null) return;
//     final otp = otpController.text.trim();
//     if (otp.length != 6) {
//       _showSnack('6 digit OTP enter karo');
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       final credential = PhoneAuthProvider.credential(
//         verificationId: _verificationId!,
//         smsCode: otp,
//       );
//       await _saveAndNavigate(phoneController.text.trim(), credential);
//     } catch (e) {
//       setState(() => _isLoading = false);
//       _showSnack('Galat OTP — dobara try karo');
//     }
//   }
//
//   // OTP verify hone ke baad Firestore mein save karo
//   Future<void> _saveAndNavigate(
//       String phone, PhoneAuthCredential credential) async {
//     try {
//       // Phone credential ko current Google user se link karo
//       final currentUser = FirebaseAuth.instance.currentUser!;
//       await currentUser.linkWithCredential(credential);
//     } on FirebaseAuthException catch (e) {
//       // Already linked hai to ignore karo
//       if (e.code != 'credential-already-in-use' &&
//           e.code != 'provider-already-linked') {
//         setState(() => _isLoading = false);
//         _showSnack('Error: ${e.message}');
//         return;
//       }
//     }
//
//     // Firestore mein save karo
//     try {
//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(widget.uid)
//           .set({
//         'uid': widget.uid,
//         'email': widget.email,
//         'name': '${widget.name} ${widget.lastName}'.trim(),
//         'firstName': widget.name,
//         'lastName': widget.lastName,
//         'phone': phone,
//         'phoneVerified': true,
//         'address': widget.address,
//         'requestedRole': widget.requestedRole,
//         'role': 'pending',
//         'status': 'pending',
//         'photoURL': widget.photoURL,
//         'createdAt': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//
//       if (!mounted) return;
//       NavigationHelper.pushReplace(
//           context, const WaitingApprovalScreen());
//     } catch (e) {
//       setState(() => _isLoading = false);
//       _showSnack('Save error: $e');
//     }
//   }
//
//   void _showSnack(String msg) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(SnackBar(content: Text(msg)));
//   }
//
//   @override
//   void dispose() {
//     phoneController.dispose();
//     otpController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade50,
//       appBar: AppBar(
//         title: const Text('Verify Phone Number'),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//
//             // Top icon
//             Center(
//               child: Container(
//                 padding: const EdgeInsets.all(24),
//                 decoration: BoxDecoration(
//                   color: Colors.deepOrange.shade50,
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.phone_android,
//                   size: 52,
//                   color: Colors.deepOrange,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 24),
//
//             Center(
//               child: Text(
//                 _otpSent
//                     ? 'OTP Enter Karo'
//                     : 'Phone Verify Karo',
//                 style: const TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 8),
//             Center(
//               child: Text(
//                 _otpSent
//                     ? 'SMS bheja gaya ${phoneController.text} pe'
//                     : 'Admin aur supervisor contact kar sakein isliye number verify karo',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 14,
//                   color: Colors.grey.shade600,
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 36),
//
//             // Phone number field
//             if (!_otpSent) ...[
//               // Country code + number
//               Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 14, vertical: 16),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: Colors.grey.shade400),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: const Text(
//                       '+91',
//                       style: TextStyle(
//                           fontSize: 16, fontWeight: FontWeight.w600),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: TextFormField(
//                       controller: phoneController,
//                       keyboardType: TextInputType.phone,
//                       maxLength: 10,
//                       decoration: InputDecoration(
//                         hintText: '10 digit number',
//                         labelText: 'Phone Number',
//                         counterText: '',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),
//
//               // Send OTP button
//               SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _sendOtp,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.deepOrange,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator(
//                       color: Colors.white, strokeWidth: 2)
//                       : const Text(
//                     'Send OTP',
//                     style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ),
//             ],
//
//             // OTP input field
//             if (_otpSent) ...[
//               // 6 boxes style OTP field
//               TextFormField(
//                 controller: otpController,
//                 keyboardType: TextInputType.number,
//                 maxLength: 6,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 12,
//                 ),
//                 decoration: InputDecoration(
//                   hintText: '------',
//                   hintStyle: TextStyle(
//                     letterSpacing: 12,
//                     color: Colors.grey.shade300,
//                     fontSize: 28,
//                   ),
//                   counterText: '',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 24),
//
//               // Verify button
//               SizedBox(
//                 width: double.infinity,
//                 height: 54,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _verifyOtp,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: _isLoading
//                       ? const CircularProgressIndicator(
//                       color: Colors.white, strokeWidth: 2)
//                       : const Text(
//                     'Verify & Continue',
//                     style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 16),
//
//               // Resend OTP
//               Center(
//                 child: TextButton(
//                   onPressed: _isLoading
//                       ? null
//                       : () {
//                     setState(() {
//                       _otpSent = false;
//                       otpController.clear();
//                     });
//                   },
//                   child: const Text(
//                     'Wrong number? Change karo',
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 ),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }