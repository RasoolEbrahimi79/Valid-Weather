import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:valid_weather/models/city_suggestion.dart';
import 'package:valid_weather/models/weather_data.dart';
import 'package:valid_weather/services/weather_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;
  WeatherData? _weatherData;
  bool _isLoading = false;
  final WeatherService _weatherService = WeatherService();

  Future<void> _fetchWeather(double lat, double lon) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final weather = await _weatherService.fetchWeather(lat, lon);
      setState(() {
        _weatherData = weather;
        _isLoading = false;
        _errorText = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = 'Error fetching weather: $e';
      });
    }
  }

  void _validateInput(String value) {
    setState(() {
      _errorText = value.isEmpty ? 'City name cannot be empty' : null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valid Weather'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer, // Dark theme surface
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Material 3 spacing: 16dp
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Section: City Name TextField with Suggestions
              TypeAheadField<CitySuggestion>(
                controller: _controller,
                suggestionsCallback: (pattern) async {
                  return await _weatherService.getCitySuggestions(pattern);
                },
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: _validateInput,
                    decoration: InputDecoration(
                      labelText: 'City Name',
                      labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0), // Material 3: rounded corners
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainer,
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () {
                                setState(() {
                                  _controller.clear();
                                  _errorText = null;
                                  _weatherData = null;
                                });
                              },
                            )
                          : null,
                      errorText: _errorText,
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  );
                },
                itemBuilder: (context, CitySuggestion suggestion) {
                  return ListTile(
                    title: Text(suggestion.name),
                    subtitle: Text(suggestion.country),
                    leading: const Icon(Icons.location_on, color: Colors.blue),
                  );
                },
                onSelected: (CitySuggestion suggestion) {
                  _controller.text = '${suggestion.name}, ${suggestion.country}';
                  _validateInput(_controller.text);
                  _fetchWeather(suggestion.lat, suggestion.lon);
                },
                loadingBuilder: (context) => const SizedBox(
                  height: 60,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorBuilder: (context, error) => const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text('Error fetching suggestions', style: TextStyle(color: Colors.grey)),
                  ),
                ),
                emptyBuilder: (context) => const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text('No cities found', style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ),
              // Center Section: Weather Data
              Expanded(
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : _weatherData != null
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _weatherData!.temperature,
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                                const SizedBox(height: 8.0), // Material 3 spacing
                                Text(
                                  _weatherData!.condition,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Max: ${_weatherData!.maxTemperature} | Min: ${_weatherData!.minTemperature}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  '${_weatherData!.humidity} | ${_weatherData!.wind}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '25°C', // Placeholder for temperature
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                                const SizedBox(height: 8.0), // Material 3 spacing
                                Text(
                                  'Sunny', // Placeholder for weather condition
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Max: 28°C | Min: 22°C', // Placeholder for max/min
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Humidity: 60% | Wind: 10 km/h', // Placeholder for additional info
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                ),
              ),
              // Bottom Section: Placeholder Icon
              Container(
                height: 150, // Fixed height for placeholder
                alignment: Alignment.bottomCenter,
                child: Icon(
                  Icons.wb_sunny, // Placeholder for weather icon
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}