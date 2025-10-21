class CitySuggestion {
  final String name;
  final String country;
  final double lat;
  final double lon;
  final int? population;

  CitySuggestion({
    required this.name,
    required this.country,
    required this.lat,
    required this.lon,
    this.population,
  });

  factory CitySuggestion.fromJson(Map<String, dynamic> json) {
    return CitySuggestion(
      name: json['city'] ?? '',
      country: json['country'] ?? '',
      lat: (json['latitude'] as num).toDouble(),
      lon: (json['longitude'] as num).toDouble(),
      population: json['population'],
    );
  }
}