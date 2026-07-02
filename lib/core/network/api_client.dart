import 'package:dio/dio.dart';

class ApiClient {
  // Singleton pattern
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio _dio;

  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      // URL du serveur FastAPI (Render - Production)
      baseUrl: 'https://queuecare-backend-u770.onrender.com',
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Ajout d'intercepteurs pour logger les requêtes (pratique pour le débug)
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🌐 [HTTP Request] ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ [HTTP Response] ${response.statusCode} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print('❌ [HTTP Error] ${e.response?.statusCode} ${e.requestOptions.uri}');
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}
