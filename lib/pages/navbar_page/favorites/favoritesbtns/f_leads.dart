import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';
import 'package:smartassist/pages/Home/reassign_enq.dart';
import 'package:smartassist/pages/Home/single_details_pages/singleLead_followup.dart';
import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/utils/snackbar_helper.dart';
import 'package:smartassist/utils/storage.dart';
import 'package:smartassist/widgets/home_btn.dart/edit_dashboardpopup.dart/lead_update.dart';
import 'package:smartassist/widgets/reusable/skeleton_card.dart';

class FLeads extends StatefulWidget {
  const FLeads({super.key});

  @override
  State<FLeads> createState() => _FLeadsState();
}

class _FLeadsState extends State<FLeads> {
  bool isLoading = true;
  final Map<String, double> _swipeOffsets = {};
  Set<String> selectedLeads = {};
  bool isSelectionMode = false;
  List<dynamic> upcomingTasks = [];

  void _onHorizontalDragUpdate(DragUpdateDetails details, String leadId) {
    setState(() {
      _swipeOffsets[leadId] =
          (_swipeOffsets[leadId] ?? 0) + (details.primaryDelta ?? 0);
    });
  }

  void _toggleSelection(String leadId) {
    HapticFeedback.selectionClick();

    setState(() {
      if (selectedLeads.contains(leadId)) {
        selectedLeads.remove(leadId);
        if (selectedLeads.isEmpty) {
          isSelectionMode = false;
        }
      } else {
        selectedLeads.add(leadId);
        if (!isSelectionMode) {
          isSelectionMode = true;
          HapticFeedback.mediumImpact();
        }
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, dynamic item, int index) {
    String leadId = item['lead_id'];
    double swipeOffset = _swipeOffsets[leadId] ?? 0;

    if (swipeOffset > 100) {
      // Right Swipe (Favorite)
      _toggleFavorite(leadId, index);
    } else if (swipeOffset < -100) {
      // Left Swipe (Call)
      _handleCall(item);
    }

    // Reset animation
    setState(() {
      _swipeOffsets[leadId] = 0.0;
    });
  }

  Future<void> _toggleFavorite(String leadId, int index) async {
    final token = await Storage.getToken();
    try {
      // Get the current favorite status before toggling
      bool currentStatus = upcomingTasks[index]['favourite'] ?? false;
      bool newFavoriteStatus = !currentStatus;

      final response = await http.put(
        Uri.parse(
          'https://api.smartassistapp.in/api/favourites/mark-fav/lead/$leadId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Parse the response to get the updated favorite status
        final responseData = json.decode(response.body);

        // Update only the specific item in the list
        setState(() {
          upcomingTasks[index]['favourite'] = newFavoriteStatus;
        });
        await fetchTasksData();
      } else {
        print('Failed to toggle favorite: ${response.statusCode}');
      }
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  void _handleCall(dynamic item) {
    print("Call action triggered for ${item['name']}");
    // Implement actual call functionality here
  }

  @override
  void initState() {
    super.initState();
    fetchTasksData();
  }

  Future<void> fetchTasksData() async {
    try {
      final result = await LeadsSrv.fetchFavLeadsAll();

      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          upcomingTasks = data['rows'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        final errorMessage = result['message'] ?? 'Failed to fetch tasks';
        if (mounted) {
          showErrorMessageGetx(message: errorMessage);
        }
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }

  // Future<void> fetchTasksData() async {
  //   final token = await Storage.getToken();
  //   try {
  //     final response = await http.get(
  //       Uri.parse('favourites/leads/all'),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Content-Type': 'application/json',
  //       },
  //     );

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       setState(() {
  //         upcomingTasks =
  //             data['data']['rows'] ?? []; // Store only upcoming tasks
  //         isLoading = false;
  //       });
  //     } else {
  //       print("Failed to load data: ${response.statusCode}");
  //       setState(() => isLoading = false);
  //     }
  //   } catch (e) {
  //     print("Error fetching data: $e");
  //     setState(() => isLoading = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SkeletonCard();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTasksList(upcomingTasks), // Only upcoming tasks
        ],
      ),
    );
  }

  Widget _buildTasksList(List<dynamic> tasks) {
    // if (tasks.isEmpty) {
    //   return const Padding(
    //     padding: EdgeInsets.only(bottom: 10.0),
    //     child: Center(child: Text('No Leads available')),
    //   );
    // }

    if (tasks.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 0.15, vertical: 20),
        child: Center(
          child: Text(
            'No data found',
            style: AppFont.dropDowmLabel(context),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        var item = tasks[index];

        // Make sure all required fields exist or provide defaults
        if (!(item.containsKey('lead_id') && item.containsKey('lead_name'))) {
          return ListTile(title: Text('Invalid data at index $index'));
        }

        String leadId = item['lead_id'] ?? '';
        double swipeOffset = _swipeOffsets[leadId] ?? 0;

        return GestureDetector(
          onHorizontalDragUpdate: (details) =>
              _onHorizontalDragUpdate(details, leadId),
          onHorizontalDragEnd: (details) =>
              _onHorizontalDragEnd(details, item, index),
          child: TaskItem(
            name: item['lead_name'] ?? '',
            date: item['created_at'] ?? '', // Using created_at as fallback
            subject: item['email'] ?? 'No subject',
            number: item['mobile'] ?? 'NA',
            vehicle:
                item['PMI'] ?? 'No vehicle', // PMI contains the vehicle info
            leadId: leadId,
            taskId: leadId, // Using leadId as taskId since there's no taskId
            brand: item['brand'] ?? '',
            isFavorite: item['favourite'] ?? false,
            swipeOffset: swipeOffset,
            fetchDashboardData: () {},
            onFavoriteToggled: fetchTasksData,
            onTap: selectedLeads.isNotEmpty
                ? () => _toggleSelection(leadId)
                : null,
            onFavoriteChanged: (newStatus) {
              setState(() {
                upcomingTasks[index]['favourite'] = newStatus;
              });
            },
            onToggleFavorite: () {
              // Find the correct index in the original list
              int originalIndex = upcomingTasks.indexWhere(
                (task) => task['lead_id'] == leadId,
              );
              if (originalIndex != -1) {
                _toggleFavorite(leadId, originalIndex);
              }
            },
          ),
        );
      },
    );
  }
}

// ---------------- TASK ITEM ----------------
class TaskItem extends StatefulWidget {
  final String name, subject, number;
  final String date;
  final String vehicle;
  final String leadId;
  final String taskId;
  final String brand;
  final double swipeOffset;
  final bool isFavorite;
  final VoidCallback fetchDashboardData;
  final VoidCallback onFavoriteToggled;
  final Function(bool) onFavoriteChanged;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onTap;

  const TaskItem({
    super.key,
    required this.name,
    required this.number,
    required this.date,
    required this.vehicle,
    required this.leadId,
    required this.taskId,
    required this.isFavorite,
    required this.onFavoriteToggled,
    required this.brand,
    required this.subject,
    required this.onTap,
    required this.swipeOffset,
    required this.fetchDashboardData,
    required this.onToggleFavorite,
    required this.onFavoriteChanged,
  });

  @override
  State<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem>
    with SingleTickerProviderStateMixin {
  late SlidableController _slidableController;
  late bool isFav;

  void updateFavoriteStatus(bool newStatus) {
    setState(() {
      isFav = newStatus;
    });
  }

  @override
  void initState() {
    super.initState();
    _slidableController = SlidableController(this);
    _slidableController.animation.addListener(() {
      final isOpen = _slidableController.ratio != 0;
      if (_isActionPaneOpen != isOpen) {
        setState(() {
          _isActionPaneOpen = isOpen;
        });
      }
    });
    isFav = widget.isFavorite;
  }

  @override
  void dispose() {
    _slidableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? 15 : 10,
        isTablet ? 8 : 5,
        isTablet ? 15 : 10,
        0,
      ),
      child: _buildFollowupCard(context),
    );
  }

  Widget _buildFollowupCard(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    bool isFavoriteSwipe = widget.swipeOffset > 50;
    bool isCallSwipe = widget.swipeOffset < -50;

    return GestureDetector(
      onTap:
          widget.onTap ??
          () {
            if (widget.leadId.isNotEmpty) {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowupsDetails(
                    leadId: widget.leadId,
                    isFromFreshlead: false,
                    isFromManager: true,
                    spId: '',
                    isFromTestdriveOverview: false,
                    refreshDashboard: () async {},
                  ),
                ),
              );
            } else {
              print("Invalid leadId");
            }
          },
      child: Slidable(
        key: ValueKey(widget.leadId),
        controller: _slidableController, // Add this line
        closeOnScroll: true,
        startActionPane: ActionPane(
          extentRatio: isTablet ? 0.15 : 0.2,
          motion: const ScrollMotion(),
          children: [
            ReusableSlidableAction(
              onPressed: () {
                widget.onToggleFavorite();
                _slidableController.close();
                setState(() {
                  _isActionPaneOpen = false;
                });
              },
              onDismissed: () {},
              backgroundColor: Colors.amber,
              icon: widget.isFavorite
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              foregroundColor: Colors.white,
              iconSize: isTablet ? 45 : 40,
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const StretchMotion(),
          extentRatio: isTablet ? 0.15 : 0.2,
          children: [
            ReusableSlidableAction(
              onPressed: () {
                _mailAction();
                _slidableController.close();
                setState(() {
                  _isActionPaneOpen = false;
                });
              },

              backgroundColor: const Color.fromARGB(255, 231, 225, 225),
              icon: Icons.edit,
              foregroundColor: Colors.white,
              iconSize: isTablet ? 45 : 40,
              onDismissed: () {
                setState(() {
                  _isActionPaneOpen = false;
                });
              },
            ),
          ],
        ),
        child: Stack(
          children: [
            // Favorite Swipe Overlay
            if (isFavoriteSwipe)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.yellow.withOpacity(0.2),
                        Colors.yellow.withOpacity(0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: isTablet ? 20 : 15),
                        Icon(
                          isFav
                              ? Icons.star_outline_rounded
                              : Icons.star_rounded,
                          color: const Color.fromRGBO(226, 195, 34, 1),
                          size: isTablet ? 50 : 40,
                        ),
                        SizedBox(width: isTablet ? 15 : 10),
                        Text(
                          isFav ? 'Unfavorite' : 'Favorite',
                          style: GoogleFonts.poppins(
                            color: const Color.fromRGBO(187, 158, 0, 1),
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Call Swipe Overlay
            if (isCallSwipe)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.2),
                        Colors.green.withOpacity(0.8),
                      ],
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(width: isTablet ? 15 : 10),
                        Icon(
                          Icons.phone_in_talk,
                          color: Colors.white,
                          size: isTablet ? 35 : 30,
                        ),
                        SizedBox(width: isTablet ? 15 : 10),
                        Text(
                          'Call',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: isTablet ? 20 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Main Container
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 15 : 10,
                vertical: isTablet ? 20 : 15,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundLightGrey,
                borderRadius: BorderRadius.circular(7),
                border: Border(
                  left: BorderSide(
                    width: isTablet ? 10.0 : 8.0,
                    color: isFav
                        ? (isCallSwipe
                              ? Colors.green.withOpacity(0.9)
                              : Colors.yellow.withOpacity(
                                  isFavoriteSwipe ? 0.1 : 0.9,
                                ))
                        : (isFavoriteSwipe
                              ? Colors.yellow.withOpacity(0.1)
                              : (isCallSwipe
                                    ? Colors.green.withOpacity(0.1)
                                    : AppColors.sideGreen)),
                  ),
                ),
              ),
              child: Opacity(
                opacity: (isFavoriteSwipe || isCallSwipe) ? 0 : 1.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(width: isTablet ? 12 : 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Flexible(child: _buildUserDetails(context)),
                                    _buildVerticalDivider(isTablet ? 18 : 15),
                                    Flexible(
                                      child: _buildSubjectDetails(context),
                                    ),
                                  ],
                                ),
                                SizedBox(height: isTablet ? 6 : 4),
                                Row(
                                  children: [
                                    Flexible(child: _buildCarModel(context)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildNavigationButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mailAction() {
    print("Mail action triggered");

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: LeadUpdate(
            onFormSubmit: () {},
            leadId: widget.leadId,
            onEdit: widget.onFavoriteToggled,
          ),
        );
      },
    );
  }

  bool _isActionPaneOpen = false;
  Widget _buildNavigationButton(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return GestureDetector(
      onTap: () {
        if (_isActionPaneOpen) {
          // Close the action pane if it's open
          _slidableController.close();
          setState(() {
            _isActionPaneOpen = false;
          });
        } else {
          // Open the end action pane if it's closed
          _slidableController.openEndActionPane();
          setState(() {
            _isActionPaneOpen = true;
          });
        }
      },
      child: Container(
        padding: EdgeInsets.all(isTablet ? 4 : 3),
        decoration: BoxDecoration(
          color: AppColors.arrowContainerColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Icon(
          _isActionPaneOpen
              ? Icons.arrow_forward_ios_rounded
              : Icons.arrow_back_ios_rounded,
          size: isTablet ? 28 : 25,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildUserDetails(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Text(
      widget.name,
      textAlign: TextAlign.start,
      style:
          AppFont.dashboardName(
            context,
          )?.copyWith(fontSize: isTablet ? 18 : null) ??
          GoogleFonts.poppins(
            fontSize: isTablet ? 18 : 16,
            fontWeight: FontWeight.w500,
          ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubjectDetails(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    String mobile = widget.number;
    String hiddenMobile = _hideMobileNumber(mobile);

    return Text(
      hiddenMobile,
      style:
          AppFont.smallText(
            context,
          )?.copyWith(fontSize: isTablet ? 14 : null) ??
          GoogleFonts.poppins(
            fontSize: isTablet ? 14 : 12,
            color: Colors.grey[600],
          ),
      overflow: TextOverflow.ellipsis,
    );
  }

  String _hideMobileNumber(String mobile) {
    if (mobile.length >= 10) {
      return mobile.substring(0, 3) + '*****' + mobile.substring(8);
    } else {
      return mobile;
    }
  }

  Widget _buildVerticalDivider(double height) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Container(
      margin: EdgeInsets.only(
        bottom: 3,
        left: isTablet ? 15 : 10,
        right: isTablet ? 15 : 10,
      ),
      height: height,
      width: 0.1,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.fontColor)),
      ),
    );
  }

  Widget _buildCarModel(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Text(
      widget.vehicle,
      textAlign: TextAlign.start,
      style:
          AppFont.dashboardCarName(
            context,
          )?.copyWith(fontSize: isTablet ? 16 : null) ??
          GoogleFonts.poppins(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w400,
          ),
      softWrap: true,
      overflow: TextOverflow.ellipsis,
    );
  }
}
