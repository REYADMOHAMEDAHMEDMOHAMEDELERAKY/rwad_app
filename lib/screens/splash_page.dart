import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart' as auth_bloc;
import 'welcome_page.dart';
import 'manager_page.dart';
import 'driver_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.elasticOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startAnimation();
  }

  void _startAnimation() {
    _mainController.forward();
    _pulseController.repeat(reverse: true);

    // Check authentication status after animation
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        // Trigger authentication check through AuthBloc
        context.read<auth_bloc.AuthBloc>().add(auth_bloc.CheckAuthStatus());
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<auth_bloc.AuthBloc, auth_bloc.AuthState>(
      listener: (context, state) {
        if (state is auth_bloc.AuthAuthenticated) {
          // Navigate based on user role
          if (state.user.role == 'driver') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder:
                    (_) => DriverPage(
                      userInfo: {
                        'id': state.user.id,
                        'username': state.user.username,
                        'full_name': state.user.fullName,
                        'role': state.user.role,
                      },
                    ),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ManagerPage()),
            );
          }
        } else if (state is auth_bloc.AuthUnauthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WelcomePage()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: AnimatedBuilder(
            animation: Listenable.merge([_mainController, _pulseController]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value * _pulseAnimation.value,
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Image.asset(
                            'assets/logo.png',
                            width: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.directions_car,
                                size: 80,
                                color: Colors.blue.shade600,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // App Name
                      Text(
                        'FleetTracker',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        'نظام إدارة وتتبع السيارات',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Loading Indicator
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
