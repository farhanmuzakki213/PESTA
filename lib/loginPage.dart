import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'homePage.dart'; // Pastikan path benar

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Fungsi untuk mendapatkan base URL secara dinamis
  String getBaseUrl() {
    if (kIsWeb) return 'http://localhost:8000';
    return 'http://10.0.3.2:8000'; // Emulator Android
  }

  Future<void> _login() async {
    final String apiUrl = '${getBaseUrl()}/api/mobile/login';

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      );

      if (!mounted) return;

      // Handle error status code
      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        throw Exception('Login gagal: ${errorData['message']}');
      }

      final responseData = json.decode(response.body);

      // Parsing data sesuai struktur respons
      final token = responseData['meta']['token'];
      final userId = responseData['data']['id'];

      // Simpan token dan userId
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setInt('userId', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Login berhasil! Selamat datang ${responseData['data']['name']}')),
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (BuildContext context) => const HomePage(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}
