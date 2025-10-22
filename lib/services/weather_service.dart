import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:valid_weather/models/city_suggestion.dart';
import 'package:valid_weather/models/weather_data.dart';

class WeatherService {
  Future<List<CitySuggestion>> getCitySuggestions(String query) async {
    print('getCitySuggestions called with query: $query');
    if (query.length < 2) {
      print('Query too short: $query');
      return [];
    }
    try {
      print('Making GeoDB API call for: $query');
      final response = await http.get(
        Uri.parse('https://wft-geo-db.p.rapidapi.com/v1/geo/cities?minPopulation=10000&namePrefix=$query&limit=5'),
        headers: {
          'X-RapidAPI-Key': '3340767099msh678cedaf75158afp156c56jsn5e78743b7e3a',
          'X-RapidAPI-Host': 'wft-geo-db.p.rapidapi.com'
        },
      );
      print('GeoDB API response status: ${response.statusCode}');
      print('GeoDB API response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed GeoDB JSON: $data');
        final List<dynamic> results = data['data'] ?? [];
        print('Found ${results.length} cities');
        final suggestions = results.map((json) => CitySuggestion.fromJson(json)).toList();
        print('Mapped suggestions: $suggestions');
        return suggestions;
      } else {
        print('GeoDB API error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception in getCitySuggestions: $e');
      return [];
    }
  }

  Future<WeatherData?> getWeatherData(double lat, double lon) async {
    try {
      print('Fetching weather for lat: $lat, lon: $lon');
      final response = await http.get(
        Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min&timezone=auto'),
      );
      print('Open-Meteo API status: ${response.statusCode}');
      print('Open-Meteo API response: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        print('Open-Meteo API error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception in getWeatherData: $e');
      return null;
    }
  }

  String getWeatherIcon(int weatherCode, double windSpeed) {
    print('Mapping weather code: $weatherCode, windSpeed: $windSpeed');
    if (windSpeed > 20) {
      return 'assets/icons/windy.svg';
    }
    switch (weatherCode) {
      case 0:
      case 1:
        return 'assets/icons/sunny.svg';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return 'assets/icons/rainy.svg';
      default:
        return 'assets/icons/mixed.svg';
    }
  }
}