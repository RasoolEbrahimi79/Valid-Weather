import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:valid_weather/models/city_suggestion.dart';
import 'package:valid_weather/models/weather_data.dart';
import 'package:valid_weather/services/database_helper.dart';
import 'package:valid_weather/services/weather_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _errorText;
  final WeatherService _weatherService = WeatherService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  Timer? _debounce;
  WeatherData? _weatherData;
  bool _isLoading = false;
  String _unit = 'metric';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final unit = await _databaseHelper.getUnitPreference();
    setState(() {
      _unit = unit;
    });
  }

  void _validateInput(String value) {
    print('Validating input: $value');
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _errorText = value.isEmpty ? 'City name cannot be empty' : null;
      });
    });
  }

  Future<void> _fetchWeather(CitySuggestion suggestion) async {
    setState(() {
      _isLoading = true;
    });
    final weather = await _weatherService.getWeatherData(suggestion.lat, suggestion.lon);
    setState(() {
      _weatherData = weather;
      _isLoading = false;
    });
  }

  void _toggleUnit(bool isMetric) async {
    setState(() {
      _unit = isMetric ? 'metric' : 'imperial';
    });
    await _databaseHelper.saveUnitPreference(_unit);
    print('Toggled unit to: $_unit');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _databaseHelper.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('Building MainScreen');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valid Weather'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        actions: [
          Row(
            children: [
              Text(
                '°C',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _unit == 'metric'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              Switch(
                value: _unit == 'metric',
                onChanged: _toggleUnit,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
              Text(
                '°F',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _unit == 'imperial'
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TypeAheadField<CitySuggestion>(
                controller: _controller,
                suggestionsCallback: (pattern) async {
                  print('SuggestionsCallback triggered for: $pattern');
                  final suggestions = await _weatherService.getCitySuggestions(pattern);
                  print('Suggestions returned: $suggestions');
                  return suggestions;
                },
                builder: (context, controller, focusNode) {
                  print('Building TextField');
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (value) {
                      print('TextField changed: $value');
                      _validateInput(value);
                    },
                    decoration: InputDecoration(
                      labelText: 'City Name',
                      labelStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
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
                                print('Clear button pressed');
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
                  print('Rendering suggestion: ${suggestion.name}, ${suggestion.country}');
                  return ListTile(
                    title: Text(suggestion.name),
                    subtitle: Text(suggestion.country),
                    leading: const Icon(Icons.location_on, color: Colors.blue),
                  );
                },
                onSelected: (CitySuggestion suggestion) {
                  print('Selected suggestion: ${suggestion.name}, ${suggestion.country}');
                  _controller.text = '${suggestion.name}, ${suggestion.country}';
                  _validateInput(_controller.text);
                  _fetchWeather(suggestion);
                },
                loadingBuilder: (context) {
                  print('Showing loading indicator');
                  return const SizedBox(
                    height: 60,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error) {
                  print('TypeAhead error: $error');
                  return const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text('Error fetching suggestions', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                },
                emptyBuilder: (context) {
                  print('No suggestions found');
                  return const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text('No cities found', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  print('Test API button pressed');
                  final suggestions = await _weatherService.getCitySuggestions('Lon');
                  print('Manual test suggestions: $suggestions');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Found ${suggestions.length} cities')),
                  );
                },
                child: const Text('Test API'),
              ),
              Expanded(
                child: Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : _weatherData == null
                          ? Text(
                              'Select a city to view weather',
                              style: Theme.of(context).textTheme.bodyLarge,
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${_weatherData!.getTemperature(_unit).toStringAsFixed(1)}${_weatherData!.getTemperatureUnit(_unit)}',
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  _weatherService.getWeatherIcon(_weatherData!.weatherCode, _weatherData!.windSpeed).split('/').last.replaceAll('.svg', '').toUpperCase(),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Max: ${_weatherData!.getMaxTemp(_unit).toStringAsFixed(1)}${_weatherData!.getTemperatureUnit(_unit)} | Min: ${_weatherData!.getMinTemp(_unit).toStringAsFixed(1)}${_weatherData!.getTemperatureUnit(_unit)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'Humidity: ${_weatherData!.humidity}% | Wind: ${_weatherData!.getWindSpeed(_unit).toStringAsFixed(1)} ${_weatherData!.getWindSpeedUnit(_unit)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                ),
              ),
              Container(
                height: 150,
                alignment: Alignment.bottomCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: SvgPicture.asset(
                    _weatherData == null
                        ? 'assets/icons/sunny.svg'
                        : _weatherService.getWeatherIcon(_weatherData!.weatherCode, _weatherData!.windSpeed),
                    key: ValueKey<String>(
                      _weatherData == null
                          ? 'sunny'
                          : _weatherService.getWeatherIcon(_weatherData!.weatherCode, _weatherData!.windSpeed),
                    ),
                    width: 100,
                    height: 100,
                    
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}