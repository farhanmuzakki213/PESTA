import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:pesta/models/booking_model.dart';

class CspSolver {
  late List<ScheduleAssignment> _successfulAssignments;
  late List<UnscheduledStudent> _allStudents;
  late List<EnrichedBooking> _existingBookings;

  Map<String, List> solve({
    required List<UnscheduledStudent> students,
    required DateTimeRange dateRange,
    required List<Sesi> availableSessions,
    required List<Ruangan> availableRooms,
    required Map<int, List<DosenConstraint>> dosenConstraints,
    required List<EnrichedBooking> existingBookings, // DATA LAMA
  }) {
    _allStudents = List.from(students);
    _successfulAssignments = [];
    _existingBookings = existingBookings; // Simpan data booking lama

    final Map<UnscheduledStudent, List<DomainValue>> domains =
        _initializeDomains(
            students, dateRange, availableSessions, availableRooms, dosenConstraints);

    _backtrack({}, domains);
    
    final Set<int> successfulStudentIds = _successfulAssignments.map((e) => e.student.mahasiswaId).toSet();
    final List<UnscheduledStudent> failedStudents = _allStudents.where((student) => !successfulStudentIds.contains(student.mahasiswaId)).toList();

    return {
      'success': _successfulAssignments,
      'failed': failedStudents,
    };
  }

  bool _backtrack(
    Map<UnscheduledStudent, ScheduleAssignment> currentAssignments,
    Map<UnscheduledStudent, List<DomainValue>> domains,
  ) {
    if (currentAssignments.length == _allStudents.length) {
      _successfulAssignments = currentAssignments.values.toList();
      return true;
    }

    final studentToSchedule = _selectUnassignedStudentMRV(currentAssignments, domains);
    if (studentToSchedule == null) return false;

    final orderedDomain =
        _orderDomainValuesLCV(studentToSchedule, domains[studentToSchedule]!, currentAssignments, domains);

    for (final value in orderedDomain) {
      final newAssignment = ScheduleAssignment(
        student: studentToSchedule,
        tanggal: value.tanggal,
        sesi: value.sesi,
        ruangan: value.ruangan,
      );

      // Cek konsistensi dengan data baru DAN data lama
      if (_isConsistent(newAssignment, currentAssignments)) {
        currentAssignments[studentToSchedule] = newAssignment;

        if (_backtrack(currentAssignments, domains)) {
          return true;
        }

        currentAssignments.remove(studentToSchedule);
      }
    }

    return false;
  }

  UnscheduledStudent? _selectUnassignedStudentMRV(
    Map<UnscheduledStudent, ScheduleAssignment> assignments,
    Map<UnscheduledStudent, List<DomainValue>> domains,
  ) {
    UnscheduledStudent? bestStudent;
    int minDomainSize = double.maxFinite.toInt();

    for (final student in _allStudents) {
      if (!assignments.containsKey(student)) {
        int legalValuesCount = 0;
        for (final value in domains[student]!) {
           final tempAssignment = ScheduleAssignment(
              student: student,
              tanggal: value.tanggal,
              sesi: value.sesi,
              ruangan: value.ruangan,
           );
           if (_isConsistent(tempAssignment, assignments)) {
             legalValuesCount++;
           }
        }
        
        if (legalValuesCount < minDomainSize) {
          minDomainSize = legalValuesCount;
          bestStudent = student;
        }
      }
    }
    return bestStudent;
  }
  
  List<DomainValue> _orderDomainValuesLCV(
      UnscheduledStudent student,
      List<DomainValue> domain,
      Map<UnscheduledStudent, ScheduleAssignment> assignments,
      Map<UnscheduledStudent, List<DomainValue>> allDomains) {

    final otherStudents = _allStudents.where((s) => s != student && !assignments.containsKey(s));
    if(otherStudents.isEmpty) return domain;

    return domain.sortedBy<num>((value) {
        int conflicts = 0;
        final tempAssignment = ScheduleAssignment(student: student, tanggal: value.tanggal, sesi: value.sesi, ruangan: value.ruangan);
        
        final newAssignments = Map.of(assignments);
        newAssignments[student] = tempAssignment;
        
        for(final otherStudent in otherStudents){
            for(final otherValue in allDomains[otherStudent]!){
                final otherTempAssignment = ScheduleAssignment(student: otherStudent, tanggal: otherValue.tanggal, sesi: otherValue.sesi, ruangan: otherValue.ruangan);
                if(!_isConsistent(otherTempAssignment, newAssignments)){
                    conflicts++;
                }
            }
        }
        return conflicts;
    });
  }

