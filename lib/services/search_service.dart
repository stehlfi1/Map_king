import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/search_result.dart';

class SearchService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org/search';
  static const String _userAgent = 'MapPhotoApp/1.0.0 (Filip Stehlik)';
  
  // Rate limiting: Nominatim allows 1 request per second
  static DateTime? _lastRequestTime;
  static const Duration _minRequestInterval = Duration(seconds: 1);

  static Future<List<SearchResult>> searchPlaces(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    // Rate limiting
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - timeSinceLastRequest);
      }
    }

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': query.trim(),
        'format': 'json',
        'limit': '10',
        'addressdetails': '1',
        'extratags': '1',
      });

      _lastRequestTime = DateTime.now();
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map((json) => SearchResult.fromJson(json))
            .where((result) => result.isValid)
            .toList();
      } else {
        throw Exception('Search failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Search error: $e');
    }
  }

  static Future<List<SearchResult>> searchNearby({
    required double latitude,
    required double longitude,
    String? type,
    int limit = 10,
  }) async {
    // Rate limiting
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest < _minRequestInterval) {
        await Future.delayed(_minRequestInterval - timeSinceLastRequest);
      }
    }

    try {
      final Map<String, String> queryParams = {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
        'limit': limit.toString(),
        'addressdetails': '1',
        'extratags': '1',
        'zoom': '18', // High zoom for nearby places
      };

      if (type != null) {
        queryParams['type'] = type;
      }

      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse')
          .replace(queryParameters: queryParams);

      _lastRequestTime = DateTime.now();
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);
        if (jsonResponse is Map<String, dynamic>) {
          return [SearchResult.fromJson(jsonResponse)];
        } else if (jsonResponse is List) {
          return jsonResponse
              .map((json) => SearchResult.fromJson(json))
              .where((result) => result.isValid)
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Nearby search error: $e');
    }
  }
}