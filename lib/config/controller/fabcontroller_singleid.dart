// import
// // Create a mixin for FAB functionality
// mixin FabMixin<T extends StatefulWidget> on State<T> {
//   late FabController fabController;
//   late ScrollController scrollController;
//   double lastScrollPosition = 0.0;

//   // Override this in each page to provide unique tag
//   String get fabControllerTag;

//   @override
//   void initState() {
//     super.initState();

//     // Create unique controller for this page
//     fabController = Get.put(FabController(), tag: fabControllerTag);

//     // Create page-specific scroll controller
//     scrollController = ScrollController();
//     scrollController.addListener(_handleScroll);

//     // Ensure FAB is visible when page loads
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       fabController.resetFabState();
//     });
//   }

//   void _handleScroll() {
//     if (!scrollController.hasClients) return;

//     final currentScrollPosition = scrollController.offset;
//     final scrollDifference = (currentScrollPosition - lastScrollPosition).abs();

//     if (scrollDifference < 10) return;

//     // Hide FAB when scrolling down, show when scrolling up
//     if (currentScrollPosition > lastScrollPosition &&
//         currentScrollPosition > 50) {
//       if (fabController.isFabVisible.value) {
//         fabController.isFabVisible.value = false;
//         if (fabController.isFabExpanded.value) {
//           fabController.isFabExpanded.value = false;
//         }
//       }
//     } else if (currentScrollPosition < lastScrollPosition) {
//       if (!fabController.isFabVisible.value) {
//         fabController.isFabVisible.value = true;
//       }
//     }

//     lastScrollPosition = currentScrollPosition;
//   }

//   @override
//   void dispose() {
//     scrollController.removeListener(_handleScroll);
//     scrollController.dispose();

//     // Clean up the controller with the same tag
//     Get.delete<FabController>(tag: fabControllerTag);

//     super.dispose();
//   }

//   // Common FAB building methods
//   Widget buildFab(BuildContext context) {
//     return Obx(
//       () => AnimatedPositioned(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeInOut,
//         bottom: fabController.isFabVisible.value ? 26 : -80,
//         right: 18,
//         child: AnimatedOpacity(
//           duration: const Duration(milliseconds: 300),
//           opacity: fabController.isFabVisible.value ? 1.0 : 0.0,
//           child: buildFloatingActionButton(context),
//         ),
//       ),
//     );
//   }

//   Widget buildFloatingActionButton(BuildContext context) {
//     return Obx(() {
//       return GestureDetector(
//         onTap: () {
//           fabController.toggleFab();
//         },
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 300),
//           width: MediaQuery.of(context).size.width * .15,
//           height: MediaQuery.of(context).size.height * .08,
//           decoration: BoxDecoration(
//             color: fabController.isFabDisabled.value
//                 ? Colors.grey.withOpacity(0.5)
//                 : (fabController.isFabExpanded.value
//                       ? Colors.red
//                       : AppColors.colorsBlue),
//             shape: BoxShape.circle,
//           ),
//           child: Center(
//             child: AnimatedRotation(
//               turns: fabController.isFabExpanded.value ? 0.25 : 0.0,
//               duration: const Duration(milliseconds: 300),
//               child: Icon(
//                 fabController.isFabExpanded.value ? Icons.close : Icons.add,
//                 color: Colors.white,
//                 size: 30,
//               ),
//             ),
//           ),
//         ),
//       );
//     });
//   }

//   Widget buildPopupMenu(BuildContext context, List<PopupMenuItem> items) {
//     return Obx(
//       () => fabController.isFabExpanded.value
//           ? _buildPopupMenuInternal(context, items)
//           : SizedBox.shrink(),
//     );
//   }

//   Widget _buildPopupMenuInternal(
//     BuildContext context,
//     List<PopupMenuItem> items,
//   ) {
//     return GestureDetector(
//       onTap: fabController.closeFab,
//       child: Stack(
//         children: [
//           // Background overlay
//           Positioned.fill(
//             child: Container(color: Colors.black.withOpacity(0.7)),
//           ),

