import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:valid_weather/models/city_suggestion.dart';
import 'package:valid_weather/models/weather_data.dart';

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

  Future<WeatherData> fetchWeather(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&hourly=temperature_2m&daily=temperature_2m_max,temperature_2m_min&timezone=auto'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_weather'] ?? {};
        final daily = data['daily'] ?? {};
        
        return WeatherData(
          temperature: '${current['temperature']?.toStringAsFixed(0) ?? 'N/A'}°C',
          condition: _getWeatherCondition(current['weathercode'] ?? 0),
          humidity: 'N/A%',
          wind: '${current['windspeed']?.toStringAsFixed(0) ?? 'N/A'} km/h',
          maxTemperature: '${daily['temperature_2m_max']?[0]?.toStringAsFixed(0) ?? 'N/A'}°C',
          minTemperature: '${daily['temperature_2m_min']?[0]?.toStringAsFixed(0) ?? 'N/A'}°C',
        );
      } else {
        throw Exception('Failed to fetch weather data');
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }

  String _getWeatherCondition(int code) {
    switch (code) {
      case 0:
        return 'Clear';
      case 1:
      case 2:
      case 3:
        return 'Clouds';
      case 45:
      case 48:
        return 'Mist';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 80:
      case 81:
      case 82:
        return 'Showers';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Unknown';
    }
  }
}