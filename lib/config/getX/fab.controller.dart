// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';

// class FabController extends GetxController {
//   ScrollController? _scrollController;
//   final RxBool isFabExpanded = false.obs;
//   final RxList events = <dynamic>[].obs;

//   var isFabDisabled = false.obs;

//   // Add these new variables for scroll hide/show functionality
//   final RxBool isFabVisible = true.obs;
//   double lastScrollPosition = 0.0;

//   // Add a small threshold to prevent excessive state changes
//   static const double scrollThreshold = 10.0;

//   // Add debouncing for scroll events
//   DateTime? lastScrollTime;
//   static const Duration scrollDebounceTime = Duration(milliseconds: 100);

//   // Add timer reference to properly manage disable state
//   Timer? _disableTimer;

//   ScrollController get scrollController {
//     _scrollController ??= ScrollController();
//     return _scrollController!;
//   }

//   @override
//   void onInit() {
//     super.onInit();
//     scrollController.addListener(_scrollListener);

//     // Add periodic check to ensure FAB state is correct
//     Timer.periodic(const Duration(seconds: 30), (timer) {
//       if (isClosed) {
//         timer.cancel();
//         return;
//       }
//       _validateFabState();
//     });
//   }

//   void _scrollListener() {
//     // Check if controller is disposed or doesn't have clients
//     if (isClosed ||
//         _scrollController == null ||
//         !_scrollController!.hasClients) {
//       return;
//     }

//     final now = DateTime.now();

//     // Debounce scroll events
//     if (lastScrollTime != null &&
//         now.difference(lastScrollTime!) < scrollDebounceTime) {
//       return;
//     }
//     lastScrollTime = now;

//     try {
//       final currentScrollPosition = _scrollController!.offset;
//       final scrollDifference = (currentScrollPosition - lastScrollPosition)
//           .abs();

//       // Add debouncing to prevent rapid state changes
//       if (scrollDifference < scrollThreshold) return;

//       // Hide FAB when scrolling down, show when scrolling up
//       if (currentScrollPosition > lastScrollPosition &&
//           currentScrollPosition > 50) {
//         if (isFabVisible.value) {
//           isFabVisible.value = false;
//           if (isFabExpanded.value) {
//             isFabExpanded.value = false;
//           }
//         }
//       } else if (currentScrollPosition < lastScrollPosition) {
//         if (!isFabVisible.value) {
//           isFabVisible.value = true;
//         }
//       }

//       lastScrollPosition = currentScrollPosition;
//     } catch (e) {
//       print('Error in scroll listener: $e');
//       // Reset scroll position on error
//       lastScrollPosition = 0.0;
//     }
//   }

//   void toggleFab() {
//     print(
//       'toggleFab called - Visible: ${isFabVisible.value}, Disabled: ${isFabDisabled.value}',
//     );

//     // Check if controller is disposed
//     if (isClosed) {
//       print('Controller is disposed, ignoring toggle');
//       return;
//     }

//     // Simplified condition - only check if visible and not disabled
//     if (isFabVisible.value && !isFabDisabled.value) {
//       try {
//         HapticFeedback.lightImpact();
//         isFabExpanded.toggle();
//         print('FAB toggled successfully - Expanded: ${isFabExpanded.value}');
//       } catch (e) {
//         print('Error toggling FAB: $e');
//       }
//     } else {
//       print(
//         'FAB toggle blocked - Visible: ${isFabVisible.value}, Disabled: ${isFabDisabled.value}',
//       );
//     }
//   }

//   // Method to disable FAB temporarily with better error handling
//   void temporarilyDisableFab({Duration duration = const Duration(seconds: 2)}) {
//     if (isClosed) return;

//     print('Temporarily disabling FAB for ${duration.inSeconds} seconds');

//     // Cancel any existing timer
//     _disableTimer?.cancel();

//     isFabDisabled.value = true;
//     isFabExpanded.value = false;

//     // Create new timer
//     _disableTimer = Timer(duration, () {
//       // Check if controller is still initialized
//       if (!isClosed) {
//         isFabDisabled.value = false;
//         print('FAB re-enabled after timeout');
//       }
//     });
//   }

//   void closeFab() {
//     if (isClosed) return;
//     isFabExpanded.value = false;
//   }

//   // Add this method to reset FAB state if needed
//   void resetFabState() {
//     if (isClosed) return;

//     print('Resetting FAB state');
//     _disableTimer?.cancel();
//     isFabExpanded.value = false;
//     isFabVisible.value = true;
//     isFabDisabled.value = false;
//   }

//   // Add method to validate FAB state periodically
//   void _validateFabState() {
//     if (isClosed) return;

