// File: lib/blocs/user/user_state.dart (Kode yang Diperbaiki)

import 'package:equatable/equatable.dart';
import 'package:astronacci_test_flutter/models/user_model.dart';

abstract class UserState extends Equatable {
  const UserState();

  @override
  // Pastikan tipe kembalian adalah List<Object>
  List<Object> get props => []; 
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<UserModel> users;
  final bool hasReachedMax;
  final int currentPage;
  final String? searchQuery;

  const UserLoaded({
    required this.users,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.searchQuery,
  });

  UserLoaded copyWith({
    List<UserModel>? users,
    bool? hasReachedMax,
    int? currentPage,
    String? searchQuery,
  }) {
    return UserLoaded(
      users: users ?? this.users,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  // UBAH: Kembalikan List<Object> dan pastikan searchQuery bukan null
  List<Object> get props => [
        users, 
        hasReachedMax, 
        currentPage, 
        searchQuery ?? '' // Jika searchQuery null, gunakan string kosong ('')
      ]; 
}

class UserError extends UserState {
  final String message;
  const UserError(this.message);

  @override
  List<Object> get props => [message];
}