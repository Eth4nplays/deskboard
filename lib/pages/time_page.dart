import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/spotify_service.dart';
import '../widgets/lyrics.dart';
import 'home_page.dart';

class FullScreenClockPage extends StatefulWidget {
  const FullScreenClockPage({super.key});

  @override
  State<FullScreenClockPage> createState() => _FullScreenClockPageState();
}

class _FullScreenClockPageState extends State<FullScreenClockPage> {
  late Timer _clockTimer;
  late DateTime _currentTime;
  Timer? _positionTimer;
  Timer? _spotifyTimer;
  Map<String, dynamic>? _currentTrack;

  String _spotifyTitle = 'Not Playing';
  String _spotifyArtist = 'No Artist';
  Duration _spotifyPosition = Duration.zero;
  bool _spotifyIsPlaying = false;
  DateTime? _lastSyncTime;
  bool _hasLyrics = false;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      // Higher frequency for smoother lyrics
      if (_spotifyIsPlaying && _lastSyncTime != null) {
        setState(() {
          final additionalDelta =
              DateTime.now().difference(_lastSyncTime!).inMilliseconds;
          // Current position = The base progress from Spotify + time passed since sync
          _spotifyPosition = Duration(
            milliseconds: (_currentTrack?['progressMs'] ?? 0) + additionalDelta,
          );
        });
      }
    });
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
      final startTime = DateTime.now();
      final track = await spotify.getCurrentTrack();
      final RTT = DateTime.now().difference(startTime).inMilliseconds;
      if (!mounted) return;
      setState(() {
        _currentTrack = track;
        _lastSyncTime = DateTime.now();
        _spotifyTitle = track['title'] ?? 'Not Playing';
        _spotifyArtist = track['artist'] ?? 'No Artist';
        int baseProgress = track['progressMs'] ?? 0;
        _spotifyPosition = Duration(milliseconds: baseProgress + (RTT ~/ 2));
        _spotifyIsPlaying = track['isPlaying'] ?? false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _currentTrack = null;
        _spotifyTitle = 'Not Playing';
        _spotifyArtist = 'No Artist';
        _spotifyPosition = Duration.zero;
        _spotifyIsPlaying = false;
      });
    }
  }

  /// Navigate back to HomePage immediately on any activity
  void _goToHomePage() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => MouseRegion(
              cursor: SystemMouseCursors.none,
              child: const HomePage(),
            ),
      ),
    );
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _spotifyTimer?.cancel();
    _positionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('hh:mm').format(_currentTime);
    final amPm = DateFormat('a').format(_currentTime);
    final day = DateFormat('EEEE').format(_currentTime);
    final date = DateFormat('dd/MM/yyyy').format(_currentTime);

    final showLyrics = _spotifyIsPlaying && _hasLyrics;
    final clockFontSize = showLyrics ? 75.0 : 95.0;
    final amPmFontSize = showLyrics ? 35.0 : 45.0;
    final dayDateFontSize = showLyrics ? 22.0 : 28.0;

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
              // 3:1 Layout Split for Clock and Lyrics
              Row(
                children: [
                  // Clock display takes 3 parts of the space
                  Expanded(
                    flex: showLyrics ? 8 : 100,
                    child: Center(
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: clockFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                amPm,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: amPmFontSize,
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: dayDateFontSize,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                date,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: dayDateFontSize,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Lyrics display takes 1 part of the space
                  if (_currentTrack != null &&
                      _currentTrack!['isPlaying'] == true)
                    Expanded(
                      flex: showLyrics ? 4 : 0,
                      child: SpotifyLyrics(
                        artist: _spotifyArtist,
                        title: _spotifyTitle,
                        currentPosition: _spotifyPosition,
                        onLyricsStatusChanged: (bool found) {
                          if (_hasLyrics != found) {
                            setState(() => _hasLyrics = found);
                          }
                        },
                      ),
                    )
                  // Keeps the clock perfectly aligned if no song is playing
                  else
                    const Expanded(flex: 1, child: SizedBox.shrink()),
                ],
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
                          color: Colors.grey[900]?.withValues(alpha: 0.8),
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
