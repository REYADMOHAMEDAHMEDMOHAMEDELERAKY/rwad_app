import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import 'manager_page.dart';
// using raster PNG logo instead of SVG

class ManagerLoginPage extends StatefulWidget {
  const ManagerLoginPage({super.key});

  @override
  State<ManagerLoginPage> createState() => _ManagerLoginPageState();
}

class _ManagerLoginPageState extends State<ManagerLoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // الانتقال لصفحة المدير عند نجاح تسجيل الدخول
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const ManagerPage()),
            );
          } else if (state is AuthError) {
            // عرض رسالة الخطأ
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFFF6F6F8), // soft dark-white background
                child: Stack(
                  children: [
                    // Animated background elements
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _BackgroundPainter(
                            animationValue: _animationController.value,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),

                    // Main content
                    Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Logo and title card
                            _buildHeaderCard(),
                            const SizedBox(height: 32),
                            // Login form (flat, no card)
                            _buildLoginFormCard(state),
                          ],
                        ),
                      ),
                    ),

                    // Loading overlay
                    if (state is AuthLoading)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Column(
      children: [
        // Show PNG logo directly without a big background box
        Image.asset('assets/logo.png', height: 120),
        const SizedBox(height: 20),
        // Title
        Text(
          'مرحباً بعودتك',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'تسجيل الدخول كمدير',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(
              context,
            ).primaryColor.withAlpha((0.75 * 255).toInt()),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginFormCard(AuthState state) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Username field
          TextFormField(
            controller: _userController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال اسم المستخدم';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'أدخل اسم المستخدم',
              prefixIcon: Icon(
                Icons.person_outline,
                color: Theme.of(context).primaryColor,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى إدخال كلمة المرور';
              }
              return null;
            },
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              hintText: 'أدخل كلمة المرور',
              prefixIcon: Icon(
                Icons.lock_outline,
                color: Theme.of(context).primaryColor,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey[600],
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 32),

          // Login button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              onPressed: state is AuthLoading ? null : _onLoginPressed,
              child: state is AuthLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'تسجيل دخول',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onLoginPressed() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;

      // استخدام AuthBloc لتسجيل الدخول
      final authBloc = context.read<AuthBloc>();
      authBloc.add(
        LoginRequested(
          username: _userController.text.trim(),
          password: _passController.text.trim(),
        ),
      );
    }
  }
}

class _BackgroundPainter extends CustomPainter {
  final double animationValue;

  _BackgroundPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha((0.05 * 255).toInt())
      ..style = PaintingStyle.fill;

    // Calculate positions based on animation
    final offset1 = Offset(
      size.width * 0.2 + (animationValue * 40 - 20),
      size.height * 0.2 + (animationValue * 30 - 15),
    );

    final offset2 = Offset(
      size.width * 0.8 - (animationValue * 30 - 15),
      size.height * 0.7 - (animationValue * 40 - 20),
    );

    final offset3 = Offset(
      size.width * 0.7 + (animationValue * 20 - 10),
      size.height * 0.3 - (animationValue * 20 - 10),
    );

    // Draw animated circles
    canvas.drawCircle(offset1, 100, paint);
    canvas.drawCircle(offset2, 150, paint);
    canvas.drawCircle(offset3, 70, paint);

    // Draw connecting lines
    paint
      ..color = Colors.white.withAlpha((0.1 * 255).toInt())
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(offset1, offset2, paint);
    canvas.drawLine(offset2, offset3, paint);
    canvas.drawLine(offset3, offset1, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
