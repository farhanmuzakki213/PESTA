import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesta/utils/schedule_type_enum.dart';

class Booking {
  final int id;
  final int mahasiswaId;
  final String mahasiswaName;
  final String tipe;
  final DateTime tglBooking;
  final String ruanganName;
  final String sesi;
  bool isSelected;

  Booking({
    required this.id,
    required this.mahasiswaId,
    required this.mahasiswaName,
    required this.tipe,
    required this.tglBooking,
    required this.ruanganName,
    required this.sesi,
    this.isSelected = false,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id_booking'],
      mahasiswaId: json['mahasiswa']['id'],
      mahasiswaName:
          json['mahasiswa']['nama'] ?? 'Nama Mahasiswa Tidak Ditemukan',
      tipe: json['tipe'] ?? '0',
      tglBooking: DateTime.parse(json['tgl_booking']),
      ruanganName: json['ruangan']['nama'] ?? 'N/A',
      sesi: json['sesi']['nama'] ?? 'N/A',
    );
  }
}

class Dosen {
  final int id;
  final String nama;
  final String? peran;
  Dosen({required this.id, required this.nama, this.peran});
}

class SidangDetail {
  final String judul;
  final List<Dosen> dosenList;
  SidangDetail({required this.judul, required this.dosenList});
}

class UnscheduledStudent {
  final int mahasiswaId;
  final String mahasiswaName;
  final ScheduleType tipeSidang;
  final List<Dosen> dosenTerlibat;
  bool isSelected;

  UnscheduledStudent({
    required this.mahasiswaId,
    required this.mahasiswaName,
    required this.tipeSidang,
    required this.dosenTerlibat,
    this.isSelected = true,
  });
}

class Sesi {
  final int id;
  final String nama;
  Sesi({required this.id, required this.nama});
}

class Ruangan {
  final int id;
  final String nama;
  Ruangan({required this.id, required this.nama});
}

class ScheduleAssignment {
  final UnscheduledStudent student;
  final DateTime tanggal;
  final Sesi sesi;
  final Ruangan ruangan;
  ScheduleAssignment(
      {required this.student,
      required this.tanggal,
      required this.sesi,
      required this.ruangan});
}

abstract class DosenConstraint {
  String get description;
}

class DateConstraint extends DosenConstraint {
  final DateTime date;
  DateConstraint(this.date);

  @override
  String get description =>
      'Seharian pada ${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date)}';
}

class DateRangeConstraint extends DosenConstraint {
  final DateTimeRange dateRange;
  DateRangeConstraint(this.dateRange);

  @override
  String get description =>
      'Dari ${DateFormat('dd/MM/yy').format(dateRange.start)} - ${DateFormat('dd/MM/yy').format(dateRange.end)}';
}

class DateTimeSessionConstraint extends DosenConstraint {
  final DateTime date;
  final Sesi sesi;
  DateTimeSessionConstraint(this.date, this.sesi);

  @override
  String get description =>
      '${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date)} - Sesi ${sesi.nama}';
}
