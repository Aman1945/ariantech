import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smartassist/config/component/font/font.dart';

class PlacePrediction {
  final String placeId;
  final String description;

  PlacePrediction({required this.placeId, required this.description});

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      placeId: json['place_id'],
      description: json['description'],
    );
  }
}

class PlaceDetails {
  final double lat;
  final double lng;
  final String city;
  final String pincode;
  final String state;
  final String country;
  final String address;

  PlaceDetails({
    required this.lat,
    required this.lng,
    required this.city,
    required this.pincode,
    required this.state,
    required this.country,
    required this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'city': city,
      'pincode': pincode,
      'state': state,
      'country': country,
      'address': address,
    };
  }
}

class CustomGooglePlacesField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String label;
  final ValueChanged<String> onChanged;
  final ValueChanged<PlaceDetails?>?
  onPlaceSelected; // New callback for place details
  final ValueChanged<bool>?
  onValidationChanged; // New callback for validation status
  final String googleApiKey;
  final bool isRequired;
  final String? errorText;

  const CustomGooglePlacesField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.label,
    required this.onChanged,
    this.onPlaceSelected,
    this.onValidationChanged,
    required this.googleApiKey,
    this.isRequired = false,
    this.errorText,
  }) : super(key: key);

  @override
  State<CustomGooglePlacesField> createState() =>
      _CustomGooglePlacesFieldState();
}

class _CustomGooglePlacesFieldState extends State<CustomGooglePlacesField> {
  List<PlacePrediction> _predictions = [];
  bool _isLoading = false;
  Timer? _debounce;
  bool _showPredictions = false;
  bool _isValidSelection = false;
  String _lastValidText = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getPlacePredictions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _predictions = [];
        _isLoading = false;
        _showPredictions = false;
        _isValidSelection = false;
      });
      return;
    }

    // If user is typing and it doesn't match last valid selection, mark as invalid
    if (input != _lastValidText && _lastValidText.isNotEmpty) {
      setState(() {
        _isValidSelection = false;
      });
      // Notify parent about validation status
      if (widget.onValidationChanged != null) {
        widget.onValidationChanged!(false);
      }
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&components=country:in&key=${widget.googleApiKey}',
    );
    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final predictions = (data['predictions'] as List)
            .map((prediction) => PlacePrediction.fromJson(prediction))
            .toList();

        if (mounted) {
          setState(() {
            _predictions = predictions;
            _isLoading = false;
            _showPredictions = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _predictions = [];
            _isLoading = false;
            _showPredictions = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _predictions = [];
          _isLoading = false;
          _showPredictions = false;
        });
      }
    }
  }

  Future<PlaceDetails?> _getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${widget.googleApiKey}',
    );

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final result = data['result'];
        final geometry = result['geometry']['location'];
        final addressComponents = result['address_components'] as List;

        // Extract address components
        String city = '';
        String state = '';
        String country = '';
        String pincode = '';

        for (var component in addressComponents) {
          final types = component['types'] as List;

          if (types.contains('locality') ||
              types.contains('administrative_area_level_2')) {
            city = component['long_name'];
          } else if (types.contains('administrative_area_level_1')) {
            state = component['long_name'];
          } else if (types.contains('country')) {
            country = component['long_name'];
          } else if (types.contains('postal_code')) {
            pincode = component['long_name'];
          }
        }

        return PlaceDetails(
          lat: geometry['lat'].toDouble(),
          lng: geometry['lng'].toDouble(),
          city: city,
          pincode: pincode,
          state: state,
          country: country,
          address: result['formatted_address'],
        );
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }

    return null;
  }

  // Helper method to check if current input is valid
  bool isValidInput() {
    if (widget.controller.text.isEmpty) {
      return true; // Empty is valid for optional field
    }
    return _isValidSelection && widget.controller.text == _lastValidText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: widget.label,
                  style: AppFont.dropDowmLabel(context),
                ),
                // if (widget.isRequired)
                //   const TextSpan(
                //     text: " *",
                //     style: TextStyle(color: Colors.red),
                //   ),
              ],
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: const Color.fromARGB(255, 248, 247, 247),
            border: widget.errorText != null
                ? Border.all(color: Colors.red, width: 1.0)
                : null,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              minLines: 1,
              maxLines: null,
              controller: widget.controller,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: InputBorder.none,
                // border: OutlineInputBorder(
                //   borderRadius: BorderRadius.circular(5),
                //   borderSide: BorderSide(
                //     color:
                //         widget.errorText != null && widget.errorText!.isNotEmpty
                //         ? Colors.red
                //         : Colors.transparent,
                //   ),
                // ),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          widget.controller.clear();
                          setState(() {
                            _predictions = [];
                            _showPredictions = false;
                            _isValidSelection = false;
                            _lastValidText = '';
                          });
                          widget.onChanged('');
                          // Clear place details
                          if (widget.onPlaceSelected != null) {
                            widget.onPlaceSelected!(null);
                          }
                          // Notify parent about validation status
                          if (widget.onValidationChanged != null) {
                            widget.onValidationChanged!(
                              true,
                            ); // Empty is valid for optional field
                          }
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  _getPlacePredictions(value);
                });
                widget.onChanged(value);
              },
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              onTap: () {
                if (_predictions.isNotEmpty) {
                  setState(() {
                    _showPredictions = true;
                  });
                }
              },
            ),
          ),
        ),

        // Error text
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        // Predictions list
        if (_showPredictions && (_predictions.isNotEmpty || _isLoading))
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: _predictions.map((prediction) {
                        return InkWell(
                          onTap: () async {
                            widget.controller.text = prediction.description;
                            widget.onChanged(prediction.description);
                            setState(() {
                              _showPredictions = false;
                              _isValidSelection = true;
                              _lastValidText = prediction.description;
                            });

                            // Notify parent about validation status
                            if (widget.onValidationChanged != null) {
                              widget.onValidationChanged!(true);
                            }

                            // Fetch place details
                            if (widget.onPlaceSelected != null) {
                              final placeDetails = await _getPlaceDetails(
                                prediction.placeId,
                              );
                              widget.onPlaceSelected!(placeDetails);
                            }

                            // Hide keyboard
                            FocusScope.of(context).unfocus();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    prediction.description,
                                    style: TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
      ],
    );
  }
}

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:smartassist/config/component/font/font.dart';

