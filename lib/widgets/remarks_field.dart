import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class EnhancedSpeechTextField extends StatefulWidget {
  final bool isRequired;
  final String label;
  final bool error;
  final TextEditingController controller;
  final String hint;
  final Function(String)? onChanged;
  final bool enabled;
  final int maxLines;
  final int minLines;
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? contentPadding;
  final bool showLiveTranscription;
  final Duration listenDuration;
  final Duration pauseDuration;

  const EnhancedSpeechTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 5,
    this.minLines = 1,
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 14,
    this.contentPadding,
    this.showLiveTranscription = true,
    this.listenDuration = const Duration(seconds: 30),
    this.pauseDuration = const Duration(seconds: 5),
    required this.isRequired,
    required this.error,
  });

  @override
  State<EnhancedSpeechTextField> createState() =>
      _EnhancedSpeechTextFieldState();
}

class _EnhancedSpeechTextFieldState extends State<EnhancedSpeechTextField>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  stt.SpeechToText? _speech;
  bool _isListening = false;
  bool _isInitialized = false;
  bool _speechAvailable = false;
  String _currentLocaleId = '';
  late AnimationController _waveController;
  Timer? _forceStopTimer;
  Timer? _stateCheckTimer;
  Timer? _engineSyncTimer;
  bool _isDisposing = false;
  bool _isProcessing = false;
  String? _lastError;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  bool _permissionChecked = false; //remove this is not working on the samsung
  Color get _primaryColor => widget.primaryColor ?? Colors.grey.shade800;
  Color get _errorColor => Colors.red;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    // _initSpeechEngine();
    _forceAnimationSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _isDisposing = true;
    _cancelAllTimers();
    _waveController.dispose();
    _killSpeechEngine();
    _flutterTts.stop(); // Add this line
    super.dispose();
  }

  void _cancelAllTimers() {
    _forceStopTimer?.cancel();
    _stateCheckTimer?.cancel();
    _engineSyncTimer?.cancel();
  }

  void _forceAnimationSync() {
    _stateCheckTimer?.cancel();
    _stateCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || _isDisposing || _speech == null) return;

      final actuallyListening = _speech!.isListening;
      if (_isListening != actuallyListening) {
        if (mounted) setState(() => _isListening = actuallyListening);
        if (actuallyListening) {
          _waveController.repeat();
        } else {
          _waveController.stop();
          _waveController.reset();
        }
      }
      if (!actuallyListening) {
        _waveController.stop();
        _waveController.reset();
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
        // Clear callbacks to prevent further setState calls
        _speech = null;
      }
    } catch (_) {}
  }

  // Future<void> _initSpeechEngine() async {
  //   _isProcessing = true;
  //   await _killSpeechEngine();
  //   _speech = stt.SpeechToText();

  //   _speechAvailable = await _speech!.initialize(
  //     onStatus: _onSpeechStatus,
  //     onError: _onSpeechError,
  //     debugLogging: false,
  //   );

  //   if (_speechAvailable) {
  //     final locales = await _speech!.locales();
  //     List<String> englishLocaleIds = [
  //       'en_US',
  //       'en_GB',
  //       'en_IN',
  //       'en_AU',
  //       'en_CA',
  //       'en_IE',
  //       'en_SG',
  //     ];
  //     _currentLocaleId = locales
  //         .map((l) => l.localeId)
  //         .firstWhere(
  //           (id) => englishLocaleIds.contains(id),
  //           orElse: () => locales.first.localeId,
  //         );
  //   }

  //   // Initialize TTS here
  //   await _initTextToSpeech();

  //   try {
  //     if (mounted) setState(() => _isInitialized = true);
  //   } catch (e) {
  //     debugPrint('Speech init error: $e');
  //     if (mounted) {
  //       setState(() {
  //         _isInitialized = true;
  //         _speechAvailable = false;
  //       });
  //     }
  //   }
  //   _isProcessing = false;
  // }

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

      // Initialize TTS after speech
      await _initTextToSpeech();

      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Speech init error: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _speechAvailable = false;
        });
      }
    }
    _isProcessing = false;
  }

  Future<void> _initTextToSpeech() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      _flutterTts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });

      _flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        if (mounted) setState(() => _isSpeaking = false);
      });

      debugPrint('Text-to-speech initialized');
    } catch (e) {
      debugPrint('TTS initialization error: $e');
    }
  }

  // Future<void> _initTextToSpeech() async {
  //   try {
  //     await _flutterTts.setLanguage("en-US");
  //     await _flutterTts.setSpeechRate(0.5);
  //     await _flutterTts.setPitch(1.0);
  //     await _flutterTts.setVolume(1.0);

  //     _flutterTts.setStartHandler(() {
  //       if (mounted) setState(() => _isSpeaking = true);
  //     });

  //     _flutterTts.setCompletionHandler(() {
  //       if (mounted) setState(() => _isSpeaking = false);
  //     });

  //     _flutterTts.setErrorHandler((msg) {
  //       debugPrint('TTS Error: $msg');
  //       if (mounted) setState(() => _isSpeaking = false);
  //     });

  //     debugPrint('Text-to-speech initialized');
  //   } catch (e) {
  //     debugPrint('TTS initialization error: $e');
  //   }
  // }

  Future<void> _speakText() async {
    try {
      if (_isSpeaking) {
        await _flutterTts.stop();
        setState(() => _isSpeaking = false);
      } else if (widget.controller.text.trim().isNotEmpty) {
        await _flutterTts.speak(widget.controller.text);
      }
    } catch (e) {
      debugPrint('TTS speak error: $e');
      _showFeedback("Failed to speak text: $e", isError: true);
    }
  }

  // if not working in the samsung remove this one and add the bottom one so it will work fine in samsung
  // Future<bool> _checkMicrophonePermission() async {
  //   if (_permissionChecked) {
  //     // Check current status without requesting again
  //     PermissionStatus currentStatus = await Permission.microphone.status;
  //     return currentStatus.isGranted;
  //   }

  //   try {
  //     if (Platform.isIOS) {
  //       Map<Permission, PermissionStatus> statuses = await [
  //         Permission.microphone,
  //         Permission.speech,
  //       ].request();

  //       bool micGranted = statuses[Permission.microphone]?.isGranted ?? false;
  //       bool speechGranted = statuses[Permission.speech]?.isGranted ?? false;

  //       setState(() => _permissionChecked = true);

  //       if (!micGranted || !speechGranted) {
  //         // _showPermissionDialog();
  //         print('permission not granted');
  //         return false;
  //       }
  //       return true;
  //     } else {
  //       PermissionStatus micStatus = await Permission.microphone.request();
  //       setState(() => _permissionChecked = true);

  //       if (!micStatus.isGranted) {
  //         // _showPermissionDialog();
  //       }
  //       return micStatus.isGranted;
  //     }
  //   } catch (e) {
  //     debugPrint('Permission check error: $e');
  //     setState(() => _permissionChecked = true);
  //     return false;
  //   }
  // }

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

  // Future<bool> _checkMicrophonePermission() async {
  //   try {
  //     if (Platform.isIOS) {
  //       bool speechPermission = await _speech!.hasPermission;
  //       PermissionStatus micStatus = await Permission.microphone.status;

  //       if (speechPermission) {
  //         return true;
  //       }

  //       if (!speechPermission && !micStatus.isGranted) {
  //         _showPermissionDialog();
  //         return false;
  //       }

  //       return speechPermission;
  //     } else {
  //       PermissionStatus micStatus = await Permission.microphone.status;

  //       if (micStatus.isGranted) {
  //         return true;
  //       }

  //       if (micStatus.isPermanentlyDenied) {
  //         _showPermissionDialog();
  //         return false;
  //       }

  //       PermissionStatus requestResult = await Permission.microphone.request();
  //       if (!requestResult.isGranted) {
  //         _showPermissionDialog();
  //       }
  //       return requestResult.isGranted;
  //     }
  //   } catch (e) {
  //     return false;
  //   }
  // }

  // void _showPermissionDialog() {
  //   if (!mounted) return;
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Permissions Required'),
  //       content: const Text(
  //         'This app needs microphone and speech recognition permissions to work properly. Please enable them in Settings.',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Cancel'),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             openAppSettings();
  //           },
  //           child: const Text('Open Settings'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    debugPrint('[onStatus] $status');
    if (status == 'notListening' || status == 'done') {
      _updateListeningUI(false);
      _forceStopTimer?.cancel();
      // Aggressive cleanup to prevent system sound popup
      Future.delayed(const Duration(milliseconds: 50), () async {
        if (mounted && _speech != null) {
          try {
            await _speech!.cancel();
            // Additional delay and reinit to ensure clean state
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
    debugPrint('[onError] $error');
    _updateListeningUI(false);
    _lastError = error.toString();
    _showFeedback(_getErrorMessage(_lastError!), isError: true);
    _forceStopTimer?.cancel();

    // Aggressive cleanup to prevent system sound popup after error
    Future.delayed(const Duration(milliseconds: 50), () async {
      if (mounted && _speech != null) {
        try {
          await _speech!.cancel();
          // Kill and reinitialize engine to prevent phantom mic sounds
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted && !_isListening) {
            await _killSpeechEngine();
            await Future.delayed(const Duration(milliseconds: 200));
            _initSpeechEngine();
          }
        } catch (_) {}
      }
    });

    // For Samsung bug: show help
    // if (_lastError != null &&
    //     (_lastError!.contains('Speech recognition not available') ||
    //         _lastError!.contains('ERROR_CLIENT') ||
    //         _lastError!.contains('not available on device'))) {
    //   _showSamsungSpeechErrorDialog();
    // }
  }

  void _showSamsungSpeechErrorDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Speech Input Not Working'),
        content: const Text(
          'Speech-to-text is not available on your device or requires Samsung Voice Input to be enabled. '
          '\n\nPlease:\n'
          '1. Go to Settings > General Management > Keyboard list and default\n'
          '2. Enable Google Voice Typing or your preferred Speech service\n'
          '3. Set it as default\n'
          'If problem persists, try updating Google App and Samsung Keyboard via Play Store.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _updateListeningUI(bool listening) {
    if (!mounted) return;
    if (_isListening != listening) {
      setState(() => _isListening = listening);
    }
    if (listening) {
      _waveController.repeat();
    } else {
      _waveController.stop();
      _waveController.reset();
    }
  }

  void _startForceStopTimer() {
    _forceStopTimer?.cancel();
    _forceStopTimer = Timer(const Duration(seconds: 10), () async {
      if (!mounted || !_isListening) return; // Add mounted check here

      debugPrint('[SAFETY TIMEOUT] No speech or engine event - force stop.');
      _updateListeningUI(false);

      try {
        if (_speech != null && _speech!.isListening) {
          await _speech!.stop();
          await Future.delayed(const Duration(milliseconds: 300));
          await _speech!.cancel();
          await Future.delayed(const Duration(milliseconds: 200));
          await _killSpeechEngine();
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) _initSpeechEngine(); // Add mounted check here
        }
      } catch (_) {}

      if (mounted)
        _showFeedback("Mic stopped due to inactivity.", isError: true);
    });
  }

  // void _startForceStopTimer() {
  //   _forceStopTimer?.cancel();
  //   _forceStopTimer = Timer(const Duration(seconds: 10), () async {
  //     if (mounted && _isListening) {
  //       debugPrint('[SAFETY TIMEOUT] No speech or engine event - force stop.');
  //       // Immediate UI update
  //       _updateListeningUI(false);

  //       // Aggressive cleanup sequence to prevent system sound popup
  //       try {
  //         if (_speech != null && _speech!.isListening) {
  //           await _speech!.stop();
  //           await Future.delayed(const Duration(milliseconds: 300));
  //           await _speech!.cancel();
  //           await Future.delayed(const Duration(milliseconds: 200));
  //           // Kill and reinitialize engine to ensure clean state
  //           await _killSpeechEngine();
  //           await Future.delayed(const Duration(milliseconds: 300));
  //           _initSpeechEngine();
  //         }
  //       } catch (_) {}

  //       _showFeedback("Mic stopped due to inactivity.", isError: true);
  //     }
  //   });
  // }

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
  // Future<void> _startListening() async {
  //   if (!mounted || _isProcessing) return;

  //   // Check permissions first
  //   bool hasPermissions = await _checkMicrophonePermission();
  //   if (!hasPermissions) {
  //     print('permission not granted ');
  //     // _showFeedback("Microphone permission required", isError: true);
  //     return;
  //   }

  //   // Initialize speech engine if needed
  //   if (_speech == null || !_speechAvailable) {
  //     _speech = stt.SpeechToText();
  //     try {
  //       _speechAvailable = await _speech!.initialize(
  //         onStatus: _onSpeechStatus,
  //         onError: _onSpeechError,
  //         debugLogging: false,
  //       );

  //       if (_speechAvailable) {
  //         final locales = await _speech!.locales();
  //         List<String> englishLocaleIds = [
  //           'en_US',
  //           'en_GB',
  //           'en_IN',
  //           'en_AU',
  //           'en_CA',
  //           'en_IE',
  //           'en_SG',
  //         ];
  //         _currentLocaleId = locales
  //             .map((l) => l.localeId)
  //             .firstWhere(
  //               (id) => englishLocaleIds.contains(id),
  //               orElse: () => locales.first.localeId,
  //             );
  //       }
  //     } catch (e) {
  //       _showFeedback("Failed to initialize speech engine", isError: true);
  //       return;
  //     }
  //   }

  //   if (!_speechAvailable || _speech == null) {
  //     _showFeedback("Speech recognition not available", isError: true);
  //     return;
  //   }

  //   if (_speech!.isListening) {
  //     await _speech!.stop();
  //     await Future.delayed(const Duration(milliseconds: 100));
  //   }

  //   _updateListeningUI(true);
  //   try {
  //     await _speech!.listen(
  //       onResult: _onSpeechResult,
  //       listenFor: widget.listenDuration,
  //       pauseFor: widget.pauseDuration,
  //       partialResults: true,
  //       cancelOnError: true,
  //       listenMode: stt.ListenMode.dictation,
  //       localeId: _currentLocaleId.isNotEmpty ? _currentLocaleId : null,
  //     );
  //     _startForceStopTimer();
  //   } catch (e) {
  //     _updateListeningUI(false);
  //     _showFeedback(_getErrorMessage(e.toString()), isError: true);
  //     _forceStopTimer?.cancel();
  //   }
  // }

  Future<void> _stopListening() async {
    if (!mounted || _speech == null) return;
    _forceStopTimer?.cancel();

    // Set UI state immediately to prevent any new operations
    _updateListeningUI(false);

    try {
      if (_speech!.isListening) {
        // Stop first
        await _speech!.stop();
        // Wait longer to ensure stop is processed
        await Future.delayed(const Duration(milliseconds: 300));
        // Force cancel to ensure microphone is completely released
        await _speech!.cancel();
        // Additional delay to ensure system processes the cancel
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
    }
    // else if (error.contains('Speech recognition not available') ||
    //     error.contains('ERROR_CLIENT')) {
    //   return 'Speech-to-text is not available on this device. Please check your keyboard or voice input settings.';
    // }
    return 'No speech was detected.';
  }

  void _onSpeechResult(stt.SpeechRecognitionResult result) {
    if (!mounted) return;
    if (result.finalResult) {
      _addToTextField(result.recognizedWords);
      // Stop listening immediately after getting final result
      Future.delayed(const Duration(milliseconds: 200), () async {
        if (mounted && _isListening) {
          // Immediate UI update
          _updateListeningUI(false);

          // Aggressive cleanup to prevent system sound popup
          try {
            if (_speech != null && _speech!.isListening) {
              await _speech!.stop();
              await Future.delayed(const Duration(milliseconds: 300));
              await _speech!.cancel();
            }
          } catch (_) {}
        }
      });
    }
    if (_isListening) _startForceStopTimer();
  }

  void _addToTextField(String words) {
    if (words.trim().isEmpty) return;
    String currentText = widget.controller.text;
    String formattedWords = words.trim();
    if (formattedWords.isNotEmpty) {
      formattedWords =
          formattedWords[0].toUpperCase() + formattedWords.substring(1);
    }
    if (currentText.isEmpty || currentText.endsWith(' ')) {
      widget.controller.text += formattedWords;
    } else {
      widget.controller.text += ' $formattedWords';
    }
    if (!widget.controller.text.endsWith(' ')) {
      widget.controller.text += ' ';
    }
    widget.onChanged?.call(widget.controller.text);
    setState(() {}); // Add this line to refresh speaker button
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
        state == AppLifecycleState.detached ||
        state.toString() == 'AppLifecycleState.hidden') {
      _stopListening();
      _waveController.stop();
      _waveController.reset();
    }
    if (state == AppLifecycleState.resumed) {
      _forceAnimationSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [_buildLabel(), _buildInputContainer()],
    );
  }

  Widget _buildLabel() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          children: [
            TextSpan(text: '${widget.label}'),
            if (widget.isRequired)
              const TextSpan(
                text: " *",
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: widget.backgroundColor ?? Colors.grey.shade100,
      ),
      child: Row(
        children: [
          Expanded(child: _buildTextField()),
          _buildSpeechButton(),
          if (widget.controller.text.trim().isNotEmpty) _buildSpeakButton(),
        ],
      ),
    );
  }

  Widget _buildSpeakButton() {
    return IconButton(
      onPressed: () => _speakText(),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          _isSpeaking ? FontAwesomeIcons.stop : FontAwesomeIcons.volumeHigh,
          key: ValueKey(_isSpeaking),
          color: _isSpeaking ? Colors.red : _primaryColor,
          size: 16,
        ),
      ),
      tooltip: _isSpeaking ? 'Stop speaking' : 'Speak text',
      splashRadius: 24,
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled && !_isListening,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: TextInputType.multiline,
      onChanged: (text) {
        widget.onChanged?.call(text);
        setState(() {}); // Add this line to refresh speaker button
      },
      decoration: InputDecoration(
        hintText: _isListening ? "Listening..." : widget.hint,
        hintStyle: GoogleFonts.poppins(
          color: _isListening ? _primaryColor : Colors.grey.shade600,
        ),
        contentPadding:
            widget.contentPadding ??
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        // border: InputBorder.none,
        border: widget.error
            ? OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              )
            : InputBorder.none,
      ),
      style: TextStyle(
        fontSize: widget.fontSize,
        color: widget.textColor ?? Colors.black,
      ),
    );
  }

  // Widget _buildSpeechButton() {
  //   if (!_isInitialized) {
  //     return const Padding(
  //       padding: EdgeInsets.all(12.0),
  //       child: SizedBox(
  //         width: 18,
  //         height: 18,
  //         child: CircularProgressIndicator(strokeWidth: 2),
  //       ),
  //     );
  //   }

  //   return IconButton(
  //     onPressed:
  //         !_isProcessing // Remove the _speechAvailable check here
  //         ? () {
  //             if (_isListening) {
  //               _stopListening();
  //             } else {
  //               _startListening();
  //             }
  //           }
  //         : null,
  //     icon: AnimatedSwitcher(
  //       duration: const Duration(milliseconds: 200),
  //       child: Icon(
  //         _isListening ? FontAwesomeIcons.stop : FontAwesomeIcons.microphone,
  //         key: ValueKey(_isListening),
  //         color: _isListening
  //             ? Colors.red
  //             : (_permissionChecked
  //                   ? _primaryColor
  //                   : Colors.grey), // Change this line
  //         size: 16,
  //       ),
  //     ),
  //     tooltip: _isListening ? 'Stop recording' : 'Start voice input',
  //     splashRadius: 24,
  //   );
  // }

  Widget _buildSpeechButton() {
    if (!_speechAvailable) {
      return IconButton(
        onPressed: _initSpeechEngine,
        icon: Icon(
          Icons.mic_off_rounded,
          color: Colors.grey.shade400,
          size: 16,
        ),
        tooltip: 'Microphone not available',
        splashRadius: 24,
      );
    }

    if (!_isInitialized) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return IconButton(
      onPressed: (_speechAvailable && !_isProcessing)
          ? () {
              if (_isListening) {
                _stopListening();
              } else {
                _startListening();
              }
            }
          : null,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          _isListening ? FontAwesomeIcons.stop : FontAwesomeIcons.microphone,
          key: ValueKey(_isListening),
          color: _isListening
              ? Colors.red
              : (_speechAvailable ? _primaryColor : Colors.grey.shade400),
          size: 16,
        ),
      ),
      tooltip: _isListening ? 'Stop recording' : 'Start voice input',
      splashRadius: 24,
    );
  }
} 
// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_recognition_result.dart' as stt;
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:record/record.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:flutter_sound/flutter_sound.dart';

