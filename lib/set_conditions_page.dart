import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesta/csp_solver.dart';
import 'package:pesta/draft_schedule_page.dart';
import 'package:pesta/models/booking_model.dart';
import 'package:pesta/services/api_service.dart';
import 'package:pesta/widgets/add_constraint_dialog.dart';

class SetConditionsPage extends StatefulWidget {
  final List<UnscheduledStudent> students;
  const SetConditionsPage({super.key, required this.students});

  @override
  State<SetConditionsPage> createState() => _SetConditionsPageState();
}

class _SetConditionsPageState extends State<SetConditionsPage> {
  DateTimeRange? _scheduleDateRange;
  final List<Dosen> _uniqueDosen = [];
  final Map<int, List<DosenConstraint>> _dosenConstraints = {};
  
  List<EnrichedBooking> _existingBookings = [];
  bool _isLoading = true;

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
  
  final Set<Sesi> _selectedSessions = {};

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    final seenDosenIds = <int>{};
    for (var student in widget.students) {
      for (var dosen in student.dosenTerlibat) {
        if (seenDosenIds.add(dosen.id)) {
          _uniqueDosen.add(dosen);
        }
      }
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final bookings = await ApiService.getEnrichedBookings();
      if(mounted){
        setState(() {
          _existingBookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted){
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data booking yang ada: $e'))
        );
      }
    }
  }

  Future<void> _selectScheduleDateRange(BuildContext context) async {
    final initialDateRange = _scheduleDateRange ?? DateTimeRange(start: DateTime.now(), end: DateTime.now().add(const Duration(days: 30)));
    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: initialDateRange,
    );
    if (newDateRange != null) setState(() => _scheduleDateRange = newDateRange);
  }
  
  void _showAddConstraintDialog(Dosen dosen) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddConstraintDialog(
          dosen: dosen,
          allSessions: _allSessions,
          onAddConstraint: (constraint) {
            setState(() {
              _dosenConstraints.putIfAbsent(dosen.id, () => []).add(constraint);
            });
          },
        );
      },
    );
  }
  
  void _runSchedulingProcess() {
    if (_scheduleDateRange == null || _selectedSessions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap tentukan rentang tanggal dan sesi terlebih dahulu.')));
        return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
    
    final solver = CspSolver();
    final results = solver.solve(
      students: widget.students,
      dateRange: _scheduleDateRange!,
      availableSessions: _selectedSessions.toList(),
      availableRooms: _allRooms,
      dosenConstraints: _dosenConstraints,
      existingBookings: _existingBookings,
    );
    
    Navigator.of(context, rootNavigator: true).pop();

    Navigator.push(context, MaterialPageRoute(
        builder: (_) => DraftSchedulePage(
            successfulAssignments: results['success'] as List<ScheduleAssignment>,
            failedStudents: results['failed'] as List<UnscheduledStudent>,
        ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Atur Kondisi Jadwal')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data jadwal...'),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Atur Kondisi Jadwal')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            title: '1. Tentukan Rentang Penjadwalan',
            icon: Icons.date_range,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilih tanggal mulai dan selesai untuk penjadwalan.', style: TextStyle(fontSize: 15)),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(_scheduleDateRange == null ? 'Pilih Rentang Tanggal' : '${DateFormat('dd/MM/yy').format(_scheduleDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_scheduleDateRange!.end)}'),
                  onTap: () => _selectScheduleDateRange(context),
                ),
                const SizedBox(height: 20),
                const Text('Pilih sesi yang tersedia setiap harinya.', style: TextStyle(fontSize: 15)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  children: _allSessions.map((sesi) {
                    final isSelected = _selectedSessions.contains(sesi);
                    return FilterChip(
                      label: Text(sesi.nama),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) _selectedSessions.add(sesi);
                          else _selectedSessions.remove(sesi);
                        });
                      },
                      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: '2. Atur Batasan Waktu Dosen',
            icon: Icons.person_off,
            content: Column(
              children: _uniqueDosen.map((dosen) {
                final constraints = _dosenConstraints[dosen.id] ?? [];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(dosen.nama, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16))),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: () => _showAddConstraintDialog(dosen),
                            ),
                          ],
                        ),
                        if (constraints.isNotEmpty) ...[
                          const Divider(),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: constraints.map((constraint) {
                              return Chip(
                                avatar: const Icon(Icons.block, color: Colors.white, size: 16),
                                label: Text(constraint.description, style: const TextStyle(color: Colors.white)),
                                backgroundColor: Colors.grey.shade600,
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () => setState(() => _dosenConstraints[dosen.id]!.remove(constraint)),
                                padding: const EdgeInsets.all(6),
                              );
                            }).toList(),
                          )
                        ] else
                          const Center(child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text('Tidak ada batasan waktu', style: TextStyle(color: Colors.grey)),
                          )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
       bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.auto_awesome, color: Colors.white),
          label: const Text('Buat Jadwal Otomatis', style: TextStyle(fontSize: 16, color: Colors.white)),
          onPressed: _runSchedulingProcess,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget content}) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            content,
          ],
        ),
      ),
    );
  }
}