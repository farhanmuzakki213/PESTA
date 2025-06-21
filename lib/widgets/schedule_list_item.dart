import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesta/models/booking_model.dart';
import 'package:pesta/schedule_detail_page.dart';
import '../utils/schedule_type_enum.dart';

class ScheduleListItem extends StatelessWidget {
  final Booking booking;
  final Widget? leadingWidget;
  const ScheduleListItem({super.key, required this.booking, this.leadingWidget,});

  @override
  Widget build(BuildContext context) {
    final scheduleType = getScheduleTypeFromString(booking.tipe);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        leading: leadingWidget ?? Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(color: scheduleType.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.class_, color: scheduleType.color),
        ),
        title: Text(booking.mahasiswaName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${scheduleType.name} • ${DateFormat.yMMMMd('id_ID').format(booking.tglBooking)}', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 2),
            Text('Sesi: ${booking.sesi} • Ruangan: ${booking.ruanganName}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => ScheduleDetailPage(booking: booking)));
        },
      ),
    );
  }
}