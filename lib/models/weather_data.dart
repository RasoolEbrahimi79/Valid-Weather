class DailyForecast {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;

  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
  });
}

class WeatherData {
  final double temperature;          // current temperature
  final int weatherCode;             // current weather code
  final int humidity;
  final double windSpeed;
  final List<DailyForecast> dailyForecast;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.humidity,
    required this.windSpeed,
    required this.dailyForecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'] ?? {};
    final daily = json['daily'] ?? {};

    final dates = (daily['time'] as List<dynamic>?)?.cast<String>() ?? [];
    final maxTempsList = (daily['temperature_2m_max'] as List<dynamic>?) ?? [];
    final minTempsList = (daily['temperature_2m_min'] as List<dynamic>?) ?? [];
    final codesList = (daily['weather_code'] as List<dynamic>?) ?? [];

    final int length = dates.length;
    final List<DailyForecast> forecastList = [];

    for (int i = 0; i < length; i++) {
      if (i >= maxTempsList.length || i >= minTempsList.length || i >= codesList.length) {
        break;
      }
      forecastList.add(DailyForecast(
        date: DateTime.parse(dates[i]),
        maxTemp: (maxTempsList[i] as num).toDouble(),
        minTemp: (minTempsList[i] as num).toDouble(),
        weatherCode: (codesList[i] as num).toInt(),
      ));
    }

    return WeatherData(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      dailyForecast: forecastList,
    );
  }

  // Helper methods used in main_screen.dart
  double getCurrentTemp(String unit) =>
      unit == 'metric' ? temperature : temperature * 9 / 5 + 32;

  double getTemp(double temp, String unit) =>
      unit == 'metric' ? temp : temp * 9 / 5 + 32;

  double getWindSpeedFormatted(String unit) =>
      unit == 'metric' ? windSpeed : windSpeed * 0.621371;

  String getTemperatureUnit(String unit) => unit == 'metric' ? '°C' : '°F';

  String getWindSpeedUnit(String unit) => unit == 'metric' ? 'km/h' : 'mph';
}