import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../env.dart';

class ApiService {
  static const String baseUrl = Env.baseUrl;

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {'Authorization': 'Bearer $token'};
  }
  // TELEGRAM
  static Future<Map<String, dynamic>> getTelegramStatus() async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get('/api/v1/telegram/status',
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка'};
    }
  }

  static Future<Map<String, dynamic>> generateTelegramCode() async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.post('/api/v1/telegram/generate-code',
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка'};
    }
  }

  static Future<Map<String, dynamic>> unlinkTelegram() async {
    try {
      final headers = await _authHeaders();
      await _dio.delete('/api/v1/telegram/unlink',
          options: Options(headers: headers));
      return {'success': true};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка'};
    }
  }
  // РЕГИСТРАЦИЯ
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/api/v1/auth/register',
          data: {'name': name, 'email': email, 'password': password});
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка соединения'};
    }
  }

  // ВХОД
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/api/v1/auth/login',
          data: {'email': email, 'password': password});
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка соединения'};
    }
  }

  static Future<bool> validateToken() async {
    try {
      final headers = await _authHeaders();
      await _dio.get('/api/v1/auth/me', options: Options(headers: headers));
      return true;
    } catch (_) {
      return false;
    }
  }

  // ПИТОМЦЫ
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get('/api/v1/dashboard/stats',
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException {
      return {'success': false};
    }
  }

  static Future<Map<String, dynamic>> getPets() async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get('/api/v1/pets',
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка соединения'};
    }
  }

  static Future<Map<String, dynamic>> createPet({
    required String name,
    String? breed,
    String? birthDate,
    String? sex,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.post('/api/v1/pets',
          data: {'name': name, 'breed': breed, 'birth_date': birthDate, 'sex': sex},
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка соединения'};
    }
  }

  static Future<Map<String, dynamic>> updatePet({
    required String petId,
    String? name,
    String? breed,
    String? birthDate,
    String? sex,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.put('/api/v1/pets/$petId',
          data: {
            if (name != null) 'name': name,
            if (breed != null) 'breed': breed,
            if (birthDate != null) 'birth_date': birthDate,
            if (sex != null) 'sex': sex,
          },
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка соединения'};
    }
  }

  static Future<Map<String, dynamic>> deletePet(String petId) async {
    try {
      final headers = await _authHeaders();
      await _dio.delete('/api/v1/pets/$petId', options: Options(headers: headers));
      return {'success': true};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка соединения'};
    }
  }

  static Future<Map<String, dynamic>> uploadPetPhoto({
    required String petId,
    required String filePath,
  }) async {
    try {
      final token = await getToken();
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post('/api/v1/pets/$petId/photo',
          data: formData,
          options: Options(headers: {'Authorization': 'Bearer $token'}));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка загрузки'};
    }
  }

  // ЗДОРОВЬЕ
  static Future<Map<String, dynamic>> getHealthRecords(String petId) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get('/api/v1/pets/$petId/health',
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка соединения'};
    }
  }

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
      final response = await _dio.post('/api/v1/pets/$petId/health',
          data: {
            'record_type': recordType,
            'title': title,
            'description': description,
            'record_date': recordDate,
            'next_date': nextDate,
          },
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка соединения'};
    }
  }

  // ВЕС
  static Future<Map<String, dynamic>> getWeightLogs(String petId) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get('/api/v1/pets/$petId/weight',
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка соединения'};
    }
  }

  static Future<Map<String, dynamic>> addWeight({
    required String petId,
    required double weightKg,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.post('/api/v1/pets/$petId/weight',
          data: {'weight_kg': weightKg},
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка соединения'};
    }
  }

  // НАПОМИНАНИЯ
  static Future<Map<String, dynamic>> getReminders() async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get('/api/v1/reminders',
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка соединения'};
    }
  }

  static Future<Map<String, dynamic>> createReminder({
    required String petId,
    required String title,
    required String remindAt,
    String? repeatRule,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.post('/api/v1/reminders',
          data: {
            'pet_id': petId,
            'title': title,
            'remind_at': remindAt,
            if (repeatRule != null) 'repeat_rule': repeatRule,
          },
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка соединения'};
    }
  }

  static Future<Map<String, dynamic>> deleteReminder(String reminderId) async {
    try {
      final headers = await _authHeaders();
      await _dio.delete('/api/v1/reminders/$reminderId',
          options: Options(headers: headers));
      return {'success': true};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка соединения'};
    }
  }

  static Future<Map<String, dynamic>> exportHealthPdf(String petId) async {
    try {
      final token = await getToken();
      final response = await _dio.get(
        '/api/v1/pets/$petId/health/export',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      return {'success': true, 'bytes': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data.toString() ?? 'Ошибка экспорта'};
    }
  }

  static Future<Map<String, dynamic>> completeReminder(String reminderId) async {
    try {
      final headers = await _authHeaders();
      await _dio.put('/api/v1/reminders/$reminderId/done',
          options: Options(headers: headers));
      return {'success': true};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка соединения'};
    }
  }

  // ТЕЧКИ
  static Future<Map<String, dynamic>> getHeatCycles(String petId) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get('/api/v1/pets/$petId/heat-cycles',
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка'};
    }
  }

  static Future<Map<String, dynamic>> addHeatCycle({
    required String petId,
    required String startedAt,
    String? notes,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.post('/api/v1/pets/$petId/heat-cycles',
          data: {'started_at': startedAt, if (notes != null) 'notes': notes},
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка'};
    }
  }

  static Future<Map<String, dynamic>> updateHeatCycle({
    required String petId,
    required String cycleId,
    String? startedAt,
    String? endedAt,
    String? notes,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.put('/api/v1/pets/$petId/heat-cycles/$cycleId',
          data: {
            if (startedAt != null) 'started_at': startedAt,
            if (endedAt != null) 'ended_at': endedAt,
            if (notes != null) 'notes': notes,
          },
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка'};
    }
  }

  static Future<Map<String, dynamic>> deleteHeatCycle({
    required String petId,
    required String cycleId,
  }) async {
    try {
      final headers = await _authHeaders();
      await _dio.delete('/api/v1/pets/$petId/heat-cycles/$cycleId',
          options: Options(headers: headers));
      return {'success': true};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка'};
    }
  }

  // КАРТА
  static Future<Map<String, dynamic>> getVets({
    required double lat,
    required double lon,
    String placeType = 'vets',
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.get('/api/v1/map/vets',
          queryParameters: {'lat': lat, 'lon': lon, 'place_type': placeType},
          options: Options(headers: headers));
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка соединения'};
    }
  }
  // УДАЛИТЬ ЗАПИСЬ ЗДОРОВЬЯ
  static Future<Map<String, dynamic>> deleteHealthRecord({
    required String petId,
    required String recordId,
  }) async {
    try {
      final headers = await _authHeaders();
      await _dio.delete(
        '/api/v1/pets/$petId/health/$recordId',
        options: Options(headers: headers),
      );
      return {'success': true};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка'};
    }
  }

  // РЕДАКТИРОВАТЬ ЗАПИСЬ ЗДОРОВЬЯ
  static Future<Map<String, dynamic>> updateHealthRecord({
    required String petId,
    required String recordId,
    String? title,
    String? description,
    String? recordDate,
    String? nextDate,
  }) async {
    try {
      final headers = await _authHeaders();
      final response = await _dio.put(
        '/api/v1/pets/$petId/health/$recordId',
        data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
          if (recordDate != null) 'record_date': recordDate,
          if (nextDate != null) 'next_date': nextDate,
        },
        options: Options(headers: headers),
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка'};
    }
  }

  // GOOGLE OAUTH
  static Future<Map<String, dynamic>> loginWithGoogleCode(String code) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/google/exchange',
        data: {'code': code},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка Google авторизации'};
    }
  }

  // TELEGRAM LOGIN
  static Future<Map<String, dynamic>> loginWithTelegramCode(String code) async {
    try {
      final response = await _dio.post(
        '/api/v1/auth/telegram-login',
        data: {'code': code},
      );
      return {'success': true, 'data': response.data};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Неверный код'};
    }
  }

  // УДАЛИТЬ ЗАПИСЬ ВЕСА
  static Future<Map<String, dynamic>> deleteWeightLog({
    required String petId,
    required String weightId,
  }) async {
    try {
      final headers = await _authHeaders();
      await _dio.delete(
        '/api/v1/pets/$petId/weight/$weightId',
        options: Options(headers: headers),
      );
      return {'success': true};
    } on DioException catch (e) {
      return {'success': false, 'message': e.response?.data['detail'] ?? 'Ошибка'};
    }
  }
}