// class EnhancedSpeechTextField extends StatefulWidget {
//   final bool isRequired;
//   final String label;
//   final TextEditingController controller;
//   final String hint;
//   final Function(String)? onChanged;
//   final Function(String)? onTextGenerated;
//   final Function(String)? onRecordingComplete;
//   final bool enabled;
//   final int maxLines;
//   final int minLines;
//   final Color? primaryColor;
//   final Color? backgroundColor;
//   final Color? textColor;
//   final double? fontSize;
//   final EdgeInsets? contentPadding;
//   final bool showLiveTranscription;
//   final Duration listenDuration;
//   final Duration pauseDuration;
//   final bool enableRecording;
//   final bool showRecordingsList;

//   const EnhancedSpeechTextField({
//     Key? key,
//     required this.label,
//     required this.controller,
//     required this.hint,
//     this.onChanged,
//     this.onTextGenerated,
//     this.onRecordingComplete,
//     this.enabled = true,
//     this.maxLines = 5,
//     this.minLines = 1,
//     this.primaryColor,
//     this.backgroundColor,
//     this.textColor,
//     this.fontSize = 14,
//     this.contentPadding,
//     this.showLiveTranscription = true,
//     this.listenDuration = const Duration(seconds: 30),
//     this.pauseDuration = const Duration(seconds: 5),
//     this.enableRecording = false,
//     this.showRecordingsList = false,
//     required this.isRequired,
//   }) : super(key: key);

