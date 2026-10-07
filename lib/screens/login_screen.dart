import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  // Admin credentials
  static const String _adminEmail = 'cricket.mania78362@gmail.com';
  static const String _adminPin = '1996';
  static const String _adminPassword = '19961996';

  Future<void> _login() async {
    final enteredPin = _codeCtrl.text.trim();

    // Quick PIN check
    if (enteredPin != _adminPin) {
      _showError('Ghalat code!');
      return;
    }

    setState(() => _loading = true);

    try {
      // Firebase Auth sign-in
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _adminEmail,
        password: _adminPassword,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';
      if (e.code == 'user-not-found') {
        message = 'Admin account not found';
      } else if (e.code == 'wrong-password') {
        message = 'Invalid credentials';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format';
      } else {
        message = e.message ?? 'Login failed';
      }
      _showError(message);
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sports_cricket, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'CRIC MANIA ADMIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                obscureText: true,
                textAlign: TextAlign.center,
                enabled: !_loading,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  hintText: '****',
                  hintStyle: const TextStyle(
                    color: Colors.white38,
                    letterSpacing: 8,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white54),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF0A1931),
                          ),
                        )
                      : const Text(
                          'LOGIN',
                          style: TextStyle(
                            color: Color(0xFF0A1931),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}