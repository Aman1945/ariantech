import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechSearchWidget extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final bool enabled;
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? contentPadding;
  final Duration listenDuration;
  final Duration pauseDuration;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool showBorder;
  final double borderRadius;
  final InputBorder? border;
  final InputBorder? focusedBorder;
  final InputBorder? enabledBorder;

  const SpeechSearchWidget({
    Key? key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 16,
    this.contentPadding,
    this.listenDuration = const Duration(seconds: 30),
    this.pauseDuration = const Duration(seconds: 5),
    this.prefixIcon,
    this.suffixIcon,
    this.showBorder = true,
    this.borderRadius = 8.0,
    this.border,
    this.focusedBorder,
    this.enabledBorder,
  }) : super(key: key);

  @override
  State<SpeechSearchWidget> createState() => _SpeechSearchWidgetState();
}

class _SpeechSearchWidgetState extends State<SpeechSearchWidget>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _isInitialized = false;
  bool _speechAvailable = false;
  bool _isProcessing = false;
  bool _isDisposing = false;
  String _currentLocaleId = '';
  Timer? _forceStopTimer;
  Timer? _stateCheckTimer;
  String? _lastError;

  Color get _primaryColor => widget.primaryColor ?? AppColors.colorsBlue;
  Color get _errorColor => Colors.red;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // _initSpeechEngine();
    _forceAnimationSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposing = true;
    _cancelAllTimers();
    _killSpeechEngine();
    super.dispose();
  }

  void _cancelAllTimers() {
    _forceStopTimer?.cancel();
    _stateCheckTimer?.cancel();
  }

  // === Always force UI to match engine ===
  void _forceAnimationSync() {
    _stateCheckTimer?.cancel();
    _stateCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || _isDisposing || _speech == null) return;
      final actuallyListening = _speech!.isListening;
      if (_isListening != actuallyListening) {
        setState(() => _isListening = actuallyListening);
      }
    });
  }

  Future<void> _killSpeechEngine() async {
    try {
      if (_speech != null) {
        if (_speech!.isListening) {
          await _speech!.stop();
          await Future.delayed(const Duration(milliseconds: 100));
          await _speech!.cancel();
        }
      }
    } catch (_) {}
    _speech = null;
  }

  Future<void> _initSpeechEngine() async {
    _isProcessing = true;
    await _killSpeechEngine();
    _speech = stt.SpeechToText();

    try {
      bool hasPermission = await _checkMicrophonePermission();
      if (!mounted) return;

      if (!hasPermission) {
        setState(() {
          _isInitialized = true;
          _speechAvailable = false;
        });
        // _showFeedback("Microphone permission not granted", isError: true);
        return;
      }

      _speechAvailable = await _speech!.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
        debugLogging: false,
      );

      if (_speechAvailable) {
        final locales = await _speech!.locales();
        List<String> englishLocaleIds = [
          'en_US',
          'en_GB',
          'en_IN',
          'en_AU',
          'en_CA',
          'en_IE',
          'en_SG',
        ];
        _currentLocaleId = locales
            .map((l) => l.localeId)
            .firstWhere(
              (id) => englishLocaleIds.contains(id),
              orElse: () => locales.first.localeId,
            );
      }

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _speechAvailable = false;
        });
      }
    }
    _isProcessing = false;
  }

  Future<bool> _checkMicrophonePermission() async {
    try {
      if (Platform.isIOS) {
        bool speechPermission = await _speech!.hasPermission;
        PermissionStatus micStatus = await Permission.microphone.status;

        if (speechPermission) {
          return true;
        }

        if (!speechPermission && !micStatus.isGranted) {
          _showPermissionDialog();
          return false;
        }

        return speechPermission;
      } else {
        PermissionStatus micStatus = await Permission.microphone.status;

        if (micStatus.isGranted) {
          return true;
        }

        if (micStatus.isPermanentlyDenied) {
          _showPermissionDialog();
          return false;
        }

        PermissionStatus requestResult = await Permission.microphone.request();
        if (!requestResult.isGranted) {
          _showPermissionDialog();
        }
        return requestResult.isGranted;
      }
    } catch (e) {
      return false;
    }
  }

  void _showPermissionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: Text(
          Platform.isIOS
              ? 'This app needs microphone and speech recognition permissions to work properly. Please enable them in Settings > Privacy & Security > Microphone and Speech Recognition.'
              : 'This app needs microphone permission to work properly. Please enable it in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status == 'notListening' || status == 'done') {
      _updateListeningUI(false);
      _forceStopTimer?.cancel();
      // Aggressive cleanup to prevent system sound popup
      Future.delayed(const Duration(milliseconds: 50), () async {
        if (mounted && _speech != null) {
          try {
            await _speech!.cancel();
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted && !_isListening) {
              _initSpeechEngine();
            }
          } catch (_) {}
        }
      });
    } else if (status == 'listening') {
      _updateListeningUI(true);
      _startForceStopTimer();
    }
  }

  void _onSpeechError(dynamic error) {
    if (!mounted) return;
    _updateListeningUI(false);
    _lastError = error.toString();
    _showFeedback(_getErrorMessage(_lastError!), isError: true);
    _forceStopTimer?.cancel();

    // Aggressive cleanup to prevent system sound popup after error
    Future.delayed(const Duration(milliseconds: 50), () async {
      if (mounted && _speech != null) {
        try {
          await _speech!.cancel();
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted && !_isListening) {
            await _killSpeechEngine();
            await Future.delayed(const Duration(milliseconds: 200));
            _initSpeechEngine();
          }
        } catch (_) {}
      }
    });
  }

  void _updateListeningUI(bool listening) {
    if (!mounted) return;
    if (_isListening != listening) {
      setState(() => _isListening = listening);
    }
  }

  void _startForceStopTimer() {
    _forceStopTimer?.cancel();
    _forceStopTimer = Timer(const Duration(seconds: 10), () async {
      if (mounted && _isListening) {
        _updateListeningUI(false);
        try {
          if (_speech != null && _speech!.isListening) {
            await _speech!.stop();
            await Future.delayed(const Duration(milliseconds: 300));
            await _speech!.cancel();
            await Future.delayed(const Duration(milliseconds: 200));
            await _killSpeechEngine();
            await Future.delayed(const Duration(milliseconds: 300));
            _initSpeechEngine();
          }
        } catch (_) {}
        _showFeedback("Mic stopped due to inactivity.", isError: true);
      }
    });
  }

  Future<void> _startListening() async {
    if (!mounted || !_isInitialized || !_speechAvailable || _isProcessing)
      return;
    if (_speech == null) return;

    if (!await _checkMicrophonePermission()) {
      _showFeedback("Please enable microphone permissions!", isError: true);
      return;
    }

    if (_speech!.isListening) {
      await _speech!.stop();
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _updateListeningUI(true);

    try {
      await _speech!.listen(
        onResult: _onSpeechResult,
        listenFor: widget.listenDuration,
        pauseFor: widget.pauseDuration,
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      );
      _startForceStopTimer();
    } catch (e) {
      _updateListeningUI(false);
      _showFeedback(_getErrorMessage(e.toString()), isError: true);
      _forceStopTimer?.cancel();
    }
  }

  Future<void> _stopListening() async {
    if (!mounted || _speech == null) return;
    _forceStopTimer?.cancel();

    _updateListeningUI(false);

    try {
      if (_speech!.isListening) {
        await _speech!.stop();
        await Future.delayed(const Duration(milliseconds: 300));
        await _speech!.cancel();
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (_) {}

    // Force reinitialize speech engine to clean state
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_isListening) {
        _initSpeechEngine();
      }
    });
  }

  String _getErrorMessage(String error) {
    if (error.contains('speech timeout') || error.contains('e_4')) {
      return 'Listening timed out. Please speak sooner.';
    } else if (error.contains('no-speech') || error.contains('e_6')) {
      return 'No speech was detected.';
    } else if (error.contains('network') || error.contains('e_7')) {
      return 'A network error occurred.';
    } else if (error.contains('audio') || error.contains('e_3')) {
      return 'Microphone access error.';
    } else if (error.contains('Speech recognition not available') ||
        error.contains('ERROR_CLIENT')) {
      return 'Speech-to-text is not available on this device.';
    }
    return 'No speech was detected.';
  }

  void _onSpeechResult(stt.SpeechRecognitionResult result) {
    if (!mounted) return;

    if (result.finalResult) {
      widget.controller.text = result.recognizedWords;
      widget.onChanged?.call(result.recognizedWords);

      // Stop listening immediately after getting final result
      Future.delayed(const Duration(milliseconds: 200), () async {
        if (mounted && _isListening) {
          await _stopListening();
        }
      });
    }

    if (_isListening) _startForceStopTimer();
  }

  void _showFeedback(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? _errorColor : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopListening();
    }
    if (state == AppLifecycleState.resumed) {
      _forceAnimationSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      constraints: BoxConstraints(
        minHeight: 40, // Minimum touch target size
        maxHeight: 48, // Maximum height for single line
      ),
      child: TextField(
        controller: widget.controller,
        enabled: widget.enabled && !_isListening,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        style: TextStyle(
          fontSize: widget.fontSize,
          color: widget.textColor,
          fontFamily: GoogleFonts.poppins().fontFamily,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: _isListening ? "Listening..." : widget.hintText,
          hintStyle: TextStyle(
            color: _isListening ? _primaryColor : Colors.grey.shade500,
            fontFamily: GoogleFonts.poppins().fontFamily,
            fontWeight: FontWeight.w300,
            fontSize: widget.fontSize! * 0.95,
          ),
          prefixIcon: widget.prefixIcon,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.suffixIcon != null) widget.suffixIcon!,
              _buildSpeechButton(),
            ],
          ),
          contentPadding:
              widget.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          filled: true,
          fillColor: widget.backgroundColor ?? Colors.grey.shade50,
          border:
              widget.border ??
              (widget.showBorder
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide.none,
                    )
                  : InputBorder.none),
          enabledBorder:
              widget.enabledBorder ??
              (widget.showBorder
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1.5,
                      ),
                    )
                  : InputBorder.none),
          focusedBorder:
              widget.focusedBorder ??
              (widget.showBorder
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(color: _primaryColor, width: 0.2),
                    )
                  : InputBorder.none),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            borderSide: BorderSide(color: Colors.red.shade400, width: 2.0),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeechButton() {
    if (!_speechAvailable) {
      return Container(
        margin: EdgeInsets.only(right: 6),
        child: IconButton(
          onPressed: _initSpeechEngine,
          icon: Icon(
            Icons.mic_off_rounded,
            color: Colors.grey.shade400,
            size: 16,
          ),
          tooltip: 'Microphone not available',
          splashRadius: 18,
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        margin: EdgeInsets.only(right: 8),
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: (_speechAvailable && !_isProcessing)
              ? () {
                  if (_isListening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(20),
          splashColor: _primaryColor.withOpacity(0.1),
          highlightColor: _primaryColor.withOpacity(0.05),
          child: Container(
            padding: EdgeInsets.all(6),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  _isListening
                      ? FontAwesomeIcons.stop
                      : FontAwesomeIcons.microphone,
                  key: ValueKey(_isListening),
                  color: _isListening
                      ? Colors.red.shade500
                      : (_speechAvailable
                            ? _primaryColor
                            : Colors.grey.shade400),
                  size: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//       child: TextField(
//         controller: widget.controller,
//         enabled: widget.enabled && !_isListening,
//         onChanged: widget.onChanged,
//         onSubmitted: widget.onSubmitted,
//         style: TextStyle(fontSize: widget.fontSize, color: widget.textColor),
//         decoration: InputDecoration(
//           hintText: _isListening ? "Listening..." : widget.hintText,
//           hintStyle: TextStyle(
//             color: _isListening ? _primaryColor : Colors.grey,
//           ),
//           prefixIcon: widget.prefixIcon,
//           suffixIcon: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (widget.suffixIcon != null) widget.suffixIcon!,
//               _buildSpeechButton(),
//             ],
//           ),
//           contentPadding:
//               widget.contentPadding ??
//               const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           filled: widget.backgroundColor != null,
//           fillColor: widget.backgroundColor,
//           border:
//               widget.border ??
//               (widget.showBorder
//                   ? OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(widget.borderRadius),
//                     )
//                   : InputBorder.none),
//           enabledBorder:
//               widget.enabledBorder ??
//               (widget.showBorder
//                   ? OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(widget.borderRadius),
//                       borderSide: BorderSide(color: Colors.grey.shade300),
//                     )
//                   : InputBorder.none),
//           focusedBorder:
//               widget.focusedBorder ??
//               (widget.showBorder
//                   ? OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(widget.borderRadius),
//                       borderSide: BorderSide(color: _primaryColor),
//                     )
//                   : InputBorder.none),
//         ),
//       ),
//     );
//   }

//   Widget _buildSpeechButton() {
//     if (!_speechAvailable) {
//       return IconButton(
//         onPressed: null,
//         icon: const Icon(Icons.mic_off, color: Colors.grey),
//         tooltip: 'Microphone not available',
//       );
//     }

//     if (!_isInitialized) {
//       return const Padding(
//         padding: EdgeInsets.all(12.0),
//         child: SizedBox(
//           width: 18,
//           height: 18,
//           child: CircularProgressIndicator(strokeWidth: 2),
//         ),
//       );
//     }

//     return IconButton(
//       onPressed: (_speechAvailable && !_isProcessing)
//           ? () {
//               if (_isListening) {
//                 _stopListening();
//               } else {
//                 _startListening();
//               }
//             }
//           : null,
//       icon: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 200),
//         child: Icon(
//           _isListening ? FontAwesomeIcons.stop : FontAwesomeIcons.microphone,
//           key: ValueKey(_isListening),
//           color: _isListening
//               ? Colors.red
//               : (_speechAvailable ? _primaryColor : Colors.grey),
//           size: 16,
//         ),
//       ),
//       tooltip: _isListening ? 'Stop recording' : 'Start voice input',
//       splashRadius: 24,
//     );
//   }
// }

// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_recognition_result.dart' as stt;
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:permission_handler/permission_handler.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:smartassist/config/component/color/colors.dart'; // Adjust import based on your project

// class GlobleSpeechtotext extends StatefulWidget {
//   final Function(String) onSpeechResult; // Callback for final speech result
//   final Function(bool)? onListeningStateChanged; // Callback for listening state
//   final double iconSize; // Customizable icon size
//   final Color activeColor; // Color when listening
//   final Color inactiveColor; // Color when not listening
//   final Duration listenDuration; // Add this
//   final Duration pauseDuration;

//   const GlobleSpeechtotext({
//     super.key,
//     required this.onSpeechResult,
//     this.onListeningStateChanged,
//     this.iconSize = 16.0,
//     this.activeColor = AppColors.iconGrey,
//     this.inactiveColor = AppColors.fontColor,
//     this.listenDuration = const Duration(seconds: 30), // Default
//     this.pauseDuration = const Duration(seconds: 5), // Default
//   });

//   @override
//   State<GlobleSpeechtotext> createState() => _GlobleSpeechtotextState();
// }

// class _GlobleSpeechtotextState extends State<GlobleSpeechtotext>
//     with TickerProviderStateMixin, WidgetsBindingObserver {
//   final stt.SpeechToText _speech = stt.SpeechToText();
//   bool _isListening = false;
//   bool _isInitialized = false;
//   bool _speechAvailable = false;
//   String _currentWords = '';
//   double _confidence = 0.0;
//   String _currentLocaleId = '';
//   late AnimationController _waveController;
//   late Animation<double> _waveAnimation;
//   Timer? _timeoutTimer;
//   Timer? _stateCheckTimer;
//   Color get _primaryColor => widget.activeColor ?? AppColors.iconGrey;
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
//     _initializeAnimations();
//     _initializeSpeech();
//     _startStateMonitoring(); // Start state monitoring
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this); // Remove observer
//     _stateCheckTimer?.cancel(); // Cancel state timer
//     _waveController.dispose();
//     _timeoutTimer?.cancel();
//     if (_speech.isListening) {
//       _speech.cancel();
//     }
//     super.dispose();
//   }

//   // @override
//   // void didChangeAppLifecycleState(AppLifecycleState state) {
//   //   super.didChangeAppLifecycleState(state);
//   //   if (state == AppLifecycleState.resumed) {
//   //     _syncSpeechState();
//   //   } else if (state == AppLifecycleState.paused ||
//   //       state == AppLifecycleState.inactive) {
//   //     if (_isListening) {
//   //       _forceStopListening();
//   //     }
//   //   }
//   // }
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     if (state == AppLifecycleState.resumed) {
//       // Reset all states to force re-initialization
//       setState(() {
//         _isInitialized = false;
//         _speechAvailable = false;
//         _isListening = false;
//       });
//       _initializeSpeech();
//       debugPrint(
//         'App resumed, re-initializing speech and checking permissions',
//       );
//     } else if (state == AppLifecycleState.paused ||
//         state == AppLifecycleState.inactive) {
//       if (_isListening) {
//         _forceStopListening();
//       }
//     }
//   }

//   void _startStateMonitoring() {
//     _stateCheckTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (mounted) {
//         _syncSpeechState();
//       }
//     });
//   }

//   void _syncSpeechState() {
//     if (!mounted || !_isInitialized) return;

//     bool actuallyListening = _speech.isListening;

//     if (_isListening != actuallyListening) {
//       debugPrint(
//         'State mismatch detected! UI: $_isListening, Engine: $actuallyListening',
//       );
//       if (actuallyListening && !_isListening) {
//         setState(() {
//           _isListening = true;
//         });
//         widget.onListeningStateChanged?.call(true);
//         _startAnimations();
//       } else if (!actuallyListening && _isListening) {
//         _forceStopListening();
//       }
//     }
//   }

//   void _initializeAnimations() {
//     _waveController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );
//     _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
//     );
//   }

//   Future<void> _initializeSpeech() async {
//     try {
//       debugPrint('Starting speech initialization');
//       bool hasPermission = await _checkMicrophonePermission();
//       if (!mounted) return;

//       if (!hasPermission) {
//         setState(() => _isInitialized = true);
//         debugPrint('Microphone permissions not granted');
//         _showFeedback(
//           'Please grant microphone and speech permissions in Settings.',
//           isError: true,
//         );
//         return;
//       }

//       debugPrint('Initializing speech_to_text plugin');
//       _speechAvailable = await _speech.initialize(
//         onStatus: (status) => _onSpeechStatus(status),
//         onError: (error) => _onSpeechError(error),
//         debugLogging: true, // Enable detailed logging
//       );

//       if (_speechAvailable) {
//         var locales = await _speech.locales();
//         debugPrint(
//           'Available locales: ${locales.map((l) => l.localeId).join(', ')}',
//         );

//         var englishLocale = locales.firstWhere(
//           (locale) => locale.localeId == 'en_US',
//           orElse: () => locales.firstWhere(
//             (locale) => locale.localeId.startsWith('en'),
//             orElse: () => locales.isNotEmpty
//                 ? locales.first
//                 : stt.LocaleName('en_US', 'English'),
//           ),
//         );
//         _currentLocaleId = englishLocale.localeId;
//         debugPrint('Selected locale: $_currentLocaleId');
//       } else {
//         debugPrint('Speech initialization failed');
//         _showFeedback(
//           'Speech recognition not available. Check your connection or permissions.',
//           isError: true,
//         );
//       }

//       if (mounted) {
//         setState(() => _isInitialized = true);
//         debugPrint(
//           'Speech initialization complete, _speechAvailable: $_speechAvailable',
//         );
//       }
//     } catch (e) {
//       debugPrint('Speech initialization error: $e');
//       if (mounted) {
//         setState(() {
//           _isInitialized = true;
//           _speechAvailable = false;
//         });
//         _showFeedback(
//           'Failed to initialize speech recognition: $e',
//           isError: true,
//         );
//       }
//     }
//   }

//   void _onSpeechStatus(String status) {
//     if (!mounted) return;
//     debugPrint('Speech engine status: $status. UI is listening: $_isListening');

//     _timeoutTimer?.cancel();

//     if (status == 'notListening' || status == 'done') {
//       if (_isListening) {
//         debugPrint('Engine stopped unexpectedly. Forcing UI to update.');
//         _forceStopListening();
//       }
//     } else if (status == 'listening') {
//       if (!_isListening) {
//         setState(() {
//           _isListening = true;
//         });
//         widget.onListeningStateChanged?.call(true);
//         _startAnimations();
//       }
//       _timeoutTimer = Timer(
//         widget.listenDuration + const Duration(seconds: 5),
//         () {
//           if (_isListening) {
//             debugPrint('Safety timeout triggered');
//             _forceStopListening(showError: true, error: 'Speech timeout');
//           }
//         },
//       );
//     }
//   }

//   Future<bool> _checkMicrophonePermission() async {
//     try {
//       if (Platform.isIOS) {
//         // Check current status
//         PermissionStatus micStatus = await Permission.microphone.status;
//         PermissionStatus speechStatus = await Permission.speech.status;
//         debugPrint('Initial microphone status: $micStatus');
//         debugPrint('Initial speech status: $speechStatus');

//         // If both are granted, return true
//         if (micStatus.isGranted && speechStatus.isGranted) {
//           debugPrint('Both permissions granted');
//           return true;
//         }

//         // If permanently denied, show dialog and return false
//         if (micStatus.isPermanentlyDenied || speechStatus.isPermanentlyDenied) {
//           debugPrint('One or both permissions permanently denied');
//           _showPermissionDialog();
//           // Attempt to re-check status after a delay to ensure Settings changes are detected
//           await Future.delayed(const Duration(milliseconds: 500));
//           micStatus = await Permission.microphone.status;
//           speechStatus = await Permission.speech.status;
//           debugPrint('Re-checked microphone status: $micStatus');
//           debugPrint('Re-checked speech status: $speechStatus');
//           if (micStatus.isGranted && speechStatus.isGranted) {
//             return true;
//           }
//           if (micStatus.isPermanentlyDenied ||
//               speechStatus.isPermanentlyDenied) {
//             return false;
//           }
//         }

//         // Request permissions sequentially
//         if (!micStatus.isGranted) {
//           micStatus = await Permission.microphone.request();
//           debugPrint('Microphone permission after request: $micStatus');
//         }

//         if (micStatus.isGranted && !speechStatus.isGranted) {
//           speechStatus = await Permission.speech.request();
//           debugPrint('Speech permission after request: $speechStatus');
//         }

//         bool finalResult = micStatus.isGranted && speechStatus.isGranted;
//         debugPrint('Final permission result: $finalResult');

//         if (!finalResult &&
//             (micStatus.isPermanentlyDenied ||
//                 speechStatus.isPermanentlyDenied)) {
//           debugPrint('Permissions denied after request, showing dialog');
//           _showPermissionDialog();
//         }

//         return finalResult;
//       } else {
//         // Android
//         PermissionStatus status = await Permission.microphone.status;
//         debugPrint('Initial microphone status (Android): $status');
//         if (status.isGranted) {
//           return true;
//         }
//         if (status.isPermanentlyDenied) {
//           debugPrint('Microphone permission permanently denied (Android)');
//           _showPermissionDialog();
//           return false;
//         }
//         status = await Permission.microphone.request();
//         debugPrint('Microphone permission after request (Android): $status');
//         return status.isGranted;
//       }
//     } catch (e) {
//       debugPrint('Permission check error: $e');
//       return false;
//     }
//   }

//   void _showPermissionDialog() {
//     if (!mounted) return;
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             title: const Text('Permissions Required'),
//             content: const Text(
//               'This app needs microphone and speech recognition permissions to function properly. Please enable them in Settings.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 child: const Text('Cancel'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   openAppSettings();
//                 },
//                 child: const Text('Open Settings'),
//               ),
//             ],
//           );
//         },
//       );
//     });
//   }

//   void _onSpeechError(dynamic error) {
//     debugPrint('Speech error: $error');
//     if (!mounted) return;
//     _forceStopListening(showError: true, error: error.toString());
//   }

//   void _startAnimations() {
//     if (mounted && !_waveController.isAnimating) {
//       _waveController.repeat();
//     }
//   }

//   void _stopAnimations() {
//     if (mounted) {
//       _waveController.stop();
//       _waveController.reset();
//     }
//   }

//   Future<void> _toggleSpeechRecognition() async {
//     if (!_isInitialized) return;
//     if (!_speechAvailable) {
//       _showFeedback('Speech recognition not available.', isError: true);
//       _initializeSpeech();
//       return;
//     }

//     if (_isListening) {
//       await _stopListening();
//     } else {
//       await _startListening();
//     }
//   }

//   Future<void> _startListening() async {
//     if (!mounted) return;

//     if (_speech.isListening) {
//       debugPrint('Speech engine already listening, stopping first');
//       await _speech.stop();
//       await Future.delayed(const Duration(milliseconds: 100));
//     }

//     setState(() {
//       _isListening = true;
//       _currentWords = '';
//     });
//     widget.onListeningStateChanged?.call(true);
//     _startAnimations();

//     try {
//       await _speech.listen(
//         onResult: _onSpeechResult,
//         listenFor: widget.listenDuration, // Use custom duration
//         pauseFor: widget.pauseDuration, // Use custom duration
//         partialResults: true,
//         cancelOnError: true,
//         listenMode: stt.ListenMode.dictation,
//         localeId: _currentLocaleId,
//       );
//     } catch (e) {
//       debugPrint('Error starting listen: $e');
//       await _forceStopListening(showError: true, error: e.toString());
//     }
//   }

//   Future<void> _stopListening({bool showError = false, String? error}) async {
//     if (!mounted) return;

//     setState(() {
//       _isListening = false;
//     });
//     widget.onListeningStateChanged?.call(false);
//     _stopAnimations();
//     _timeoutTimer?.cancel();

//     if (_speech.isListening) {
//       try {
//         await _speech.stop();
//       } catch (e) {
//         debugPrint('Error stopping speech: $e');
//       }
//     }

//     if (showError && error != null) {
//       _showFeedback(_getErrorMessage(error), isError: true);
//     }
//   }

//   Future<void> _forceStopListening({
//     bool showError = false,
//     String? error,
//   }) async {
//     if (!mounted) return;

//     setState(() {
//       _isListening = false;
//     });
//     widget.onListeningStateChanged?.call(false);
//     _stopAnimations();
//     _timeoutTimer?.cancel();

//     if (_speech.isListening) {
//       try {
//         await _speech.cancel();
//       } catch (e) {
//         debugPrint('Error canceling speech: $e');
//       }
//     }

//     if (showError && error != null) {
//       _showFeedback(_getErrorMessage(error), isError: true);
//     }
//   }

//   void _onSpeechResult(stt.SpeechRecognitionResult result) {
//     if (!mounted) return;

//     setState(() {
//       _currentWords = result.recognizedWords;
//       _confidence = result.confidence;
//     });

//     if (result.recognizedWords.isNotEmpty) {
//       String formattedWords = result.recognizedWords.trim();
//       if (formattedWords.isNotEmpty) {
//         formattedWords =
//             formattedWords[0].toUpperCase() + formattedWords.substring(1);
//       }
//       widget.onSpeechResult(formattedWords);
//     }

//     if (result.finalResult) {
//       Future.delayed(const Duration(milliseconds: 400), () {
//         if (mounted && _isListening) {
//           _stopListening();
//         }
//       });
//     }
//   }

//   String _getErrorMessage(String error) {
//     if (error.contains('speech timeout') || error.contains('e_4')) {
//       return 'Listening timed out. Please speak sooner.';
//     } else if (error.contains('no-speech') || error.contains('e_6')) {
//       return 'No speech detected.';
//     } else if (error.contains('network') || error.contains('e_7')) {
//       return 'Network error occurred.';
//     } else if (error.contains('audio') || error.contains('e_3')) {
//       return 'Microphone access error.';
//     }
//     return 'Speech recognition error.';
//   }

//   void _showFeedback(String message, {required bool isError}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).hideCurrentSnackBar();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _toggleSpeechRecognition,
//       child: AnimatedBuilder(
//         animation: _waveAnimation,
//         builder: (context, child) {
//           return Stack(
//             alignment: Alignment.center,
//             children: [
//               if (_isListening)
//                 Container(
//                   width: widget.iconSize * 1.5,
//                   height: widget.iconSize * 1.5,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: widget.activeColor.withOpacity(
//                       0.2 * _waveAnimation.value,
//                     ),
//                   ),
//                 ),
//               Icon(
//                 _isListening
//                     ? FontAwesomeIcons.stop
//                     : FontAwesomeIcons.microphone,
//                 color: _isListening
//                     ? Colors.red
//                     : (_speechAvailable ? _primaryColor : AppColors.iconGrey),
//                 size: widget.iconSize,
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
