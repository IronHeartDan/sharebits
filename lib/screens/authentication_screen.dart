import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sharebits/screens/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        child: Container(
          margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          padding: EdgeInsets.all(20.w),
          child: Column(
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.phone),
                    label: Text("Enter Phone"),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(50)))),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please Enter Number";
                  }
                  if (value.length != 10) {
                    return "Invalid Phone";
                  }
                  return null;
                },
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      logIn();
                    }
                  },
                  child: const Text("LogIn"))
            ],
          ),
        ),
      ),
    );
  }

  Future logIn() async {
    var phone = "+91${_phoneController.text}";
    var auth = FirebaseAuth.instance;

    await auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (phoneAuthCredential) async {
          await auth.signInWithCredential(phoneAuthCredential);
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false);
        },
        verificationFailed: (e) {},
        codeSent: (id, code) async {
          var _codeController = TextEditingController();
          var _codeForm = GlobalKey<FormState>();
          bool invalidCode = false;
          await showDialog(
              context: context,
              builder: (context) {
                return WillPopScope(
                  onWillPop: () async {
                    return false;
                  },
                  child: StatefulBuilder(builder: (context, setAlertBoxState) {
                    return AlertDialog(
                      title: const Text("Enter OTP"),
                      content: Form(
                        key: _codeForm,
                        child: TextFormField(
                          controller: _codeController,
                          maxLength: 6,
                          decoration: InputDecoration(
                              errorText: invalidCode ? "Invalid OTP" : null,
                              label: const Text("OTP"),
                              border: const OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)))),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.length < 6) {
                              return "Please Enter Verification Code Of Length 6";
                            }

                            return null;
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () async {
                              if (_codeForm.currentState!.validate()) {
                                setAlertBoxState(() {
                                  invalidCode = false;
                                });

                                var phoneAuthCredential =
                                    PhoneAuthProvider.credential(
                                        verificationId: id,
                                        smsCode: _codeController.text);
                                try {
                                  await auth.signInWithCredential(
                                      phoneAuthCredential);
                                } on FirebaseAuthException {
                                  setAlertBoxState(() {
                                    invalidCode = true;
                                  });
                                }

                                Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const HomeScreen()),
                                    (route) => false);
                              }
                            },
                            child: const Text("Verify"))
                      ],
                    );
                  }),
                );
              },
              barrierDismissible: false);
        },
        codeAutoRetrievalTimeout: (codeAutoRetrievalTimeout) {});
  }
}
