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
  final FocusNode _focusNode = FocusNode();
  String? _errorText;
  final WeatherService _weatherService = WeatherService();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  Timer? _debounce;
  WeatherData? _weatherData;
  bool _isLoading = false;
  CitySuggestion? _lastCity;
  String _unit = 'metric';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final city = await _databaseHelper.getLastCity();
    final unit = await _databaseHelper.getUnitPreference();
    setState(() {
      _unit = unit;
      _lastCity = city;
      if (city != null) {
        _controller.text = '${city.name}, ${city.country}';
      }
    });
    if (city != null) {
      await _fetchWeather(city);
    }
  }

  void _validateInput(String value) {
    print('Validating input: $value');
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _errorText = value.isEmpty && _lastCity == null ? 'City name cannot be empty' : null;
      });
    });
  }

  Future<void> _fetchWeather(CitySuggestion suggestion) async {
    setState(() {
      _isLoading = true;
      _focusNode.unfocus();
    });
    final weather = await _weatherService.getWeatherData(suggestion.lat, suggestion.lon);
    await _databaseHelper.saveLastCity(suggestion);
    // Delay SVG transition to start after keyboard dismissal (~200ms)
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      _weatherData = weather;
      _lastCity = suggestion;
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
    _focusNode.dispose();
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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TypeAheadField<CitySuggestion>(
                  controller: _controller,
                  focusNode: _focusNode,
                  suggestionsCallback: (pattern) async {
                    print('SuggestionsCallback triggered for: $pattern');
                    if (pattern.isEmpty) return [];
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
                                    _errorText = _lastCity == null ? 'City name cannot be empty' : null;
                                    _focusNode.unfocus();
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
                      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 8.0),
                
                const SizedBox(height: 8.0),
                _isLoading
                    ? const CircularProgressIndicator()
                    : _weatherData == null
                        ? Text(
                            'Select a city to view weather',
                            style: Theme.of(context).textTheme.bodyLarge,
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 60,),
                              Text(
                                '${_lastCity!.name}, ${_lastCity!.country}',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8.0),
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
                              const SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                 Text(
                                    '°F',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: _unit == 'imperial'
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Switch(
                                    value: _unit == 'metric',
                                    onChanged: _toggleUnit,
                                    activeThumbColor: Theme.of(context).colorScheme.primary,
                                  ),
                                   Text(
                                    '°C',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: _unit == 'metric'
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                const SizedBox(height: 180.0),
                _lastCity == null
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        alignment: Alignment.center,
                        child: AnimatedSwitcher(
                          switchInCurve: Curves.easeIn ,
                          switchOutCurve: Curves.easeOut,
                          duration: const Duration(milliseconds: 500),
                          
                          // transitionBuilder: (Widget child, Animation<double> animation) {
                          //   return FadeTransition(opacity: animation, child: child);
                          // },
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
      ),
    );
  }
}