//   @override
//   State<EnhancedSpeechTextField> createState() =>
//       _EnhancedSpeechTextFieldState();
// }

// class _EnhancedSpeechTextFieldState extends State<EnhancedSpeechTextField>
//     with TickerProviderStateMixin, WidgetsBindingObserver {
//   // Speech to text
//   stt.SpeechToText? _speech;
//   bool _isListening = false;
//   bool _speechAvailable = false;
//   String _currentLocaleId = '';

//   // Text-to-Speech
//   final FlutterTts _flutterTts = FlutterTts();
//   bool _isSpeaking = false;

//   // Optional recording
//   final _audioRecorder = AudioRecorder();
//   final _audioPlayer = FlutterSoundPlayer();
//   bool _isRecording = false; // Fixed: was initialized to true
//   bool _isPlaying = false;
//   String? _currentRecordingPath;
//   List<String> _savedRecordings = [];

//   // Common
//   bool _isInitialized = false;
//   bool _permissionsGranted = false;
//   bool _permissionChecked = false; // Added to track permission check status
//   late AnimationController _waveController;
//   late AnimationController _pulseController;
//   Timer? _forceStopTimer;
//   Timer? _stateCheckTimer;
//   bool _isDisposing = false;
//   bool _isProcessing = false;
//   String? _lastError;

