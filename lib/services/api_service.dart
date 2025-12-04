import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;
  ApiService(this._dio);

  Future<List<dynamic>> fetchFinanceTips() async {
    final response = await _dio.get('/posts'); // example endpoint
    return response.data as List<dynamic>;
  }
}
