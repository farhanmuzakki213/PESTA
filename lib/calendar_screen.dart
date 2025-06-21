import 'package:flutter/material.dart';
import 'package:pesta/models/booking_model.dart';
import 'package:pesta/services/api_service.dart';
import 'package:pesta/widgets/schedule_list_item.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late Future<List<Booking>> _bookingsFuture;
  Map<DateTime, List<Booking>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _bookingsFuture = ApiService.getBookings();
    _bookingsFuture.then(
        (bookings) => setState(() => _events = _groupBookingsByDay(bookings)));
  }

  Map<DateTime, List<Booking>> _groupBookingsByDay(List<Booking> bookings) {
    Map<DateTime, List<Booking>> data = {};
    for (var booking in bookings) {
      DateTime date = DateTime(booking.tglBooking.year,
          booking.tglBooking.month, booking.tglBooking.day);
      if (data[date] == null) data[date] = [];
      data[date]!.add(booking);
    }
    return data;
  }

  List<Booking> _getEventsForDay(DateTime day) =>
      _events[DateTime(day.year, day.month, day.day)] ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kalender Jadwal'), centerTitle: true),
      body: Column(
        children: [
          TableCalendar(
            locale: 'id_ID',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) => setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            }),
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
            calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle),
                markerDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle)),
            headerStyle: const HeaderStyle(
                titleCentered: true, formatButtonVisible: false),
          ),
          const SizedBox(height: 8.0),
          const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider()),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _getEventsForDay(_selectedDay!).length,
              itemBuilder: (context, index) {
                final booking = _getEventsForDay(_selectedDay!)[index];
                return ScheduleListItem(booking: booking);
              },
            ),
          ),
        ],
      ),
    );
  }
}