// class PlacePrediction {
//   final String placeId;
//   final String description;

//   PlacePrediction({required this.placeId, required this.description});

//   factory PlacePrediction.fromJson(Map<String, dynamic> json) {
//     return PlacePrediction(
//       placeId: json['place_id'],
//       description: json['description'],
//     );
//   }
// }

// class PlaceDetails {
//   final double lat;
//   final double lng;
//   final String city;
//   final String pincode;
//   final String state;
//   final String country;
//   final String address;

//   PlaceDetails({
//     required this.lat,
//     required this.lng,
//     required this.city,
//     required this.pincode,
//     required this.state,
//     required this.country,
//     required this.address,
//   });

//   Map<String, dynamic> toJson() {
//     return {
//       'lat': lat,
//       'lng': lng,
//       'city': city,
//       'pincode': pincode,
//       'state': state,
//       'country': country,
//       'address': address,
//     };
//   }
// }

// class CustomGooglePlacesField extends StatefulWidget {
//   final TextEditingController controller;
//   final String hintText;
//   final String label;
//   final ValueChanged<String> onChanged;
//   final ValueChanged<PlaceDetails?>?
//   onPlaceSelected; // New callback for place details
//   final String googleApiKey;
//   final bool isRequired;
//   final String? errorText;

//   const CustomGooglePlacesField({
//     Key? key,
//     required this.controller,
//     required this.hintText,
//     required this.label,
//     required this.onChanged,
//     this.onPlaceSelected,
//     required this.googleApiKey,
//     this.isRequired = false,
//     this.errorText,
//   }) : super(key: key);

//   @override
//   State<CustomGooglePlacesField> createState() =>
//       _CustomGooglePlacesFieldState();
// }

