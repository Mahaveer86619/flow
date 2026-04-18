import 'package:dio/dio.dart';
import 'youtube_interceptor.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  static DioClient get instance => _instance;

  late final Dio dio;

  DioClient._internal() {
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    dio.interceptors.add(YoutubeInterceptor());
    // Add logging interceptor if needed
  }
}