//   Color get _primaryColor => widget.primaryColor ?? Colors.grey.shade800;
//   Color get _errorColor => Colors.red;
//   Color get _activeColor => Colors.red.shade600;
//   Color get _playingColor => Colors.green.shade600;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     _waveController = AnimationController(
//       duration: const Duration(milliseconds: 1200),
//       vsync: this,
//     );

//     _pulseController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );

//     // Initialize without checking permissions first
//     _initializeBasic();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _isDisposing = true;
//     _cancelAllTimers();
//     _waveController.dispose();
//     _pulseController.dispose();
//     _killSpeechEngine();
//     _flutterTts.stop();
//     _audioRecorder.dispose();
//     _audioPlayer.closePlayer();
//     super.dispose();
//   }

//   void _cancelAllTimers() {
//     _forceStopTimer?.cancel();
//     _stateCheckTimer?.cancel();
//   }

//   // Initialize basic components without permissions
//   Future<void> _initializeBasic() async {
//     await _initTextToSpeech();
//     if (widget.enableRecording || widget.showRecordingsList) {
//       await _audioPlayer.openPlayer();
//       await _loadSavedRecordings();
//     }
//     setState(() => _isInitialized = true);
//   }

//   // Only check permissions when user actually clicks the mic button
//   Future<bool> _checkAndRequestPermissions() async {
//     if (_permissionChecked && _permissionsGranted) {
//       return true;
//     }