  /// Memeriksa apakah penugasan baru konsisten dengan penugasan yang sudah ada (baru & lama).
  bool _isConsistent(
      ScheduleAssignment newAssignment, Map<UnscheduledStudent, ScheduleAssignment> existingAssignments) {
    
    // PERIKSA KONFLIK DENGAN JADWAL LAMA DARI API
    for (final oldBooking in _existingBookings) {
        final booking = oldBooking.booking;
        // Cek konflik waktu & ruangan
        if (newAssignment.tanggal.isAtSameMomentAs(booking.tglBooking) &&
            newAssignment.sesi.id.toString() == booking.sesi &&
            newAssignment.ruangan.nama == booking.ruanganName) {
            return false;
        }

        // Cek konflik dosen
        final hasSharedDosen = newAssignment.student.dosenTerlibat.any((d1) => oldBooking.dosenTerlibat.any((d2) => d1.id == d2.id));
        if (hasSharedDosen && newAssignment.tanggal.isAtSameMomentAs(booking.tglBooking) && newAssignment.sesi.id.toString() == booking.sesi) {
            return false;
        }
    }

    // PERIKSA KONFLIK DENGAN JADWAL BARU YANG SEDANG DIBUAT
    for (final assignment in existingAssignments.values) {
      if (newAssignment.tanggal == assignment.tanggal &&
          newAssignment.sesi.id == assignment.sesi.id &&
          newAssignment.ruangan.id == assignment.ruangan.id) {
        return false;
      }

      final hasSharedDosen = newAssignment.student.dosenTerlibat
          .any((d1) => assignment.student.dosenTerlibat.any((d2) => d1.id == d2.id));

      if (hasSharedDosen &&
          newAssignment.tanggal == assignment.tanggal &&
          newAssignment.sesi.id == assignment.sesi.id) {
        return false;
      }
    }
    return true;
  }
  
  Map<UnscheduledStudent, List<DomainValue>> _initializeDomains(
    List<UnscheduledStudent> students,
    DateTimeRange dateRange,
    List<Sesi> availableSessions,
    List<Ruangan> availableRooms,
    Map<int, List<DosenConstraint>> dosenConstraints,
  ) {
    final Map<UnscheduledStudent, List<DomainValue>> domains = {};

    final allDates = List.generate(
      dateRange.end.difference(dateRange.start).inDays + 1,
      (i) => dateRange.start.add(Duration(days: i)),
    );

    for (final student in students) {
      domains[student] = [];
      final involvedDosenIds = student.dosenTerlibat.map((d) => d.id).toSet();

      for (final date in allDates) {
        if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) continue;

        for (final sesi in availableSessions) {
          bool isAnyDosenUnavailable = false;
          for (final dosenId in involvedDosenIds) {
            final constraints = dosenConstraints[dosenId] ?? [];
            if (_isDosenConstrained(date, sesi, constraints)) {
              isAnyDosenUnavailable = true;
              break;
            }
          }
          if (isAnyDosenUnavailable) continue;

          for (final ruangan in availableRooms) {
            final tempAssignment = ScheduleAssignment(student: student, tanggal: date, sesi: sesi, ruangan: ruangan);
            // PRUNING: Cek langsung dengan data booking lama sebelum dimasukkan ke domain
            if(_isConsistent(tempAssignment, {})) {
                domains[student]!.add(DomainValue(date, sesi, ruangan));
            }
          }
        }
      }
    }
    return domains;
  }
  
  bool _isDosenConstrained(DateTime date, Sesi sesi, List<DosenConstraint> constraints) {
      for(final constraint in constraints) {
          if (constraint is DateConstraint && constraint.date.isAtSameMomentAs(date)) return true;
          if (constraint is DateRangeConstraint && (date.isAfter(constraint.dateRange.start) && date.isBefore(constraint.dateRange.end) || date.isAtSameMomentAs(constraint.dateRange.start) || date.isAtSameMomentAs(constraint.dateRange.end))) return true;
          if (constraint is DateTimeSessionConstraint && constraint.date.isAtSameMomentAs(date) && constraint.sesi.id == sesi.id) return true;
      }
      return false;
  }
}

class DomainValue {
  final DateTime tanggal;
  final Sesi sesi;
  final Ruangan ruangan;

  DomainValue(this.tanggal, this.sesi, this.ruangan);
}