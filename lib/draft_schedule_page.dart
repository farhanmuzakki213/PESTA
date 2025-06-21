import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesta/models/booking_model.dart';
import 'package:pesta/services/api_service.dart';
import 'package:pesta/utils/schedule_type_enum.dart';

class DraftSchedulePage extends StatefulWidget {
  final List<ScheduleAssignment> successfulAssignments;
  final List<UnscheduledStudent> failedStudents;

  const DraftSchedulePage({
    super.key,
    required this.successfulAssignments,
    required this.failedStudents,
  });

  @override
  State<DraftSchedulePage> createState() => _DraftSchedulePageState();
}

class _DraftSchedulePageState extends State<DraftSchedulePage> {
  bool _isSaving = false;

  Future<void> _saveSchedules() async {
    setState(() => _isSaving = true);

    int successCount = 0;
    int failCount = 0;

    for (final assignment in widget.successfulAssignments) {
      final bookingData = {
        "ruangan_id": assignment.ruangan.id.toString(),
        "sesi_id": assignment.sesi.id.toString(),
        "mahasiswa_id": assignment.student.mahasiswaId.toString(),
        "tipe": getTipeStringFromEnum(assignment.student.tipeSidang),
        "tgl_booking": DateFormat('yyyy-MM-dd').format(assignment.tanggal),
      };

      try {
        final success = await ApiService.postBooking(bookingData);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
      }
    }
    
    if(!mounted) return;
    
    setState(() => _isSaving = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Proses Selesai'),
        content: Text('$successCount jadwal berhasil disimpan, $failCount gagal.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Draf Jadwal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.successfulAssignments.isNotEmpty)
            _buildResultSection(
              title: 'Jadwal Berhasil Dibuat',
              icon: Icons.check_circle,
              color: Colors.green,
              count: widget.successfulAssignments.length,
              children: widget.successfulAssignments.map((assignment) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(assignment.student.mahasiswaName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      '${DateFormat('EEEE, dd/MM/yy', 'id_ID').format(assignment.tanggal)}\nSesi: ${assignment.sesi.nama} • Ruangan: ${assignment.ruangan.nama}',
                    ),
                    isThreeLine: true,
                  ),
                );
              }).toList(),
            ),
          
          if (widget.failedStudents.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildResultSection(
              title: 'Gagal Dijadwalkan',
              icon: Icons.cancel,
              color: Colors.red,
              count: widget.failedStudents.length,
              children: widget.failedStudents.map((student) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.red.shade50,
                  child: ListTile(
                    title: Text(student.mahasiswaName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Tidak ditemukan slot yang cocok untuk semua dosen.'),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveSchedules,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Simpan Jadwal', style: TextStyle(fontSize: 16, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildResultSection({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text('$title ($count)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}