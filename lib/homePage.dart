import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pesta/models/booking_model.dart';
import 'package:pesta/models/pkl_model.dart';
import 'package:pesta/models/sempro_model.dart';
import 'package:pesta/models/ta_model.dart';
import 'package:pesta/services/booking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'loginPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Booking> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
      return;
    }

    try {
      final bookingService = BookingService('http://10.0.3.2:8000');
      final bookings = await bookingService.getBookingsWithDetails(token);

      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Filter variables
  String _filterJenis = 'Semua';
  String _filterStatus = 'Semua';
  DateTimeRange? _filterTanggalRange;

  String getBaseUrl() {
    if (kIsWeb) return 'http://localhost:8000';
    return 'http://10.0.3.2:8000'; // For emulator
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('${getBaseUrl()}/api/mobile/logout'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Clear saved credentials
        await prefs.remove('token');
        await prefs.remove('userId');

        // Navigate to login page
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      } else {
        throw Exception('Logout failed: ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  String _convertTipe(String tipe) {
    switch (tipe) {
      case '1':
        return 'PKL';
      case '2':
        return 'Sempro';
      case '3':
        return 'TA';
      default:
        return tipe;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = _bookings.where((booking) {
      final jenis = _convertTipe(booking.tipe);
      final jenisMatch = _filterJenis == 'Semua' || jenis == _filterJenis;
      final statusMatch =
          _filterStatus == 'Semua' || booking.statusBooking == _filterStatus;
      final tanggalMatch = _filterTanggalRange == null ||
          (booking.tglBooking.isAfter(_filterTanggalRange!.start) &&
              booking.tglBooking.isBefore(
                  _filterTanggalRange!.end.add(const Duration(days: 1))));

      return jenisMatch && statusMatch && tanggalMatch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Penjadwalan Sidang',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Apakah Anda yakin ingin logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          _buildFilterSection(),
          const SizedBox(height: 8),
          // Schedule List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredBookings.isEmpty
                    ? const Center(
                        child: Text(
                            'Tidak ada jadwal yang sesuai dengan filter',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          return _buildScheduleCard(booking);
                        },
                      ),
          ),
        ],
      ),
      /* floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add new schedule
          _showAddScheduleDialog();
        },
        backgroundColor: Colors.blue[800],
        child: const Icon(Icons.add, color: Colors.white),
      ), */
    );
  }

  Widget _buildFilterSection() {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterJenis,
                    decoration: const InputDecoration(
                      labelText: 'Jenis Sidang',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: ['Semua', 'PKL', 'Sempro', 'Tugas Akhir']
                        .map((jenis) => DropdownMenuItem<String>(
                              value: jenis,
                              child: Text(jenis),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _filterJenis = value!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: ['Semua', 'Booking', 'Selesai', 'Cancel']
                        .map((status) => DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _filterStatus = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2025, 12, 31),
                  initialDateRange: _filterTanggalRange ??
                      DateTimeRange(
                        start: now.subtract(const Duration(days: 7)),
                        end: now,
                      ),
                );
                if (picked != null) {
                  setState(() {
                    _filterTanggalRange = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Rentang Tanggal',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  suffixIcon: Icon(Icons.date_range),
                ),
                child: Text(
                  _filterTanggalRange == null
                      ? 'Pilih rentang tanggal'
                      : '${DateFormat('dd MMM yyyy').format(_filterTanggalRange!.start)} - '
                          '${DateFormat('dd MMM yyyy').format(_filterTanggalRange!.end)}',
                ),
              ),
            ),
            if (_filterTanggalRange != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _filterTanggalRange = null;
                  });
                },
                child: const Text('Hapus filter tanggal'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Booking booking) {
    String jenis = _convertTipe(booking.tipe);

    Color statusColor;
    switch (booking.statusBooking) {
      case 'Cancel':
        statusColor = Colors.red;
        break;
      case 'Booking':
        statusColor = Colors.orange;
        break;
      case 'Selesai':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showScheduleDetail(booking),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    jenis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      booking.statusBooking,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                booking.mahasiswa,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(booking.nim, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    booking.tglBooking != null
                        ? DateFormat('dd MMM yyyy').format(booking.tglBooking)
                        : 'Tanggal tidak tersedia',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(booking.sesi,
                      style: const TextStyle(color: Colors.grey)),
                  const SizedBox(width: 16),
                  const Icon(Icons.room, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(booking.ruangan,
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showScheduleDetail(Booking booking) {
    String jenis = _convertTipe(booking.tipe);
    String judul = '';
    List<Widget> detailWidgets = [];

    // Handle jika detailData null
    if (booking.detailData != null) {
      switch (booking.tipe) {
        case '1': // PKL
          if (booking.detailData is Pkl) {
            Pkl pkl = booking.detailData as Pkl;
            judul = pkl.judul;
            detailWidgets = [
              _buildDetailRow('Judul', judul),
              _buildDetailRow('Pembimbing', pkl.pembimbing),
              _buildDetailRow('Penguji', pkl.penguji),
            ];
          }
          break;

        case '2': // Sempro
          if (booking.detailData is Sempro) {
            Sempro sempro = booking.detailData as Sempro;
            judul = sempro.judul;
            detailWidgets = [
              _buildDetailRow('Judul', judul),
              _buildDetailRow('Pembimbing 1', sempro.pembimbing1),
              _buildDetailRow('Pembimbing 2', sempro.pembimbing2),
              _buildDetailRow('Penguji', sempro.penguji),
            ];
          }
          break;

        case '3': // TA
          if (booking.detailData is Ta) {
            Ta ta = booking.detailData as Ta;
            judul = ta.judul;
            detailWidgets = [
              _buildDetailRow('Judul', judul),
              _buildDetailRow('Pembimbing 1', ta.pembimbing1),
              _buildDetailRow('Pembimbing 2', ta.pembimbing2),
              _buildDetailRow('Penguji 1', ta.penguji1),
              _buildDetailRow('Penguji 2', ta.penguji2),
              _buildDetailRow('Ketua', ta.ketua),
              _buildDetailRow('Sekretaris', ta.sekretaris),
            ];
          }
          break;
      }
    } else {
      detailWidgets = [
        const SizedBox(height: 8),
        const Text(
          'Detail tidak tersedia',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      ];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Detail Jadwal Sidang',
                style: Theme.of(context).textTheme.headline6,
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Mahasiswa', booking.mahasiswa),
              _buildDetailRow('NIM', booking.nim),
              _buildDetailRow('Jenis Sidang', jenis),
              _buildDetailRow(
                'Tanggal',
                DateFormat('EEEE, dd MMMM yyyy').format(booking.tglBooking),
              ),
              _buildDetailRow('Sesi', booking.sesi),
              _buildDetailRow('Ruang', booking.ruangan),
              ...detailWidgets,
              _buildDetailRow(
                'Status',
                booking.statusBooking,
                isStatus: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isStatus = false}) {
    Color statusColor = Colors.grey;
    if (isStatus) {
      switch (value) {
        case 'Cancel':
          statusColor = Colors.red;
          break;
        case 'Booking':
          statusColor = Colors.orange;
          break;
        case 'Selesai':
          statusColor = Colors.green;
          break;
        default:
          statusColor = Colors.grey;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isStatus
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      value,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }

  /* void _showAddScheduleDialog() {
    final formKey = GlobalKey<FormState>();
    final Map<String, dynamic> newSchedule = {
      'mahasiswa': '',
      'nim': '',
      'jenis': 'PKL',
      'tanggal': DateTime.now(),
      'sesi': 'Sesi 1',
      'ruang': 'R101',
      'penguji1': '',
      'penguji2': '',
      'status': 'Menunggu',
    };

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Jadwalkan Sidang Baru'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Nama Mahasiswa'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap isi nama mahasiswa';
                          }
                          return null;
                        },
                        onSaved: (value) =>
                            newSchedule['mahasiswa'] = value!.trim(),
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'NIM'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap isi NIM';
                          }
                          return null;
                        },
                        onSaved: (value) => newSchedule['nim'] = value!.trim(),
                      ),
                      DropdownButtonFormField<String>(
                        value: newSchedule['jenis'],
                        decoration:
                            const InputDecoration(labelText: 'Jenis Sidang'),
                        items: ['PKL', 'Sempro', 'Tugas Akhir']
                            .map((jenis) => DropdownMenuItem<String>(
                                  value: jenis,
                                  child: Text(jenis),
                                ))
                            .toList(), // ✅ fixed
                        onChanged: (String? value) {
                          setModalState(() {
                            newSchedule['jenis'] = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: newSchedule['tanggal'],
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2025),
                          );
                          if (selectedDate != null) {
                            setModalState(() {
                              newSchedule['tanggal'] = selectedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration:
                              const InputDecoration(labelText: 'Tanggal'),
                          child: Text(
                            DateFormat('dd MMMM yyyy')
                                .format(newSchedule['tanggal']),
                          ),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: newSchedule['sesi'],
                        decoration: const InputDecoration(labelText: 'Sesi'),
                        items: ['Sesi 1', 'Sesi 2', 'Sesi 3', 'Sesi 4']
                            .map((sesi) => DropdownMenuItem<String>(
                                  value: sesi,
                                  child: Text(sesi),
                                ))
                            .toList(),
                        onChanged: (String? value) {
                          setModalState(() {
                            newSchedule['sesi'] = value!;
                          });
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: newSchedule['ruang'],
                        decoration: const InputDecoration(labelText: 'Ruang'),
                        items: ['R101', 'R102', 'R103']
                            .map((ruang) => DropdownMenuItem<String>(
                                  value: ruang,
                                  child: Text(ruang),
                                ))
                            .toList(),
                        onChanged: (String? value) {
                          setModalState(() {
                            newSchedule['ruang'] = value!;
                          });
                        },
                      ),
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Penguji 1'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap isi nama penguji';
                          }
                          return null;
                        },
                        onSaved: (value) =>
                            newSchedule['penguji1'] = value!.trim(),
                      ),
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Penguji 2'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap isi nama penguji';
                          }
                          return null;
                        },
                        onSaved: (value) =>
                            newSchedule['penguji2'] = value!.trim(),
                      ),
                      DropdownButtonFormField<String>(
                        value: newSchedule['status'],
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: ['Disetujui', 'Menunggu', 'Ditolak']
                            .map((status) => DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (String? value) {
                          setModalState(() {
                            newSchedule['status'] = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      setState(() {
                        _bookings.add({
                          ...newSchedule,
                          'id': _bookings.isNotEmpty
                              ? _bookings.last['id'] + 1
                              : 1,
                        });
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Jadwal berhasil ditambahkan')),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  } */

  /* void _showEditScheduleDialog(Map<String, dynamic> jadwal) {
    final formKey = GlobalKey<FormState>();
    final editedSchedule = Map<String, dynamic>.from(jadwal);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Edit Jadwal Sidang'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: editedSchedule['mahasiswa'],
                        decoration:
                            const InputDecoration(labelText: 'Nama Mahasiswa'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap isi nama mahasiswa';
                          }
                          return null;
                        },
                        onSaved: (value) =>
                            editedSchedule['mahasiswa'] = value!.trim(),
                      ),
                      TextFormField(
                        initialValue: editedSchedule['nim'],
                        decoration: const InputDecoration(labelText: 'NIM'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap isi NIM';
                          }
                          return null;
                        },
                        onSaved: (value) =>
                            editedSchedule['nim'] = value!.trim(),
                      ),
                      DropdownButtonFormField<String>(
                        value: editedSchedule['jenis'],
                        decoration:
                            const InputDecoration(labelText: 'Jenis Sidang'),
                        items: ['PKL', 'Sempro', 'Tugas Akhir']
                            .map((jenis) => DropdownMenuItem<String>(
                                  value: jenis,
                                  child: Text(jenis),
                                ))
                            .toList(),
                        onChanged: (String? value) {
                          setModalState(() {
                            editedSchedule['jenis'] = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: editedSchedule['tanggal'],
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2025),
                          );
                          if (selectedDate != null) {
                            setModalState(() {
                              editedSchedule['tanggal'] = selectedDate;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration:
                              const InputDecoration(labelText: 'Tanggal'),
                          child: Text(
                            DateFormat('dd MMMM yyyy')
                                .format(editedSchedule['tanggal']),
                          ),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: editedSchedule['sesi'],
                        decoration: const InputDecoration(labelText: 'Sesi'),
                        items: ['Sesi 1', 'Sesi 2', 'Sesi 3', 'Sesi 4']
                            .map((sesi) => DropdownMenuItem<String>(
                                  value: sesi,
                                  child: Text(sesi),
                                ))
                            .toList(),
                        onChanged: (String? value) {
                          setModalState(() {
                            editedSchedule['sesi'] = value!;
                          });
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: editedSchedule['ruang'],
                        decoration: const InputDecoration(labelText: 'Ruang'),
                        items: ['R101', 'R102', 'R103']
                            .map((ruang) => DropdownMenuItem<String>(
                                  value: ruang,
                                  child: Text(ruang),
                                ))
                            .toList(),
                        onChanged: (String? value) {
                          setModalState(() {
                            editedSchedule['ruang'] = value!;
                          });
                        },
                      ),
                      TextFormField(
                        initialValue: editedSchedule['penguji1'],
                        decoration:
                            const InputDecoration(labelText: 'Penguji 1'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap isi nama penguji';
                          }
                          return null;
                        },
                        onSaved: (value) =>
                            editedSchedule['penguji1'] = value!.trim(),
                      ),
                      TextFormField(
                        initialValue: editedSchedule['penguji2'],
                        decoration:
                            const InputDecoration(labelText: 'Penguji 2'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap isi nama penguji';
                          }
                          return null;
                        },
                        onSaved: (value) =>
                            editedSchedule['penguji2'] = value!.trim(),
                      ),
                      DropdownButtonFormField<String>(
                        value: editedSchedule['status'],
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: ['Disetujui', 'Menunggu', 'Ditolak']
                            .map((status) => DropdownMenuItem<String>(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (String? value) {
                          setModalState(() {
                            editedSchedule['status'] = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      setState(() {
                        final index = _bookings.indexWhere(
                            (item) => item['id'] == editedSchedule['id']);
                        if (index != -1) {
                          _bookings[index] = editedSchedule;
                        }
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Jadwal berhasil diperbarui')),
                      );
                    }
                  },
                  child: const Text('Simpan Perubahan'),
                ),
              ],
            );
          },
        );
      },
    );
  } */

  /* _bookings */
}
