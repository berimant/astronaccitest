// File: lib/blocs/auth/auth_state.dart

import 'package:equatable/equatable.dart';
import '/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String token; 
  
  const AuthAuthenticated({
    required this.user,
    required this.token,
  });

  @override
  List<Object?> get props => [user, token];
}

class AuthUnauthenticated extends AuthState {}

// Menambahkan properti rawLog dan memastikan Equatable compatibility
class AuthError extends AuthState {
  final String message;
  final String? rawLog;

  const AuthError({required this.message, this.rawLog});

  @override
  List<Object?> get props => [message, rawLog];
}