// class _CustomGooglePlacesFieldState extends State<CustomGooglePlacesField> {
//   List<PlacePrediction> _predictions = [];
//   bool _isLoading = false;
//   Timer? _debounce;
//   bool _showPredictions = false;

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   Future<void> _getPlacePredictions(String input) async {
//     if (input.isEmpty) {
//       setState(() {
//         _predictions = [];
//         _isLoading = false;
//         _showPredictions = false;
//       });
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     final url = Uri.parse(
//       'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&components=country:in&key=${widget.googleApiKey}',
//     );
//     try {
//       final response = await http.get(url);
//       final data = json.decode(response.body);

//       if (data['status'] == 'OK') {
//         final predictions = (data['predictions'] as List)
//             .map((prediction) => PlacePrediction.fromJson(prediction))
//             .toList();

//         if (mounted) {
//           setState(() {
//             _predictions = predictions;
//             _isLoading = false;
//             _showPredictions = true;
//           });
//         }
//       } else {
//         if (mounted) {
//           setState(() {
//             _predictions = [];
//             _isLoading = false;
//           });
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _predictions = [];
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<PlaceDetails?> _getPlaceDetails(String placeId) async {
//     final url = Uri.parse(
//       'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=${widget.googleApiKey}',
//     );

//     try {
//       final response = await http.get(url);
//       final data = json.decode(response.body);

//       if (data['status'] == 'OK') {
//         final result = data['result'];
//         final geometry = result['geometry']['location'];
//         final addressComponents = result['address_components'] as List;

//         // Extract address components
//         String city = '';
//         String state = '';
//         String country = '';
//         String pincode = '';

//         for (var component in addressComponents) {
//           final types = component['types'] as List;

//           if (types.contains('locality') ||
//               types.contains('administrative_area_level_2')) {
//             city = component['long_name'];
//           } else if (types.contains('administrative_area_level_1')) {
//             state = component['long_name'];
//           } else if (types.contains('country')) {
//             country = component['long_name'];
//           } else if (types.contains('postal_code')) {
//             pincode = component['long_name'];
//           }
//         }

//         return PlaceDetails(
//           lat: geometry['lat'].toDouble(),
//           lng: geometry['lng'].toDouble(),
//           city: city,
//           pincode: pincode,
//           state: state,
//           country: country,
//           address: result['formatted_address'],
//         );
//       }
//     } catch (e) {
//       print('Error fetching place details: $e');
//     }

//     return null;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Label
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
//           child: RichText(
//             text: TextSpan(
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black,
//               ),
//               children: [
//                 TextSpan(
//                   text: widget.label,
//                   style: AppFont.dropDowmLabel(context),
//                 ),
//                 // if (widget.isRequired)
//                 //   const TextSpan(
//                 //     text: " *",
//                 //     style: TextStyle(color: Colors.red),
//                 //   ),
//               ],
//             ),
//           ),
//         ),
//         Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(5),
//             color: const Color.fromARGB(255, 248, 247, 247),
//             border: widget.errorText != null
//                 ? Border.all(color: Colors.red, width: 1.0)
//                 : null,
//           ),
//           child: Align(
//             alignment: Alignment.centerLeft,
//             child: TextField(
//               minLines: 1,
//               maxLines: null,
//               controller: widget.controller,
//               decoration: InputDecoration(
//                 hintText: widget.hintText,
//                 hintStyle: GoogleFonts.poppins(
//                   color: Colors.grey,
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 10,
//                 ),
//                 border: InputBorder.none,
//                 suffixIcon: widget.controller.text.isNotEmpty
//                     ? IconButton(
//                         icon: const Icon(Icons.clear),
//                         onPressed: () {
//                           widget.controller.clear();
//                           setState(() {
//                             _predictions = [];
//                             _showPredictions = false;
//                           });
//                           widget.onChanged('');
//                           // Clear place details
//                           if (widget.onPlaceSelected != null) {
//                             widget.onPlaceSelected!(null);
//                           }
//                         },
//                       )
//                     : null,
//               ),
//               onChanged: (value) {
//                 if (_debounce?.isActive ?? false) _debounce?.cancel();
//                 _debounce = Timer(const Duration(milliseconds: 500), () {
//                   _getPlacePredictions(value);
//                 });
//                 widget.onChanged(value);
//               },
//               keyboardType: TextInputType.text,
//               textInputAction: TextInputAction.done,
//               onTap: () {
//                 if (_predictions.isNotEmpty) {
//                   setState(() {
//                     _showPredictions = true;
//                   });
//                 }
//               },
//             ),
//           ),
//         ),

//         // Error text
//         if (widget.errorText != null)
//           Padding(
//             padding: const EdgeInsets.only(left: 8, top: 4),
//             child: Text(
//               widget.errorText!,
//               style: const TextStyle(color: Colors.red, fontSize: 12),
//             ),
//           ),

//         // Predictions list
//         if (_showPredictions && (_predictions.isNotEmpty || _isLoading))
//           Container(
//             constraints: BoxConstraints(maxHeight: 200),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(5),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 4,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: _isLoading
//                 ? const Center(
//                     child: Padding(
//                       padding: EdgeInsets.all(10.0),
//                       child: CircularProgressIndicator(),
//                     ),
//                   )
//                 : SingleChildScrollView(
//                     child: Column(
//                       children: _predictions.map((prediction) {
//                         return InkWell(
//                           onTap: () async {
//                             widget.controller.text = prediction.description;
//                             widget.onChanged(prediction.description);
//                             setState(() {
//                               _showPredictions = false;
//                             });

//                             // Fetch place details
//                             if (widget.onPlaceSelected != null) {
//                               final placeDetails = await _getPlaceDetails(
//                                 prediction.placeId,
//                               );
//                               widget.onPlaceSelected!(placeDetails);
//                             }

//                             // Hide keyboard
//                             FocusScope.of(context).unfocus();
//                           },
//                           child: Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.all(12),
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.location_on, size: 18),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: Text(
//                                     prediction.description,
//                                     style: TextStyle(fontSize: 14),
//                                     overflow: TextOverflow.ellipsis,
//                                     maxLines: 2,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//           ),
//       ],
//     );
//   }
// }


// old one without latlong  
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:smartassist/config/component/font/font.dart';

// class PlacePrediction {
//   final String placeId;
//   final String description;

//   PlacePrediction({required this.placeId, required this.description});

//   factory PlacePrediction.fromJson(Map<String, dynamic> json) {
//     return PlacePrediction(
//         placeId: json['place_id'], description: json['description']);
//   }
// }

// class CustomGooglePlacesField extends StatefulWidget {
//   final TextEditingController controller;
//   final String hintText;
//   final String label;
//   final ValueChanged<String> onChanged;
//   final String googleApiKey;
//   final bool isRequired;
//   final String? errorText;

//   const CustomGooglePlacesField({
//     Key? key,
//     required this.controller,
//     required this.hintText,
//     required this.label,
//     required this.onChanged,
//     required this.googleApiKey,
//     this.isRequired = false,
//     this.errorText,
//   }) : super(key: key);

//   @override
//   State<CustomGooglePlacesField> createState() =>
//       _CustomGooglePlacesFieldState();
// }

// class _CustomGooglePlacesFieldState extends State<CustomGooglePlacesField> {
//   List<PlacePrediction> _predictions = [];
//   bool _isLoading = false;
//   Timer? _debounce;
//   bool _showPredictions = false;

//   @override
//   void dispose() {
//     _debounce?.cancel();
//     super.dispose();
//   }

//   Future<void> _getPlacePredictions(String input) async {
//     if (input.isEmpty) {
//       setState(() {
//         _predictions = [];
//         _isLoading = false;
//         _showPredictions = false;
//       });
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     final url = Uri.parse(
//         'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&components=country:in&key=${widget.googleApiKey}');
//     try {
//       final response = await http.get(url);
//       final data = json.decode(response.body);

//       if (data['status'] == 'OK') {
//         final predictions = (data['predictions'] as List)
//             .map((prediction) => PlacePrediction.fromJson(prediction))
//             .toList();

//         if (mounted) {
//           setState(() {
//             _predictions = predictions;
//             _isLoading = false;
//             _showPredictions = true;
//           });
//         }
//       } else {
//         if (mounted) {
//           setState(() {
//             _predictions = [];
//             _isLoading = false;
//           });
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _predictions = [];
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Label
//         Padding(
//           padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
//           child: RichText(
//             text: TextSpan(
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.black,
//               ),
//               children: [
//                 TextSpan(
//                     text: widget.label, style: AppFont.dropDowmLabel(context)),
//                 // if (widget.isRequired)
//                 //   const TextSpan(
//                 //     text: " *",
//                 //     style: TextStyle(color: Colors.red),
//                 //   ),
//               ],
//             ),
//           ),
//         ),
//         Container(
//           width: double.infinity,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(5),
//             color: const Color.fromARGB(255, 248, 247, 247),
//             border: widget.errorText != null
//                 ? Border.all(color: Colors.red, width: 1.0)
//                 : null,
//           ),
//           child: Align(
//             alignment: Alignment.centerLeft,
//             child: TextField(
//               minLines: 1,
//               maxLines: null,
//               controller: widget.controller,
//               decoration: InputDecoration(
//                 hintText: widget.hintText,
//                 hintStyle: GoogleFonts.poppins(
//                     color: Colors.grey,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500),
//                 contentPadding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//                 border: InputBorder.none,
//                 suffixIcon: widget.controller.text.isNotEmpty
//                     ? IconButton(
//                         icon: const Icon(Icons.clear),
//                         onPressed: () {
//                           widget.controller.clear();
//                           setState(() {
//                             _predictions = [];
//                             _showPredictions = false;
//                           });
//                           widget.onChanged('');
//                         },
//                       )
//                     : null,
//               ),
//               onChanged: (value) {
//                 if (_debounce?.isActive ?? false) _debounce?.cancel();
//                 _debounce = Timer(const Duration(milliseconds: 500), () {
//                   _getPlacePredictions(value);
//                 });
//                 widget.onChanged(value);
//               },
//               keyboardType: TextInputType.text,
//               textInputAction: TextInputAction.done,
//               onTap: () {
//                 if (_predictions.isNotEmpty) {
//                   setState(() {
//                     _showPredictions = true;
//                   });
//                 }
//               },
//             ),
//           ),
//         ),

//         // Error text
//         if (widget.errorText != null)
//           Padding(
//             padding: const EdgeInsets.only(left: 8, top: 4),
//             child: Text(
//               widget.errorText!,
//               style: const TextStyle(color: Colors.red, fontSize: 12),
//             ),
//           ),

//         // Predictions list
//         if (_showPredictions && (_predictions.isNotEmpty || _isLoading))
//           Container(
//             constraints: BoxConstraints(maxHeight: 200),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(5),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   blurRadius: 4,
//                   offset: Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: _isLoading
//                 ? const Center(
//                     child: Padding(
//                       padding: EdgeInsets.all(10.0),
//                       child: CircularProgressIndicator(),
//                     ),
//                   )
//                 : SingleChildScrollView(
//                     child: Column(
//                       children: _predictions.map((prediction) {
//                         return InkWell(
//                           onTap: () {
//                             widget.controller.text = prediction.description;
//                             widget.onChanged(prediction.description);
//                             setState(() {
//                               _showPredictions = false;
//                             });
//                             // Hide keyboard
//                             FocusScope.of(context).unfocus();
//                           },
//                           child: Container(
//                             width: double.infinity,
//                             padding: const EdgeInsets.all(12),
//                             child: Row(
//                               children: [
//                                 const Icon(Icons.location_on, size: 18),
//                                 const SizedBox(width: 10),
//                                 Expanded(
//                                   child: Text(
//                                     prediction.description,
//                                     style: TextStyle(fontSize: 14),
//                                     overflow: TextOverflow.ellipsis,
//                                     maxLines: 2,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     ),
//                   ),
//           ),
//       ],
//     );
//   }
// }
