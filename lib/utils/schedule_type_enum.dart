import 'package:flutter/material.dart';

enum ScheduleType { magang, sempro, tugasAkhir }
extension ScheduleTypeExtension on ScheduleType {
    String get name {
        switch (this) {
        case ScheduleType.magang: return 'Magang';
        case ScheduleType.sempro: return 'Sempro';
        case ScheduleType.tugasAkhir: return 'Tugas Akhir';
        }
    }
    Color get color {
        switch (this) {
        case ScheduleType.magang: return Colors.blue;
        case ScheduleType.sempro: return Colors.orange;
        case ScheduleType.tugasAkhir: return Colors.green;
        }
    }
}

ScheduleType getScheduleTypeFromString(String apiType) {
    switch (apiType) {
      case '1': return ScheduleType.magang;
      case '2': return ScheduleType.sempro;
      case '3': return ScheduleType.tugasAkhir;
      default: return ScheduleType.magang;
    }
}

String getTipeStringFromEnum(ScheduleType type) {
    switch (type) {
      case ScheduleType.magang: return '1';
      case ScheduleType.sempro: return '2';
      case ScheduleType.tugasAkhir: return '3';
    }
}