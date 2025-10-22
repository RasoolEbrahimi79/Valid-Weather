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
    print('Parsing city JSON: $json');
    return CitySuggestion(
      name: json['city'] ?? json['name'] ?? 'Unknown',
      country: json['country'] ?? json['countryCode'] ?? 'Unknown',
      lat: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      lon: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      population: json['population'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'latitude': lat,
      'longitude': lon,
      'population': population,
    };
  }

  @override
  String toString() {
    return 'CitySuggestion(name: $name, country: $country, lat: $lat, lon: $lon, population: $population)';
  }
}