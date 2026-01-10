import 'dart:convert';
import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio;
  ApiService(this._dio);

  // -------------------------
  // Finance Tips (AdviceSlip) - FINAL FIX
  // -------------------------
  Future<List<Map<String, dynamic>>> fetchFinanceTips() async {
    try {
      final List<Map<String, dynamic>> tips = [];

      for (int i = 0; i < 5; i++) {
        final response = await _dio.get(
          'https://api.adviceslip.com/advice',
          options: Options(
            headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
          ),
        );

        dynamic data = response.data;

        // 🔥 FIX: API bazen String döndürüyor
        if (data is String) {
          data = jsonDecode(data);
        }

        if (data is Map<String, dynamic> &&
            data['slip'] is Map<String, dynamic>) {
          tips.add(Map<String, dynamic>.from(data['slip']));
        }
      }

      return tips;
    } on DioException catch (e) {
      throw Exception(
        e.response?.statusMessage ??
            e.message ??
            'Failed to fetch finance tips',
      );
    } catch (e) {
      throw Exception('Failed to fetch finance tips: $e');
    }
  }

  // -------------------------
  // Exchange Rates (Frankfurter)
  // -------------------------
  Future<Map<String, dynamic>> fetchExchangeRates({String base = 'EUR'}) async {
    try {
      final response = await _dio.get(
        'https://api.frankfurter.app/latest',
        queryParameters: {'from': base},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
        e.response?.statusMessage ?? 'Failed to fetch exchange rates',
      );
    }
  }
}
