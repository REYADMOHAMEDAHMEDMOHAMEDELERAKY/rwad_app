import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../bloc/auth_bloc.dart' as auth_bloc;
import 'driver_page.dart';

class DriverLoginPage extends StatefulWidget {
  const DriverLoginPage({super.key});

  @override
  State<DriverLoginPage> createState() => _DriverLoginPageState();
}

class _DriverLoginPageState extends State<DriverLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState!.validate()) {
      // Use AuthBloc for login instead of direct database call
      final authBloc = context.read<auth_bloc.AuthBloc>();
      authBloc.add(
        auth_bloc.LoginRequested(
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text('خطأ'),
            ],
          ),
          content: Text(message, style: GoogleFonts.cairo(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('موافق'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<auth_bloc.AuthBloc, auth_bloc.AuthState>(
      listener: (context, state) {
        if (state is auth_bloc.AuthAuthenticated) {
          // Navigate to driver page with user info
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder:
                  (context) => DriverPage(
                    userInfo: {
                      'id': state.user.id,
                      'username': state.user.username,
                      'full_name': state.user.fullName,
                      'role': state.user.role,
                    },
                  ),
            ),
            (route) => false,
          );
        } else if (state is auth_bloc.AuthError) {
          _showErrorDialog(state.message);
        }
      },
      child: BlocBuilder<auth_bloc.AuthBloc, auth_bloc.AuthState>(
        builder: (context, state) {
          final isLoading = state is auth_bloc.AuthLoading;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: Colors.grey[50],
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 60),

                        // Logo
                        Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(25),
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.directions_car,
                                    size: 70,
                                    color: Colors.blue.shade600,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Title
                        Text(
                          'تسجيل دخول السائق',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'أدخل بياناتك للوصول إلى واجهة السائق',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 50),

                        // Username Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'اسم المستخدم',
                              prefixIcon: Icon(
                                Icons.person,
                                color: Colors.blue.shade400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال اسم المستخدم';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Password Field
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: Icon(
                                Icons.lock,
                                color: Colors.blue.shade400,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'يرجى إدخال كلمة المرور';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Login Button
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _onLoginPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 3,
                            ),
                            child:
                                isLoading
                                    ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                    : Text(
                                      'تسجيل الدخول',
                                      style: GoogleFonts.cairo(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Back Button
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'العودة للصفحة الرئيسية',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
