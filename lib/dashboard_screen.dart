import 'dart:math';

import 'package:flutter/material.dart';
import 'package:pesta/models/booking_model.dart';
import 'package:pesta/services/api_service.dart';
import 'package:pesta/widgets/schedule_list_item.dart';
import 'package:pesta/widgets/summary_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}
class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Booking>> _bookingsFuture;
  String _userName = "Admin";
  bool _showAllUpcoming = false;
  final int _initialDisplayCount = 3;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndBookings();
  }
  
  void _loadUserDataAndBookings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('userName') ?? 'Admin';
    });
    _bookingsFuture = ApiService.getBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Halo, $_userName!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.grey[600])), const Text('Selamat Datang', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))]),
        actions: [Padding(padding: const EdgeInsets.only(right: 16.0), child: CircleAvatar(backgroundColor: Colors.blue.shade100, child: const Icon(Icons.person)))],
      ),
      body: FutureBuilder<List<Booking>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Tidak ada jadwal ditemukan.'));
          
          final bookings = snapshot.data!;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          
          final nextSevenDays = today.add(const Duration(days: 7));
          final bookingsThisWeek = bookings.where((b) {
            final bookingDate = b.tglBooking;
            return !bookingDate.isBefore(today) && bookingDate.isBefore(nextSevenDays);
          }).length;
          final bookingsThisMonth = bookings.where((b) => b.tglBooking.month == now.month && b.tglBooking.year == now.year).length;

          final allUpcomingBookings = bookings.where((b) => !b.tglBooking.isBefore(today)).toList();
          allUpcomingBookings.sort((a, b) => a.tglBooking.compareTo(b.tglBooking));
          
          final itemsToShow = _showAllUpcoming ? allUpcomingBookings : allUpcomingBookings.sublist(0, min(_initialDisplayCount, allUpcomingBookings.length));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  SummaryCard(title: 'Minggu Ini', value: bookingsThisWeek.toString(), icon: Icons.calendar_view_week, color: Colors.orange), 
                  const SizedBox(width: 16), 
                  SummaryCard(title: 'Bulan Ini', value: bookingsThisMonth.toString(), icon: Icons.calendar_month, color: Colors.blue)
                ]),
                const SizedBox(height: 24),
                const Text('Jadwal Mendatang', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: itemsToShow.length,
                  itemBuilder: (context, index) {
                    final booking = itemsToShow[index];
                    return ScheduleListItem(booking: booking);
                  },
                ),
                if (!_showAllUpcoming && allUpcomingBookings.length > _initialDisplayCount)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Center(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _showAllUpcoming = true;
                          });
                        },
                        child: const Text('Lihat Semua'),
                      ),
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }
}