//     // If FAB has been disabled for more than 30 seconds, something is wrong
//     if (isFabDisabled.value) {
//       print('Warning: FAB has been disabled for extended period, resetting...');
//       resetFabState();
//     }
//   }

//   // Add method to force enable FAB (for debugging)
//   void forceEnableFab() {
//     if (isClosed) return;

//     print('Force enabling FAB');
//     _disableTimer?.cancel();
//     isFabDisabled.value = false;
//     isFabVisible.value = true;
//   }

//   @override
//   void onClose() {
//     print('FabController disposing...');

//     // Cancel timer first
//     _disableTimer?.cancel();

//     // Remove listener and dispose controller
//     if (_scrollController != null) {
//       try {
//         _scrollController!.removeListener(_scrollListener);
//         _scrollController!.dispose();
//       } catch (e) {
//         print('Error disposing scroll controller: $e');
//       }
//       _scrollController = null;
//     }

//     super.onClose();
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class FabController extends GetxController with GetTickerProviderStateMixin {
  ScrollController? _scrollController;
  final RxBool isFabExpanded = false.obs;
  final RxList events = <dynamic>[].obs;

  var isFabDisabled = false.obs;
  final RxBool isFabVisible = true.obs;
  double lastScrollPosition = 0.0;

  // Animation controllers for X-like animations
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _menuController;

  // Animation objects
  late Animation<double> rotationAnimation;
  late Animation<double> scaleAnimation;
  late Animation<double> menuAnimation;

  static const double scrollThreshold = 10.0;
  DateTime? lastScrollTime;
  static const Duration scrollDebounceTime = Duration(milliseconds: 100);
  Timer? _disableTimer;
  Timer? _autoCloseTimer;

  ScrollController get scrollController {
    _scrollController ??= ScrollController();
    return _scrollController!;
  }

  // Getters for animations
  Animation<double> get rotation => rotationAnimation;
  Animation<double> get scale => scaleAnimation;
  Animation<double> get menu => menuAnimation;

  @override
  void onInit() {
    super.onInit();

    // Initialize animation controllers
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _menuController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    // Create animations with curves
    rotationAnimation =
        Tween<double>(
          begin: 0.0,
          end: 0.125, // 45 degrees (1/8 turn for X rotation)
        ).animate(
          CurvedAnimation(
            parent: _rotationController,
            curve: Curves.easeInOutBack,
          ),
        );

    scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    menuAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _menuController, curve: Curves.easeOutBack),
    );

    scrollController.addListener(_scrollListener);

    // Listen to fab expanded changes to trigger animations
    ever(isFabExpanded, (bool expanded) {
      try {
        if (isClosed) return;

        if (expanded) {
          _rotationController.forward();
          _menuController.forward();
          // _startAutoCloseTimer();
        } else {
          _rotationController.reverse();
          _menuController.reverse();
          _cancelAutoCloseTimer();
        }
      } catch (e) {
        print('Error in animation: $e');
        // Reset animations on error
        if (!isClosed) {
          _rotationController.reset();
          _menuController.reset();
        }
      }
    });

    // Periodic validation
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      _validateFabState();
    });
  }

  void _scrollListener() {
    if (isClosed ||
        _scrollController == null ||
        !_scrollController!.hasClients) {
      return;
    }

    final now = DateTime.now();
    if (lastScrollTime != null &&
        now.difference(lastScrollTime!) < scrollDebounceTime) {
      return;
    }
    lastScrollTime = now;

    try {
      final currentScrollPosition = _scrollController!.offset;
      final scrollDifference = (currentScrollPosition - lastScrollPosition)
          .abs();

      if (scrollDifference < scrollThreshold) return;

      if (currentScrollPosition > lastScrollPosition &&
          currentScrollPosition > 50) {
        if (isFabVisible.value) {
          isFabVisible.value = false;
          if (isFabExpanded.value) {
            closeFab();
          }
        }
      } else if (currentScrollPosition < lastScrollPosition) {
        if (!isFabVisible.value) {
          isFabVisible.value = true;
        }
      }

      lastScrollPosition = currentScrollPosition;
    } catch (e) {
      print('Error in scroll listener: $e');
      lastScrollPosition = 0.0;
    }
  }

  void toggleFab() {
    print(
      'toggleFab called - Visible: ${isFabVisible.value}, Disabled: ${isFabDisabled.value}',
    );

    if (isClosed) {
      print('Controller is disposed, ignoring toggle');
      return;
    }

    if (isFabVisible.value && !isFabDisabled.value) {
      try {
        HapticFeedback.lightImpact();

        // Add scale animation for tap feedback
        _scaleController.forward().then((_) {
          if (!isClosed) {
            _scaleController.reverse();
          }
        });

        isFabExpanded.toggle();
        print('FAB toggled successfully - Expanded: ${isFabExpanded.value}');
      } catch (e) {
        print('Error toggling FAB: $e');
      }
    } else {
      print(
        'FAB toggle blocked - Visible: ${isFabVisible.value}, Disabled: ${isFabDisabled.value}',
      );
    }
  }

  void _startAutoCloseTimer() {
    _cancelAutoCloseTimer();
    _autoCloseTimer = Timer(const Duration(seconds: 5), () {
      if (!isClosed && isFabExpanded.value) {
        closeFab();
      }
    });
  }

  void _cancelAutoCloseTimer() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = null;
  }

  void temporarilyDisableFab({Duration duration = const Duration(seconds: 2)}) {
    if (isClosed) return;

    print('Temporarily disabling FAB for ${duration.inSeconds} seconds');
    _disableTimer?.cancel();

    isFabDisabled.value = true;
    closeFab();

    _disableTimer = Timer(duration, () {
      if (!isClosed) {
        isFabDisabled.value = false;
        print('FAB re-enabled after timeout');
      }
    });
  }

  void closeFab() {
    if (isClosed) return;
    _cancelAutoCloseTimer();
    isFabExpanded.value = false;
  }

  void resetFabState() {
    if (isClosed) return;

    print('Resetting FAB state');
    _disableTimer?.cancel();
    _cancelAutoCloseTimer();

    // Reset animations
    _rotationController.reset();
    _scaleController.reset();
    _menuController.reset();

    isFabExpanded.value = false;
    isFabVisible.value = true;
    isFabDisabled.value = false;
  }

  void _validateFabState() {
    if (isClosed) return;

    if (isFabDisabled.value) {
      print('Warning: FAB has been disabled for extended period, resetting...');
      resetFabState();
    }
  }

  void forceEnableFab() {
    if (isClosed) return;

    print('Force enabling FAB');
    _disableTimer?.cancel();
    _cancelAutoCloseTimer();
    isFabDisabled.value = false;
    isFabVisible.value = true;
  }

  @override
  void onClose() {
    print('FabController disposing...');

    _disableTimer?.cancel();
    _autoCloseTimer?.cancel();

    // Dispose animation controllers
    _rotationController.dispose();
    _scaleController.dispose();
    _menuController.dispose();

    if (_scrollController != null) {
      try {
        _scrollController!.removeListener(_scrollListener);
        _scrollController!.dispose();
      } catch (e) {
        print('Error disposing scroll controller: $e');
      }
      _scrollController = null;
    }

    super.onClose();
  }
}


// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';

// class FabController extends GetxController {
//   final ScrollController scrollController = ScrollController();
//   final RxBool isFabExpanded = false.obs;
//   final RxList events = <dynamic>[].obs;

//   var isFabDisabled = false.obs; // Variable to track disabled state
  
//   // Add these new variables for scroll hide/show functionality
//   final RxBool isFabVisible = true.obs;
//   double lastScrollPosition = 0.0;

//   @override
//   void onInit() {
//     super.onInit();
//     // Add scroll listener for hide/show functionality
//     scrollController.addListener(_scrollListener);
//   }

//   // New method to handle scroll events
//   void _scrollListener() {
//     final currentScrollPosition = scrollController.
//     offset;
    
//     // If scrolling down (current position > last position)
//     if (currentScrollPosition > lastScrollPosition && currentScrollPosition > 50) {
//       if (isFabVisible.value) {
//         isFabVisible.value = false;
//         // Also close FAB when hiding
//         isFabExpanded.value = false;
//       }
//     }
//     // If scrolling up (current position < last position)
//     else if (currentScrollPosition < lastScrollPosition) {
//       if (!isFabVisible.value) {
//         isFabVisible.value = true;
//       }
//     }
    
//     lastScrollPosition = currentScrollPosition;
//   }

//   void toggleFab() {
//     // Only toggle if the FAB is not disabled and is visible
//     if (!isFabDisabled.value && isFabVisible.value) {
//       HapticFeedback.lightImpact();
//       isFabExpanded.toggle();
//     }
//   }

//   // Method to disable FAB temporarily
//   void temporarilyDisableFab() {
//     isFabDisabled.value = true;

//     // Make sure FAB is closed when disabled
//     isFabExpanded.value = false;

//     // Enable after 10 seconds
//     Future.delayed(const Duration(seconds: 10), () {
//       isFabDisabled.value = false;
//     });
//   }

//   void closeFab() {
//     isFabExpanded.value = false;
//   }

//   @override
//   void onClose() {
//     scrollController.dispose();
//     super.onClose();
//   }
// }