//     try {
//       PermissionStatus micStatus = await Permission.microphone.status;

//       if (Platform.isIOS) {
//         PermissionStatus speechStatus = await Permission.speech.status;

//         if (micStatus.isGranted && speechStatus.isGranted) {
//           setState(() {
//             _permissionsGranted = true;
//             _permissionChecked = true;
//           });
//           return true;
//         }

//         if (micStatus.isPermanentlyDenied || speechStatus.isPermanentlyDenied) {
//           _showPermissionDialog();
//           return false;
//         }

//         // Request permissions
//         if (!micStatus.isGranted) {
//           micStatus = await Permission.microphone.request();
//         }
//         if (!speechStatus.isGranted) {
//           speechStatus = await Permission.speech.request();
//         }

//         bool granted = micStatus.isGranted && speechStatus.isGranted;
//         setState(() {
//           _permissionsGranted = granted;
//           _permissionChecked = true;
//         });
//         return granted;
//       } else {
//         if (micStatus.isGranted) {
//           setState(() {
//             _permissionsGranted = true;
//             _permissionChecked = true;
//           });
//           return true;
//         }

//         if (micStatus.isPermanentlyDenied) {
//           _showPermissionDialog();
//           return false;
//         }

//         if (!micStatus.isGranted) {
//           micStatus = await Permission.microphone.request();
//         }

//         bool granted = micStatus.isGranted;
//         setState(() {
//           _permissionsGranted = granted;
//           _permissionChecked = true;
//         });
//         return granted;
//       }
//     } catch (e) {
//       debugPrint('Permission check error: $e');
//       setState(() {
//         _permissionsGranted = false;
//         _permissionChecked = true;
//       });
//       return false;
//     }
//   }

//   Future<void> _loadSavedRecordings() async {
//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final dir = Directory(directory.path);
//       final files = dir
//           .listSync()
//           .where(
//             (file) =>
//                 file.path.endsWith('.m4a') && file.path.contains('speech_'),
//           )
//           .map((file) => file.path)
//           .toList();

//       files.sort(
//         (a, b) =>
//             File(b).lastModifiedSync().compareTo(File(a).lastModifiedSync()),
//       );

//       if (mounted) {
//         setState(() {
//           _savedRecordings = files;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error loading recordings: $e');
//     }
//   }

//   void _startAnimations() {
//     if (mounted && _isListening) {
//       _waveController.repeat();
//     }
//   }

//   void _stopAnimations() {
//     if (mounted) {
//       _waveController.stop();
//       _waveController.reset();
//     }
//   }

//   Future<void> _killSpeechEngine() async {
//     try {
//       if (_speech != null) {
//         if (_speech!.isListening) {
//           await _speech!.stop();
//           await Future.delayed(const Duration(milliseconds: 100));
//         }
//       }
//     } catch (_) {}
//     _speech = null;
//   }

//   Future<void> _initSpeechEngine() async {
//     if (!_permissionsGranted) return;

//     _isProcessing = true;
//     await _killSpeechEngine();

//     try {
//       _speech = stt.SpeechToText();

//       bool hasPermission = await _speech!.hasPermission;
//       if (!hasPermission) {
//         debugPrint('Speech permission not granted');
//         setState(() {
//           _speechAvailable = false;
//         });
//         return;
//       }

//       _speechAvailable = await _speech!.initialize(
//         onStatus: _onSpeechStatus,
//         onError: _onSpeechError,
//         debugLogging: true,
//       );

//       debugPrint('Speech engine initialized: $_speechAvailable');

//       if (_speechAvailable) {
//         final locales = await _speech!.locales();
//         debugPrint('Available locales: ${locales.length}');

//         List<String> englishLocaleIds = [
//           'en_US',
//           'en_GB',
//           'en_IN',
//           'en_AU',
//           'en_CA',
//           'en_IE',
//           'en_SG',
//         ];

//         _currentLocaleId = locales
//             .map((l) => l.localeId)
//             .firstWhere(
//               (id) => englishLocaleIds.contains(id),
//               orElse: () =>
//                   locales.isNotEmpty ? locales.first.localeId : 'en_US',
//             );
//         debugPrint('Speech will use locale: $_currentLocaleId');
//       } else {
//         debugPrint('Speech engine not available');
//         _showFeedback(
//           "Speech recognition not available on this device",
//           isError: true,
//         );
//       }
//     } catch (e) {
//       debugPrint('Speech init error: $e');
//       setState(() {
//         _speechAvailable = false;
//       });
//       _showFeedback("Failed to initialize speech engine: $e", isError: true);
//     }
//     _isProcessing = false;
//   }

