import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/networking/app_failure.dart';
import 'user_model.dart';

part 'auth_state.freezed.dart';

@freezed
sealed class AuthState with _$AuthState {
  const AuthState._();

  const factory AuthState.initial() = _Initial;
  const factory AuthState.loading() = _Loading;
  const factory AuthState.authenticated(User user) = _Authenticated;
  const factory AuthState.unauthenticated() = _Unauthenticated;
  const factory AuthState.error(AppFailure failure) = _Error;

  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function(User user) authenticated,
    required T Function() unauthenticated,
    required T Function(AppFailure failure) error,
  }) {
    return switch (this) {
      _Initial() => initial(),
      _Loading() => loading(),
      _Authenticated(:final user) => authenticated(user),
      _Unauthenticated() => unauthenticated(),
      _Error(:final failure) => error(failure),
    };
  }

  T? whenOrNull<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(User user)? authenticated,
    T Function()? unauthenticated,
    T Function(AppFailure failure)? error,
  }) {
    return switch (this) {
      _Initial() => initial?.call(),
      _Loading() => loading?.call(),
      _Authenticated(:final user) => authenticated?.call(user),
      _Unauthenticated() => unauthenticated?.call(),
      _Error(:final failure) => error?.call(failure),
    };
  }

  T maybeWhen<T>({
    T Function()? initial,
    T Function()? loading,
    T Function(User user)? authenticated,
    T Function()? unauthenticated,
    T Function(AppFailure failure)? error,
    required T Function() orElse,
  }) {
    return switch (this) {
      _Initial() => initial?.call() ?? orElse(),
      _Loading() => loading?.call() ?? orElse(),
      _Authenticated(:final user) => authenticated?.call(user) ?? orElse(),
      _Unauthenticated() => unauthenticated?.call() ?? orElse(),
      _Error(:final failure) => error?.call(failure) ?? orElse(),
    };
  }
}
