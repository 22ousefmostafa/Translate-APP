import 'package:http/http.dart' as http;
import 'dart:convert';

class VerbService {
  static Future<Map<String, List<String>>> getConjugations(
    String verb,
    String lang,
  ) async {
    if (lang == 'en') {
      // Local conjugations for English (simple rules)
      return {
        'Base Form': [verb],
        'Past Tense': ['${verb}ed'],
        'Present Tense (3rd person)': ['${verb}s'],
        'Past Participle': ['${verb}ed'],
        'Present Participle': ['${verb}ing'],
      };
    } else if (lang == 'ar') {
      // Check for API key
      const apiKey = 'YOUR_API_KEY';
      if (apiKey == 'YOUR_API_KEY') {
        return {
          'Error': [
            'Arabic verb conjugations require an API key. Please set your Verbix API key in verb_service.dart.',
          ],
        };
      }
      try {
        final response = await http.get(
          Uri.parse(
            'https://api.verbix.com/conjugator/json?D1=5&T1=$verb&L1=$lang&K=$apiKey',
          ),
        );
        if (response.statusCode == 200) {
          try {
            final data = json.decode(response.body);
            return {
              'Base Form': [verb],
              'Past': [data['past']?.toString() ?? 'N/A'],
              'Present': [data['present']?.toString() ?? 'N/A'],
              'Past Participle': [data['pastparticiple']?.toString() ?? 'N/A'],
              'Present Participle': [
                data['presentparticiple']?.toString() ?? 'N/A',
              ],
            };
          } catch (e) {
            return {
              'Error': [
                'API response was not valid JSON. Please check your API key or try again later.',
              ],
            };
          }
        } else {
          return {
            'Error': ['API Error: ${response.statusCode}'],
          };
        }
      } catch (e) {
        return {
          'Error': ['Network Error: $e'],
        };
      }
    }
    return {};
  }
}
