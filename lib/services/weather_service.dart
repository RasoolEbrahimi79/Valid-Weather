import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:valid_weather/models/city_suggestion.dart';

class WeatherService {
  Future<List<CitySuggestion>> getCitySuggestions(String query) async {
    if (query.length < 2) return [];
    try {
      final response = await http.get(
        Uri.parse('https://wft-geo-db.p.rapidapi.com/v1/geo/cities?minPopulation=20000&namePrefix=$query&limit=5'),
        headers: {
          'X-RapidAPI-Key': '3340767099msh678cedaf75158afp156c56jsn5e78743b7e3a',
          'X-RapidAPI-Host': 'wft-geo-db.p.rapidapi.com'
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['data'] ?? [];
        return results.map((json) => CitySuggestion.fromJson(json)).toList();
      }
    } catch (e) {
      // Fallback to empty list if API fails
    }
    return [];
  }
}