import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'floating_ball_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Must initialize windowManager
  await windowManager.ensureInitialized();

  // Configure transparent, frameless, and floating window styles
  WindowOptions windowOptions = const WindowOptions(
    size: Size(95, 95), // extra spacing for glow/shadows
    center: false,
    backgroundColor: Colors.transparent, // Required for transparent window
    skipTaskbar: true, // Hide from Windows taskbar or macOS Dock
    titleBarStyle: TitleBarStyle.hidden, // Frameless window
    alwaysOnTop: true, // Stay above other applications
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Enable transparency natively
    await windowManager.setBackgroundColor(Colors.transparent);
    await windowManager.setAsFrameless();
    await windowManager.setHasShadow(false); // We draw custom shadows in Flutter for perfect spheres
    
    // Position ball near the right edge of the primary screen initially
    Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
    double initialX = primaryDisplay.visibleSize!.width - 115;
    double initialY = primaryDisplay.visibleSize!.height * 0.4;
    await windowManager.setPosition(Offset(initialX, initialY));
    
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent, // Keep app background fully transparent
        body: FloatingBallContainer(),
      ),
    );
  }
}
