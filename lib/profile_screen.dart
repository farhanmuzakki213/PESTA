import 'package:flutter/material.dart';
import 'package:pesta/login_page.dart';
import 'package:pesta/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Memuat...';
  String _userEmail = 'Memuat...';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Nama Tidak Ditemukan';
      _userEmail = prefs.getString('userEmail') ?? 'Email Tidak Ditemukan';
    });
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if(mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          // Bagian Header Profil
          Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                // Gunakan huruf pertama dari nama untuk gambar dummy
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'A',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _userName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _userEmail,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Bagian Menu Pengaturan
          const Text('Pengaturan Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildProfileMenuItem(
                  context,
                  icon: Icons.person_outline,
                  text: "Edit Profil",
                  onTap: () { /* Navigasi ke halaman edit profil */ },
                ),
                _buildProfileMenuItem(
                  context,
                  icon: Icons.lock_outline,
                  text: "Ubah Password",
                  onTap: () { /* Navigasi ke halaman ubah password */ },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Bagian Menu Lainnya
          const Text('Lainnya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Card(
             elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildProfileMenuItem(
                  context,
                  icon: Icons.help_outline,
                  text: "Pusat Bantuan",
                  onTap: () {},
                ),
                _buildProfileMenuItem(
                  context,
                  icon: Icons.info_outline,
                  text: "Tentang Aplikasi",
                  onTap: () {},
                ),
                _buildProfileMenuItem(
                  context,
                  icon: Icons.logout,
                  text: "Logout",
                  textColor: Theme.of(context).colorScheme.error,
                  onTap: () => _logout(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget untuk membuat item menu
  Widget _buildProfileMenuItem(BuildContext context, {required IconData icon, required String text, required VoidCallback onTap, Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Theme.of(context).textTheme.bodyLarge?.color),
      title: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
      trailing: textColor == null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
      onTap: onTap,
    );
  }
}