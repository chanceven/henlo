import 'package:dio/dio.dart';

class PlacesService {
  static const String _url =
      'https://lyjxzdcapqdvwxyamcbz.supabase.co/functions/v1/places-proxy';
  static final Dio _dio = Dio();

  static Future<Map<String, dynamic>> search(String query) async {
    final response = await _dio.post(_url, data: {
      'action': 'search',
      'query': query,
    });
    return response.data;
  }

  static Future<Map<String, dynamic>> autocomplete(String input) async {
    final response = await _dio.post(_url, data: {
      'action': 'autocomplete',
      'input': input,
    });
    return response.data;
  }

  static Future<Map<String, dynamic>> details(String placeId) async {
    final response = await _dio.post(_url, data: {
      'action': 'details',
      'placeId': placeId,
    });
    return response.data;
  }
}
