import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
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
                    if (pattern.isEmpty) return [];
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
                  itemBuilder: (context, suggestion) {
                    return ListTile(
                      tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      title: Text(suggestion.name),
                      subtitle: Text(suggestion.country),
                      leading: const Icon(Icons.location_on, color: Colors.blue),
                    );
                  },
                  onSelected: (suggestion) {
                    _controller.text = '${suggestion.name}, ${suggestion.country}';
                    _validateInput(_controller.text);
                    _fetchWeather(suggestion);
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
                  emptyBuilder: (context) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),

                // Main weather content
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.only(top: 50),
                        child: CircularProgressIndicator(),
                      )
                    : _weatherData == null && _lastCity == null
                        ? Text(
                            'Select a city to view weather',
                            style: Theme.of(context).textTheme.bodyLarge,
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 40),

                              // City name
                              if (_lastCity != null)
                                Text(
                                  '${_lastCity!.name}, ${_lastCity!.country}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),

                              const SizedBox(height: 16),

                              // Big animated weather icon
                              if (_weatherData != null)
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 500),
                                  switchInCurve: Curves.easeIn,
                                  switchOutCurve: Curves.easeOut,
                                  child: SvgPicture.asset(
                                    _weatherService.getWeatherIcon(
                                        _weatherData!.weatherCode, _weatherData!.windSpeed),
                                    key: ValueKey(_weatherService.getWeatherIcon(
                                        _weatherData!.weatherCode, _weatherData!.windSpeed)),
                                    width: 120,
                                    height: 120,
                                  ),
                                ),

                              const SizedBox(height: 8),

                              // Current temperature
                              if (_weatherData != null)
                                Text(
                                  '${_weatherData!.getCurrentTemp(_unit).toStringAsFixed(1)}${_weatherData!.getTemperatureUnit(_unit)}',
                                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),

                              const SizedBox(height: 8),

                              // Max / Min today
                              if (_weatherData != null && _weatherData!.dailyForecast.isNotEmpty)
                                Text(
                                  'Max: ${_weatherData!.getTemp(_weatherData!.dailyForecast.first.maxTemp, _unit).toStringAsFixed(1)}${_weatherData!.getTemperatureUnit(_unit)} | '
                                  'Min: ${_weatherData!.getTemp(_weatherData!.dailyForecast.first.minTemp, _unit).toStringAsFixed(1)}${_weatherData!.getTemperatureUnit(_unit)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),

                              const SizedBox(height: 8),

                              // Humidity and wind
                              if (_weatherData != null)
                                Text(
                                  'Humidity: ${_weatherData!.humidity}% | Wind: ${_weatherData!.getWindSpeedFormatted(_unit).toStringAsFixed(1)} ${_weatherData!.getWindSpeedUnit(_unit)}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),

                              const SizedBox(height: 16),

                              // Unit switch
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
                                    activeColor: Theme.of(context).colorScheme.primary,
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

                              const SizedBox(height: 32),

                              // 5-Day Forecast title
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  '5-Day Forecast',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Horizontal forecast list
                              if (_weatherData != null && _weatherData!.dailyForecast.isNotEmpty)
                                SizedBox(
                                  height: 150,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _weatherData!.dailyForecast.length.clamp(0, 6),
                                    itemBuilder: (context, index) {
                                      final day = _weatherData!.dailyForecast[index];
                                      final isToday = index == 0;
                                      final dayName = isToday ? 'Today' : DateFormat('EEE').format(day.date);
                                      final dateStr = DateFormat('MMM d').format(day.date);

                                      return Container(
                                        width: 100,
                                        margin: const EdgeInsets.only(right: 12),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              dayName,
                                              style: TextStyle(
                                                fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                            Text(
                                              dateStr,
                                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                                            ),
                                            const SizedBox(height: 8),
                                            SvgPicture.asset(
                                              _weatherService.getWeatherIcon(day.weatherCode, 0),
                                              width: 40,
                                              height: 40,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${_weatherData!.getTemp(day.maxTemp, _unit).toStringAsFixed(0)}°',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                            Text(
                                              '${_weatherData!.getTemp(day.minTemp, _unit).toStringAsFixed(0)}°',
                                              style: TextStyle(color: Colors.grey[400], fontSize: 14),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 50),
                            ],
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}