//   Future<void> _initTextToSpeech() async {
//     try {
//       await _flutterTts.setLanguage("en-US");
//       await _flutterTts.setSpeechRate(0.5);
//       await _flutterTts.setPitch(1.0);
//       await _flutterTts.setVolume(1.0);

//       _flutterTts.setStartHandler(() {
//         if (mounted) setState(() => _isSpeaking = true);
//       });

//       _flutterTts.setCompletionHandler(() {
//         if (mounted) setState(() => _isSpeaking = false);
//       });

//       _flutterTts.setErrorHandler((msg) {
//         debugPrint('TTS Error: $msg');
//         if (mounted) setState(() => _isSpeaking = false);
//       });

//       debugPrint('Text-to-speech initialized');
//     } catch (e) {
//       debugPrint('TTS initialization error: $e');
//     }
//   }

//   Future<void> _speakText() async {
//     try {
//       if (_isSpeaking) {
//         await _flutterTts.stop();
//         setState(() => _isSpeaking = false);
//       } else if (widget.controller.text.trim().isNotEmpty) {
//         await _flutterTts.speak(widget.controller.text);
//       }
//     } catch (e) {
//       debugPrint('TTS speak error: $e');
//       _showFeedback("Failed to speak text: $e", isError: true);
//     }
//   }

//   Future<void> _startRecording() async {
//     if (!widget.enableRecording) return;

//     try {
//       final directory = await getApplicationDocumentsDirectory();
//       final timestamp = DateTime.now().millisecondsSinceEpoch;
//       _currentRecordingPath = '${directory.path}/speech_$timestamp.m4a';

//       await _audioRecorder.start(
//         RecordConfig(
//           encoder: AudioEncoder.aacLc,
//           sampleRate: 44100,
//           bitRate: 128000,
//         ),
//         path: _currentRecordingPath!,
//       );

//       setState(() => _isRecording = true);
//       debugPrint('Recording started: $_currentRecordingPath');
//     } catch (e) {
//       debugPrint('Recording error: $e');
//       _showFeedback("Failed to start recording: $e", isError: true);
//     }
//   }

//   Future<void> _stopRecording() async {
//     if (!_isRecording) return;

//     try {
//       final path = await _audioRecorder.stop();
//       setState(() => _isRecording = false);

//       if (path != null) {
//         _savedRecordings.insert(0, path);
//         await _loadSavedRecordings();
//         widget.onRecordingComplete?.call(path);
//         debugPrint('Recording saved: $path');
//         _showFeedback("Speech recording saved", isError: false);
//       }
//     } catch (e) {
//       debugPrint('Stop recording error: $e');
//       _showFeedback("Failed to save recording: $e", isError: true);
//     }
//   }

//   Future<void> _playRecording(String path) async {
//     try {
//       if (_isPlaying) {
//         await _audioPlayer.stopPlayer();
//         setState(() => _isPlaying = false);
//         _pulseController.stop();
//         _pulseController.reset();
//       } else {
//         setState(() => _isPlaying = true);
//         _pulseController.repeat();

//         await _audioPlayer.startPlayer(
//           fromURI: path,
//           whenFinished: () {
//             if (mounted) {
//               setState(() => _isPlaying = false);
//               _pulseController.stop();
//               _pulseController.reset();
//             }
//           },
//         );
//       }
//     } catch (e) {
//       _showFeedback("Failed to play recording: $e", isError: true);
//       if (mounted) {
//         setState(() => _isPlaying = false);
//         _pulseController.stop();
//         _pulseController.reset();
//       }
//     }
//   }

//   Future<void> _deleteRecording(String path) async {
//     try {
//       await File(path).delete();
//       await _loadSavedRecordings();
//       _showFeedback("Recording deleted", isError: false);
//     } catch (e) {
//       _showFeedback("Failed to delete recording: $e", isError: true);
//     }
//   }

//   void _showPermissionDialog() {
//     if (!mounted) return;
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Permissions Required'),
//         content: Text(
//           Platform.isIOS
//               ? 'This app needs microphone and speech recognition permissions to work properly.'
//               : 'This app needs microphone permission to work properly.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               openAppSettings();
//             },
//             child: const Text('Open Settings'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _onSpeechStatus(String status) {
//     if (!mounted) return;
//     debugPrint('[Speech Status] $status');

//     if (status == 'notListening' || status == 'done') {
//       setState(() => _isListening = false);
//       _stopAnimations(); // Stop animations
//       _forceStopTimer?.cancel();

//       // Stop recording when speech stops
//       if (widget.enableRecording && _isRecording) {
//         Future.delayed(const Duration(milliseconds: 500), () {
//           _stopRecording();
//         });
//       }
//     } else if (status == 'listening') {
//       setState(() => _isListening = true);
//       _startAnimations(); // Start animations
//       _startForceStopTimer();
//       debugPrint('Speech engine is now listening...');
//     }
//   }

//   void _onSpeechError(dynamic error) {
//     if (!mounted) return;
//     debugPrint('[Speech Error] $error');

//     setState(() => _isListening = false);
//     _stopAnimations(); // Stop animations on error
//     _lastError = error.toString();

//     // Stop recording on error
//     if (widget.enableRecording && _isRecording) {
//       _stopRecording();
//     }

//     if (_lastError?.contains('no-speech') ?? false) {
//       _showFeedback("No speech detected", isError: false);
//     } else if (_lastError?.contains('network') ?? false) {
//       _showFeedback("Network error occurred", isError: true);
//     } else if (_lastError?.contains('audio') ?? false) {
//       _showFeedback("Microphone error", isError: true);
//     } else {
//       _showFeedback(_getErrorMessage(_lastError ?? ''), isError: true);
//     }

