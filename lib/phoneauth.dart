// lib/PhoneAuth.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuth extends StatefulWidget {
  @override
  _PhoneAuthState createState() => _PhoneAuthState();
}

class _PhoneAuthState extends State<PhoneAuth> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isOtpSent = false;
  late String _verificationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phone Auth'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneNumberController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            _isOtpSent
                ? TextField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
              ),
            )
                : SizedBox(),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isOtpSent
                  ? () async {
                final otp = _otpController.text.trim();
                try {
                  await _auth.signInWithCredential(
                    PhoneAuthProvider.credential(
                      verificationId: _verificationId,
                      smsCode: otp,
                    ),
                  );
                  print('Signed in successfully!');
                } catch (e) {
                  print('Error: $e');
                }
              }
                  : () async {
                final phoneNumber = _phoneNumberController.text.trim();
                try {
                  await _auth.verifyPhoneNumber(
                    phoneNumber: phoneNumber,
                    verificationCompleted: (credential) async {
                      await _auth.signInWithCredential(credential);
                      print('Signed in successfully!');
                    },
                    verificationFailed: (e) {
                      print('Error: $e');
                    },
                    codeSent: (verificationId, resendToken) {
                      setState(() {
                        _isOtpSent = true;
                        _verificationId = verificationId;
                      });
                    },
                    codeAutoRetrievalTimeout: (verificationId) {
                      setState(() {
                        _isOtpSent = false;
                      });
                    },
                  );
                } catch (e) {
                  print('Error: $e');
                }
              },
              child: Text(_isOtpSent ? 'Verify OTP' : 'Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}ad