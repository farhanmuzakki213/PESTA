import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesta/models/booking_model.dart';
import 'package:pesta/services/api_service.dart';
import 'package:pesta/utils/schedule_type_enum.dart';

class EditBookingPage extends StatefulWidget {
  final Booking booking;
  const EditBookingPage({super.key, required this.booking});

  @override
  State<EditBookingPage> createState() => _EditBookingPageState();
}

class _EditBookingPageState extends State<EditBookingPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  Sesi? _selectedSesi;
  Ruangan? _selectedRuangan;
  bool _isLoading = false;

  final List<Sesi> _allSessions = [
    Sesi(id: 1, nama: '08:00 - 10:00'),
    Sesi(id: 2, nama: '10:00 - 12:00'),
    Sesi(id: 3, nama: '13:00 - 15:00'),
    Sesi(id: 4, nama: '15:00 - 17:00'),
  ];
  final List<Ruangan> _allRooms = [
    Ruangan(id: 1, nama: 'E-301'),
    Ruangan(id: 2, nama: 'E-302'),
    Ruangan(id: 3, nama: 'E-310'),
    Ruangan(id: 4, nama: 'E-311'),
  ];
  
  @override
  void initState() {
    super.initState();
    _selectedDate = widget.booking.tglBooking;
    try {
      _selectedSesi = _allSessions.firstWhere((s) => s.nama == widget.booking.sesi);
      _selectedRuangan = _allRooms.firstWhere((r) => r.nama == widget.booking.ruanganName);
    } catch (e) {
      // Handle jika data awal tidak ada di list
      _selectedSesi = null;
      _selectedRuangan = null;
    }
  }

  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final bookingData = {
        "ruangan_id": _selectedRuangan!.id.toString(),
        "sesi_id": _selectedSesi!.id.toString(),
        "tgl_booking": DateFormat('yyyy-MM-dd').format(_selectedDate),
        // Field lain yang mungkin dibutuhkan oleh API Anda saat update
        "mahasiswa_id": widget.booking.mahasiswaId.toString(),
        "tipe": widget.booking.tipe,
      };

      try {
        final success = await ApiService.updateBooking(widget.booking.id, bookingData);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal berhasil diperbarui!'), backgroundColor: Colors.green,));
          Navigator.of(context).pop(true); // Kirim 'true' untuk refresh
        } else {
          throw Exception('Gagal memperbarui jadwal.');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Jadwal')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(widget.booking.mahasiswaName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(getScheduleTypeFromString(widget.booking.tipe).name, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Sesi>(
              value: _selectedSesi,
              decoration: const InputDecoration(labelText: 'Sesi', prefixIcon: Icon(Icons.access_time)),
              items: _allSessions.map((Sesi sesi) {
                return DropdownMenuItem<Sesi>(value: sesi, child: Text(sesi.nama));
              }).toList(),
              onChanged: (Sesi? newValue) => setState(() => _selectedSesi = newValue),
              validator: (value) => value == null ? 'Sesi tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
             DropdownButtonFormField<Ruangan>(
              value: _selectedRuangan,
              decoration: const InputDecoration(labelText: 'Ruangan', prefixIcon: Icon(Icons.room_outlined)),
              items: _allRooms.map((Ruangan ruangan) {
                return DropdownMenuItem<Ruangan>(value: ruangan, child: Text(ruangan.nama));
              }).toList(),
              onChanged: (Ruangan? newValue) => setState(() => _selectedRuangan = newValue),
              validator: (value) => value == null ? 'Ruangan tidak boleh kosong' : null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submitUpdate,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Simpan Perubahan'),
        ),
      ),
    );
  }
}