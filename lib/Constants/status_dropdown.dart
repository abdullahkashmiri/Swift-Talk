import 'package:flutter/material.dart';

class StatusDropdown extends StatefulWidget {
  final void Function(String) onStatusChanged;
  final String initialStatus; // New parameter for initial status

  const StatusDropdown({super.key,
    required this.onStatusChanged,
    required this.initialStatus, // Required initial status
  });

  @override
  // ignore: library_private_types_in_public_api
  _StatusDropdownState createState() => _StatusDropdownState();
}

class _StatusDropdownState extends State<StatusDropdown> {
  late String _selectedStatus; // Use late initialization

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus; // Set initial status in initState
  }

  List<String> statusOptions = [
    'Available',
    'Busy',
    'In a Meeting',
    'Away',
    'Do Not Disturb',
    'On Vacation',
    'Offline',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              text: 'Current Status: ',
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: _selectedStatus,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          DropdownButton<String>(
            value: _selectedStatus,
            onChanged: (String? newValue) {
              setState(() {
                _selectedStatus = newValue!;
                widget.onStatusChanged(_selectedStatus); // Callback to parent widget
              });
            },
            items: statusOptions.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
