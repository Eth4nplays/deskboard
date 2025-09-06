import 'package:flutter/material.dart';
import '../services/spotify_service.dart';
import '../widgets/clock_display.dart';
import '../widgets/weather_display.dart';
import '../widgets/navigation_buttons.dart';
import '../widgets/spotify_player.dart';
import '../widgets/to_do.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final spotify = SpotifyService();

  @override
  void initState() {
    super.initState();
    spotify.init(); // initialize your service
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ClockDisplay(),
                    const SizedBox(height: 20),
                    const WeatherDisplay(),
                    const SizedBox(height: 20),
                    const NavigationButtons(),
                    const SizedBox(height: 20),
                    SpotifyPlayer(spotify: spotify), // pass in service
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: SizedBox(
              height: double.infinity,
              child: VerticalDivider(
                color: Theme.of(context).colorScheme.onSecondary,
                thickness: 2,
                width: 2,
              ),
            ),
          ),
          const Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [const TodoList()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