//           // Popup Items Container aligned bottom right
//           Positioned(
//             bottom: 20,
//             right: 20,
//             child: SizedBox(
//               width: 200,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 children: items
//                     .map(
//                       (item) => _buildPopupItem(
//                         item.icon,
//                         item.label,
//                         item.offsetY,
//                         onTap: item.onTap,
//                       ),
//                     )
//                     .toList(),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPopupItem(
//     IconData icon,
//     String label,
//     double offsetY, {
//     required Function() onTap,
//   }) {
//     return Obx(
//       () => TweenAnimationBuilder(
//         tween: Tween<double>(
//           begin: 0,
//           end: fabController.isFabExpanded.value ? 1 : 0,
//         ),
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOutBack,
//         builder: (context, double value, child) {
//           return Transform.translate(
//             offset: Offset(0, offsetY * (1 - value)),
//             child: Opacity(
//               opacity: value.clamp(0.0, 1.0),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 6),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       label,
//                       style: GoogleFonts.poppins(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     GestureDetector(
//                       onTap: onTap,
//                       behavior: HitTestBehavior.opaque,
//                       child: Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: AppColors.colorsBlue,
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         child: Icon(icon, color: Colors.white, size: 24),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // Helper class for popup items
// class PopupMenuItem {
//   final IconData icon;
//   final String label;
//   final double offsetY;
//   final VoidCallback onTap;

//   PopupMenuItem({
//     required this.icon,
//     required this.label,
//     required this.offsetY,
//     required this.onTap,
//   });
// }

// // Now use the mixin in your pages
// class FollowupsDetails extends StatefulWidget {
//   final String leadId;

//   const FollowupsDetails({Key? key, required this.leadId}) : super(key: key);

//   @override
//   State<FollowupsDetails> createState() => _FollowupsDetailsState();
// }

// class _FollowupsDetailsState extends State<FollowupsDetails> with FabMixin {
//   // Provide unique tag for this page
//   @override
//   String get fabControllerTag => 'followups_details_${widget.leadId}';

//   @override
//   Widget build(BuildContext context) {
//     // Define popup items for this page
//     final popupItems = [
//       PopupMenuItem(
//         icon: Icons.calendar_month_outlined,
//         label: "Appointment",
//         offsetY: -80,
//         onTap: () {
//           fabController.closeFab();
//           _showAppointmentPopup(context, widget.leadId);
//         },
//       ),
//       PopupMenuItem(
//         icon: Icons.directions_car,
//         label: "Test Drive",
//         offsetY: -20,
//         onTap: () {
//           fabController.closeFab();
//           _showTestdrivePopup(context, widget.leadId);
//         },
//       ),
//       PopupMenuItem(
//         icon: Icons.trending_down_sharp,
//         label: "Lost",
//         offsetY: -40,
//         onTap: () {
//           fabController.closeFab();
//           handleLostAction();
//         },
//       ),
//     ];

//     return Scaffold(
//       body: Stack(
//         children: [
//           // Your main content
//           SingleChildScrollView(
//             controller: scrollController, // From mixin
//             child: Column(
//               children: [
//                 // Your content here...
//               ],
//             ),
//           ),

//           // FAB from mixin
//           buildFab(context),

//           // Popup menu from mixin
//           buildPopupMenu(context, popupItems),
//         ],
//       ),
//     );
//   }

//   // Your existing methods
//   void _showAppointmentPopup(BuildContext context, String leadId) {
//     // Implementation
//   }

//   void _showTestdrivePopup(BuildContext context, String leadId) {
//     // Implementation
//   }

//   void handleLostAction() {
//     // Implementation
//   }
// }

// // For other pages, just use the same pattern
// class HomePage extends StatefulWidget {
//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> with FabMixin {
//   @override
//   String get fabControllerTag => 'home_page';

//   @override
//   Widget build(BuildContext context) {
//     final popupItems = [
//       PopupMenuItem(
//         icon: Icons.person_add,
//         label: "Add Contact",
//         offsetY: -80,
//         onTap: () {
//           fabController.closeFab();
//           // Handle add contact
//         },
//       ),
//       // Add more items as needed
//     ];

//     return Scaffold(
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             controller: scrollController,
//             child: Column(
//               children: [
//                 // Your home page content
//               ],
//             ),
//           ),
//           buildFab(context),
//           buildPopupMenu(context, popupItems),
//         ],
//       ),
//     );
//   }
// }
