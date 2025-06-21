import 'package:flutter/material.dart';
import 'package:pesta/main_screen.dart';
import 'package:pesta/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {  
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email dan Password tidak boleh kosong!')));
        return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.login(_emailController.text, _passwordController.text);
      
      final token = response['meta']['token'];
      final userName = response['data']['name'];
      final userEmail = response['data']['email'];

      if (token != null && userName != null && userEmail != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('userName', userName);
        await prefs.setString('userEmail', userEmail);
        
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
      } else { throw Exception('Data user tidak lengkap di dalam respons.'); }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login Gagal: ${e.toString()}')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Center(child: Icon(Icons.school, size: 60, color: Theme.of(context).colorScheme.primary)),
              const SizedBox(height: 20),
              const Center(child: Text('Selamat Datang Kembali', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
              const SizedBox(height: 8),
              const Center(child: Text('Masuk untuk mengelola jadwal sidang', style: TextStyle(fontSize: 16, color: Colors.grey))),
              const SizedBox(height: 40),
              const Text('Email / NIDN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(controller: _emailController, decoration: const InputDecoration(hintText: 'Masukkan email atau NIDN Anda', prefixIcon: Icon(Icons.person_outline)), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              const Text('Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(hintText: 'Masukkan password Anda', prefixIcon: Icon(Icons.lock_outline), suffixIcon: Icon(Icons.visibility_off_outlined))),
              const SizedBox(height: 16),
              Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Lupa password?'))),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}