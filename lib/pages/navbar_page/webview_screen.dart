import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartassist/config/component/color/colors.dart';
import 'package:smartassist/config/component/font/font.dart';

import 'package:smartassist/services/api_srv.dart';
import 'package:smartassist/utils/snackbar_helper.dart';

class SmartAssistWebView extends StatefulWidget {
  const SmartAssistWebView({super.key});

  @override
  State<SmartAssistWebView> createState() => _SmartAssistWebViewState();
}

class _SmartAssistWebViewState extends State<SmartAssistWebView> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController; 

  // ignore: deprecated_member_use
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    // ignore: deprecated_member_use
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      useOnDownloadStart: true,
      useOnLoadResource: true,
      useShouldInterceptAjaxRequest: true,
      useShouldInterceptFetchRequest: true,
      clearCache: false,
      supportZoom: true,
    ),
    // ignore: deprecated_member_use
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
      allowContentAccess: true,
      allowFileAccess: true,
      domStorageEnabled: true,
      databaseEnabled: true,
    ),
    // ignore: deprecated_member_use
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
      allowsBackForwardNavigationGestures: true,
    ),
  );

  late PullToRefreshController pullToRefreshController;
  String url = "";
  String xoxoToken = '';
  String finalUrl = '';
  double progress = 0;
  final urlController = TextEditingController();
  bool isLoading = true;
  bool isInitializing = true; // New flag for initial API calls

  @override
  void initState() {
    super.initState();
    initializeWebView();
    pullToRefreshController = PullToRefreshController(
      // ignore: deprecated_member_use
      options: PullToRefreshOptions(color: Colors.blue),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
            urlRequest: URLRequest(url: await webViewController?.getUrl()),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    urlController.dispose();
    super.dispose();
  }

  Future<void> initializeWebView() async {
    try {
      setState(() {
        isInitializing = true;
      });

      // Step 1: Call POST API to get token
      final tokenSuccess = await webViewPost();

      if (!tokenSuccess) {
        setState(() {
          isInitializing = false;
        });
        return;
      }

      // Step 2: Fetch the dashboard URL using the token
      await fetchDashboardData();
    } catch (e) {
      print('Initialization error: $e');
      showErrorMessage(context, message: 'Failed to initialize dashboard');
      setState(() {
        isInitializing = false;
      });
    }
  }

  Future<bool> webViewPost() async {
    final prefs = await SharedPreferences.getInstance();
    final spId = prefs.getString('user_id');

    try {
      // Modified to return the token instead of just boolean
      final tokenResult = await LeadsSrv.webXoxo(context);

      if (tokenResult != null && tokenResult.isNotEmpty) {
        setState(() {
          xoxoToken = tokenResult; 
        });
        return true;
      } else { 
        return false;
      }
    } catch (e) {
      print('Token fetch error: $e');
      showErrorMessage(context, message: 'Authentication failed.');
      return false;
    }
  }

  Future<void> fetchDashboardData() async {
    try {
      // Simply build the URL with the token - no API call needed
      final dashboardUrl = LeadsSrv.buildXoxoUrl(xoxoToken);

      setState(() {
        finalUrl = dashboardUrl;
        isInitializing = false;
      });

      

      print('Loading dashboard URL: $finalUrl');

      // Load the URL in WebView
      if (webViewController != null) {
        await webViewController!.loadUrl(
          urlRequest: URLRequest(url: WebUri(finalUrl)),
        );
      }
    } catch (e) {
      print('Dashboard URL build error: $e');
      showErrorMessage(context, message: 'Failed to build dashboard URL');
      setState(() {
        isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text('Smart Assist', style: AppFont.appbarfontWhite(context)),
        ),
        backgroundColor: AppColors.colorsBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (webViewController != null) {
                webViewController?.reload();
              } else {
                // If WebView not ready, reinitialize
                initializeWebView();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Progress indicator
            if (isLoading || isInitializing)
              LinearProgressIndicator(
                value: isInitializing
                    ? null
                    : progress, // Indeterminate when initializing
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.colorsBlue,
                ),
              ),

            // WebView
            Expanded(
              child: Stack(
                children: [
                  if (!isInitializing && finalUrl.isNotEmpty)
                    InAppWebView(
                      key: webViewKey,
                      initialUrlRequest: URLRequest(
                        url: WebUri(finalUrl), // Use the URL from API
                      ),
                      initialOptions: options,
                      pullToRefreshController: pullToRefreshController,
                      onWebViewCreated: (controller) {
                        webViewController = controller;
                      },
                      onLoadStart: (controller, url) {
                        setState(() {
                          this.url = url.toString();
                          isLoading = true;
                        });
                      },
                      onLoadStop: (controller, url) async {
                        pullToRefreshController.endRefreshing();
                        setState(() {
                          this.url = url.toString();
                          isLoading = false;
                        });
                      },
                      onProgressChanged: (controller, progress) {
                        setState(() {
                          this.progress = progress / 100;
                        });
                      },
                      onUpdateVisitedHistory:
                          (controller, url, androidIsReload) {
                            setState(() {
                              this.url = url.toString();
                              urlController.text = this.url;
                            });
                          },
                      onConsoleMessage: (controller, consoleMessage) {
                        print("Console: ${consoleMessage.message}");
                      },
                      shouldOverrideUrlLoading:
                          (controller, navigationAction) async {
                            var uri = navigationAction.request.url!;

                            // Handle external links
                            if ([
                              "http",
                              "https",
                              "file",
                              "chrome",
                              "data",
                              "javascript",
                              "about",
                            ].contains(uri.scheme)) {
                              return NavigationActionPolicy.ALLOW;
                            }

                            return NavigationActionPolicy.CANCEL;
                          },
                      // ignore: deprecated_member_use
                      onLoadError: (controller, url, code, message) {
                        setState(() {
                          isLoading = false;
                        });
                        _showErrorDialog("Load Error", message);
                      },
                      // ignore: deprecated_member_use
                      onLoadHttpError:
                          (controller, url, statusCode, description) {
                            setState(() {
                              isLoading = false;
                            });
                            _showErrorDialog(
                              "HTTP Error",
                              "Status: $statusCode - $description",
                            );
                          },
                    ),

                  // Loading overlay for initialization
                  if (isInitializing)
                    Container(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.colorsBlue,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Initializing XOXO Dashboard...',
                              style: AppFont.dropDowmLabel(context),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Loading overlay for WebView
                  if (!isInitializing && isLoading && progress < 1.0)
                    Container(
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.colorsBlue,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading XOXO Dashboard...',
                              style: AppFont.dropDowmLabel(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
                initializeWebView(); // Retry the whole initialization process
              },
            ),
          ],
        );
      },
    );
  }
}


// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:smartassist/config/component/color/colors.dart';
// import 'package:smartassist/config/component/font/font.dart';

// import 'package:smartassist/services/api_srv.dart';
// import 'package:smartassist/utils/snackbar_helper.dart';

// class SmartAssistWebView extends StatefulWidget {
//   const SmartAssistWebView({super.key});

//   @override
//   State<SmartAssistWebView> createState() => _SmartAssistWebViewState();
// }

// class _SmartAssistWebViewState extends State<SmartAssistWebView> {
//   final GlobalKey webViewKey = GlobalKey();
//   InAppWebViewController? webViewController;

//   // ignore: deprecated_member_use
//   InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
//     // ignore: deprecated_member_use
//     crossPlatform: InAppWebViewOptions(
//       useShouldOverrideUrlLoading: true,
//       mediaPlaybackRequiresUserGesture: false,
//       javaScriptEnabled: true,
//       javaScriptCanOpenWindowsAutomatically: true,
//       useOnDownloadStart: true,
//       useOnLoadResource: true,
//       useShouldInterceptAjaxRequest: true,
//       useShouldInterceptFetchRequest: true,
//       clearCache: false,
//       supportZoom: true,
//     ),
//     // ignore: deprecated_member_use
//     android: AndroidInAppWebViewOptions(
//       useHybridComposition: true,
//       allowContentAccess: true,
//       allowFileAccess: true,
//       domStorageEnabled: true,
//       databaseEnabled: true,
//     ),
//     // ignore: deprecated_member_use
//     ios: IOSInAppWebViewOptions(
//       allowsInlineMediaPlayback: true,
//       allowsBackForwardNavigationGestures: true,
//     ),
//   );

//   late PullToRefreshController pullToRefreshController;
//   String url = "";
//   String xoxoToken = '';
//   double progress = 0;
//   final urlController = TextEditingController();
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     webViewPost();
//     pullToRefreshController = PullToRefreshController(
//       // ignore: deprecated_member_use
//       options: PullToRefreshOptions(color: Colors.blue),
//       onRefresh: () async {
//         if (Platform.isAndroid) {
//           webViewController?.reload();
//         } else if (Platform.isIOS) {
//           webViewController?.loadUrl(
//             urlRequest: URLRequest(url: await webViewController?.getUrl()),
//           );
//         }
//       },
//     );
//   }

//   @override
//   void dispose() {
//     urlController.dispose();
//     super.dispose();
//   }

//   Future<void> webViewPost() async {
//     final prefs = await SharedPreferences.getInstance();
//     final spId = prefs.getString('user_id');

//     try {
//       final success = await LeadsSrv.webXoxo();

//       if (success) {
//         if (context.mounted) {
//           Navigator.pop(context, true);
//         }
//       } else {
//         showErrorMessage(context, message: 'Failed to submit appointment.');
//       }
//     } catch (e) {
//       print(e.toString());
//     }
//   }

//   Future<void> fetchDashboardData() async {
     
//     try {
//       final data = await LeadsSrv.fetchXoxoUrl(xoxoToken);
//     } catch (e) {
//       print('Dashboard fetch error: $e');
//       // showErrorMessage(context, message: e.toString());
//     } finally {
//       if (!mounted) return;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Align(
//           alignment: Alignment.centerLeft,
//           child: Text('Smart Assist', style: AppFont.appbarfontWhite(context)),
//         ),
//         backgroundColor: AppColors.colorsBlue,
//         foregroundColor: Colors.white,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () {
//               webViewController?.reload();
//             },
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Column(
//           children: <Widget>[
//             // Progress indicator
//             if (isLoading)
//               LinearProgressIndicator(
//                 value: progress,
//                 backgroundColor: Colors.grey[300],
//                 valueColor: const AlwaysStoppedAnimation<Color>(
//                   AppColors.colorsBlue,
//                 ),
//               ),

//             // WebView
//             Expanded(
//               child: Stack(
//                 children: [
//                   InAppWebView(
//                     key: webViewKey,
//                     initialUrlRequest: URLRequest(
//                       url: WebUri("https://payroll.razorpay.com/"),
//                     ),
//                     initialOptions: options,
//                     pullToRefreshController: pullToRefreshController,
//                     onWebViewCreated: (controller) {
//                       webViewController = controller;
//                     },
//                     onLoadStart: (controller, url) {
//                       setState(() {
//                         this.url = url.toString();
//                         isLoading = true;
//                       });
//                     },
//                     onLoadStop: (controller, url) async {
//                       pullToRefreshController.endRefreshing();
//                       setState(() {
//                         this.url = url.toString();
//                         isLoading = false;
//                       });
//                     },
//                     onProgressChanged: (controller, progress) {
//                       setState(() {
//                         this.progress = progress / 100;
//                       });
//                     },
//                     onUpdateVisitedHistory: (controller, url, androidIsReload) {
//                       setState(() {
//                         this.url = url.toString();
//                         urlController.text = this.url;
//                       });
//                     },
//                     onConsoleMessage: (controller, consoleMessage) {
//                       print("Console: ${consoleMessage.message}");
//                     },
//                     shouldOverrideUrlLoading:
//                         (controller, navigationAction) async {
//                           var uri = navigationAction.request.url!;

//                           // Handle external links
//                           if ([
//                             "http",
//                             "https",
//                             "file",
//                             "chrome",
//                             "data",
//                             "javascript",
//                             "about",
//                           ].contains(uri.scheme)) {
//                             return NavigationActionPolicy.ALLOW;
//                           }

//                           return NavigationActionPolicy.CANCEL;
//                         },
//                     // ignore: deprecated_member_use
//                     onLoadError: (controller, url, code, message) {
//                       setState(() {
//                         isLoading = false;
//                       });
//                       _showErrorDialog("Load Error", message);
//                     },
//                     // ignore: deprecated_member_use
//                     onLoadHttpError:
//                         (controller, url, statusCode, description) {
//                           setState(() {
//                             isLoading = false;
//                           });
//                           _showErrorDialog(
//                             "HTTP Error",
//                             "Status: $statusCode - $description",
//                           );
//                         },
//                   ),

//                   // Loading overlay
//                   if (isLoading && progress < 1.0)
//                     Container(
//                       color: Colors.white,
//                       child: const Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             CircularProgressIndicator(color: Color(0xff2563eb)),
//                             SizedBox(height: 16),
//                             Text(
//                               'Loading Smart Assist Dashboard...',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showErrorDialog(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(title),
//           content: Text(message),
//           actions: [
//             TextButton(
//               child: const Text('OK'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: const Text('Retry'),
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 webViewController?.reload();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
// }

// // home_page.dart - Your existing home page with updated navigation
// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Smart Assist',
//           style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: const Color(0xff2563eb),
//         foregroundColor: Colors.white,
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Color(0xff2563eb), Color(0xff10b981)],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const CircleAvatar(
//                     radius: 30,
//                     backgroundColor: Colors.white,
//                     child: Icon(
//                       Icons.dashboard,
//                       size: 30,
//                       color: Color(0xff2563eb),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     'Smart Assist',
//                     style: GoogleFonts.poppins(
//                       color: Colors.white,
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.home, size: 28),
//               title: Text('Home', style: GoogleFonts.poppins(fontSize: 18)),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.pushReplacementNamed(context, '/');
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.dashboard, size: 28),
//               title: Text(
//                 'Smart Assist',
//                 style: GoogleFonts.poppins(fontSize: 18),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.pushNamed(context, '/smart-assist');
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.web, size: 28),
//               title: Text(
//                 'Ariantech Solutions',
//                 style: GoogleFonts.poppins(fontSize: 18),
//               ),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => const ExternalWebView(
//                       url: 'https://ariantechsolutions.com/',
//                       title: 'Ariantech Solutions',
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//       body: const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.dashboard, size: 80, color: Color(0xff2563eb)),
//             SizedBox(height: 20),
//             Text(
//               'Welcome to Smart Assist Pro',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 10),
//             Text(
//               'Access your JLR dashboard from the menu',
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // external_webview.dart - For loading external websites
// class ExternalWebView extends StatefulWidget {
//   final String url;
//   final String title;

