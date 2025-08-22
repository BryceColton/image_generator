import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/photo.dart';

class UnsplashApi {
  static const String _base = 'https://api.unsplash.com/search/photos';
  static String get _key => dotenv.env['UNSPLASH_ACCESS_KEY'] ?? '';

  /// Fetches [perPage] photos for [query] at [page]. Returns items + totals.
  static Future<({List<Photo> items, int total, int totalPages})> search({
    required String query,
    required int page,
    int perPage = 10,
  }) async {
    if (_key.isEmpty) {
      throw StateError('Missing UNSPLASH_ACCESS_KEY in .env');
    }

    final uri = Uri.parse(_base).replace(queryParameters: {
      'query': query.isEmpty ? 'popular' : query,
      'page': '$page',
      'per_page': '$perPage',
      'content_filter': 'high',
    });

    final res = await http.get(
      uri,
      headers: {'Authorization': 'Client-ID $_key'},
    );
    if (res.statusCode != 200) {
      throw StateError('Unsplash error: ${res.statusCode} ${res.body}');
    }

    final Map<String, dynamic> json = jsonDecode(res.body);
    final results = (json['results'] as List)
        .map((e) => Photo.fromJson(e as Map<String, dynamic>))
        .toList();

    return (
      items: results,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
    );
  }
}