//     _forceStopTimer?.cancel();
//   }

//   void _startForceStopTimer() {
//     _forceStopTimer?.cancel();
//     _forceStopTimer = Timer(const Duration(seconds: 30), () async {
//       if (mounted && _isListening) {
//         await _stopSpeechToText();
//         _showFeedback("Stopped due to inactivity.", isError: true);
//       }
//     });
//   }

//   Future<void> _startSpeechToText() async {
//     // First check permissions
//     bool hasPermissions = await _checkAndRequestPermissions();
//     if (!hasPermissions) {
//       _showFeedback("Microphone permission required", isError: true);
//       return;
//     }

//     // Initialize speech engine if not done
//     if (_speech == null || !_speechAvailable) {
//       await _initSpeechEngine();
//     }

//     if (!_speechAvailable || _speech == null || !_speech!.isAvailable) {
//       debugPrint('Speech not available for listening');
//       _showFeedback("Speech recognition not available", isError: true);
//       return;
//     }

//     try {
//       debugPrint('Starting speech-to-text with locale: $_currentLocaleId');

//       // Start recording if enabled
//       if (widget.enableRecording) {
//         await _startRecording();
//       }

//       // Start speech recognition
//       bool? started = await _speech!.listen(
//         onResult: _onSpeechResult,
//         listenFor: widget.listenDuration,
//         pauseFor: widget.pauseDuration,
//         partialResults: true,
//         cancelOnError: true,
//         listenMode: stt.ListenMode.dictation,
//         localeId: _currentLocaleId.isNotEmpty ? _currentLocaleId : null,
//       );

//       if (started == false) {
//         _showFeedback("Failed to start speech recognition", isError: true);
//         if (widget.enableRecording && _isRecording) {
//           await _stopRecording();
//         }
//       }
//     } catch (e) {
//       debugPrint('Speech start error: $e');
//       _showFeedback(_getErrorMessage(e.toString()), isError: true);

//       // Stop recording on error
//       if (widget.enableRecording && _isRecording) {
//         await _stopRecording();
//       }
//     }
//   }

//   Future<void> _stopSpeechToText() async {
//     if (!mounted || _speech == null) return;

//     try {
//       if (_speech!.isListening) {
//         await _speech!.stop();
//       }

//       // Stop recording
//       if (widget.enableRecording && _isRecording) {
//         await _stopRecording();
//       }

//       setState(() => _isListening = false);
//       _stopAnimations();
//       debugPrint('Speech-to-text stopped');
//     } catch (e) {
//       debugPrint('Speech stop error: $e');
//     }
//   }

//   String _getErrorMessage(String error) {
//     if (error.contains('speech timeout') || error.contains('e_4')) {
//       return 'Listening timed out. Please speak sooner.';
//     } else if (error.contains('no-speech') || error.contains('e_6')) {
//       return 'No speech was detected.';
//     } else if (error.contains('network') || error.contains('e_7')) {
//       return 'A network error occurred.';
//     } else if (error.contains('audio') || error.contains('e_3')) {
//       return 'Microphone access error.';
//     } else if (error.contains('not available') ||
//         error.contains('ERROR_CLIENT')) {
//       return 'Speech recognition not available on this device.';
//     }
//     return 'Speech recognition error occurred.';
//   }

//   void _onSpeechResult(stt.SpeechRecognitionResult result) {
//     if (!mounted) return;

//     debugPrint(
//       'Speech result: ${result.recognizedWords} (confidence: ${result.confidence})',
//     );

//     if (widget.showLiveTranscription && result.recognizedWords.isNotEmpty) {
//       debugPrint('Live transcription: ${result.recognizedWords}');
//     }

//     if (result.finalResult && result.recognizedWords.isNotEmpty) {
//       debugPrint('Final result: ${result.recognizedWords}');
//       _addToTextField(result.recognizedWords);

//       widget.onTextGenerated?.call(result.recognizedWords);

//       // Auto-stop after getting final result
//       Future.delayed(const Duration(milliseconds: 500), () {
//         if (mounted) _stopSpeechToText();
//       });
//     }
//   }

//   void _addToTextField(String words) {
//     if (words.trim().isEmpty) return;

//     String currentText = widget.controller.text;
//     String formattedWords = words.trim();

//     if (formattedWords.isNotEmpty) {
//       formattedWords =
//           formattedWords[0].toUpperCase() + formattedWords.substring(1);
//     }

//     if (currentText.isEmpty || currentText.endsWith(' ')) {
//       widget.controller.text += formattedWords;
//     } else {
//       widget.controller.text += ' $formattedWords';
//     }

//     if (!widget.controller.text.endsWith(' ')) {
//       widget.controller.text += ' ';
//     }

//     widget.onChanged?.call(widget.controller.text);
//     setState(() {}); // Refresh to show speaker button
//     debugPrint('Text field updated: ${widget.controller.text}');
//   }

//   void _showFeedback(String message, {required bool isError}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).hideCurrentSnackBar();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message, style: const TextStyle(color: Colors.white)),
//         backgroundColor: isError ? _errorColor : Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     if (state == AppLifecycleState.paused ||
//         state == AppLifecycleState.detached) {
//       _stopSpeechToText();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildLabel(),
//         _buildInputContainer(),
//         if (_isListening) _buildListeningIndicator(),
//         if (widget.showRecordingsList && _savedRecordings.isNotEmpty)
//           _buildRecordingsList(),
//       ],
//     );
//   }

