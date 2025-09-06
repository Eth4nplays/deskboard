import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/spotify_service.dart';
import 'home_page.dart';

class FullScreenClockPage extends StatefulWidget {
  const FullScreenClockPage({super.key});

  @override
  State<FullScreenClockPage> createState() => _FullScreenClockPageState();
}

class _FullScreenClockPageState extends State<FullScreenClockPage> {
  late Timer _clockTimer;
  late DateTime _currentTime;

  Timer? _spotifyTimer;
  Map<String, dynamic>? _currentTrack;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();

    // Clock updates every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _currentTime = DateTime.now());
    });

    // Spotify updates every 5 seconds
    _spotifyTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadCurrentTrack();
    });

    // Initial load
    _loadCurrentTrack();
  }

  SpotifyService get spotify =>
      Provider.of<SpotifyService>(context, listen: false);

  /// Load current track safely
  Future<void> _loadCurrentTrack() async {
    try {
      final track = await spotify.getCurrentTrack();
      if (!mounted) return;
      setState(() => _currentTrack = track);
    } catch (_) {
      if (!mounted) return;
      setState(() => _currentTrack = null);
    }
  }

  /// Navigate back to HomePage immediately on any activity
  void _goToHomePage() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _spotifyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('hh:mm').format(_currentTime);
    final amPm = DateFormat('a').format(_currentTime);
    final day = DateFormat('EEEE').format(_currentTime);
    final date = DateFormat('MM/dd/yyyy').format(_currentTime);

    return MouseRegion(
      onHover: (_) => _goToHomePage(), // instant on hover
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _goToHomePage(), // instant on click
        onPointerMove: (_) => _goToHomePage(), // instant on drag
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // Clock display
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$time ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          amPm,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          date,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Spotify widget at bottom if a song is playing
              if (_currentTrack != null && _currentTrack!['isPlaying'] == true)
                Positioned(
                  bottom: 32,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[900]?.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            if (_currentTrack!['albumArt'] != null)
                              Image.network(
                                _currentTrack!['albumArt'],
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentTrack!['title'] != null
                                      ? (_currentTrack!['title'].length > 35
                                          ? '${_currentTrack!['title'].substring(0, 35)}…'
                                          : _currentTrack!['title'])
                                      : 'Unknown',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _currentTrack!['artist'] != null
                                      ? (_currentTrack!['artist'].length > 35
                                          ? '${_currentTrack!['artist'].substring(0, 35)}…'
                                          : _currentTrack!['artist'])
                                      : '',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
