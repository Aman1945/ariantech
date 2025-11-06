import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/utils/storage.dart';

class MobileNumberDialog extends StatefulWidget {
  final String leadId;
  final String leadName;
  final String heading;

  const MobileNumberDialog({
    super.key,
    required this.leadId,
    required this.leadName,
    required this.heading,
  });

  @override
  State<MobileNumberDialog> createState() => _MobileNumberDialogState();
}

class _MobileNumberDialogState extends State<MobileNumberDialog> {
  final TextEditingController mobileController = TextEditingController();
  final Map<String, String> _errors = {};
  bool isLoading = false;
  bool isApiSuccess = false;
  bool hasEdited = false;

  @override
  void dispose() {
    mobileController.dispose();
    super.dispose();
  }

  Future<void> _updateMobileNumber() async {
    setState(() {
      isLoading = true;
      _errors.clear();
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? spId = prefs.getString('user_id');

      if (spId == null) {
        throw Exception('User ID not found');
      }

      String mobileNumber = mobileController.text;

      if (!mobileNumber.startsWith('+91')) {
        mobileNumber = '+91' + mobileNumber;
      }

      final leadData = {'mobile': mobileNumber};
      final token = await Storage.getToken();

      final response = await http.put(
        Uri.parse(
          'https://api.smartassistapp.in/api/leads/update/${widget.leadId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(leadData),
      );

      print('Response body: ${response.body}');
      print('Response status: ${response.statusCode}');
      print(leadData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        String message =
            responseData['message'] ?? 'Mobile number updated successfully!';

        setState(() {
          isApiSuccess = true;
          hasEdited = false;
        });

        Get.snackbar(
          'Success',
          message,
          colorText: Colors.white,
          backgroundColor: Colors.green.shade500,
        );

        // Close dialog after successful update
        Future.delayed(Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else {
        final Map<String, dynamic> responseData = json.decode(response.body);
        String message = responseData['message'] ?? 'Update failed. Try again.';

        Get.snackbar(
          'Error',
          message,
          colorText: Colors.white,
          backgroundColor: Colors.red.shade500,
        );
        throw Exception(message);
      }
    } catch (e) {
      print('Error during PUT request: $e');
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.',
        colorText: Colors.white,
        backgroundColor: Colors.red.shade500,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String label,
    required ValueChanged<String> onChanged,
    bool isRequired = false,
    String? errorText,
    VoidCallback? onIconPressed,
    VoidCallback? onClearPressed,
    bool isLoading = false,
    bool isSuccess = false,
    bool hasEdited = false,
    String initialValue = '',
  }) {
    // bool isDoneClickable =
    //     controller.text.trim().isNotEmpty &&
    //     (hasEdited || (!hasEdited && !isSuccess));

    bool isDoneClickable =
        controller.text.trim().length == 10 && // exactly 10 digits
        (hasEdited || (!hasEdited && !isSuccess));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.fontBlack,
              ),
              children: [
                TextSpan(text: label),
                if (isRequired)
                  const TextSpan(
                    text: " *",
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: const Color.fromARGB(255, 248, 247, 247),
            border: errorText != null
                ? Border.all(color: Colors.red, width: 1.0)
                : null,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextField(
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              minLines: 1,
              maxLines: 1,
              controller: controller,
              // keyboardType: TextInputType.phone,
              style: AppFont.dropDowmLabel(context),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                border: InputBorder.none,
                suffixIcon: onIconPressed != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.text.isNotEmpty &&
                              !isLoading &&
                              !isSuccess &&
                              onClearPressed != null)
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.grey),
                              onPressed: onClearPressed,
                            ),
                          if (isLoading)
                            Container(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.colorsBlue,
                                ),
                              ),
                            )
                          else if (isSuccess)
                            Container(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                            ),
                          // else
                          //   IconButton(
                          //     icon: Icon(
                          //       Icons.done,
                          //       color: isDoneClickable
                          //           ? AppColors.colorsBlue
                          //           : Colors.grey,
                          //     ),
                          //     onPressed: isDoneClickable ? onIconPressed : null,
                          //   ),
                        ],
                      )
                    : null,
              ),
              onChanged: onChanged,
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 5),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      backgroundColor: Colors.white,
      contentPadding: EdgeInsets.zero,
      title: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Update Number', style: AppFont.popupTitleBlack(context)),
                const SizedBox(height: 10),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text('${widget.heading}', style: AppFont.dropDowmLabel(context)),

            // const SizedBox(height: 10),
            // const SizedBox(height: 10),
            _buildTextField(
              isRequired: true,
              label: 'Mobile Number',
              controller: mobileController,
              hintText: 'Enter mobile number',
              errorText: _errors['mobile'],
              isLoading: isLoading,
              isSuccess: isApiSuccess,
              hasEdited: hasEdited,
              onChanged: (value) {
                if (value.isNotEmpty && _errors.containsKey('mobile')) {
                  setState(() {
                    _errors.remove('mobile');
                  });
                }
                setState(() {
                  hasEdited = true;
                  if (hasEdited) {
                    isApiSuccess = false;
                  }
                });
              },
              onIconPressed: () {
                if (mobileController.text.trim().isEmpty) {
                  setState(() {
                    _errors['mobile'] = 'Mobile number is required';
                  });
                  return;
                }
                _updateMobileNumber();
              },
              onClearPressed: () {
                mobileController.clear();
                setState(() {
                  hasEdited = false;
                  isApiSuccess = false;
                  _errors.remove('mobile');
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: AppFont.mediumText14(context)),
        ),
        TextButton(
          onPressed: (isApiSuccess && !hasEdited)
              ? () => Navigator.of(context).pop()
              : mobileController.text.trim().length != 10
              ? null
              : () => _updateMobileNumber(),
          child: Text(
            'Add',
            style:
                (isApiSuccess && !hasEdited) ||
                    mobileController.text.trim().length == 10
                ? AppFont.mediumText14blue(context)
                : GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
          ),
        ),

        // TextButton(
        //   onPressed: (isApiSuccess && !hasEdited)
        //       ? () => Navigator.of(context).pop()
        //       : (!hasEdited && !isApiSuccess)
        //       ? () {
        //           Get.snackbar(
        //             'Edit Required',
        //             'Please add mobile number first',
        //             backgroundColor: Colors.orange,
        //             colorText: Colors.white,
        //             duration: Duration(seconds: 2),
        //           );
        //         }
        //       : mobileController.text.trim().isEmpty
        //       ? () {
        //           setState(() {
        //             _errors['mobile'] = 'Mobile number is required';
        //           });
        //         }
        //       : () => _updateMobileNumber(),
        //   // child: Text(
        //   //   'Add',
        //   //   style:
        //   //       (isApiSuccess && !hasEdited) ||
        //   //           mobileController.text.trim().isNotEmpty
        //   //       ? AppFont.mediumText14blue(context)
        //   //       : GoogleFonts.poppins(
        //   //           fontSize: 14,
        //   //           fontWeight: FontWeight.w500,
        //   //           color: Colors.grey,
        //   //         ),
        //   child: Text(
        //     'Add',
        //     style:
        //         (isApiSuccess && !hasEdited) ||
        //             mobileController.text.trim().length == 10
        //         ? AppFont.mediumText14blue(context)
        //         : GoogleFonts.poppins(
        //             fontSize: 14,
        //             fontWeight: FontWeight.w500,
        //             color: Colors.grey,
        //           ),
        //   ),
        // ),
      ],
    );
  }
}

// Static method to show the dialog
class MobileDialogHelper {
  static Future<void> showMobileDialog(
    BuildContext context, {
    required String heading,
    required String leadId,
    required String leadName,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return MobileNumberDialog(
          leadId: leadId,
          leadName: leadName,
          heading: heading,
        );
      },
    );
  }
}
