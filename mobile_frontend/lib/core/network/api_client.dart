import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Gunakan 10.0.2.2 untuk Emulator Android, atau IP Wi-Fi Laptop (misal: 192.168.1.15) untuk HP Fisik
  static const String baseUrl = 'http://10.179.106.236:3000/api'; 
  
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  ApiClient() {
    // Interceptor untuk otomatis menyisipkan Token JWT ke setiap request
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }
}