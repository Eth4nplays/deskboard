import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../models/weather.dart';
import 'dart:async';

class WeatherDisplay extends StatefulWidget {
  const WeatherDisplay({super.key});

  @override
  State<WeatherDisplay> createState() => _WeatherDisplayState();
}

class _WeatherDisplayState extends State<WeatherDisplay> {
  final _weatherService = WeatherService();
  Weather? _weather;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _timer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _fetchWeather(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  IconData _getWeatherIcon(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('sun') || c.contains('clear')) {
      return Icons.wb_sunny_outlined;
    }
    if (c.contains('cloud')) return Icons.cloud_outlined;
    if (c.contains('rain')) return Icons.grain;
    if (c.contains('thunder')) return Icons.thunderstorm_outlined;
    return Icons.wb_cloudy_outlined;
  }

  Future<void> _fetchWeather() async {
    try {
      final weather = await _weatherService.getWeather();
      if (mounted) setState(() => _weather = weather);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_weather == null) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _getWeatherIcon(_weather!.condition),
          size: 48,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _weather!.condition,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            Row(
              children: [
                Text(
                  '${_weather!.temperature.round()}°C',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${_weather!.location}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
