import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as myHttp;
import 'package:presensi/home-page.dart';
import 'package:presensi/models/login-response.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  late Future<String> _name, _token;

  // Warna aksen (menggunakan warna yang sudah dipakai di tombol kamu)
  static const Color kPrimary = Color.fromARGB(255, 135, 89, 164);
  static const Color kSurface = Color(0xFFF7F8FA);

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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  checkToken(token, name) async {
    String tokenStr = await token;
    String nameStr = await name;
    if (tokenStr != "" && nameStr != "") {
      Future.delayed(const Duration(seconds: 1), () async {
        if (!mounted) return;
        Navigator.of(context)
            .push(MaterialPageRoute(builder: (context) => const HomePage()))
            .then((value) => setState(() {}));
      });
    }
  }

  Future login(String email, String password) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      LoginResponseModel? loginResponseModel;
      final Map<String, String> body = {"email": email, "password": password};

      final response = await myHttp.post(
        Uri.parse('http://10.0.2.2:8000/api/login'),
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email atau password salah")),
        );
      } else if (response.statusCode >= 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal masuk (${response.statusCode})")),
        );
      } else {
        loginResponseModel = LoginResponseModel.fromJson(
          jsonDecode(response.body),
        );
        await saveUser(
          loginResponseModel.data.token,
          loginResponseModel.data.name,
        );
      }
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan jaringan: $err")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future saveUser(String token, String name) async {
    try {
      final SharedPreferences pref = await _prefs;
      await pref.setString("name", name);
      await pref.setString("token", token);

      if (!mounted) return;
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const HomePage()))
          .then((value) => setState(() {}));
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err.toString())));
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: kPrimary, width: 1.2),
        borderRadius: BorderRadius.circular(14),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            _emailFocus.unfocus();
            _passwordFocus.unfocus();
          },
          child: LayoutBuilder(
            builder: (_, constraints) {
              final bool isWide = constraints.maxWidth > 520;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        // minimal 90% layar kecil, tapi maksimal 520 di layar lebar
                        maxWidth:
                            MediaQuery.of(context).size.width < 600
                                ? MediaQuery.of(context).size.width * 0.9
                                : 520,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            offset: const Offset(0, 8),
                            blurRadius: 24,
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header dengan gradient & icon
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [kPrimary, Color(0xFF9E6CC8)],
                              ),
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.badge_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Masuk Akun',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Silakan masuk untuk melanjutkan absensi.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Form
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              isWide ? 40 : 24,
                              24,
                              isWide ? 40 : 24,
                              24,
                            ),
                            child: Form(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: emailController,
                                    focusNode: _emailFocus,
                                    keyboardType:
                                        TextInputType
                                            .text, // ← bukan email keyboard
                                    textInputAction: TextInputAction.next,
                                    textCapitalization: TextCapitalization.none,
                                    enableSuggestions:
                                        false, // ← matikan suggestion bar
                                    autocorrect: false, // ← matikan autocorrect
                                    autofillHints:
                                        const <String>[], // ← disable autofill
                                    inputFormatters: [
                                      FilteringTextInputFormatter.deny(
                                        RegExp(r'\s'),
                                      ), // blok spasi
                                    ],
                                    decoration: _inputDecoration(
                                      hint: 'Masukkan email',
                                      icon: Icons.email_rounded,
                                    ),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty)
                                        return 'Email tidak boleh kosong';
                                      final emailReg = RegExp(
                                        r'^[^@]+@[^@]+\.[^@]+',
                                      );
                                      if (!emailReg.hasMatch(val.trim()))
                                        return 'Format email tidak valid';
                                      return null;
                                    },
                                    onFieldSubmitted:
                                        (_) => _passwordFocus.requestFocus(),
                                  ),

                                  const SizedBox(height: 16),

                                  Text(
                                    'Password',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: passwordController,
                                    focusNode: _passwordFocus,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    decoration: _inputDecoration(
                                      hint: 'Masukkan password',
                                      icon: Icons.lock_rounded,
                                      suffix: IconButton(
                                        tooltip:
                                            _obscurePassword
                                                ? 'Tampilkan'
                                                : 'Sembunyikan',
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                        ),
                                        onPressed: () {
                                          setState(
                                            () =>
                                                _obscurePassword =
                                                    !_obscurePassword,
                                          );
                                        },
                                      ),
                                    ),
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Password tidak boleh kosong';
                                      }
                                      if (val.length < 6) {
                                        return 'Minimal 6 karakter';
                                      }
                                      return null;
                                    },
                                    onFieldSubmitted: (_) => _submit(),
                                  ),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        // TODO: route lupa password (optional)
                                      },
                                      child: const Text(
                                        'Lupa Password?',
                                        style: TextStyle(color: kPrimary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Tombol Login
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: kPrimary,
                                        disabledBackgroundColor: kPrimary
                                            .withOpacity(0.6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      child:
                                          _isLoading
                                              ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                              : const Text(
                                                'Masuk',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('Belum punya akun? '),
                                      GestureDetector(
                                        onTap: () {
                                          // TODO: navigasi ke halaman Sign Up (jika ada)
                                        },
                                        child: const Text(
                                          'Daftar',
                                          style: TextStyle(
                                            color: kPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa kembali form kamu')),
      );
      return;
    }
    login(emailController.text.trim(), passwordController.text);
  }
}
