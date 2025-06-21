import 'package:flutter/material.dart';
import 'package:pesta/models/booking_model.dart';
import 'package:pesta/services/api_service.dart';
import 'package:pesta/set_conditions_page.dart';
import 'package:pesta/utils/schedule_type_enum.dart';

class MassSchedulePage extends StatefulWidget {
  const MassSchedulePage({super.key});

  @override
  State<MassSchedulePage> createState() => _MassSchedulePageState();
}

class _MassSchedulePageState extends State<MassSchedulePage> {
  late Future<List<UnscheduledStudent>> _unscheduledFuture;
  List<UnscheduledStudent> _students = [];

  @override
  void initState() {
    super.initState();
    _unscheduledFuture = ApiService.getUnscheduledStudents().then((students) {
      _students = students;
      return students;
    });
  }

  void _selectAll(bool select) {
    setState(() {
      for (var student in _students) {
        student.isSelected = select;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Mahasiswa'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'select_all') _selectAll(true);
              if (value == 'deselect_all') _selectAll(false);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(value: 'select_all', child: Text('Pilih Semua')),
              const PopupMenuItem<String>(value: 'deselect_all', child: Text('Batal Pilih Semua')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<UnscheduledStudent>>(
        future: _unscheduledFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Tidak ada mahasiswa yang perlu dijadwalkan.'));

          return ListView(
            children: [
              _buildStudentGroup(ScheduleType.magang, 'Sidang PKL / Magang'),
              _buildStudentGroup(ScheduleType.sempro, 'Sidang Seminar Proposal'),
              _buildStudentGroup(ScheduleType.tugasAkhir, 'Sidang Tugas Akhir'),
            ],
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            final selectedStudents = _students.where((s) => s.isSelected).toList();
            if (selectedStudents.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih setidaknya satu mahasiswa.')));
              return;
            }
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => SetConditionsPage(students: selectedStudents)
            ));
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Lanjut ke Pengaturan Kondisi', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildStudentGroup(ScheduleType type, String title) {
    final group = _students.where((s) => s.tipeSidang == type).toList();
    if (group.isEmpty) return const SizedBox.shrink();

    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      initiallyExpanded: true,
      children: group.map((student) {
        return CheckboxListTile(
          title: Text(student.mahasiswaName),
          subtitle: Text('Dosen: ${student.dosenTerlibat.map((d) => d.nama.split(',').first).join(', ')}'),
          value: student.isSelected,
          onChanged: (bool? value) => setState(() => student.isSelected = value ?? false),
        );
      }).toList(),
    );
  }
}