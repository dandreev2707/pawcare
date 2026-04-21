import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8001';
  
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  // Сохранить токен
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Получить токен
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Удалить токен (выход)
  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Заголовки с токеном
  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // РЕГИСТРАЦИЯ
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/register',
        data: {'name': name, 'email': email, 'password': password},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Ошибка соединения';
      return {'success': false, 'message': message};
    }
  }

  // ВХОД
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/login',
        data: {'email': email, 'password': password},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Ошибка соединения';
      return {'success': false, 'message': message};
    }
  }

  // ПОЛУЧИТЬ ПИТОМЦЕВ
  static Future<Map<String, dynamic>> getPets() async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get(
        '/api/v1/pets',
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Ошибка соединения';
      return {'success': false, 'message': message};
    }
  }

  // ДОБАВИТЬ ПИТОМЦА
  static Future<Map<String, dynamic>> createPet({
    required String name,
    String? breed,
    String? birthDate,
    String? sex,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.post(
        '/api/v1/pets',
        data: {
          'name': name,
          'breed': breed,
          'birth_date': birthDate,
          'sex': sex,
        },
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Ошибка соединения';
      return {'success': false, 'message': message};
    }
  }

  // УДАЛИТЬ ПИТОМЦА
  static Future<Map<String, dynamic>> deletePet(String petId) async {
    try {
      final headers = await _authHeaders();
      await _dio.delete(
        '/api/v1/pets/$petId',
        options: Options(headers: headers),
      );
      return {'success': true};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Ошибка соединения';
      return {'success': false, 'message': message};
    }
  }

  // ПОЛУЧИТЬ ЗАПИСИ ЗДОРОВЬЯ
  static Future<Map<String, dynamic>> getHealthRecords(String petId) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get(
        '/api/v1/pets/$petId/health',
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Ошибка соединения';
      return {'success': false, 'message': message};
    }
  }

  // ДОБАВИТЬ ЗАПИСЬ ЗДОРОВЬЯ
  static Future<Map<String, dynamic>> addHealthRecord({
    required String petId,
    required String recordType,
    required String title,
    String? description,
    required String recordDate,
    String? nextDate,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.post(
        '/api/v1/pets/$petId/health',
        data: {
          'record_type': recordType,
          'title': title,
          'description': description,
          'record_date': recordDate,
          'next_date': nextDate,
        },
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      final message = e.response?.data['detail'] ?? 'Ошибка соединения';
      return {'success': false, 'message': message};
    }
  }
}