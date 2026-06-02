import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  Future<void> _handleResult(Map<String, dynamic> result, String fallback) async {
    if (result['success'] == true) {
      final token = result['data']['access_token'] as String;
      await ApiService.saveToken(token);
      emit(AuthAuthenticated(token));
    } else {
      emit(AuthError(result['message'] ?? fallback));
    }
  }

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    await _handleResult(
      await ApiService.login(email: email, password: password),
      'Ошибка входа',
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    await _handleResult(
      await ApiService.register(name: name, email: email, password: password),
      'Ошибка регистрации',
    );
  }

  Future<void> loginWithGoogleCode(String code) async {
    emit(AuthLoading());
    await _handleResult(
      await ApiService.loginWithGoogleCode(code),
      'Ошибка Google авторизации',
    );
  }

  Future<void> loginWithTelegramCode(String code) async {
    emit(AuthLoading());
    await _handleResult(
      await ApiService.loginWithTelegramCode(code),
      'Неверный или устаревший код',
    );
  }

  void resetState() => emit(AuthInitial());
}
