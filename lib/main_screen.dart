import 'package:flutter/material.dart';
import 'package:pesta/calendar_screen.dart';
import 'package:pesta/dashboard_screen.dart';
import 'package:pesta/data_page.dart';
import 'package:pesta/mass_schedule_page.dart';
import 'package:pesta/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    CalendarScreen(),
    DataPage(),
    ProfileScreen()
  ];
  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MassSchedulePage()));
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white))
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: [
                  MaterialButton(
                      minWidth: 40,
                      onPressed: () => _onItemTapped(0),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.home_filled,
                                color: _selectedIndex == 0
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey),
                            Text('Home',
                                style: TextStyle(
                                    color: _selectedIndex == 0
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey))
                          ])),
                  MaterialButton(
                      minWidth: 40,
                      onPressed: () => _onItemTapped(1),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today,
                                color: _selectedIndex == 1
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey),
                            Text('Kalender',
                                style: TextStyle(
                                    color: _selectedIndex == 1
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey))
                          ])),
                ],
              ),
              Row(
                children: [
                  MaterialButton(
                      minWidth: 40,
                      onPressed: () => _onItemTapped(2),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.data_usage,
                                color: _selectedIndex == 2
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey),
                            Text('Data',
                                style: TextStyle(
                                    color: _selectedIndex == 2
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey))
                          ])),
                  MaterialButton(
                      minWidth: 40,
                      onPressed: () => _onItemTapped(3),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person,
                                color: _selectedIndex == 3
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey),
                            Text('Profil',
                                style: TextStyle(
                                    color: _selectedIndex == 3
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey))
                          ])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
