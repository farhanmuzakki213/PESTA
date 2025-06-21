import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking_model.dart';
import '../models/pkl_model.dart';
import '../models/sempro_model.dart';
import '../models/ta_model.dart';

class BookingService {
  final String baseUrl;

  BookingService(this.baseUrl);

  Future<List<Booking>> getBookingsWithDetails(String token) async {
    try {
      // 1. Get bookings data
      final bookingResponse = await http.get(
        Uri.parse('$baseUrl/api/mobile/bookings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (bookingResponse.statusCode != 200) {
        throw Exception('Failed to load bookings');
      }

      final bookingData = json.decode(bookingResponse.body);
      final List<Booking> bookings = (bookingData['data'] as List)
          .map((item) => Booking.fromJson(item))
          .toList();

      // 2. Get details for each booking
      for (var booking in bookings) {
        try {
          switch (booking.tipe) {
            case '1': // PKL
              final pklResponse = await http.get(
                Uri.parse('$baseUrl/api/mobile/pkl-mahasiswa'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              );

              if (pklResponse.statusCode == 200) {
                final pklData = json.decode(pklResponse.body);
                final pklDetail = (pklData['data'] as List).firstWhere(
                  (item) =>
                      item['mahasiswa']['id_mahasiswa'] == booking.idMahasiswa,
                  orElse: () => null,
                );

                if (pklDetail != null) {
                  booking.detailData = Pkl.fromJson(pklDetail);
                }
              }
              break;

            case '2': // Sempro
              final semproResponse = await http.get(
                Uri.parse('$baseUrl/api/mobile/sempro-mahasiswa'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              );

              if (semproResponse.statusCode == 200) {
                final semproData = json.decode(semproResponse.body);
                final semproList = semproData['data'] as List;
                final semproDetail = semproList.firstWhere(
                  (item) =>
                      item['mahasiswa']['id_mahasiswa'] == booking.idMahasiswa,
                  orElse: () => null,
                );

                if (semproDetail != null) {
                  booking.detailData = Sempro.fromJson(semproDetail);
                }
              }
              break;

            case '3': // TA
              final taResponse = await http.get(
                Uri.parse('$baseUrl/api/mobile/ta-mahasiswa'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              );

              if (taResponse.statusCode == 200) {
                final taData = json.decode(taResponse.body);
                final taList = (taData['data'] ?? []) as List;
                final taDetail = taList.firstWhere(
                  (item) =>
                      item['mahasiswa']['id_mahasiswa'] == booking.idMahasiswa,
                  orElse: () => null,
                );

                if (taDetail != null) {
                  booking.detailData = Ta.fromJson(taDetail);
                }
              }
              break;
          }
        } catch (e) {
          print('Error loading detail for booking ${booking.idBooking}: $e');
        }
      }

      return bookings;
    } catch (e) {
      throw Exception('Failed to load booking details: $e');
    }
  }
}
