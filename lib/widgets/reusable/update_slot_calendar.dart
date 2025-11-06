import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

class UpdateSlotCalendar extends StatefulWidget {
  final String label;
  final bool isRequired;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final VoidCallback onTextFieldTap;
  final String vehicleId;
  final TextEditingController? controller;
  final String? startTimeError;
  final String? endTimeError;
  final String? initialDate; // Add this
  final String? initialStartTime; // Add this
  final String? initialEndTime; // Add this

  const UpdateSlotCalendar({
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
    this.initialDate, // Add this
    this.initialStartTime, // Add this
    this.initialEndTime, // Add this
  });

  @override
  State<UpdateSlotCalendar> createState() => _UpdateSlotCalendarState();
}

class _UpdateSlotCalendarState extends State<UpdateSlotCalendar> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _isCalendarVisible = false;
  late TextEditingController _internalController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
    _initializeWithExistingData();
  }

  // Initialize with existing data
  void _initializeWithExistingData() {
    print('🔍 Initializing with data:');
    print('Date: ${widget.initialDate}');
    print('Start Time: ${widget.initialStartTime}');
    print('End Time: ${widget.initialEndTime}');

    if (widget.initialDate != null &&
        widget.initialStartTime != null &&
        widget.initialEndTime != null) {
      try {
        // Parse date (format: yyyy-MM-dd or dd/MM/yyyy)
        DateTime parsedDate;
        if (widget.initialDate!.contains('/')) {
          parsedDate = DateFormat('dd/MM/yyyy').parse(widget.initialDate!);
        } else {
          parsedDate = DateFormat('yyyy-MM-dd').parse(widget.initialDate!);
        }
        // changes

        // Parse start time (format: HH:mm:ss or HH:mm)
        final startTimeParts = widget.initialStartTime!.split(':');
        final startHour = int.parse(startTimeParts[0]);
        final startMinute = int.parse(startTimeParts[1]);

        // Parse end time (format: HH:mm:ss or HH:mm)
        final endTimeParts = widget.initialEndTime!.split(':');
        final endHour = int.parse(endTimeParts[0]);
        final endMinute = int.parse(endTimeParts[1]);

        _selectedDate = parsedDate;
        _selectedStartTime = TimeOfDay(hour: startHour, minute: startMinute);
        _selectedEndTime = TimeOfDay(hour: endHour, minute: endMinute);
        _isInitialized = true;

        // Update display text immediately
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _updateDisplayText();
          print('✅ Display text updated: ${_internalController.text}');
        });
      } catch (e) {
        print('❌ Error parsing initial data: $e');
      }
    } else {
      print('⚠️ Initial data is incomplete');
    }
  }
  // void _initializeWithExistingData() {
  //   if (widget.initialDate != null &&
  //       widget.initialStartTime != null &&
  //       widget.initialEndTime != null) {
  //     try {
  //       // Parse date (format: yyyy-MM-dd or dd/MM/yyyy)
  //       DateTime parsedDate;
  //       if (widget.initialDate!.contains('/')) {
  //         parsedDate = DateFormat('dd/MM/yyyy').parse(widget.initialDate!);
  //       } else {
  //         parsedDate = DateFormat('yyyy-MM-dd').parse(widget.initialDate!);
  //       }

  //       // Parse start time (format: HH:mm:ss or HH:mm)
  //       final startTimeParts = widget.initialStartTime!.split(':');
  //       final startHour = int.parse(startTimeParts[0]);
  //       final startMinute = int.parse(startTimeParts[1]);

  //       // Parse end time (format: HH:mm:ss or HH:mm)
  //       final endTimeParts = widget.initialEndTime!.split(':');
  //       final endHour = int.parse(endTimeParts[0]);
  //       final endMinute = int.parse(endTimeParts[1]);

  //       setState(() {
  //         _selectedDate = parsedDate;
  //         _selectedStartTime = TimeOfDay(hour: startHour, minute: startMinute);
  //         _selectedEndTime = TimeOfDay(hour: endHour, minute: endMinute);
  //         _isInitialized = true;
  //       });

  //       // Update display text
  //       _updateDisplayText();
  //     } catch (e) {
  //       print('Error parsing initial data: $e');
  //     }
  //   }
  // }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  // Convert TimeOfDay to string format (HH:mm:ss)
  String _timeToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  void _toggleCalendar() {
    setState(() {
      _isCalendarVisible = !_isCalendarVisible;
    });
    widget.onTextFieldTap();
  }

  void _onDateSelected(DateTime selectedDate) {
    setState(() {
      _selectedDate = selectedDate;
      _isCalendarVisible = false;
      // Don't reset times if they're already set from initialization
      if (!_isInitialized) {
        _selectedStartTime = null;
        _selectedEndTime = null;
      }
      _isInitialized = false; // Reset flag after first selection
    });

    if (_selectedStartTime != null && _selectedEndTime != null) {
      _updateDisplayText();
    } else {
      final formattedDate = DateFormat('MMM dd, yyyy').format(selectedDate);
      _internalController.text = 'Selected: $formattedDate';
      widget.onChanged('date_selected');
    }
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
                Icon(
                  _isCalendarVisible
                      ? Icons.keyboard_arrow_up
                      : Icons.calendar_month_outlined,
                  color: AppColors.fontColor,
                ),
              ],
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
                        color: widget.startTimeError != null
                            ? Colors.red
                            : Colors.grey.shade300,
                        width: widget.startTimeError != null ? 1.5 : 1.0,
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
                        color: widget.endTimeError != null
                            ? Colors.red
                            : Colors.grey.shade300,
                        width: widget.endTimeError != null ? 1.5 : 1.0,
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
        ],
      ],
    );
  }
}

