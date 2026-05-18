import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../config.dart';
import '../models.dart';

// ignore_for_file: avoid_print

class ApiService {
  /// Sends an image to the GblackAI API and returns the structured result.
  ///
  /// Throws [ApiException] on HTTP error.
  /// Throws [FormatException] if the response is not valid JSON.
  static Future<AnalysisResponse> analyze({
    required File imageFile,
    required AnalysisType analysisType,
  }) async {
    final uri = Uri.parse('$kApiBaseUrl/api/v12/analyze');
    final request = http.MultipartRequest('POST', uri);

    request.fields['analysis_type'] = analysisType.value;
    final ext = imageFile.path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'png' : 'jpeg';
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType('image', mime),
      ),
    );

    final streamed = await request.send().timeout(kRequestTimeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AnalysisResponse.fromJson(json);
    }

    // Extract error message from API response
    String errorMessage;
    try {
      final errorJson = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = errorJson['detail']?.toString() ?? 'Unknown error';
    } catch (_) {
      errorMessage = response.body;
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: errorMessage,
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';

  String get userFriendlyMessage {
    return switch (statusCode) {
      415 => 'Unsupported image format.',
      429 => 'API quota exceeded. Please try again in a moment.',
      502 => 'The AI model returned an invalid response.',
      503 => 'AI service temporarily unavailable.',
      _ => message,
    };
  }
}
