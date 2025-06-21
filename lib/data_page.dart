import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pesta/edit_booking_page.dart';
import 'package:pesta/models/booking_model.dart';
import 'package:pesta/schedule_detail_page.dart';
import 'package:pesta/services/api_service.dart';
import 'package:pesta/widgets/schedule_list_item.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  State<DataPage> createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<int> _selectedBookingIds = {};

  @override
  void initState() {
    super.initState();
    _refreshBookings();
  }

  Future<void> _refreshBookings() async {
    setState(() {
      _isLoading = true;
      _isSelectionMode = false;
      _selectedBookingIds.clear();
    });
    try {
      final bookings = await ApiService.getBookings();
      bookings.sort((a, b) => b.tglBooking.compareTo(a.tglBooking));
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
    }
  }

  void _toggleSelection(int bookingId) {
    setState(() {
      if (_selectedBookingIds.contains(bookingId)) {
        _selectedBookingIds.remove(bookingId);
      } else {
        _selectedBookingIds.add(bookingId);
      }
      if (_selectedBookingIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _enterSelectionMode(int bookingId) {
    setState(() {
      _isSelectionMode = true;
      _selectedBookingIds.add(bookingId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedBookingIds.clear();
    });
  }
  
  void _deleteSelectedItems() async {
    final confirm = await _showConfirmationDialog(
      title: 'Hapus Jadwal',
      content: 'Anda yakin ingin menghapus ${_selectedBookingIds.length} jadwal yang dipilih?',
    );

    if (confirm == true) {
      for (int id in _selectedBookingIds) {
        await ApiService.deleteBooking(id);
      }
      _refreshBookings();
    }
  }
  
  Future<bool?> _showConfirmationDialog({required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Hapus', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              title: Text('${_selectedBookingIds.length} Dipilih'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _deleteSelectedItems,
                )
              ],
            )
          : AppBar(
              title: const Text('Semua Jadwal'),
              centerTitle: true,
            ),
      body: RefreshIndicator(
        onRefresh: _refreshBookings,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _bookings.isEmpty
                ? const Center(child: Text('Tidak ada jadwal.'))
                : ListView.builder(
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      return _buildSlidableListItem(booking);
                    },
                  ),
      ),
    );
  }

  Widget _buildSlidableListItem(Booking booking) {
    final isSelected = _selectedBookingIds.contains(booking.id);
    return Slidable(
      key: ValueKey(booking.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        children: [
          SlidableAction(
            onPressed: (context) async {
              final result = await Navigator.push<bool>(context, MaterialPageRoute(
                builder: (_) => EditBookingPage(booking: booking)
              ));
              if (result == true) {
                _refreshBookings();
              }
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
          ),
          SlidableAction(
            onPressed: (context) async {
              final confirm = await _showConfirmationDialog(
                title: 'Hapus Jadwal', 
                content: 'Anda yakin ingin menghapus jadwal ${booking.mahasiswaName}?'
              );
              if (confirm == true) {
                await ApiService.deleteBooking(booking.id);
                _refreshBookings();
              }
            },
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Hapus',
          ),
        ],
      ),
      child: GestureDetector(
        onLongPress: () {
          if (!_isSelectionMode) _enterSelectionMode(booking.id);
        },
        onTap: () {
          if (_isSelectionMode) {
            _toggleSelection(booking.id);
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleDetailPage(booking: booking)));
          }
        },
        child: Container(
          color: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
          child: ScheduleListItem(
            booking: booking,
            leadingWidget: _isSelectionMode 
              ? Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleSelection(booking.id),
                )
              : null,
          ),
        ),
      ),
    );
  }
}