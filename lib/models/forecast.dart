class Forecast {
  final DateTime date;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;

  Forecast({
  required this.date, 
  required this.weatherCode, 
  required this.maxTemp, 
  required this.minTemp
  }
  );
}