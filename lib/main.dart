import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pesta/login_page.dart';
import 'package:pesta/main_screen.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const JadwalSidangApp());
}

class JadwalSidangApp extends StatefulWidget {
  const JadwalSidangApp({super.key});

  @override
  State<JadwalSidangApp> createState() => _JadwalSidangAppState();
}

class _JadwalSidangAppState extends State<JadwalSidangApp> {
  // Pastikan tipe Future ini adalah Map<String, String?>
  late final Future<Map<String, String?>> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initializeApp();
  }
  
  // Pastikan fungsi ini mengembalikan Future dengan tipe Map<String, String?>
  Future<Map<String, String?>> _initializeApp() async {
    await initializeDateFormatting('id_ID', null);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? userName = prefs.getString('userName');
    
    // Kembalikan data sebagai Map agar sesuai dengan tipe Future
    return {'token': token, 'userName': userName};
  }

  @override
  Widget build(BuildContext context) {
    // Pastikan FutureBuilder menggunakan tipe Map<String, String?>
    return FutureBuilder<Map<String, String?>>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        if (snapshot.hasError) {
           return MaterialApp(
            home: Scaffold(body: Center(child: Text('Gagal memulai aplikasi: ${snapshot.error}'))),
          );
        }
        
        final initialData = snapshot.data ?? {};
        final token = initialData['token'];

        return MaterialApp(
          title: 'Aplikasi Penjadwalan Sidang',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
              bodyColor: const Color(0xFF1F2937),
              displayColor: const Color(0xFF1F2937),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF8F9FA),
              elevation: 0,
              iconTheme: IconThemeData(color: Color(0xFF1F2937)),
              titleTextStyle: TextStyle(color: Color(0xFF1F2937), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2A64F5),
              secondary: Color(0xFF34D399),
              error: Color(0xFFEF4444),
            ),
            inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            ),
          ),
          home: token != null ? const MainScreen() : const LoginPage(),
        );
      },
    );
  }
}