import 'dart:convert';

import 'package:MyBankMobile/AuthenticatedUser.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'register.dart';
import 'forgotpasword.dart';
import 'src/widgets.dart';
import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'User.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'fingerprintauth.dart';
import 'dashboard.dart';

class LoginPage extends StatelessWidget {
  static final _auth = LocalAuthentication();

  static Future<bool> hasBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      return false;
    }
  }

  static Future<List<BiometricType>> getBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      return <BiometricType>[];
    }
  }

  Future<void> _authenticateWithFingerprint(BuildContext context) async {
    final isAvailable = await hasBiometrics();

    if (!isAvailable) {
      return;
    }

    try {
      bool authenticated = await _auth.authenticate(
        localizedReason: 'Scan Fingerprint to Authenticate',
      );

      if (authenticated) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => DashboardPage()));
        Provider.of<ApplicationState>(context, listen: false).setloggenIn(true);
      }
    } on PlatformException catch (e) {
      print('Error: $e');
    }
  }

  Future<void> login(
      String username, String password, BuildContext context) async {
    final url = Uri.parse("http://192.168.1.20:8080/api/auth/signin");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );
    String responseBody = response.body;
    if (response.statusCode == 200) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('Backend Response'),
            content: Text(responseBody),
          );
        },
      );

      Map<String, dynamic> responseMap = json.decode(responseBody);

      AuthenticatedUser authenticatedUser =
          AuthenticatedUser.fromJson(responseMap);

      try {
        Get.to(DashboardPage(), arguments: authenticatedUser);
      } catch (e) {
        print('Navigation error: $e');
      }
    } else {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('Backend Response'),
            content: Text(
                'An error occurred. Status code: ${response.statusCode}. Message ${response.body}'),
          );
        },
      );
    }
  }

  TextEditingController usernameController = TextEditingController();
  TextEditingController pwdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: pwdController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password cannot be empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    String username = usernameController.text;
                    String password = pwdController.text;
                    login(username, password, context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(58, 71, 80, 1),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: Color(0xFFD3D6DB),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegisterPage()));
                  },
                  child: const Text(
                    "Don't have an account ? click here to create one",
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ForgotPasswordPage()));
                  },
                  child: const Text(
                    "Forgot password ?",
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                SizedBox(height: 150),
                ElevatedButton(
                  onPressed: () => _authenticateWithFingerprint(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 16),
                    backgroundColor: const Color.fromRGBO(58, 71, 80, 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fingerprint,
                        color: Color(0xFFD3D6DB),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Authenticate with Fingerprint',
                        style: TextStyle(
                          color: Color(0xFFD3D6DB),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  User parseUserDataFromResponse(String responseBody) {
    print("JSON Response: $responseBody");
    // Parse the JSON response and extract user data
    final Map<String, dynamic> responseData =
        json.decode(responseBody) as Map<String, dynamic>;

    //final userData = responseData['user'];
    final userId = responseData['id'];
    final firstName = responseData['firstName'];
    final lastName = responseData['lastName'];
    final email = responseData['email'];
    final mobile = responseData['mobile'];
    final cinNumber = responseData['cinNumber'];
    final address = responseData['address'];
    final job = responseData['job'];
    final dateOfBirth = responseData['dateOfBirth'];
    final gender = responseData['gender'];
    final status = responseData['status'];

    // Create a User instance
    User authenticatedUser = User(
      firstName,
      lastName,
      email,
      '', // Empty string for password
      mobile,
      cinNumber,
      address,
      job,
      dateOfBirth ?? '', // Handle missing keys gracefully
      gender ?? '', // Handle missing keys gracefully
      status ?? '', // Handle missing keys gracefully
    );

    return authenticatedUser;
  }
}
