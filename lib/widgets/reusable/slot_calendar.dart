import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/utils/storage.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

class SlotCalendar extends StatefulWidget {
  final String label;
  final bool isRequired;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final VoidCallback onTextFieldTap;
  final String vehicleId;
  final TextEditingController? controller;
  final String? startTimeError;
  final String? endTimeError;

  const SlotCalendar({
    super.key,
    required this.label,
    this.isRequired = false,
    required this.onChanged,
    this.errorText,
    required this.onTextFieldTap,
    required this.vehicleId,
    this.controller,
    this.startTimeError,
    this.endTimeError,
  });

  @override
  State<SlotCalendar> createState() => _SlotCalendarState();
}

class _SlotCalendarState extends State<SlotCalendar> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  List<Map<String, String>> bookedSlots = [];
  bool _isCalendarVisible = false;
  late TextEditingController _internalController;
  bool _isLoadingSlots = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
    // Only fetch if vehicleId is valid
    if (_isValidVehicleId(widget.vehicleId)) {
      _fetchBookedSlots();
    }
    print('Initial vehicleId: ${widget.vehicleId}');
  }

  @override
  void didUpdateWidget(SlotCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fetch slots if vehicleId changes and is valid
    if (widget.vehicleId != oldWidget.vehicleId) {
      print(
        'vehicleId changed from: ${oldWidget.vehicleId} to: ${widget.vehicleId}',
      );

      if (_isValidVehicleId(widget.vehicleId)) {
        _fetchBookedSlots();
      } else {
        // Clear booked slots if vehicleId becomes invalid
        setState(() {
          bookedSlots.clear();
          _selectedDate = null;
          _selectedStartTime = null;
          _selectedEndTime = null;
          _internalController.clear();
        });
      }
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  // Helper method to check if vehicleId is valid
  bool _isValidVehicleId(String vehicleId) {
    return vehicleId.isNotEmpty &&
        vehicleId != "null" &&
        vehicleId != "NULL" &&
        vehicleId.toLowerCase() != "null";
  }

  Future<void> _fetchBookedSlots() async {
    if (!_isValidVehicleId(widget.vehicleId)) {
      print('Invalid vehicleId, skipping API call: ${widget.vehicleId}');
      return;
    }

    setState(() {
      _isLoadingSlots = true;
      _errorMessage = null;
    });

    final token = await Storage.getToken();

    try {
      final url =
          'https://api.smartassistapp.in/api/slots/${widget.vehicleId}/slots/all';
      print('Fetching booked slots from: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if data structure is as expected
        if (data != null && data['data'] != null) {
          setState(() {
            bookedSlots = List<Map<String, String>>.from(
              data['data'].map(
                (slot) => {
                  'start_time': slot['start_time_slot']?.toString() ?? '',
                  'end_time': slot['end_time_slot']?.toString() ?? '',
                  'date': slot['date_of_booking']?.toString() ?? '',
                  'owner_name': slot['owner_name']?.toString() ?? 'No Name',
                },
              ),
            );
            _isLoadingSlots = false;
          });
          print('Successfully loaded ${bookedSlots.length} booked slots');
        } else {
          throw Exception('Invalid response structure');
        }
      } else {
        // Handle different HTTP status codes
        String errorMessage;
        switch (response.statusCode) {
          case 404:
            errorMessage = 'Vehicle not found';
            break;
          case 401:
            errorMessage = 'Unauthorized access';
            break;
          case 500:
            errorMessage = 'Server error';
            break;
          default:
            errorMessage =
                'Failed to load booked slots (${response.statusCode})';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error fetching booked slots: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoadingSlots = false;
        // Don't clear existing slots on error, just show error
      });
    }
  }

  // Convert TimeOfDay to string format (HH:mm:ss)
  String _timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  // Get disabled hours and minutes for time picker
  Set<int> _getDisabledHours() {
    if (_selectedDate == null) return {};

    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    Set<int> disabledHours = {};

    for (var bookedSlot in bookedSlots) {
      if (bookedSlot['date'] == selectedDateStr) {
        var startParts = bookedSlot['start_time']!.split(':');
        var endParts = bookedSlot['end_time']!.split(':');

        int startHour = int.parse(startParts[0]);
        int endHour = int.parse(endParts[0]);

        // Add all hours in the booked range
        for (int hour = startHour; hour <= endHour; hour++) {
          disabledHours.add(hour);
        }
      }
    }

    return disabledHours;
  }

  // Check if specific time is disabled
  bool _isTimeDisabled(DateTime time) {
    if (_selectedDate == null) return false;

    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final timeMinutes = time.hour * 60 + time.minute;

    for (var bookedSlot in bookedSlots) {
      if (bookedSlot['date'] == selectedDateStr) {
        var startParts = bookedSlot['start_time']!.split(':');
        var endParts = bookedSlot['end_time']!.split(':');

        int startMinutes =
            int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        int endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

        if (timeMinutes >= startMinutes && timeMinutes < endMinutes) {
          return true;
        }
      }
    }

    return false;
  }

  // Get list of booked times for the selected date
  List<Map<String, String>> _getBookedTimesForSelectedDate() {
    if (_selectedDate == null) return [];

    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

    return bookedSlots.where((slot) => slot['date'] == selectedDateStr).map((
      slot,
    ) {
      final name = slot['owner_name'] ?? 'No Name';
      final startTime = slot['start_time']!.substring(0, 5);
      final endTime = slot['end_time']!.substring(0, 5);

      return {'name': name, 'time': '$startTime - $endTime'};
    }).toList();
  }

  // Count booked slots for a specific date
  int _countBookedSlotsForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return bookedSlots.where((slot) => slot['date'] == dateStr).length;
  }

  void _toggleCalendar() {
    if (!_isValidVehicleId(widget.vehicleId)) {
      Get.snackbar(
        'Error',
        'Please select a vehicle before choosing a date',
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    setState(() {
      _isCalendarVisible = !_isCalendarVisible;
    });
    widget.onTextFieldTap();
  }

  void _onDateSelected(DateTime selectedDate) {
    setState(() {
      _selectedDate = selectedDate;
      _isCalendarVisible = false;
      _selectedStartTime = null;
      _selectedEndTime = null;
    });

    final formattedDate = DateFormat('MMM dd, yyyy').format(selectedDate);
    _internalController.text = 'Selected: $formattedDate';
    widget.onChanged('date_selected');
  }

  Future<void> _showCustomTimePicker(bool isStartTime) async {
    DateTime initialTime = DateTime.now();
    if (isStartTime && _selectedStartTime != null) {
      initialTime = DateTime(
        2023,
        1,
        1,
        _selectedStartTime!.hour,
        _selectedStartTime!.minute,
      );
    } else if (!isStartTime && _selectedEndTime != null) {
      initialTime = DateTime(
        2023,
        1,
        1,
        _selectedEndTime!.hour,
        _selectedEndTime!.minute,
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        DateTime tempTime = initialTime;
        return AlertDialog(
          title: Text(isStartTime ? 'Select Start Time' : 'Select End Time'),
          content: SizedBox(
            height: 200,
            child: TimePickerSpinner(
              time: initialTime,
              is24HourMode: false,
              itemHeight: 40,
              normalTextStyle: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              highlightedTextStyle: const TextStyle(
                fontSize: 18,
                color: AppColors.colorsBlue,
              ),
              spacing: 20,
              itemWidth: 60,
              onTimeChange: (time) {
                tempTime = time;
              },
              isForce2Digits: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_isTimeDisabled(tempTime)) {
                  Get.snackbar(
                    'Time Not Available',
                    'This time slot is already booked',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }

                final selectedTime = TimeOfDay.fromDateTime(tempTime);

                if (isStartTime) {
                  setState(() {
                    _selectedStartTime = selectedTime;
                    if (_selectedEndTime != null) {
                      int startMinutes =
                          selectedTime.hour * 60 + selectedTime.minute;
                      int endMinutes =
                          _selectedEndTime!.hour * 60 +
                          _selectedEndTime!.minute;
                      if (endMinutes <= startMinutes) {
                        _selectedEndTime = null;
                      }
                    }
                  });
                  // Clear start time error immediately when start time is selected
                  widget.onChanged('clear_start_time_error');
                } else {
                  if (_selectedStartTime != null) {
                    int startMinutes =
                        _selectedStartTime!.hour * 60 +
                        _selectedStartTime!.minute;
                    int endMinutes =
                        selectedTime.hour * 60 + selectedTime.minute;

                    if (endMinutes <= startMinutes) {
                      Get.snackbar(
                        'Invalid Time',
                        'End time must be after start time',
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                      );
                      return;
                    }

                    setState(() {
                      _selectedEndTime = selectedTime;
                    });
                    // Clear end time error immediately when end time is selected
                    widget.onChanged('clear_end_time_error');
                    _updateDisplayText();
                  }
                }

                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _updateDisplayText() {
    if (_selectedDate != null &&
        _selectedStartTime != null &&
        _selectedEndTime != null) {
      final formattedDate = DateFormat('MMM dd, yyyy').format(_selectedDate!);
      final startTimeStr = _selectedStartTime!.format(context);
      final endTimeStr = _selectedEndTime!.format(context);

      final displayText = '$startTimeStr - $endTimeStr on $formattedDate';
      _internalController.text = displayText;

      final slotData = {
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'start_time_slot': _timeToString(_selectedStartTime!),
        'end_time_slot': _timeToString(_selectedEndTime!),
        'display_text': displayText,
      };

      widget.onChanged(jsonEncode(slotData));
    }
  }

  Map<String, dynamic>? get selectedSlotData {
    if (_selectedDate != null &&
        _selectedStartTime != null &&
        _selectedEndTime != null) {
      return {
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'start_time_slot': _timeToString(_selectedStartTime!),
        'end_time_slot': _timeToString(_selectedEndTime!),
        'display_text': _internalController.text,
      };
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              children: [
                TextSpan(text: widget.label),
                if (widget.isRequired)
                  const TextSpan(
                    text: " *",
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),

        GestureDetector(
          onTap: _toggleCalendar,
          child: Container(
            height: 45,
            width: double.infinity,
            decoration: BoxDecoration(
              border: widget.errorText != null
                  ? Border.all(color: Colors.red, width: 1.0)
                  : Border.all(color: Colors.grey.shade300, width: 1.0),
              borderRadius: BorderRadius.circular(8),
              color: const Color.fromARGB(255, 248, 247, 247),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _internalController.text.isEmpty
                        ? "Select Date & Time"
                        : _internalController.text,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _internalController.text.isEmpty
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoadingSlots)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      _isCalendarVisible
                          ? Icons.keyboard_arrow_up
                          : Icons.calendar_month_outlined,
                      color: AppColors.fontColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Show error message if any
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Failed to load booking data',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // Calendar Widget
        if (_isCalendarVisible)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: CalenderWidget(
              onDateSelected: _onDateSelected,
              selectedDate: _selectedDate,
              bookedSlots: bookedSlots,
            ),
          ),

        // Time Picker Section - Show when date is selected
        if (_selectedDate != null) ...[
          const SizedBox(height: 15),
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.fontBlack,
              ),
              children: [
                TextSpan(text: 'Select Time'),
                if (widget.isRequired)
                  const TextSpan(
                    text: " *",
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Start Time Container
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCustomTimePicker(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            widget.startTimeError != null &&
                                _selectedStartTime == null
                            ? Colors.red
                            : Colors.grey.shade300,
                        width:
                            widget.startTimeError != null &&
                                _selectedStartTime == null
                            ? 1.5
                            : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedStartTime != null
                              ? _selectedStartTime!.format(context)
                              : 'Start Time',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _selectedStartTime != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                        const Icon(Icons.access_time, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // End Time Container
              Expanded(
                child: GestureDetector(
                  onTap: () => _showCustomTimePicker(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color:
                            widget.endTimeError != null &&
                                _selectedEndTime == null
                            ? Colors.red
                            : Colors.grey.shade300,
                        width:
                            widget.endTimeError != null &&
                                _selectedEndTime == null
                            ? 1.5
                            : 1.0,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedEndTime != null
                              ? _selectedEndTime!.format(context)
                              : 'End Time',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _selectedEndTime != null
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                        const Icon(Icons.access_time, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Show booked times for selected date
          if (_getBookedTimesForSelectedDate().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Booked times for this date:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _getBookedTimesForSelectedDate().map((slot) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        slot['time']!,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      textAlign: TextAlign.start,
                      slot['name']!,
                      style: AppFont.smallText12(context),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      ],
    );
  }
}

class CalenderWidget extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final DateTime? selectedDate;
  final List<Map<String, String>> bookedSlots;

  const CalenderWidget({
    super.key,
    required this.onDateSelected,
    this.selectedDate,
    required this.bookedSlots,
  });

  @override
  State<CalenderWidget> createState() => _CalenderWidgetState();
}

class _CalenderWidgetState extends State<CalenderWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.selectedDate;
  }

  List<Widget> _buildMarkers(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final count = widget.bookedSlots
        .where((slot) => slot['date'] == dateStr)
        .length;

    // Determine color based on slot count
    Color markerColor;
    if (count >= 3) {
      markerColor = Colors.red;
    } else if (count == 2) {
      markerColor = Colors.orange;
    } else if (count == 1) {
      markerColor = Colors.green;
    } else {
      markerColor = Colors.transparent;
    }

    // Always show only one circle indicator
    return [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(color: markerColor, shape: BoxShape.circle),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15),
      child: TableCalendar(
        firstDay: DateTime.now(),
        lastDay: DateTime.utc(2100, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          if (selectedDay.isBefore(
            DateTime.now().subtract(const Duration(days: 1)),
          )) {
            return;
          }

          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          widget.onDateSelected(selectedDay);
        },
        calendarStyle: CalendarStyle(
          isTodayHighlighted: true,
          selectedDecoration: const BoxDecoration(
            color: AppColors.colorsBlue,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.colorsBlue, width: 1),
            color: AppColors.colorsBlue.withOpacity(0.1),
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.colorsBlue,
            fontWeight: FontWeight.bold,
          ),
          disabledDecoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
          ),
          disabledTextStyle: TextStyle(color: Colors.grey.shade400),
          outsideDaysVisible: false,
          markersAlignment: Alignment.bottomCenter,
          markerSizeScale: 0.1,
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        enabledDayPredicate: (day) {
          return !day.isBefore(
            DateTime.now().subtract(const Duration(days: 1)),
          );
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, date, events) {
            final markers = _buildMarkers(date);
            if (markers.isEmpty) return null;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: markers,
            );
          },
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:smartassist/config/component/color/colors.dart';
// import 'package:smartassist/config/component/font/font.dart';
// import 'package:smartassist/utils/storage.dart';
// import 'dart:convert';
// import 'package:table_calendar/table_calendar.dart';
// import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

// class SlotCalendar extends StatefulWidget {
//   final String label;
//   final bool isRequired;
//   final ValueChanged<String> onChanged;
//   final String? errorText;
//   final VoidCallback onTextFieldTap;
//   final String vehicleId;
//   final TextEditingController? controller;
//   final String? startTimeError;
//   final String? endTimeError;

//   const SlotCalendar({
//     super.key,
//     required this.label,
//     this.isRequired = false,
//     required this.onChanged,
//     this.errorText,
//     required this.onTextFieldTap,
//     required this.vehicleId,
//     this.controller,
//     this.startTimeError,
//     this.endTimeError,
//   });

//   @override
//   State<SlotCalendar> createState() => _SlotCalendarState();
// }

// class _SlotCalendarState extends State<SlotCalendar> {
//   DateTime? _selectedDate;
//   TimeOfDay? _selectedStartTime;
//   TimeOfDay? _selectedEndTime;
//   List<Map<String, String>> bookedSlots = [];
//   bool _isCalendarVisible = false;
//   late TextEditingController _internalController;
//   bool _isLoadingSlots = false;
//   String? _errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     _internalController = widget.controller ?? TextEditingController();
//     // Only fetch if vehicleId is valid
//     if (_isValidVehicleId(widget.vehicleId)) {
//       _fetchBookedSlots();
//     }
//     print('Initial vehicleId: ${widget.vehicleId}');
//   }

//   @override
//   void didUpdateWidget(SlotCalendar oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // Fetch slots if vehicleId changes and is valid
//     if (widget.vehicleId != oldWidget.vehicleId) {
//       print(
//         'vehicleId changed from: ${oldWidget.vehicleId} to: ${widget.vehicleId}',
//       );

//       if (_isValidVehicleId(widget.vehicleId)) {
//         _fetchBookedSlots();
//       } else {
//         // Clear booked slots if vehicleId becomes invalid
//         setState(() {
//           bookedSlots.clear();
//           _selectedDate = null;
//           _selectedStartTime = null;
//           _selectedEndTime = null;
//           _internalController.clear();
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     if (widget.controller == null) {
//       _internalController.dispose();
//     }
//     super.dispose();
//   }

//   // Helper method to check if vehicleId is valid
//   bool _isValidVehicleId(String vehicleId) {
//     return vehicleId.isNotEmpty &&
//         vehicleId != "null" &&
//         vehicleId != "NULL" &&
//         vehicleId.toLowerCase() != "null";
//   }

//   Future<void> _fetchBookedSlots() async {
//     if (!_isValidVehicleId(widget.vehicleId)) {
//       print('Invalid vehicleId, skipping API call: ${widget.vehicleId}');
//       return;
//     }

//     setState(() {
//       _isLoadingSlots = true;
//       _errorMessage = null;
//     });

//     final token = await Storage.getToken();

//     try {
//       final url =
//           'https://api.smartassistapp.in/api/slots/${widget.vehicleId}/slots/all';
//       print('Fetching booked slots from: $url');

//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//         },
//       );

//       print('Response status code: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);

//         // Check if data structure is as expected
//         if (data != null && data['data'] != null) {
//           setState(() {
//             bookedSlots = List<Map<String, String>>.from(
//               data['data'].map(
//                 (slot) => {
//                   'start_time': slot['start_time_slot']?.toString() ?? '',
//                   'end_time': slot['end_time_slot']?.toString() ?? '',
//                   'date': slot['date_of_booking']?.toString() ?? '',
//                   'owner_name': slot['owner_name']?.toString() ?? 'No Name',
//                 },
//               ),
//             );
//             _isLoadingSlots = false;
//           });
//           print('Successfully loaded ${bookedSlots.length} booked slots');
//         } else {
//           throw Exception('Invalid response structure');
//         }
//       } else {
//         // Handle different HTTP status codes
//         String errorMessage;
//         switch (response.statusCode) {
//           case 404:
//             errorMessage = 'Vehicle not found';
//             break;
//           case 401:
//             errorMessage = 'Unauthorized access';
//             break;
//           case 500:
//             errorMessage = 'Server error';
//             break;
//           default:
//             errorMessage =
//                 'Failed to load booked slots (${response.statusCode})';
//         }
//         throw Exception(errorMessage);
//       }
//     } catch (e) {
//       print('Error fetching booked slots: $e');
//       setState(() {
//         _errorMessage = e.toString();
//         _isLoadingSlots = false;
//         // Don't clear existing slots on error, just show error
//       });

//       // Show error snackbar
//       if (mounted) {
//         // Get.snackbar(
//         //   'Error',
//         //   'Failed to load booking data: ${e.toString()}',
//         //   duration: const Duration(seconds: 3),
//         //   snackPosition: SnackPosition.TOP,
//         //   backgroundColor: Colors.red,
//         //   colorText: Colors.white,
//         // );
//       }
//     }
//   }

//   // Convert TimeOfDay to string format (HH:mm:ss)
//   String _timeToString(TimeOfDay time) {
//     return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
//   }

//   // Get disabled hours and minutes for time picker
//   Set<int> _getDisabledHours() {
//     if (_selectedDate == null) return {};

//     final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
//     Set<int> disabledHours = {};

//     for (var bookedSlot in bookedSlots) {
//       if (bookedSlot['date'] == selectedDateStr) {
//         var startParts = bookedSlot['start_time']!.split(':');
//         var endParts = bookedSlot['end_time']!.split(':');

//         int startHour = int.parse(startParts[0]);
//         int endHour = int.parse(endParts[0]);

//         // Add all hours in the booked range
//         for (int hour = startHour; hour <= endHour; hour++) {
//           disabledHours.add(hour);
//         }
//       }
//     }

//     return disabledHours;
//   }

//   // Check if specific time is disabled
//   bool _isTimeDisabled(DateTime time) {
//     if (_selectedDate == null) return false;

//     final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
//     final timeMinutes = time.hour * 60 + time.minute;

//     for (var bookedSlot in bookedSlots) {
//       if (bookedSlot['date'] == selectedDateStr) {
//         var startParts = bookedSlot['start_time']!.split(':');
//         var endParts = bookedSlot['end_time']!.split(':');

//         int startMinutes =
//             int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
//         int endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

//         if (timeMinutes >= startMinutes && timeMinutes < endMinutes) {
//           return true;
//         }
//       }
//     }

//     return false;
//   }

//   // Get list of booked times for the selected date
//   List<Map<String, String>> _getBookedTimesForSelectedDate() {
//     if (_selectedDate == null) return [];

//     final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

//     return bookedSlots.where((slot) => slot['date'] == selectedDateStr).map((
//       slot,
//     ) {
//       final name = slot['owner_name'] ?? 'No Name';
//       final startTime = slot['start_time']!.substring(0, 5);
//       final endTime = slot['end_time']!.substring(0, 5);

//       return {'name': name, 'time': '$startTime - $endTime'};
//     }).toList();
//   }

//   // Count booked slots for a specific date
//   int _countBookedSlotsForDate(DateTime date) {
//     final dateStr = DateFormat('yyyy-MM-dd').format(date);
//     return bookedSlots.where((slot) => slot['date'] == dateStr).length;
//   }

//   void _toggleCalendar() {
//     if (!_isValidVehicleId(widget.vehicleId)) {
//       Get.snackbar(
//         'Error',
//         'Please select a vehicle before choosing a date',
//         duration: const Duration(seconds: 3),
//         snackPosition: SnackPosition.TOP,
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//       );
//       return;
//     }
//     setState(() {
//       _isCalendarVisible = !_isCalendarVisible;
//     });
//     widget.onTextFieldTap();
//   }

//   void _onDateSelected(DateTime selectedDate) {
//     setState(() {
//       _selectedDate = selectedDate;
//       _isCalendarVisible = false;
//       _selectedStartTime = null;
//       _selectedEndTime = null;
//     });

//     final formattedDate = DateFormat('MMM dd, yyyy').format(selectedDate);
//     _internalController.text = 'Selected: $formattedDate';
//     // widget.onChanged('Selected: $formattedDate');
//     widget.onChanged('date_selected');
//   }

//   Future<void> _showCustomTimePicker(bool isStartTime) async {
//     DateTime initialTime = DateTime.now();
//     if (isStartTime && _selectedStartTime != null) {
//       initialTime = DateTime(
//         2023,
//         1,
//         1,
//         _selectedStartTime!.hour,
//         _selectedStartTime!.minute,
//       );
//     } else if (!isStartTime && _selectedEndTime != null) {
//       initialTime = DateTime(
//         2023,
//         1,
//         1,
//         _selectedEndTime!.hour,
//         _selectedEndTime!.minute,
//       );
//     }

//     // if (isStartTime) {
//     //   // Clear start time error when user starts selecting start time
//     //   widget.onChanged('clear_start_time_error');
//     // } else {
//     //   // Clear end time error when user starts selecting end time
//     //   widget.onChanged('clear_end_time_error');
//     // }

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         DateTime tempTime = initialTime;
//         return AlertDialog(
//           title: Text(isStartTime ? 'Select Start Time' : 'Select End Time'),
//           content: SizedBox(
//             height: 200,
//             child: TimePickerSpinner(
//               time: initialTime,
//               is24HourMode: false,
//               itemHeight: 40,
//               normalTextStyle: const TextStyle(
//                 fontSize: 16,
//                 color: Colors.black54,
//               ),
//               highlightedTextStyle: const TextStyle(
//                 fontSize: 18,
//                 color: AppColors.colorsBlue,
//               ),
//               spacing: 20,
//               itemWidth: 60,
//               onTimeChange: (time) {
//                 tempTime = time;
//               },
//               isForce2Digits: true,
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () {
//                 if (_isTimeDisabled(tempTime)) {
//                   Get.snackbar(
//                     'Time Not Available',
//                     'This time slot is already booked',
//                     backgroundColor: Colors.red,
//                     colorText: Colors.white,
//                   );
//                   return;
//                 }

//                 final selectedTime = TimeOfDay.fromDateTime(tempTime);

//                 if (isStartTime) {
//                   setState(() {
//                     _selectedStartTime = selectedTime;
//                     if (_selectedEndTime != null) {
//                       int startMinutes =
//                           selectedTime.hour * 60 + selectedTime.minute;
//                       int endMinutes =
//                           _selectedEndTime!.hour * 60 +
//                           _selectedEndTime!.minute;
//                       if (endMinutes <= startMinutes) {
//                         _selectedEndTime = null;
//                       }
//                     }
//                   });
//                   // ONLY clear start time error when start time is actually selected:
//                   widget.onChanged('clear_start_time_error');
//                 } else {
//                   if (_selectedStartTime != null) {
//                     int startMinutes =
//                         _selectedStartTime!.hour * 60 +
//                         _selectedStartTime!.minute;
//                     int endMinutes =
//                         selectedTime.hour * 60 + selectedTime.minute;

//                     if (endMinutes <= startMinutes) {
//                       Get.snackbar(
//                         'Invalid Time',
//                         'End time must be after start time',
//                         backgroundColor: Colors.red,
//                         colorText: Colors.white,
//                       );
//                       return;
//                     }

//                     setState(() {
//                       _selectedEndTime = selectedTime;
//                     });
//                     // ONLY clear end time error when end time is actually selected:
//                     widget.onChanged('clear_end_time_error');
//                     _updateDisplayText();
//                   }
//                 }

//                 Navigator.of(context).pop();
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _updateDisplayText() {
//     if (_selectedDate != null &&
//         _selectedStartTime != null &&
//         _selectedEndTime != null) {
//       final formattedDate = DateFormat('MMM dd, yyyy').format(_selectedDate!);
//       final startTimeStr = _selectedStartTime!.format(context);
//       final endTimeStr = _selectedEndTime!.format(context);

//       final displayText = '$startTimeStr - $endTimeStr on $formattedDate';
//       _internalController.text = displayText;

//       final slotData = {
//         'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
//         'start_time_slot': _timeToString(_selectedStartTime!),
//         'end_time_slot': _timeToString(_selectedEndTime!),
//         'display_text': displayText,
//       };

//       widget.onChanged(jsonEncode(slotData));
//     }
//   }

//   Map<String, dynamic>? get selectedSlotData {
//     if (_selectedDate != null &&
//         _selectedStartTime != null &&
//         _selectedEndTime != null) {
//       return {
//         'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
//         'start_time_slot': _timeToString(_selectedStartTime!),
//         'end_time_slot': _timeToString(_selectedEndTime!),
//         'display_text': _internalController.text,
//       };
//     }
//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
//           child: RichText(
//             text: TextSpan(
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black,
//               ),
//               children: [
//                 TextSpan(text: widget.label),
//                 if (widget.isRequired)
//                   const TextSpan(
//                     text: " *",
//                     style: TextStyle(color: Colors.red),
//                   ),
//               ],
//             ),
//           ),
//         ),

//         GestureDetector(
//           onTap: _toggleCalendar,
//           child: Container(
//             height: 45,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               border: widget.errorText != null
//                   ? Border.all(color: Colors.red, width: 1.0)
//                   : Border.all(color: Colors.grey.shade300, width: 1.0),
//               borderRadius: BorderRadius.circular(8),
//               color: const Color.fromARGB(255, 248, 247, 247),
//             ),
//             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Text(
//                     _internalController.text.isEmpty
//                         ? "Select Date & Time"
//                         : _internalController.text,
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                       color: _internalController.text.isEmpty
//                           ? Colors.grey
//                           : Colors.black,
//                     ),
//                   ),
//                 ),
//                 Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     if (_isLoadingSlots)
//                       const SizedBox(
//                         width: 16,
//                         height: 16,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                     const SizedBox(width: 8),
//                     Icon(
//                       _isCalendarVisible
//                           ? Icons.keyboard_arrow_up
//                           : Icons.calendar_month_outlined,
//                       color: AppColors.fontColor,
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),

//         // Show error message if any
//         if (_errorMessage != null)
//           Padding(
//             padding: const EdgeInsets.only(top: 4.0),
//             child: Text(
//               'Failed to load booking data',
//               style: TextStyle(
//                 color: Colors.orange,
//                 fontSize: 12,
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//           ),

//         // Calendar Widget
//         if (_isCalendarVisible)
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             child: CalenderWidget(
//               onDateSelected: _onDateSelected,
//               selectedDate: _selectedDate,
//               bookedSlots: bookedSlots,
//             ),
//           ),

//         // Time Picker Section - Show when date is selected
//         if (_selectedDate != null) ...[
//           const SizedBox(height: 15),
//           // Text('Select Time', style: AppFont.dropDowmLabel(context)),
//           RichText(
//             text: TextSpan(
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.fontBlack,
//               ),
//               children: [
//                 TextSpan(text: 'Select Time'),
//                 if (widget.isRequired)
//                   const TextSpan(
//                     text: " *",
//                     style: TextStyle(color: Colors.red),
//                   ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Row(
//             children: [
//               // Start Time Container
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     GestureDetector(
//                       onTap: () => _showCustomTimePicker(true),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           vertical: 12,
//                           horizontal: 16,
//                         ),
//                         decoration: BoxDecoration(
//                           border: Border.all(
//                             color: widget.startTimeError != null
//                                 ? Colors.red
//                                 : Colors.grey.shade300,
//                             width: widget.startTimeError != null ? 1.5 : 1.0,
//                           ),
//                           borderRadius: BorderRadius.circular(8),
//                           color: Colors.white,
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               _selectedStartTime != null
//                                   ? _selectedStartTime!.format(context)
//                                   : 'Start Time',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 14,
//                                 color: _selectedStartTime != null
//                                     ? Colors.black
//                                     : Colors.grey,
//                               ),
//                             ),
//                             const Icon(Icons.access_time, color: Colors.grey),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 10),
//               // End Time Container
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     GestureDetector(
//                       onTap: () => _showCustomTimePicker(false),
//                       child: Container(
//                         padding: const EdgeInsets.symmetric(
//                           vertical: 12,
//                           horizontal: 16,
//                         ),
//                         decoration: BoxDecoration(
//                           border: Border.all(
//                             color: widget.endTimeError != null
//                                 ? Colors.red
//                                 : Colors.grey.shade300,
//                             width: widget.endTimeError != null ? 1.5 : 1.0,
//                           ),
//                           borderRadius: BorderRadius.circular(8),
//                           color: Colors.white,
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               _selectedEndTime != null
//                                   ? _selectedEndTime!.format(context)
//                                   : 'End Time',
//                               style: GoogleFonts.poppins(
//                                 fontSize: 14,
//                                 color: _selectedEndTime != null
//                                     ? Colors.black
//                                     : Colors.grey,
//                               ),
//                             ),
//                             const Icon(Icons.access_time, color: Colors.grey),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           // Show booked times for selected date
//           if (_getBookedTimesForSelectedDate().isNotEmpty) ...[
//             const SizedBox(height: 8),
//             Text(
//               'Booked times for this date:',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.red.shade700,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 4),

//             // Wrap(
//             //   spacing: 8.0,
//             //   runSpacing: 4.0,
//             //   children: _getBookedTimesForSelectedDate().map((timeSlot) {
//             //     return Row(
//             //       children: [
//             //         Container(
//             //           padding: const EdgeInsets.symmetric(
//             //             horizontal: 8,
//             //             vertical: 4,
//             //           ),
//             //           decoration: BoxDecoration(
//             //             color: Colors.red.shade50,
//             //             border: Border.all(color: Colors.red.shade200),
//             //             borderRadius: BorderRadius.circular(12),
//             //           ),
//             //           child: Text(
//             //             timeSlot,
//             //             style: TextStyle(fontSize: 11, color: Colors.red.shade700),
//             //           ),
//             //         ),
//             //         Text(''),
//             //       ],
//             //     );
//             //   }).toList(),
//             // ),
//             Wrap(
//               spacing: 8.0,
//               runSpacing: 4.0,
//               children: _getBookedTimesForSelectedDate().map((slot) {
//                 return Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   // mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: Colors.red.shade50,
//                         border: Border.all(color: Colors.red.shade200),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         slot['time']!,
//                         style: GoogleFonts.poppins(
//                           fontSize: 11,
//                           color: Colors.red.shade700,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 3),
//                     Text(
//                       textAlign: TextAlign.start,
//                       slot['name']!,
//                       style: AppFont.smallText12(context),
//                     ),
//                   ],
//                 );
//               }).toList(),
//             ),
//           ],
//         ],

//         // if (widget.errorText != null)
//         //   Padding(
//         //     padding: const EdgeInsets.only(top: 8.0),
//         //     child: Text(
//         //       widget.errorText!,
//         //       style: const TextStyle(color: Colors.red, fontSize: 12),
//         //     ),
//         //   ),
//       ],
//     );
//   }
// }

// class CalenderWidget extends StatefulWidget {
//   final Function(DateTime) onDateSelected;
//   final DateTime? selectedDate;
//   final List<Map<String, String>> bookedSlots;

//   const CalenderWidget({
//     super.key,
//     required this.onDateSelected,
//     this.selectedDate,
//     required this.bookedSlots,
//   });

//   @override
//   State<CalenderWidget> createState() => _CalenderWidgetState();
// }

// class _CalenderWidgetState extends State<CalenderWidget> {
//   DateTime _focusedDay = DateTime.now();
//   DateTime? _selectedDay;

//   @override
//   void initState() {
//     super.initState();
//     _selectedDay = widget.selectedDate;
//   }

//   // Count booked slots for a specific date

//   List<Widget> _buildMarkers(DateTime day) {
//     final dateStr = DateFormat('yyyy-MM-dd').format(day);
//     final count = widget.bookedSlots
//         .where((slot) => slot['date'] == dateStr)
//         .length;

//     // Determine color based on slot count
//     Color markerColor;
//     if (count >= 3) {
//       markerColor = Colors.red;
//     } else if (count == 2) {
//       markerColor = Colors.orange;
//     } else if (count == 1) {
//       markerColor = Colors.green;
//     } else {
//       markerColor = Colors.transparent;
//     }

//     // Always show only one circle indicator
//     return [
//       Container(
//         width: 6,
//         height: 6,
//         decoration: BoxDecoration(color: markerColor, shape: BoxShape.circle),
//       ),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.only(top: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 5,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15),
//       child: TableCalendar(
//         firstDay: DateTime.now(), // Prevent selecting past dates
//         lastDay: DateTime.utc(2100, 12, 31),
//         focusedDay: _focusedDay,
//         selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//         onDaySelected: (selectedDay, focusedDay) {
//           // Prevent selecting past dates
//           if (selectedDay.isBefore(
//             DateTime.now().subtract(const Duration(days: 1)),
//           )) {
//             return;
//           }

//           setState(() {
//             _selectedDay = selectedDay;
//             _focusedDay = focusedDay;
//           });
//           widget.onDateSelected(selectedDay);
//         },
//         calendarStyle: CalendarStyle(
//           isTodayHighlighted: true,
//           selectedDecoration: const BoxDecoration(
//             color: AppColors.colorsBlue,
//             shape: BoxShape.circle,
//           ),
//           todayDecoration: BoxDecoration(
//             shape: BoxShape.circle,
//             border: Border.all(color: AppColors.colorsBlue, width: 1),
//             color: AppColors.colorsBlue.withOpacity(0.1),
//           ),
//           todayTextStyle: const TextStyle(
//             color: AppColors.colorsBlue,
//             fontWeight: FontWeight.bold,
//           ),
//           disabledDecoration: BoxDecoration(
//             shape: BoxShape.circle,
//             color: Colors.grey.shade200,
//           ),
//           disabledTextStyle: TextStyle(color: Colors.grey.shade400),
//           outsideDaysVisible: false,
//           markersAlignment: Alignment.bottomCenter, // Align dots at the bottom
//           markerSizeScale: 0.1,
//         ),
//         headerStyle: const HeaderStyle(
//           formatButtonVisible: false,
//           titleCentered: true,
//           titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         enabledDayPredicate: (day) {
//           // Disable past dates
//           return !day.isBefore(
//             DateTime.now().subtract(const Duration(days: 1)),
//           );
//         },
//         calendarBuilders: CalendarBuilders(
//           markerBuilder: (context, date, events) {
//             final markers = _buildMarkers(date);
//             if (markers.isEmpty) return null;
//             return Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: markers,
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';
// // import 'package:get/get.dart';
// // import 'package:google_fonts/google_fonts.dart';
// // import 'package:http/http.dart' as http;
// // import 'package:intl/intl.dart';
// // import 'package:smartassist/config/component/color/colors.dart';
// // import 'package:smartassist/config/component/font/font.dart';
// // import 'package:smartassist/utils/storage.dart';
// // import 'dart:convert';
// // import 'package:table_calendar/table_calendar.dart';

// // class SlotCalendar extends StatefulWidget {
// //   final String label;
// //   final bool isRequired;
// //   final ValueChanged<String> onChanged;
// //   final String? errorText;
// //   final VoidCallback onTextFieldTap;
// //   final String vehicleId;
// //   final TextEditingController? controller;

// //   const SlotCalendar({
// //     super.key,
// //     required this.label,
// //     this.isRequired = false,
// //     required this.onChanged,
// //     this.errorText,
// //     required this.onTextFieldTap,
// //     required this.vehicleId,
// //     this.controller,
// //   });

// //   @override
// //   State<SlotCalendar> createState() => _SlotCalendarState();
// // }

// // class _SlotCalendarState extends State<SlotCalendar> {
// //   DateTime? _selectedDate;
// //   Map<String, String>? _selectedSlot;
// //   List<Map<String, String>> bookedSlots = [];
// //   bool _isCalendarVisible = false;
// //   late TextEditingController _internalController;
// //   bool _isLoadingSlots = false;
// //   String? _errorMessage;

// //   // Static time slots
// //   final List<Map<String, String>> staticSlots = [
// //     {
// //       'display': '10:00 AM - 12:00 PM',
// //       'start_time': '10:00:00',
// //       'end_time': '12:00:00',
// //     },
// //     {
// //       'display': '1:00 PM - 3:00 PM',
// //       'start_time': '13:00:00',
// //       'end_time': '15:00:00',
// //     },
// //     {
// //       'display': '5:00 PM - 7:00 PM',
// //       'start_time': '17:00:00',
// //       'end_time': '19:00:00',
// //     },
// //   ];

// //   @override
// //   void initState() {
// //     super.initState();
// //     _internalController = widget.controller ?? TextEditingController();
// //     // Only fetch if vehicleId is valid
// //     if (_isValidVehicleId(widget.vehicleId)) {
// //       _fetchBookedSlots();
// //     }
// //     print('Initial vehicleId: ${widget.vehicleId}');
// //   }

// //   @override
// //   void didUpdateWidget(SlotCalendar oldWidget) {
// //     super.didUpdateWidget(oldWidget);
// //     // Fetch slots if vehicleId changes and is valid
// //     if (widget.vehicleId != oldWidget.vehicleId) {
// //       print(
// //         'vehicleId changed from: ${oldWidget.vehicleId} to: ${widget.vehicleId}',
// //       );

// //       if (_isValidVehicleId(widget.vehicleId)) {
// //         _fetchBookedSlots();
// //       } else {
// //         // Clear booked slots if vehicleId becomes invalid
// //         setState(() {
// //           bookedSlots.clear();
// //           _selectedDate = null;
// //           _selectedSlot = null;
// //           _internalController.clear();
// //         });
// //       }
// //     }
// //   }

// //   @override
// //   void dispose() {
// //     if (widget.controller == null) {
// //       _internalController.dispose();
// //     }
// //     super.dispose();
// //   }

// //   // Helper method to check if vehicleId is valid
// //   bool _isValidVehicleId(String vehicleId) {
// //     return vehicleId.isNotEmpty &&
// //         vehicleId != "null" &&
// //         vehicleId != "NULL" &&
// //         vehicleId.toLowerCase() != "null";
// //   }

// //   Future<void> _fetchBookedSlots() async {
// //     if (!_isValidVehicleId(widget.vehicleId)) {
// //       print('Invalid vehicleId, skipping API call: ${widget.vehicleId}');
// //       return;
// //     }

// //     setState(() {
// //       _isLoadingSlots = true;
// //       _errorMessage = null;
// //     });

// //     final token = await Storage.getToken();

// //     try {
// //       final url =
// //           'https://api.smartassistapp.in/api/slots/${widget.vehicleId}/slots/all';
// //       print('Fetching booked slots from: $url');

// //       final response = await http.get(
// //         Uri.parse(url),
// //         headers: {
// //           'Authorization': 'Bearer $token',
// //           'Content-Type': 'application/json',
// //         },
// //       );

// //       print('Response status code: ${response.statusCode}');
// //       print('Response body: ${response.body}');

// //       if (response.statusCode == 200) {
// //         final data = jsonDecode(response.body);

// //         // Check if data structure is as expected
// //         if (data != null && data['data'] != null) {
// //           setState(() {
// //             bookedSlots = List<Map<String, String>>.from(
// //               data['data'].map(
// //                 (slot) => {
// //                   'start_time': slot['start_time_slot']?.toString() ?? '',
// //                   'end_time': slot['end_time_slot']?.toString() ?? '',
// //                   'date': slot['date_of_booking']?.toString() ?? '',
// //                 },
// //               ),
// //             );
// //             _isLoadingSlots = false;
// //           });
// //           print('Successfully loaded ${bookedSlots.length} booked slots');
// //         } else {
// //           throw Exception('Invalid response structure');
// //         }
// //       } else {
// //         // Handle different HTTP status codes
// //         String errorMessage;
// //         switch (response.statusCode) {
// //           case 404:
// //             errorMessage = 'Vehicle not found';
// //             break;
// //           case 401:
// //             errorMessage = 'Unauthorized access';
// //             break;
// //           case 500:
// //             errorMessage = 'Server error';
// //             break;
// //           default:
// //             errorMessage =
// //                 'Failed to load booked slots (${response.statusCode})';
// //         }
// //         throw Exception(errorMessage);
// //       }
// //     } catch (e) {
// //       print('Error fetching booked slots: $e');
// //       setState(() {
// //         _errorMessage = e.toString();
// //         _isLoadingSlots = false;
// //         // Don't clear existing slots on error, just show error
// //       });

// //       // Show error snackbar
// //       if (mounted) {
// //         Get.snackbar(
// //           'Error',
// //           'Failed to load booking data: ${e.toString()}',
// //           duration: const Duration(seconds: 3),
// //           snackPosition: SnackPosition.TOP,
// //           backgroundColor: Colors.red,
// //           colorText: Colors.white,
// //         );
// //       }
// //     }
// //   }

// //   // Check if a slot is booked for the selected date
// //   bool _isSlotBooked(Map<String, String> slot) {
// //     if (_selectedDate == null) return false;

// //     final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

// //     return bookedSlots.any(
// //       (bookedSlot) =>
// //           bookedSlot['start_time'] == slot['start_time'] &&
// //           bookedSlot['end_time'] == slot['end_time'] &&
// //           bookedSlot['date'] == selectedDateStr,
// //     );
// //   }

// //   // Count booked slots for a specific date
// //   int _countBookedSlotsForDate(DateTime date) {
// //     final dateStr = DateFormat('yyyy-MM-dd').format(date);
// //     return bookedSlots.where((slot) => slot['date'] == dateStr).length;
// //   }

// //   void _toggleCalendar() {
// //     if (!_isValidVehicleId(widget.vehicleId)) {
// //       Get.snackbar(
// //         'Error',
// //         'Please select a vehicle before choosing a date',
// //         duration: const Duration(seconds: 3),
// //         snackPosition: SnackPosition.TOP,
// //         backgroundColor: Colors.red,
// //         colorText: Colors.white,
// //       );
// //       return;
// //     }
// //     setState(() {
// //       _isCalendarVisible = !_isCalendarVisible;
// //     });
// //     widget.onTextFieldTap();
// //   }

// //   void _onDateSelected(DateTime selectedDate) {
// //     setState(() {
// //       _selectedDate = selectedDate;
// //       _isCalendarVisible = false;
// //       _selectedSlot = null; // Reset slot selection when date changes
// //     });

// //     final formattedDate = DateFormat('MMM dd, yyyy').format(selectedDate);
// //     _internalController.text = 'Selected: $formattedDate';
// //     widget.onChanged('Selected: $formattedDate');
// //   }

// //   void _onSlotSelected(Map<String, String> slot) {
// //     if (_isSlotBooked(slot)) return;

// //     setState(() {
// //       _selectedSlot = slot;
// //     });

// //     if (_selectedDate != null) {
// //       final formattedDate = DateFormat('MMM dd, yyyy').format(_selectedDate!);
// //       final displayText = '${slot['display']} on $formattedDate';

// //       _internalController.text = displayText;

// //       final slotData = {
// //         'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
// //         'start_time_slot': slot['start_time'],
// //         'end_time_slot': slot['end_time'],
// //         'display_text': displayText,
// //       };

// //       widget.onChanged(jsonEncode(slotData));
// //     }
// //   }

// //   Map<String, dynamic>? get selectedSlotData {
// //     if (_selectedDate != null && _selectedSlot != null) {
// //       return {
// //         'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
// //         'start_time_slot': _selectedSlot!['start_time'],
// //         'end_time_slot': _selectedSlot!['end_time'],
// //         'display_text': _internalController.text,
// //       };
// //     }
// //     return null;
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Padding(
// //           padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
// //           child: RichText(
// //             text: TextSpan(
// //               style: GoogleFonts.poppins(
// //                 fontSize: 14,
// //                 fontWeight: FontWeight.w500,
// //                 color: Colors.black,
// //               ),
// //               children: [
// //                 TextSpan(text: widget.label),
// //                 if (widget.isRequired)
// //                   const TextSpan(
// //                     text: " *",
// //                     style: TextStyle(color: Colors.red),
// //                   ),
// //               ],
// //             ),
// //           ),
// //         ),

// //         GestureDetector(
// //           onTap: _toggleCalendar,
// //           child: Container(
// //             height: 45,
// //             width: double.infinity,
// //             decoration: BoxDecoration(
// //               border: widget.errorText != null
// //                   ? Border.all(color: Colors.red, width: 1.0)
// //                   : Border.all(color: Colors.grey.shade300, width: 1.0),
// //               borderRadius: BorderRadius.circular(8),
// //               color: const Color.fromARGB(255, 248, 247, 247),
// //             ),
// //             padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
// //             child: Row(
// //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
// //               children: [
// //                 Expanded(
// //                   child: Text(
// //                     _internalController.text.isEmpty
// //                         ? "Select Date & Slot"
// //                         : _internalController.text,
// //                     style: GoogleFonts.poppins(
// //                       fontSize: 14,
// //                       fontWeight: FontWeight.w500,
// //                       color: _internalController.text.isEmpty
// //                           ? Colors.grey
// //                           : Colors.black,
// //                     ),
// //                   ),
// //                 ),
// //                 Row(
// //                   mainAxisSize: MainAxisSize.min,
// //                   children: [
// //                     if (_isLoadingSlots)
// //                       const SizedBox(
// //                         width: 16,
// //                         height: 16,
// //                         child: CircularProgressIndicator(strokeWidth: 2),
// //                       ),
// //                     const SizedBox(width: 8),
// //                     Icon(
// //                       _isCalendarVisible
// //                           ? Icons.keyboard_arrow_up
// //                           : Icons.calendar_month_outlined,
// //                       color: AppColors.fontColor,
// //                     ),
// //                   ],
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ),
// //         // Show error message if any
// //         if (_errorMessage != null)
// //           Padding(
// //             padding: const EdgeInsets.only(top: 4.0),
// //             child: Text(
// //               'Failed to load booking data',
// //               style: TextStyle(
// //                 color: Colors.orange,
// //                 fontSize: 12,
// //                 fontStyle: FontStyle.italic,
// //               ),
// //             ),
// //           ),

// //         // Calendar Widget
// //         if (_isCalendarVisible)
// //           AnimatedContainer(
// //             duration: const Duration(milliseconds: 300),
// //             child: CalenderWidget(
// //               onDateSelected: _onDateSelected,
// //               selectedDate: _selectedDate,
// //               bookedSlots: bookedSlots,
// //             ),
// //           ),

// //         // Slot Selection - Show static slots when date is selected
// //         if (_selectedDate != null) ...[
// //           const SizedBox(height: 15),
// //           Text('Select Time Slot', style: AppFont.dropDowmLabel(context)),
// //           const SizedBox(height: 8),
// //           Wrap(
// //             spacing: 8.0,
// //             runSpacing: 8.0,
// //             children: staticSlots.map((slot) {
// //               final isSelected = _selectedSlot == slot;
// //               final isBooked = _isSlotBooked(slot);
// //               return InkWell(
// //                 onTap: isBooked ? null : () => _onSlotSelected(slot),
// //                 child: Container(
// //                   padding: const EdgeInsets.symmetric(
// //                     horizontal: 5,
// //                     vertical: 2,
// //                   ),
// //                   decoration: BoxDecoration(
// //                     border: Border.all(
// //                       color: isSelected
// //                           ? AppColors.colorsBlueButton
// //                           : AppColors.fontColor,
// //                       width: 0.5,
// //                     ),
// //                     borderRadius: BorderRadius.circular(15),
// //                     color: isSelected
// //                         ? AppColors.colorsBlue.withOpacity(0.2)
// //                         : AppColors.innerContainerBg,
// //                   ),
// //                   child: Text(
// //                     slot['display']!,
// //                     style: GoogleFonts.poppins(
// //                       color: isSelected
// //                           ? AppColors.colorsBlue
// //                           : AppColors.fontColor,
// //                       fontSize: 14,
// //                       fontWeight: FontWeight.w400,
// //                       decoration: isBooked ? TextDecoration.lineThrough : null,
// //                     ),
// //                   ),
// //                 ),
// //               );
// //             }).toList(),
// //           ),

// //           // Show booked slots info
// //           if (bookedSlots.isNotEmpty && _selectedDate != null) ...[
// //             const SizedBox(height: 8),
// //             Text(
// //               'Booked slots are disabled',
// //               style: TextStyle(
// //                 fontSize: 12,
// //                 color: Colors.grey.shade600,
// //                 fontStyle: FontStyle.italic,
// //               ),
// //             ),
// //           ],
// //         ],
// //         if (widget.errorText != null)
// //           Padding(
// //             padding: const EdgeInsets.only(top: 8.0),
// //             child: Text(
// //               widget.errorText!,
// //               style: const TextStyle(color: Colors.red, fontSize: 12),
// //             ),
// //           ),
// //       ],
// //     );
// //   }
// // }

// // class CalenderWidget extends StatefulWidget {
// //   final Function(DateTime) onDateSelected;
// //   final DateTime? selectedDate;
// //   final List<Map<String, String>> bookedSlots;

// //   const CalenderWidget({
// //     super.key,
// //     required this.onDateSelected,
// //     this.selectedDate,
// //     required this.bookedSlots,
// //   });

// //   @override
// //   State<CalenderWidget> createState() => _CalenderWidgetState();
// // }

// // class _CalenderWidgetState extends State<CalenderWidget> {
// //   DateTime _focusedDay = DateTime.now();
// //   DateTime? _selectedDay;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _selectedDay = widget.selectedDate;
// //   }

// //   // Count booked slots for a specific date
// //   List<Widget> _buildMarkers(DateTime day) {
// //     final dateStr = DateFormat('yyyy-MM-dd').format(day);
// //     final count = widget.bookedSlots
// //         .where((slot) => slot['date'] == dateStr)
// //         .length;

// //     // Return up to three dots based on the number of bookings
// //     return List.generate(
// //       count > 3 ? 3 : count,
// //       (index) => Container(
// //         width: 5,
// //         height: 5,
// //         margin: const EdgeInsets.symmetric(horizontal: 1),
// //         decoration: const BoxDecoration(
// //           color: Colors.red,
// //           shape: BoxShape.circle,
// //         ),
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Container(
// //       margin: const EdgeInsets.only(top: 8),
// //       decoration: BoxDecoration(
// //         color: Colors.white,
// //         borderRadius: BorderRadius.circular(12),
// //         boxShadow: [
// //           BoxShadow(
// //             color: Colors.grey.withOpacity(0.1),
// //             spreadRadius: 1,
// //             blurRadius: 5,
// //             offset: const Offset(0, 2),
// //           ),
// //         ],
// //       ),
// //       padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15),
// //       child: TableCalendar(
// //         firstDay: DateTime.now(), // Prevent selecting past dates
// //         lastDay: DateTime.utc(2100, 12, 31),
// //         focusedDay: _focusedDay,
// //         selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
// //         onDaySelected: (selectedDay, focusedDay) {
// //           // Prevent selecting past dates
// //           if (selectedDay.isBefore(
// //             DateTime.now().subtract(const Duration(days: 1)),
// //           )) {
// //             return;
// //           }

// //           setState(() {
// //             _selectedDay = selectedDay;
// //             _focusedDay = focusedDay;
// //           });
// //           widget.onDateSelected(selectedDay);
// //         },
// //         calendarStyle: CalendarStyle(
// //           isTodayHighlighted: true,
// //           selectedDecoration: const BoxDecoration(
// //             color: AppColors.colorsBlue,
// //             shape: BoxShape.circle,
// //           ),
// //           todayDecoration: BoxDecoration(
// //             shape: BoxShape.circle,
// //             border: Border.all(color: AppColors.colorsBlue, width: 1),
// //             color: AppColors.colorsBlue.withOpacity(0.1),
// //           ),
// //           todayTextStyle: const TextStyle(
// //             color: AppColors.colorsBlue,
// //             fontWeight: FontWeight.bold,
// //           ),
// //           disabledDecoration: BoxDecoration(
// //             shape: BoxShape.circle,
// //             color: Colors.grey.shade200,
// //           ),
// //           disabledTextStyle: TextStyle(color: Colors.grey.shade400),
// //           outsideDaysVisible: false,
// //           markersAlignment: Alignment.bottomCenter, // Align dots at the bottom
// //           markerSizeScale: 0.1,
// //         ),
// //         headerStyle: const HeaderStyle(
// //           formatButtonVisible: false,
// //           titleCentered: true,
// //           titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
// //         ),
// //         enabledDayPredicate: (day) {
// //           // Disable past dates
// //           return !day.isBefore(
// //             DateTime.now().subtract(const Duration(days: 1)),
// //           );
// //         },
// //         calendarBuilders: CalendarBuilders(
// //           markerBuilder: (context, date, events) {
// //             final markers = _buildMarkers(date);
// //             if (markers.isEmpty) return null;
// //             return Row(
// //               mainAxisAlignment: MainAxisAlignment.center,
// //               children: markers,
// //             );
// //           },
// //         ),
// //       ),
// //     );
// //   }
// // }
