part of 'auth_bloc.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final dynamic user;
  AuthAuthenticated({required this.user});
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure({required this.message});
}
