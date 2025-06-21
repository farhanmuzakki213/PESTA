import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesta/models/booking_model.dart';
import 'package:pesta/services/api_service.dart';
import 'package:pesta/utils/schedule_type_enum.dart';

class ScheduleDetailPage extends StatefulWidget {
  final Booking booking;
  const ScheduleDetailPage({super.key, required this.booking});

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late Future<SidangDetail> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = ApiService.getSidangDetails(widget.booking);
  }

  @override
  Widget build(BuildContext context) {
    ScheduleType scheduleType = getScheduleTypeFromString(widget.booking.tipe); 
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Jadwal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Mahasiswa', widget.booking.mahasiswaName),
            _buildDetailRow('Tipe Sidang', scheduleType.name),
            _buildDetailRow('Tanggal', DateFormat.yMMMMd('id_ID').format(widget.booking.tglBooking)),
            _buildDetailRow('Waktu (Sesi)', widget.booking.sesi),
            _buildDetailRow('Ruangan', widget.booking.ruanganName),
            const Divider(height: 40),
            
            FutureBuilder<SidangDetail>(
              future: _detailFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Gagal memuat data detail: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('Data detail tidak ditemukan.'));
                }

                final detail = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Judul', detail.judul),
                    const SizedBox(height: 20),
                    const Text('Dosen Terlibat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: detail.dosenList.length,
                      itemBuilder: (context, index) {
                        final dosen = detail.dosenList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                            title: Text(dosen.nama),
                            subtitle: dosen.peran != null ? Text(dosen.peran!) : null,
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}