import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    final result = await ApiService.login(email: email, password: password);
    if (result['success']) {
      final token = result['data']['access_token'] as String;
      await ApiService.saveToken(token);
      emit(AuthAuthenticated(token));
    } else {
      emit(AuthError(result['message'] ?? 'Ошибка входа'));
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    final result = await ApiService.register(
      name: name, email: email, password: password,
    );
    if (result['success']) {
      final token = result['data']['access_token'] as String;
      await ApiService.saveToken(token);
      emit(AuthAuthenticated(token));
    } else {
      emit(AuthError(result['message'] ?? 'Ошибка регистрации'));
    }
  }

  Future<void> loginWithGoogleCode(String code) async {
    emit(AuthLoading());
    final result = await ApiService.loginWithGoogleCode(code);
    if (result['success']) {
      final token = result['data']['access_token'] as String;
      await ApiService.saveToken(token);
      emit(AuthAuthenticated(token));
    } else {
      emit(AuthError(result['message'] ?? 'Ошибка Google авторизации'));
    }
  }

  Future<void> loginWithTelegramCode(String code) async {
    emit(AuthLoading());
    final result = await ApiService.loginWithTelegramCode(code);
    if (result['success']) {
      final token = result['data']['access_token'] as String;
      await ApiService.saveToken(token);
      emit(AuthAuthenticated(token));
    } else {
      emit(AuthError(result['message'] ?? 'Неверный или устаревший код'));
    }
  }

  void resetState() => emit(AuthInitial());
}
