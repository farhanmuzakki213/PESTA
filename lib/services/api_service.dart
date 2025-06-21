import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pesta/models/booking_model.dart';
import 'package:pesta/utils/schedule_type_enum.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // PENTING: Ganti 'localhost' dengan IP address mesin Anda jika testing di HP fisik.
  // Contoh: 'http://192.168.1.5:8000/api/mobile'
  // Jika menggunakan emulator Android, gunakan 'http://10.0.2.2:8000/api/mobile'
  static const String _baseUrl = 'http://10.0.3.2:8000/api/mobile';

  // Fungsi untuk login
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8', 'Accept': 'application/json'},
      body: jsonEncode(<String, String>{'email': email, 'password': password}),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Gagal untuk login. Status code: ${response.statusCode}');
  }
  
  static Future<String?> _getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<List<Booking>> getBookings() async {
    final String? token = await _getToken();
    if (token == null) throw Exception('Token tidak ditemukan. Silakan login kembali.');
    final response = await http.get(Uri.parse('$_baseUrl/bookings'), headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = jsonDecode(response.body);
        final List<dynamic> data = decodedResponse['data'];
        return data.map((json) => Booking.fromJson(json)).toList();
    }
    throw Exception('Gagal memuat data booking. Error: ${response.body}');
  }
  
  static Future<SidangDetail> getSidangDetails(Booking booking) async {
    String path;
    switch(booking.tipe) {
      case '1': path = '/pkl-mahasiswa'; break;
      case '2': path = '/sempro-mahasiswa'; break;
      case '3': path = '/ta-mahasiswa'; break;
      default: throw Exception("Tipe sidang tidak dikenal");
    }

    final String? token = await _getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');

    final response = await http.get(Uri.parse(_baseUrl + path), headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'});

    if (response.statusCode == 200) {
      final List<dynamic> allSidangData = jsonDecode(response.body);
      
      final sidangDetailJson = allSidangData.firstWhere(
        (item) => item['mahasiswa']['id_mahasiswa'] == booking.mahasiswaId,
        orElse: () => null,
      );

      if (sidangDetailJson == null) throw Exception("Detail sidang untuk mahasiswa ini tidak ditemukan.");

      String judul = "Judul tidak ditemukan";
      List<Dosen> dosenList = [];

      if (booking.tipe == '1') { // PKL
        judul = sidangDetailJson['judul_laporan'] ?? judul;
        if(sidangDetailJson['pembimbing']?['id_dosen'] != null) dosenList.add(Dosen(id: sidangDetailJson['pembimbing']['id_dosen'], nama: sidangDetailJson['pembimbing']['nama_pembimbing'], peran: 'Pembimbing'));
        if(sidangDetailJson['penguji']?['id_dosen'] != null) dosenList.add(Dosen(id: sidangDetailJson['penguji']['id_dosen'], nama: sidangDetailJson['penguji']['nama_penguji'], peran: 'Penguji'));
      } else if (booking.tipe == '2') { // Sempro
        judul = sidangDetailJson['judul_sempro'] ?? judul;
        if(sidangDetailJson['pembimbing_1']?['id_dosen'] != null) dosenList.add(Dosen(id: sidangDetailJson['pembimbing_1']['id_dosen'], nama: sidangDetailJson['pembimbing_1']['nama_pembimbing_1'], peran: 'Pembimbing 1'));
        if(sidangDetailJson['pembimbing_2']?['id_dosen'] != null) dosenList.add(Dosen(id: sidangDetailJson['pembimbing_2']['id_dosen'], nama: sidangDetailJson['pembimbing_2']['nama_pembimbing_2'], peran: 'Pembimbing 2'));
        if(sidangDetailJson['penguji']?['id_dosen'] != null) dosenList.add(Dosen(id: sidangDetailJson['penguji']['id_dosen'], nama: sidangDetailJson['penguji']['nama_penguji'], peran: 'Penguji'));
      } else if (booking.tipe == '3') { // TA
        judul = sidangDetailJson['judul'] ?? judul;
        if(sidangDetailJson['pembimbing_1']?['id_dosen'] != null) dosenList.add(Dosen(id: sidangDetailJson['pembimbing_1']['id_dosen'], nama: sidangDetailJson['pembimbing_1']['nama_pembimbing_1'], peran: 'Pembimbing 1'));
        if(sidangDetailJson['pembimbing_2']?['id_dosen'] != null) dosenList.add(Dosen(id: sidangDetailJson['pembimbing_2']['id_dosen'], nama: sidangDetailJson['pembimbing_2']['nama_pembimbing_2'], peran: 'Pembimbing 2'));
        if(sidangDetailJson['penguji_1']?['id_dosen'] != null) dosenList.add(Dosen(id: sidangDetailJson['penguji_1']['id_dosen'], nama: sidangDetailJson['penguji_1']['nama_penguji_1'], peran: 'Penguji 1'));
        if(sidangDetailJson['penguji_2']?['id_dosen'] != null) dosenList.add(Dosen(id: sidangDetailJson['penguji_2']['id_dosen'], nama: sidangDetailJson['penguji_2']['nama_penguji_2'], peran: 'Penguji 2'));
        if(sidangDetailJson['ketua']?['id_dosen'] != null) dosenList.add(Dosen(id: sidangDetailJson['ketua']['id_dosen'], nama: sidangDetailJson['ketua']['nama_ketua'], peran: 'Ketua Sidang'));
        if(sidangDetailJson['sekretaris']?['id_dosen'] != null) dosenList.add(Dosen(id: sidangDetailJson['sekretaris']['id_dosen'], nama: sidangDetailJson['sekretaris']['nama_sekretaris'], peran: 'Sekretaris'));
      }
      
      return SidangDetail(judul: judul, dosenList: dosenList);
    }
    throw Exception('Gagal memuat detail sidang dari $path');
  }

  static Future<List<UnscheduledStudent>> getUnscheduledStudents() async {
    final String? token = await _getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');

    final responses = await Future.wait([
      http.get(Uri.parse('$_baseUrl/bookings'), headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      http.get(Uri.parse('$_baseUrl/pkl-mahasiswa'), headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      http.get(Uri.parse('$_baseUrl/sempro-mahasiswa'), headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'}),
      http.get(Uri.parse('$_baseUrl/ta-mahasiswa'), headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'})
    ]);

    for (var response in responses) {
      if (response.statusCode != 200) throw Exception('Gagal memuat salah satu data. Status: ${response.statusCode}');
    }

    final bookingsResponse = jsonDecode(responses[0].body);
    final List<dynamic> bookingsData = bookingsResponse['data'];
    final scheduledPklIds = <int>{};
    final scheduledSemproIds = <int>{};
    final scheduledTaIds = <int>{};

    for (var booking in bookingsData) {
      if(booking['mahasiswa'] != null && booking['mahasiswa']['id'] != null) {
          switch(booking['tipe']){
              case '1': scheduledPklIds.add(booking['mahasiswa']['id']); break;
              case '2': scheduledSemproIds.add(booking['mahasiswa']['id']); break;
              case '3': scheduledTaIds.add(booking['mahasiswa']['id']); break;
          }
      }
    }

    List<UnscheduledStudent> unscheduledList = [];

    final pklData = jsonDecode(responses[1].body) as List<dynamic>;
    for (var pkl in pklData) {
        final mhsId = pkl['mahasiswa']['id_mahasiswa'];
        if (!scheduledPklIds.contains(mhsId)) {
            List<Dosen> dosenList = [];
            if(pkl['pembimbing']?['id_dosen'] != null) dosenList.add(Dosen(id: pkl['pembimbing']['id_dosen'], nama: pkl['pembimbing']['nama_pembimbing']));
            if(pkl['penguji']?['id_dosen'] != null) dosenList.add(Dosen(id: pkl['penguji']['id_dosen'], nama: pkl['penguji']['nama_penguji']));
            unscheduledList.add(UnscheduledStudent(mahasiswaId: mhsId, mahasiswaName: pkl['mahasiswa']['nama_mahasiswa'], tipeSidang: ScheduleType.magang, dosenTerlibat: dosenList));
        }
    }

    final semproData = jsonDecode(responses[2].body) as List<dynamic>;
    for (var sempro in semproData) {
        final mhsId = sempro['mahasiswa']['id_mahasiswa'];
        if (!scheduledSemproIds.contains(mhsId)) {
            List<Dosen> dosenList = [];
            if(sempro['pembimbing_1']?['id_dosen'] != null) dosenList.add(Dosen(id: sempro['pembimbing_1']['id_dosen'], nama: sempro['pembimbing_1']['nama_pembimbing_1']));
            if(sempro['pembimbing_2']?['id_dosen'] != null) dosenList.add(Dosen(id: sempro['pembimbing_2']['id_dosen'], nama: sempro['pembimbing_2']['nama_pembimbing_2']));
            if(sempro['penguji']?['id_dosen'] != null) dosenList.add(Dosen(id: sempro['penguji']['id_dosen'], nama: sempro['penguji']['nama_penguji']));
            unscheduledList.add(UnscheduledStudent(mahasiswaId: mhsId, mahasiswaName: sempro['mahasiswa']['nama_mahasiswa'], tipeSidang: ScheduleType.sempro, dosenTerlibat: dosenList));
        }
    }

    final taData = jsonDecode(responses[3].body) as List<dynamic>;
    for (var ta in taData) {
        final mhsId = ta['mahasiswa']['id_mahasiswa'];
        if (!scheduledTaIds.contains(mhsId)) {
            List<Dosen> dosenList = [];
            if(ta['pembimbing_1']?['id_dosen'] != null) dosenList.add(Dosen(id: ta['pembimbing_1']['id_dosen'], nama: ta['pembimbing_1']['nama_pembimbing_1']));
            if(ta['pembimbing_2']?['id_dosen'] != null) dosenList.add(Dosen(id: ta['pembimbing_2']['id_dosen'], nama: ta['pembimbing_2']['nama_pembimbing_2']));
            if(ta['penguji_1']?['id_dosen'] != null) dosenList.add(Dosen(id: ta['penguji_1']['id_dosen'], nama: ta['penguji_1']['nama_penguji_1']));
            if(ta['penguji_2']?['id_dosen'] != null) dosenList.add(Dosen(id: ta['penguji_2']['id_dosen'], nama: ta['penguji_2']['nama_penguji_2']));
            if(ta['ketua']?['id_dosen'] != null) dosenList.add(Dosen(id: ta['ketua']['id_dosen'], nama: ta['ketua']['nama_ketua']));
            if(ta['sekretaris']?['id_dosen'] != null) dosenList.add(Dosen(id: ta['sekretaris']['id_dosen'], nama: ta['sekretaris']['nama_sekretaris']));
            unscheduledList.add(UnscheduledStudent(mahasiswaId: mhsId, mahasiswaName: ta['mahasiswa']['nama_mahasiswa'], tipeSidang: ScheduleType.tugasAkhir, dosenTerlibat: dosenList));
        }
    }
    
    return unscheduledList;
  }

  static Future<bool> deleteBooking(int bookingId) async {
    final String? token = await _getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');

    final response = await http.delete(
      Uri.parse('$_baseUrl/bookings/$bookingId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 200 || response.statusCode == 204;
  }

  static Future<bool> updateBooking(int bookingId, Map<String, dynamic> bookingData) async {
    final String? token = await _getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');

    final response = await http.put(
      Uri.parse('$_baseUrl/bookings/$bookingId'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(bookingData),
    );
    return response.statusCode == 200;
  }
  
  static Future<bool> postBooking(Map<String, String> bookingData) async {
    final String? token = await _getToken();
    if (token == null) throw Exception('Token tidak ditemukan.');

    final response = await http.post(
      Uri.parse('$_baseUrl/bookings'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(bookingData),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }


  static Future<void> logout() async {
      final String? token = await _getToken();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (token == null) return;
      try {
        await http.post(Uri.parse('$_baseUrl/logout'), headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'});
      } finally {
        await prefs.remove('token');
        await prefs.remove('userName');
        await prefs.remove('userEmail');
      }
  }
}