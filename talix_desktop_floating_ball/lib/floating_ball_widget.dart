import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';

class FloatingBallContainer extends StatefulWidget {
  const FloatingBallContainer({super.key});

  @override
  State<FloatingBallContainer> createState() => _FloatingBallContainerState();
}

class _FloatingBallContainerState extends State<FloatingBallContainer> with SingleTickerProviderStateMixin, WindowListener {
  bool _isDragging = false;
  bool _isHovered = false;
  bool _isExpanded = false;
  Offset _dragOffset = Offset.zero;
  
  // Animation controller for snapping physics and pulsing styles
  late AnimationController _pulseController;
  
  // Timer for snapping animation
  Timer? _snappingTimer;
  
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _pulseController.dispose();
    _snappingTimer?.cancel();
    super.dispose();
  }

  // Double click handler
  void _onDoubleTap() async {
    // Toggle an expanded menu or control panel
      _showExpandedPanel();
  }

  void _showExpandedPanel() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    // In production, you would resize the window bounds dynamically using windowManager
    if (_isExpanded) {
      windowManager.setSize(const Size(280, 280));
    } else {
      windowManager.setSize(const Size(95, 95));
    }
  }

  // Handle window drag natively using cursor positions
  void _handleDragStart(DragStartDetails details) async {
    _isDragging = true;
    final pos = await windowManager.getPosition();
    final cursor = await screenRetriever.getCursorScreenPoint();
    
    setState(() {
      _dragOffset = Offset(
        cursor.dx - pos.dx,
        cursor.dy - pos.dy,
      );
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) async {
    if (!_isDragging) return;
    final cursor = await screenRetriever.getCursorScreenPoint();
    
    // Set the window position directly to the cursor minus initial offset
    await windowManager.setPosition(Offset(
      cursor.dx - _dragOffset.dx,
      cursor.dy - _dragOffset.dy,
    ));
  }

  void _handleDragEnd(DragEndDetails details) async {
    setState(() {
      _isDragging = false;
    });
    
    await _performSnappingBehavior();
  }

  // Magnetic edge-docking simulation in Flutter
  Future<void> _performSnappingBehavior() async {
    final pos = await windowManager.getPosition();
    final size = await windowManager.getSize();
    Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
    
    double screenWidth = primaryDisplay.size.width;
    double currentX = pos.dx;
    
    // Determine which edge is closer
    double targetX;
    if (currentX + (size.width / 2) < screenWidth / 2) {
      targetX = 10; // Left edge margin
    } else {
      targetX = screenWidth - size.width - 10; // Right edge margin
    }

    // Animate the window coordinates using a periodic timer for smooth interpolation
    double startX = pos.dx;
    double startY = pos.dy;
    int steps = 15;
    int currentStep = 0;
    
    _snappingTimer?.cancel();
    _snappingTimer = Timer.periodic(const Duration(milliseconds: 12), (timer) async {
      currentStep++;
      double t = currentStep / steps;
      double curve = 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t);
      
      double nextX = startX + (targetX - startX) * curve;
      await windowManager.setPosition(Offset(nextX, startY));
      
      if (currentStep >= steps) {
        timer.cancel();
        _snappingTimer = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double ballSize = 55.toDouble();
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Center(
        child: GestureDetector(
          onPanStart: _handleDragStart,
          onPanUpdate: _handleDragUpdate,
          onPanEnd: _handleDragEnd,
          onDoubleTap: _onDoubleTap,
          child: _isExpanded ? _buildExpandedView() : _buildBallView(ballSize),
        ),
      ),
    );
  }

  Widget _buildBallView(double size) {
    return AnimatedScale(
      scale: _isHovered ? 1.08 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x60a5fa).withOpacity(0.5),
              blurRadius: 16,
              spreadRadius: 4,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Stack(
            children: [
              // Core aesthetic styling based on configuration
              _buildBallAesthetic(),
              
              // Internal interactive element or indicator
              Center(
                child: _buildBallCoreIcon(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBallAesthetic() {
    switch ('pulse') {
      case 'pulse':
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xff3b82f6),
                    Color(0xff1d4ed8).withOpacity(0.6 + (_pulseController.value * 0.3)),
                  ],
                  radius: 0.55 + (_pulseController.value * 0.15),
                ),
              ),
            );
          },
        );
      case 'gauge':
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E293B),
            border: Border.all(
              color: Color(0xff3b82f6),
              width: 3,
            ),
          ),
          child: CircularProgressIndicator(
            value: 0.73, // Simulated metric (e.g. Memory / CPU load)
            strokeWidth: 4,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xff3b82f6)),
          ),
        );
      case 'neon':
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Color(0xff3b82f6),
              width: 2.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff3b82f6).withOpacity(0.4),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
        );
      case 'glass':
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
        );
      case 'crystal':
      default:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff3b82f6),
                Color(0xff1d4ed8),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildBallCoreIcon() {
    switch ('pulse') {
      case 'gauge':
        return const Text(
          '73%',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        );
      case 'glass':
        return const Icon(
          Icons.blur_on_rounded,
          color: Colors.white,
          size: 20,
        );
      default:
        return Icon(
          _isHovered ? Icons.drag_indicator : Icons.bolt_rounded,
          color: Colors.white,
          size: 24,
        );
    }
  }

  // Expanded menu panel view
  Widget _buildExpandedView() {
    return Container(
      width: 220,
      height: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '控制面板',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white60, size: 16),
                onPressed: () {
                  setState(() {
                    _isExpanded = false;
                  });
                  windowManager.setSize(const Size(95, 95));
                },
              )
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildQuickActionTile(Icons.speed, '加速运行', () {}),
                _buildQuickActionTile(Icons.cleaning_services_rounded, '清理缓存', () {}),
                _buildQuickActionTile(Icons.settings, '系统设置', () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent, size: 18),
            const SizedBox(width: 12),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
