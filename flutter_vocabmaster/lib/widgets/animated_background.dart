import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui';

class AnimatedBackground extends StatefulWidget {
  final bool isDark;

  const AnimatedBackground({
    Key? key,
    this.isDark = true,
  }) : super(key: key);

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _dropControllers;
  late List<AnimationController> _orbControllers;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    
    // Initialize 20 rain drop animations (reduced from 40 for better performance)
    _dropControllers = List.generate(20, (index) {
      final duration = 2 + _random.nextDouble() * 2;
      final delay = _random.nextDouble() * 3;
      
      final controller = AnimationController(
        duration: Duration(milliseconds: (duration * 1000).toInt()),
        vsync: this,
      );
      
      Future.delayed(Duration(milliseconds: (delay * 1000).toInt()), () {
        if (mounted) {
          controller.repeat();
        }
      });
      
      return controller;
    });
    
    // Initialize 4 background orb animations (reduced from 6)
    _orbControllers = List.generate(4, (index) {
      final duration = 20 + _random.nextDouble() * 10;
      final delay = _random.nextDouble() * 5;
      
      final controller = AnimationController(
        duration: Duration(milliseconds: (duration * 1000).toInt()),
        vsync: this,
      );
      
      Future.delayed(Duration(milliseconds: (delay * 1000).toInt()), () {
        if (mounted) {
          controller.repeat();
        }
      });
      
      return controller;
    });
  }

  @override
  void dispose() {
    for (var controller in _dropControllers) {
      controller.dispose();
    }
    for (var controller in _orbControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return IgnorePointer(
      child: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF172554), // blue-950
                Color(0xFF1e1b4b), // indigo-950
                Color(0xFF1e3a8a), // blue-900
              ],
            ),
          ),
          child: Stack(
            children: [
              // Rain drops
              ..._dropControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                final dropSize = 2.0 + _random.nextDouble() * 4;
                final initialX = _random.nextDouble();
                
                return AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    final progress = controller.value;
                    final opacity = progress < 0.1
                        ? progress * 10
                        : progress > 0.9
                            ? (1 - progress) * 10
                            : 1.0;
                    
                    return Positioned(
                      left: size.width * initialX,
                      top: -20 + (size.height + 120) * progress,
                      child: Opacity(
                        opacity: opacity * 0.6,
                        child: Container(
                          width: dropSize,
                          height: dropSize * 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(dropSize / 2),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: widget.isDark
                                  ? [
                                      const Color(0xFF06b6d4).withOpacity(0.6),
                                      const Color(0xFF06b6d4).withOpacity(0.3),
                                      Colors.transparent,
                                    ]
                                  : [
                                      const Color(0xFF06b6d4).withOpacity(0.4),
                                      const Color(0xFF06b6d4).withOpacity(0.2),
                                      Colors.transparent,
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF06b6d4).withOpacity(
                                  widget.isDark ? 0.4 : 0.3,
                                ),
                                blurRadius: widget.isDark ? 8 : 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
              
              // Background orbs
              ..._orbControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controller = entry.value;
                final orbSize = 150.0 + _random.nextDouble() * 200;
                final initialX = _random.nextDouble();
                final initialY = _random.nextDouble();
                final moveX = (_random.nextDouble() - 0.5) * 100;
                final moveY = (_random.nextDouble() - 0.5) * 100;
                
                return AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    final progress = controller.value;
                    final curve = Curves.easeInOut.transform(progress);
                    
                    // Calculate position using sine wave for smooth back-and-forth
                    final xOffset = sin(curve * 2 * pi) * moveX;
                    final yOffset = sin(curve * 2 * pi) * moveY;
                    
                    // Scale animation
                    final scale = 1.0 + sin(curve * 4 * pi) * 0.15;
                    
                    // Opacity animation
                    final opacity = 0.3 + sin(curve * 2 * pi) * 0.2;
                    
                    return Positioned(
                      left: size.width * initialX + xOffset,
                      top: size.height * initialY + yOffset,
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            width: orbSize,
                            height: orbSize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  const Color(0xFF06b6d4).withOpacity(0.08),
                                  const Color(0xFF3b82f6).withOpacity(0.04),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.5, 0.7],
                              ),
                            ),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                              child: Container(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ],
          ),
      ),
    );
  }
}