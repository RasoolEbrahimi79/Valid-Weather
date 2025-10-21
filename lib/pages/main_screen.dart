import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:valid_weather/models/city_suggestion.dart';
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
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
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
                                  _errorText = null;
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
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Current Temperature Here',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Weather Condition Here',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Max Temp  | Min Temp',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Humidity % | Wind Speed',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 150,
                alignment: Alignment.bottomCenter,
                child: Text(
                        'SVG Here',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
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