import 'package:flutter/material.dart';
import 'package:pesta/models/booking_model.dart';

class CspSolver {
  Map<String, List> solve({
    required List<UnscheduledStudent> students,
    required DateTimeRange dateRange,
    required List<Sesi> availableSessions,
    required List<Ruangan> availableRooms,
    required Map<int, List<DosenConstraint>> dosenConstraints,
  }) {
    // INI ADALAH IMPLEMENTASI DUMMY / PALSU
    
    final List<ScheduleAssignment> success = [];
    final List<UnscheduledStudent> failed = [];

    // Simulasi: Jadwalkan 80% mahasiswa, dan gagalkan sisanya.
    for (int i = 0; i < students.length; i++) {
      if (i < (students.length * 0.8).floor()) {
        success.add(ScheduleAssignment(
          student: students[i],
          tanggal: dateRange.start.add(Duration(days: i % 5)),
          sesi: availableSessions[i % availableSessions.length],
          ruangan: availableRooms[i % availableRooms.length],
        ));
      } else {
        failed.add(students[i]);
      }
    }

    return {'success': success, 'failed': failed};
  }
}