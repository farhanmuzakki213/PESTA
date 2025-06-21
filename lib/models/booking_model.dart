class Booking {
  final int idBooking;
  final String ruangan;
  final String sesi;
  final String mahasiswa;
  final int idMahasiswa;
  final String nim;
  final String tipe;
  final DateTime tglBooking;
  final String statusBooking;
  dynamic detailData;

  Booking({
    required this.idBooking,
    required this.ruangan,
    required this.sesi,
    required this.mahasiswa,
    required this.idMahasiswa,
    required this.nim,
    required this.tipe,
    required this.tglBooking,
    required this.statusBooking,
    this.detailData,
  });
  

  factory Booking.fromJson(Map<String, dynamic> json) {
    String status;
    switch (json['status_booking']) {
      case 0:
        status = 'Cancel';
        break;
      case 1:
        status = 'Booking';
        break;
      case 2:
        status = 'Selesai';
        break;
      default:
        status = 'Status Tidak Diketahui';
    }
    return Booking(
      idBooking: int.tryParse(json['id_booking'].toString()) ?? 0, // Perbaikan
      ruangan: json['ruangan']['nama'] ?? 'Ruangan Tidak Diketahui',
      sesi: json['sesi']['nama'] ?? 'Sesi Tidak Diketahui',
      mahasiswa: json['mahasiswa']['nama'] ?? 'Nama Tidak Diketahui',
      idMahasiswa:
          int.tryParse(json['mahasiswa']['id'].toString()) ?? 0, // Perbaikan
      nim: json['mahasiswa']['nim']?.toString() ?? 'NIM Tidak Diketahui',
      tipe: json['tipe'].toString(),
      tglBooking: DateTime.parse(json['tgl_booking']),
      statusBooking: status,
    );
  }
}
