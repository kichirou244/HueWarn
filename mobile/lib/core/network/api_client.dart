import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient({String? baseUrl})
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ??
                const String.fromEnvironment(
                  'API_BASE_URL',
                  defaultValue: 'https://hue-warn.spit-husc.io.vn/api',
                ),
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        );

  void updateBaseUrl(String newUrl) {
    dio.options.baseUrl = newUrl;
  }
}
