import 'package:http/http.dart' as http;
import 'dart:convert';
import 'connectivity_service.dart';
import 'hive_service.dart';
import '../utils/error_handler.dart';

class TranslationService {
  static Future<String> translate(
    String text,
    String sourceLang,
    String targetLang,
  ) async {
    final langpair = '$sourceLang|$targetLang';
    final key = '$text|$langpair';

    // Check cache first
    final cached = await HiveService.getTranslation(key);
    if (cached != null) {
      return cached;
    }

    // Check internet connectivity
    if (!await ConnectivityService.hasInternetConnection()) {
      throw Exception('No internet connection');
    }

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=$langpair',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final translated = data['responseData']['translatedText'];
        await HiveService.saveTranslation(key, translated);
        return translated;
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(ErrorHandler.handleError(e));
    }
  }

  static List<String> findSimilarWords(String word) {
    final keys = HiveService.getAllKeys();
    final similar = <String>[];
    for (final key in keys) {
      final original = key.split('|')[0].toLowerCase();
      if (original.contains(word.toLowerCase())) {
        similar.add(key.split('|')[0]);
      }
    }
    return similar;
  }
}