//   Widget _buildLabel() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 5),
//       child: RichText(
//         text: TextSpan(
//           style: GoogleFonts.poppins(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: Colors.black,
//           ),
//           children: [
//             TextSpan(text: widget.label),
//             if (widget.isRequired)
//               const TextSpan(
//                 text: " *",
//                 style: TextStyle(color: Colors.red),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInputContainer() {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(5),
//         color: widget.backgroundColor ?? Colors.grey.shade100,
//         border: _isListening ? Border.all(color: _activeColor, width: 2) : null,
//       ),
//       child: Row(
//         children: [
//           Expanded(child: _buildTextField()),
//           _buildMicButton(),
//           if (widget.controller.text.trim().isNotEmpty) _buildSpeakButton(),
//         ],
//       ),
//     );
//   }

//   Widget _buildTextField() {
//     return TextField(
//       controller: widget.controller,
//       enabled: widget.enabled && !_isListening,
//       maxLines: widget.maxLines,
//       minLines: widget.minLines,
//       keyboardType: TextInputType.multiline,
//       onChanged: (text) {
//         widget.onChanged?.call(text);
//         setState(() {}); // Refresh to show/hide speaker button
//       },
//       decoration: InputDecoration(
//         hintText: _isListening
//             ? (widget.enableRecording
//                   ? "Listening & recording..."
//                   : "Listening...")
//             : widget.hint,
//         hintStyle: GoogleFonts.poppins(
//           color: _isListening ? _activeColor : Colors.grey.shade600,
//         ),
//         contentPadding:
//             widget.contentPadding ??
//             const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         border: InputBorder.none,
//       ),
//       style: TextStyle(
//         fontSize: widget.fontSize,
//         color: widget.textColor ?? Colors.black,
//       ),
//     );
//   }

//   Widget _buildMicButton() {
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
//       onPressed: !_isProcessing
//           ? () async {
//               if (_isListening) {
//                 await _stopSpeechToText();
//               } else {
//                 await _startSpeechToText();
//               }
//             }
//           : null,
//       icon: AnimatedBuilder(
//         animation: _waveController,
//         builder: (context, child) {
//           return AnimatedSwitcher(
//             duration: const Duration(milliseconds: 300),
//             child: Icon(
//               _isListening
//                   ? FontAwesomeIcons.stop
//                   : FontAwesomeIcons.microphone,
//               key: ValueKey(_isListening),
//               color: _isListening
//                   ? _activeColor
//                   : (_permissionChecked && _permissionsGranted
//                         ? _primaryColor
//                         : Colors.grey),
//               size: 16,
//             ),
//           );
//         },
//       ),
//       tooltip: _isListening
//           ? 'Stop listening'
//           : (widget.enableRecording
//                 ? 'Start speech-to-text (with recording)'
//                 : 'Start speech-to-text'),
//       splashRadius: 24,
//     );
//   }

//   Widget _buildSpeakButton() {
//     return IconButton(
//       onPressed: () => _speakText(),
//       icon: AnimatedSwitcher(
//         duration: const Duration(milliseconds: 300),
//         child: Icon(
//           _isSpeaking ? FontAwesomeIcons.stop : FontAwesomeIcons.volumeHigh,
//           key: ValueKey(_isSpeaking),
//           color: _isSpeaking ? _activeColor : _primaryColor,
//           size: 16,
//         ),
//       ),
//       tooltip: _isSpeaking ? 'Stop speaking' : 'Speak text',
//       splashRadius: 24,
//     );
//   }

//   Widget _buildListeningIndicator() {
//     return Container(
//       margin: const EdgeInsets.only(top: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: _activeColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: _activeColor.withOpacity(0.3)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           AnimatedBuilder(
//             animation: _waveController,
//             builder: (context, child) {
//               return Container(
//                 width: 12,
//                 height: 12,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: _activeColor.withOpacity(
//                     0.3 + (_waveController.value * 0.7),
//                   ),
//                 ),
//               );
//             },
//           ),
//           const SizedBox(width: 10),
//           Icon(FontAwesomeIcons.microphone, size: 14, color: _activeColor),
//           const SizedBox(width: 6),
//           Text(
//             'Listening...',
//             style: TextStyle(
//               color: _activeColor,
//               fontSize: 13,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           if (widget.enableRecording && _isRecording) ...[
//             const SizedBox(width: 12),
//             Icon(FontAwesomeIcons.recordVinyl, size: 14, color: _activeColor),
//             const SizedBox(width: 6),
//             Text(
//               'Recording',
//               style: TextStyle(
//                 color: _activeColor,
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildRecordingsList() {
//     return Container(
//       margin: const EdgeInsets.only(top: 8),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade50,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: Text(
//               'Speech Recordings',
//               style: TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey.shade700,
//               ),
//             ),
//           ),
//           ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: _savedRecordings.length,
//             itemBuilder: (context, index) {
//               final recording = _savedRecordings[index];
//               final fileName = recording.split('/').last;
//               final timestamp = fileName
//                   .replaceAll('speech_', '')
//                   .replaceAll('.m4a', '');
//               final date = DateTime.fromMillisecondsSinceEpoch(
//                 int.tryParse(timestamp) ?? 0,
//               );

//               return Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(6),
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: ListTile(
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 4,
//                   ),
//                   leading: AnimatedBuilder(
//                     animation: _pulseController,
//                     builder: (context, child) {
//                       return IconButton(
//                         icon: Icon(
//                           _isPlaying
//                               ? FontAwesomeIcons.pause
//                               : FontAwesomeIcons.play,
//                           color: _isPlaying ? _playingColor : _primaryColor,
//                           size: 14,
//                         ),
//                         onPressed: () => _playRecording(recording),
//                         splashRadius: 20,
//                       );
//                     },
//                   ),
//                   title: Text(
//                     'Speech Recording',
//                     style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
//                   ),
//                   subtitle: Text(
//                     '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
//                     style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
//                   ),
//                   trailing: IconButton(
//                     icon: Icon(
//                       Icons.delete,
//                       color: Colors.red.shade400,
//                       size: 18,
//                     ),
//                     onPressed: () => _deleteRecording(recording),
//                     splashRadius: 18,
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
 