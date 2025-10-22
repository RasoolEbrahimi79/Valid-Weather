class WeatherData {
  final double temperature;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;
  final int humidity;
  final double windSpeed;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
    required this.humidity,
    required this.windSpeed,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    print('Parsing weather JSON: $json');
    final current = json['current'] ?? {};
    final daily = json['daily'] ?? {};
    return WeatherData(
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 0,
      maxTemp: (daily['temperature_2m_max'] as List<dynamic>?)?.first.toDouble() ?? 0.0,
      minTemp: (daily['temperature_2m_min'] as List<dynamic>?)?.first.toDouble() ?? 0.0,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
    );
  }

  double getTemperature(String unit) {
    return unit == 'metric' ? temperature : temperature * 9 / 5 + 32;
  }

  double getMaxTemp(String unit) {
    return unit == 'metric' ? maxTemp : maxTemp * 9 / 5 + 32;
  }

  double getMinTemp(String unit) {
    return unit == 'metric' ? minTemp : minTemp * 9 / 5 + 32;
  }

  double getWindSpeed(String unit) {
    return unit == 'metric' ? windSpeed : windSpeed * 0.621371;
  }

  String getTemperatureUnit(String unit) {
    return unit == 'metric' ? '°C' : '°F';
  }

  String getWindSpeedUnit(String unit) {
    return unit == 'metric' ? 'km/h' : 'mph';
  }
}