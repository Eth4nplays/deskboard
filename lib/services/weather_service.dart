import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';
import '../config.dart';

class WeatherService {

  Future<Weather> getWeather() async {
    try {
      final response = await http.get(
        Uri.parse('https://wttr.in/$city?format=j1'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Weather(
          condition: data['current_condition'][0]['weatherDesc'][0]['value'],
          temperature: double.parse(data['current_condition'][0]['temp_C']),
          location: city,
        );
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }
}
