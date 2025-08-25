import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart' as app_user;

abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;
  LoginRequested({required this.username, required this.password});
}

class LogoutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final app_user.User user;
  AuthAuthenticated({required this.user});
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);

    // فحص حالة المصادقة عند بدء التطبيق
    add(CheckAuthStatus());
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final client = Supabase.instance.client;

      // البحث عن المستخدم في جدول managers
      final response = await client
          .from('managers')
          .select()
          .eq('username', event.username)
          .eq('password', event.password)
          .eq('is_suspended', false)
          .single();

      if (response != null) {
        final user = app_user.User(
          id: response['id'].toString(),
          username: response['username'],
          password: response['password'],
          fullName: response['full_name'] ?? response['username'],
          role: response['role'] ?? 'manager',
        );

        // حفظ بيانات المستخدم محلياً
        await _saveUserSession(user);

        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError(message: 'اسم المستخدم أو كلمة المرور غير صحيحة'));
      }
    } catch (e) {
      emit(AuthError(message: 'خطأ في تسجيل الدخول: $e'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // حذف بيانات الجلسة المحلية
      await _clearUserSession();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'خطأ في تسجيل الخروج: $e'));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      // فحص وجود جلسة محفوظة
      final user = await _getSavedUserSession();
      if (user != null) {
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  // حفظ بيانات المستخدم محلياً
  Future<void> _saveUserSession(app_user.User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', user.id);
    await prefs.setString('username', user.username);
    await prefs.setString('full_name', user.fullName);
    await prefs.setString('role', user.role);
    await prefs.setBool('is_logged_in', true);
  }

  // استرجاع بيانات المستخدم المحفوظة
  Future<app_user.User?> _getSavedUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (!isLoggedIn) return null;

    final userId = prefs.getString('user_id');
    final username = prefs.getString('username');
    final fullName = prefs.getString('full_name');
    final role = prefs.getString('role');

    if (userId != null && username != null) {
      return app_user.User(
        id: userId,
        username: username,
        fullName: fullName ?? username,
        role: role ?? 'manager',
      );
    }

    return null;
  }

  // حذف بيانات الجلسة المحلية
  Future<void> _clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('username');
    await prefs.remove('full_name');
    await prefs.remove('role');
    await prefs.setBool('is_logged_in', false);
  }
}