class CalenderWidget extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final DateTime? selectedDate;

  const CalenderWidget({
    super.key,
    required this.onDateSelected,
    this.selectedDate,
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
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';
// import 'package:smartassist/config/component/color/colors.dart';
// import 'package:smartassist/config/component/font/font.dart';
// import 'dart:convert';
// import 'package:table_calendar/table_calendar.dart';
// import 'package:flutter_time_picker_spinner/flutter_time_picker_spinner.dart';

// class UpdateSlotCalendar extends StatefulWidget {
//   final String label;
//   final bool isRequired;
//   final ValueChanged<String> onChanged;
//   final String? errorText;
//   final VoidCallback onTextFieldTap;
//   final String vehicleId;
//   final TextEditingController? controller;
//   final String? startTimeError;
//   final String? endTimeError;
//   final String? initialDate; // Add this
//   final String? initialStartTime; // Add this
//   final String? initialEndTime; // Add this

//   const UpdateSlotCalendar({
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
//     this.initialDate, // Add this
//     this.initialStartTime, // Add this
//     this.initialEndTime, // Add this
//   });

//   @override
//   State<UpdateSlotCalendar> createState() => _UpdateSlotCalendarState();
// }

// class _UpdateSlotCalendarState extends State<UpdateSlotCalendar> {
//   DateTime? _selectedDate;
//   TimeOfDay? _selectedStartTime;
//   TimeOfDay? _selectedEndTime;
//   bool _isCalendarVisible = false;
//   late TextEditingController _internalController;
//   bool _isInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     _internalController = widget.controller ?? TextEditingController();
//     _initializeWithExistingData();
//   }

//   // Initialize with existing data
//   void _initializeWithExistingData() {
//     if (widget.initialDate != null &&
//         widget.initialStartTime != null &&
//         widget.initialEndTime != null) {
//       try {
//         // Parse date (format: yyyy-MM-dd or dd/MM/yyyy)
//         DateTime parsedDate;
//         if (widget.initialDate!.contains('/')) {
//           parsedDate = DateFormat('dd/MM/yyyy').parse(widget.initialDate!);
//         } else {
//           parsedDate = DateFormat('yyyy-MM-dd').parse(widget.initialDate!);
//         }

//         // Parse start time (format: HH:mm:ss or HH:mm)
//         final startTimeParts = widget.initialStartTime!.split(':');
//         final startHour = int.parse(startTimeParts[0]);
//         final startMinute = int.parse(startTimeParts[1]);

//         // Parse end time (format: HH:mm:ss or HH:mm)
//         final endTimeParts = widget.initialEndTime!.split(':');
//         final endHour = int.parse(endTimeParts[0]);
//         final endMinute = int.parse(endTimeParts[1]);

//         setState(() {
//           _selectedDate = parsedDate;
//           _selectedStartTime = TimeOfDay(hour: startHour, minute: startMinute);
//           _selectedEndTime = TimeOfDay(hour: endHour, minute: endMinute);
//           _isInitialized = true;
//         });

//         // Update display text
//         _updateDisplayText();
//       } catch (e) {
//         print('Error parsing initial data: $e');
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

//   // Convert TimeOfDay to string format (HH:mm:ss)
//   String _timeToString(TimeOfDay time) {
//     return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
//   }

//   void _toggleCalendar() {
//     setState(() {
//       _isCalendarVisible = !_isCalendarVisible;
//     });
//     widget.onTextFieldTap();
//   }

//   void _onDateSelected(DateTime selectedDate) {
//     setState(() {
//       _selectedDate = selectedDate;
//       _isCalendarVisible = false;
//       // Don't reset times if they're already set from initialization
//       if (!_isInitialized) {
//         _selectedStartTime = null;
//         _selectedEndTime = null;
//       }
//     });

//     if (_selectedStartTime != null && _selectedEndTime != null) {
//       _updateDisplayText();
//     } else {
//       final formattedDate = DateFormat('MMM dd, yyyy').format(selectedDate);
//       _internalController.text = 'Selected: $formattedDate';
//       widget.onChanged('date_selected');
//     }
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
//                 Icon(
//                   _isCalendarVisible
//                       ? Icons.keyboard_arrow_up
//                       : Icons.calendar_month_outlined,
//                   color: AppColors.fontColor,
//                 ),
//               ],
//             ),
//           ),
//         ),

//         // Calendar Widget
//         if (_isCalendarVisible)
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             child: CalenderWidget(
//               onDateSelected: _onDateSelected,
//               selectedDate: _selectedDate,
//             ),
//           ),

//         // Time Picker Section - Show when date is selected
//         if (_selectedDate != null) ...[
//           const SizedBox(height: 15),
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
//                 child: GestureDetector(
//                   onTap: () => _showCustomTimePicker(true),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       vertical: 12,
//                       horizontal: 16,
//                     ),
//                     decoration: BoxDecoration(
//                       border: Border.all(
//                         color: widget.startTimeError != null
//                             ? Colors.red
//                             : Colors.grey.shade300,
//                         width: widget.startTimeError != null ? 1.5 : 1.0,
//                       ),
//                       borderRadius: BorderRadius.circular(8),
//                       color: Colors.white,
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           _selectedStartTime != null
//                               ? _selectedStartTime!.format(context)
//                               : 'Start Time',
//                           style: GoogleFonts.poppins(
//                             fontSize: 14,
//                             color: _selectedStartTime != null
//                                 ? Colors.black
//                                 : Colors.grey,
//                           ),
//                         ),
//                         const Icon(Icons.access_time, color: Colors.grey),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               // End Time Container
//               Expanded(
//                 child: GestureDetector(
//                   onTap: () => _showCustomTimePicker(false),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                       vertical: 12,
//                       horizontal: 16,
//                     ),
//                     decoration: BoxDecoration(
//                       border: Border.all(
//                         color: widget.endTimeError != null
//                             ? Colors.red
//                             : Colors.grey.shade300,
//                         width: widget.endTimeError != null ? 1.5 : 1.0,
//                       ),
//                       borderRadius: BorderRadius.circular(8),
//                       color: Colors.white,
//                     ),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           _selectedEndTime != null
//                               ? _selectedEndTime!.format(context)
//                               : 'End Time',
//                           style: GoogleFonts.poppins(
//                             fontSize: 14,
//                             color: _selectedEndTime != null
//                                 ? Colors.black
//                                 : Colors.grey,
//                           ),
//                         ),
//                         const Icon(Icons.access_time, color: Colors.grey),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ],
//     );
//   }
// }

// class CalenderWidget extends StatefulWidget {
//   final Function(DateTime) onDateSelected;
//   final DateTime? selectedDate;

//   const CalenderWidget({
//     super.key,
//     required this.onDateSelected,
//     this.selectedDate,
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
//         firstDay: DateTime.now(),
//         lastDay: DateTime.utc(2100, 12, 31),
//         focusedDay: _focusedDay,
//         selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
//         onDaySelected: (selectedDay, focusedDay) {
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
//         ),
//         headerStyle: const HeaderStyle(
//           formatButtonVisible: false,
//           titleCentered: true,
//           titleTextStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         enabledDayPredicate: (day) {
//           return !day.isBefore(
//             DateTime.now().subtract(const Duration(days: 1)),
//           );
//         },
//       ),
//     );
//   }
// }
