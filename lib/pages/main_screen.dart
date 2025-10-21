import 'package:flutter/material.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Valid Weather'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Material 3 spacing: 16dp
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Section: City Name TextField
              TextField(
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
                ),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              // Center Section: Weather Data
              Expanded(
                child: Center(
                  child: Column(
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
                        'Humidity: 60% | Wind: 10 km/h', // Placeholder for additional info
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom Section: Weather SVG Placeholder
              Container(
                height: 150, // Fixed height for SVG
                alignment: Alignment.bottomCenter,
                child: Icon(
                  Icons.wb_sunny, // Placeholder for weather SVG
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