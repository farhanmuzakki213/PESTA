import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesta/models/booking_model.dart';

class AddConstraintDialog extends StatefulWidget {
  final Dosen dosen;
  final List<Sesi> allSessions;
  final Function(DosenConstraint) onAddConstraint;

  const AddConstraintDialog({
    super.key,
    required this.dosen,
    required this.allSessions,
    required this.onAddConstraint,
  });

  @override
  State<AddConstraintDialog> createState() => _AddConstraintDialogState();
}

enum ConstraintType { date, dateRange, dateTimeSession }

class _AddConstraintDialogState extends State<AddConstraintDialog> {
  ConstraintType _selectedType = ConstraintType.dateTimeSession;
  DateTime? _pickedDate;
  DateTimeRange? _pickedDateRange;
  Sesi? _selectedSession;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Column(
        children: [
          const Text('Atur Batasan Dosen', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(widget.dosen.nama, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.normal)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tipe Batasan:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ConstraintType>(
                // <-- PERBAIKAN DI SINI
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                    (Set<MaterialState> states) {
                      if (states.contains(MaterialState.selected)) {
                        return Theme.of(context).colorScheme.primary.withOpacity(0.2);
                      }
                      return null; // Gunakan default untuk yang tidak dipilih
                    },
                  ),
                  foregroundColor: MaterialStateProperty.all<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                segments: const <ButtonSegment<ConstraintType>>[
                  ButtonSegment<ConstraintType>(value: ConstraintType.dateTimeSession, label: Text('Spesifik'), icon: Icon(Icons.timer_outlined)),
                  ButtonSegment<ConstraintType>(value: ConstraintType.date, label: Text('Harian'), icon: Icon(Icons.calendar_today)),
                  ButtonSegment<ConstraintType>(value: ConstraintType.dateRange, label: Text('Rentang'), icon: Icon(Icons.date_range)),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<ConstraintType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
              ),
            ),
            const Divider(height: 32),
            _buildConstraintInput(),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _isInputValid() ? _addConstraint : null,
          child: const Text('Tambah'),
        ),
      ],
    );
  }
  
  bool _isInputValid() {
    switch (_selectedType) {
      case ConstraintType.date: return _pickedDate != null;
      case ConstraintType.dateRange: return _pickedDateRange != null;
      case ConstraintType.dateTimeSession: return _pickedDate != null && _selectedSession != null;
    }
  }
  
  void _addConstraint() {
    DosenConstraint? constraint;
    switch (_selectedType) {
      case ConstraintType.date:
        if (_pickedDate != null) constraint = DateConstraint(_pickedDate!);
        break;
      case ConstraintType.dateRange:
        if (_pickedDateRange != null) constraint = DateRangeConstraint(_pickedDateRange!);
        break;
      case ConstraintType.dateTimeSession:
        if (_pickedDate != null && _selectedSession != null) constraint = DateTimeSessionConstraint(_pickedDate!, _selectedSession!);
        break;
    }
    if (constraint != null) {
      widget.onAddConstraint(constraint);
      Navigator.of(context).pop();
    }
  }
  
  Widget _buildConstraintInput() {
    switch (_selectedType) {
      case ConstraintType.date:
        return _buildDatePicker();
      case ConstraintType.dateRange:
        return _buildDateRangePicker();
      case ConstraintType.dateTimeSession:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDatePicker(),
            const SizedBox(height: 16),
            _buildSessionPicker(),
          ],
        );
    }
  }

  Widget _buildDatePicker() {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
      leading: const Icon(Icons.calendar_today),
      title: Text(_pickedDate == null ? 'Pilih Tanggal' : DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_pickedDate!)),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _pickedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) setState(() => _pickedDate = date);
      },
    );
  }
  
  Widget _buildDateRangePicker() {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
      leading: const Icon(Icons.date_range_outlined),
      title: Text(_pickedDateRange == null ? 'Pilih Rentang Tanggal' : '${DateFormat('dd/MM/yy').format(_pickedDateRange!.start)} - ${DateFormat('dd/MM/yy').format(_pickedDateRange!.end)}'),
      onTap: () async {
        final dateRange = await showDateRangePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (dateRange != null) setState(() => _pickedDateRange = dateRange);
      },
    );
  }

  Widget _buildSessionPicker() {
    return DropdownButtonFormField<Sesi>(
      value: _selectedSession,
      hint: const Text('Pilih Sesi'),
      onChanged: (value) => setState(() => _selectedSession = value),
      items: widget.allSessions.map<DropdownMenuItem<Sesi>>((Sesi value) {
        return DropdownMenuItem<Sesi>(value: value, child: Text(value.nama));
      }).toList(),
      decoration: const InputDecoration(prefixIcon: Icon(Icons.access_time)),
    );
  }
}