//   const ExternalWebView({super.key, required this.url, required this.title});

//   @override
//   State<ExternalWebView> createState() => _ExternalWebViewState();
// }

// class _ExternalWebViewState extends State<ExternalWebView> {
//   final GlobalKey webViewKey = GlobalKey();
//   InAppWebViewController? webViewController;
//   bool isLoading = true;
//   double progress = 0;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.title,
//           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
//         ),
//         backgroundColor: AppColors.colorsBlue,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: () => webViewController?.reload(),
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             if (isLoading)
//               LinearProgressIndicator(
//                 value: progress,
//                 backgroundColor: Colors.grey[300],
//                 valueColor: const AlwaysStoppedAnimation<Color>(
//                   Color(0xff2563eb),
//                 ),
//               ),
//             Expanded(
//               child: InAppWebView(
//                 key: webViewKey,
//                 initialUrlRequest: URLRequest(url: WebUri(widget.url)),
//                 // ignore: deprecated_member_use
//                 initialOptions: InAppWebViewGroupOptions(
//                   // ignore: deprecated_member_use
//                   crossPlatform: InAppWebViewOptions(
//                     javaScriptEnabled: true,
//                     supportZoom: true,
//                   ),

//                   // ignore: deprecated_member_use
//                   android: AndroidInAppWebViewOptions(
//                     useHybridComposition: true,
//                   ),
//                 ),
//                 onWebViewCreated: (controller) {
//                   webViewController = controller;
//                 },
//                 onLoadStart: (controller, url) {
//                   setState(() => isLoading = true);
//                 },
//                 onLoadStop: (controller, url) {
//                   setState(() => isLoading = false);
//                 },
//                 onProgressChanged: (controller, progress) {
//                   setState(() => this.progress = progress / 100);
//                 },
//                 // ignore: deprecated_member_use
//                 onLoadError: (controller, url, code, message) {
//                   setState(() => isLoading = false);
//                   ScaffoldMessenger.of(
//                     context,
//                   ).showSnackBar(SnackBar(content: Text('Error: $message')));
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
