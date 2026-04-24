import 'dart:async';
import 'package:flutter/material.dart';
import '../services/spotify_service.dart';
import '../widgets/clock_display.dart';
import '../widgets/weather_display.dart';
import '../widgets/navigation_buttons.dart';
import '../widgets/spotify_player.dart';
import '../widgets/to_do.dart';
import 'package:provider/provider.dart';
import 'time_page.dart'; // import your clock page

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final SpotifyService spotify;
  Timer? _inactivityTimer;
  
  final Duration _timeout = const Duration(seconds: 30);



  @override
  void initState() {
    super.initState();
    spotify = Provider.of<SpotifyService>(context, listen: false);
    spotify.init();
    _startInactivityTimer();

    
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_timeout, _goToClockPage);
  }

  void _goToClockPage() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => MouseRegion(
              cursor: SystemMouseCursors.none,
              child: FullScreenClockPage(),
            ),
      ),
    );
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
  
    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.none, // always hide
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _startInactivityTimer(),
        onPointerMove: (_) => _startInactivityTimer(),
        onPointerHover: (_) => _startInactivityTimer(),
        child: Scaffold(
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
                        SpotifyPlayer(
                          spotify: spotify,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: TodoList()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
