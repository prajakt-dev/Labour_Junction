import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/home.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController phoneController = TextEditingController();
  List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );

  String verificationId = "";
  bool otpSent = false;
  bool isLoading = false;
  String? phoneNumber;
  Timer? _timer;
  int _start = 59;
  bool _isResendVisible = false;

  void startTimer() {
    _start = 59;
    _isResendVisible = false;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      if (_start == 0) {
        setState(() {
          _isResendVisible = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  Future<void> fetchPhoneNumber() async {
    setState(() => isLoading = true);
    String phone = phoneController.text.trim();

    try {
      QuerySnapshot snapshot =
          await _firestore
              .collection('users')
              .where('phone', isEqualTo: phone)
              .get();

      if (snapshot.docs.isNotEmpty) {
        phoneNumber = snapshot.docs.first['phone'];
        sendOTP();
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No user found with this phone number!")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching data, try again.")),
      );
    }
  }

  void sendOTP() async {
    if (phoneNumber == null) return;
    setState(() => isLoading = true);
    String formattedPhone =
        phoneNumber!.startsWith("+91") ? phoneNumber! : "+91$phoneNumber";

    await _auth.verifyPhoneNumber(
      phoneNumber: formattedPhone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        navigateToHome();
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification Failed: ${e.message}")),
        );
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          verificationId = verId;
          otpSent = true;
          isLoading = false;
        });
        startTimer();
      },
      codeAutoRetrievalTimeout: (String verId) {
        setState(() => verificationId = verId);
      },
      timeout: Duration(seconds: 60),
    );
  }

  void verifyOTP() async {
    setState(() => isLoading = true);
    String otpCode = otpControllers.map((e) => e.text).join();

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );
      await _auth.signInWithCredential(credential);
      navigateToHome();
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Invalid OTP! Try again.")));
    }
  }

  void navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: otpSent ? buildOtpScreen() : buildPhoneScreen(),
        ),
      ),
    );
  }

  Widget buildPhoneScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Forgot Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.teal, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            cursorColor: Colors.teal,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: InputBorder.none,
              hintText: "Enter your phone number",
              hintStyle: TextStyle(color: Colors.teal.shade300),
            ),
          ),
        ),
        SizedBox(height: 20),
        isLoading
            ? CircularProgressIndicator(color: Colors.teal)
            : ElevatedButton(
              onPressed: fetchPhoneNumber,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Get OTP",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
      ],
    );
  }

  Widget buildOtpScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Enter OTP',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            return Container(
              width: 45,
              margin: EdgeInsets.symmetric(horizontal: 5),
              child: TextField(
                controller: otpControllers[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                cursorColor: Colors.teal,
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    FocusScope.of(context).nextFocus();
                  }
                },
                decoration: InputDecoration(
                  counterText: "",
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.teal, width: 2),
                  ),
                ),
              ),
            );
          }),
        ),
        SizedBox(height: 16),
        GestureDetector(
          onTap: _isResendVisible ? sendOTP : null,
          child: Text(
            _isResendVisible
                ? "Resend Code"
                : "00:${_start.toString().padLeft(2, '0')} sec",
            style: TextStyle(
              color: _isResendVisible ? Colors.teal : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 20),
        isLoading
            ? CircularProgressIndicator(color: Colors.teal)
            : ElevatedButton(
              onPressed: verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Verify OTP",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
      ],
    );
  }
}
