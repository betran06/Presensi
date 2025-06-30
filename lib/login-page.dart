import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as myHttp;
import 'package:presensi/home-page.dart';
import 'package:presensi/models/login-response.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  late Future<String> _name, _token;

  @override
  void initState() {
    super.initState();
    _token = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("token") ?? "";
    });

    _name = _prefs.then((SharedPreferences prefs) {
      return prefs.getString("name") ?? "";
    });

    checkToken(_token, _name);
  }

  checkToken(token, name) async {
    String tokenStr = await token;
    String nameStr = await name;
    if (tokenStr != "" && nameStr != "") {
      Future.delayed(Duration(seconds: 1), () async {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => HomePage()),
        ).then((value) {
          setState(() {});
        });
      });
    }
  }

  Future login(email, password) async {
    LoginResponseModel? loginResponseModel;
    Map<String, String> body = {"email": email, "password": password};

    var response = await myHttp.post(
      Uri.parse('http://10.0.2.2:8000/api/login'),
      body: body,
    );

    if (response.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Email atau password salah")),
      );
    } else {
      loginResponseModel = LoginResponseModel.fromJson(
        jsonDecode(response.body),
      );
      saveUser(loginResponseModel.data.token, loginResponseModel.data.name);
    }
  }

  Future saveUser(token, name) async {
    try {
      final SharedPreferences pref = await _prefs;
      pref.setString("name", name);
      pref.setString("token", token);

      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => HomePage()),
      ).then((value) {
        setState(() {});
      });
    } catch (err) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Sign in to your\nAccount',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your email and password to log in',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Email',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Masukan Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Password',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Masukan Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Tambahkan aksi lupa password di sini
                    },
                    child: const Text(
                      'Forgot Password ?',
                      style: TextStyle(color:  const Color.fromARGB(255, 135, 89, 164),),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      login(emailController.text, passwordController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:  const Color.fromARGB(255, 135, 89, 164),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    GestureDetector(
                      onTap: () {
                        // Tambahkan navigasi ke halaman Sign Up
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color:  const Color.fromARGB(255, 135, 89, 164),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
