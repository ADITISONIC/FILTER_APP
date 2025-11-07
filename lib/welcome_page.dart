import 'package:flutter/material.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bubble1Animation;
  late Animation<double> _bubble2Animation;
  late Animation<double> _bubble3Animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _bubble1Animation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _bubble2Animation = Tween<double>(
      begin: 0.1,
      end: -0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _bubble3Animation = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              Color(0xFF7C4DFF),
              Color(0xFF311B92),
              Colors.black,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated Bubble 1
            AnimatedBuilder(
              animation: _bubble1Animation,
              builder: (context, child) {
                return Positioned(
                  top: screenHeight * 0.15 + (screenHeight * _bubble1Animation.value),
                  right: screenWidth * 0.1,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.purpleAccent.withOpacity(0.4),
                          Colors.purpleAccent.withOpacity(0.2),
                          Colors.transparent,
                        ],
                        stops: [0.1, 0.5, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Animated Bubble 2
            AnimatedBuilder(
              animation: _bubble2Animation,
              builder: (context, child) {
                return Positioned(
                  bottom: screenHeight * 0.2 + (screenHeight * _bubble2Animation.value),
                  left: screenWidth * 0.05,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.blueAccent.withOpacity(0.3),
                          Colors.blueAccent.withOpacity(0.15),
                          Colors.transparent,
                        ],
                        stops: [0.1, 0.5, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Animated Bubble 3 (New)
            AnimatedBuilder(
              animation: _bubble3Animation,
              builder: (context, child) {
                return Positioned(
                  top: screenHeight * 0.4,
                  left: screenWidth * 0.7 + (screenWidth * _bubble3Animation.value),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.pinkAccent.withOpacity(0.3),
                          Colors.pinkAccent.withOpacity(0.15),
                          Colors.transparent,
                        ],
                        stops: [0.1, 0.5, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Pulsating Logo
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Positioned.fill(
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(height: screenHeight * 0.1),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Pulsating Logo Container
                              Transform.scale(
                                scale: 1 + (_controller.value * 0.05),
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF7C4DFF),
                                        Color(0xFFE040FB),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purpleAccent.withOpacity(0.4 + (_controller.value * 0.2)),
                                        blurRadius: 25,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3 + (_controller.value * 0.1)),
                                      width: 2,
                                    ),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Outer Ring
                                      Container(
                                        width: 130,
                                        height: 130,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.2 + (_controller.value * 0.1)),
                                            width: 1,
                                          ),
                                        ),
                                      ),

                                      // Camera Icon with Gradient
                                      ShaderMask(
                                        shaderCallback: (bounds) => const LinearGradient(
                                          colors: [Colors.white, Color(0xFFE1F5FE)],
                                        ).createShader(bounds),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                      ),

                                      // Small Decorative Dots
                                      Positioned(
                                        top: 20,
                                        right: 20,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 500),
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.8 + (_controller.value * 0.2)),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // App Title with Gradient Text
                              ShaderMask(
                                shaderCallback: (bounds) => const LinearGradient(
                                  colors: [
                                    Color(0xFF7C4DFF),
                                    Color(0xFFE040FB),
                                    Color(0xFF18FFFF),
                                  ],
                                ).createShader(bounds),
                                child: const Text(
                                  'FILTER CAM',
                                  style: TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 3,
                                    height: 1.1,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Subtitle with modern typography
                              const Text(
                                'CREATE • CAPTURE • SHARE',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  letterSpacing: 4,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),

                              const SizedBox(height: 8),
                            ],
                          ),
                        ),

                        // Bottom Section
                        Padding(
                          padding: const EdgeInsets.only(bottom: 60),
                          child: Column(
                            children: [
                              // Start Button with Pulsating Effect
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                width: 240,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.purple.withOpacity(0.4 + (_controller.value * 0.2)),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, -5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/camera');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C4DFF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 500),
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.2 + (_controller.value * 0.1)),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'START CAMERA',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // AI Tools Buttons Row - ADD THIS SECTION


                              const SizedBox(height: 30),

                              // Animated Swipe Indicator
                              const SizedBox(height: 16),

                              // Instructions
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ADD THIS METHOD FOR AI TOOL BUTTONS
  Widget _buildAIToolButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: 110,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: color.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}