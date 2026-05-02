import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/spotify_service.dart';
import '../widgets/spotify_player.dart';

class SpotifyPlaylistsPage extends StatefulWidget {
  const SpotifyPlaylistsPage({super.key});

  @override
  State<SpotifyPlaylistsPage> createState() => _SpotifyPlaylistsPageState();
}

class _SpotifyPlaylistsPageState extends State<SpotifyPlaylistsPage> {
  List<Map<String, dynamic>> playlists = [];
  List<Map<String, dynamic>> queue = [];
  bool loadingPlaylists = true;
  bool loadingQueue = true;
  bool shuffle = false;
  String repeat = 'off'; // 'track', 'context', 'off'

  late final SpotifyService spotify;
  Timer? _queueTimer;

  @override
  void initState() {
    super.initState();
    spotify = Provider.of<SpotifyService>(context, listen: false);
    _loadPlaylists();
    _loadQueuePeriodically();
  }

  Future<void> _loadPlaylists() async {
    final data = await spotify.getUserPlaylists();
    if (!mounted) return;
    setState(() {
      playlists = data;
      loadingPlaylists = false;
    });
  }

  Future<void> _loadQueue() async {
    final data = await spotify.getQueue();
    if (!mounted) return;
    setState(() {
      queue = data;
      loadingQueue = false;
    });
  }

  void _loadQueuePeriodically() {
    _loadQueue();
    _queueTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadQueue(),
    );
  }

  void _showQueueBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        if (loadingQueue || queue.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return SizedBox(
          height: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  'Up Next',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: queue.length,
                  itemBuilder: (context, index) {
                    final track = queue[index];
                    return ListTile(
                      leading:
                          track['albumArt'] != null
                              ? Image.network(
                                track['albumArt'],
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              )
                              : const Icon(
                                Icons.music_note,
                                color: Colors.white,
                              ),
                      title: Text(
                        track['title'],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        track['artist'],
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _queueTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spotify')),
      body: Stack(
        children: [
          // Scrollable playlists
          Padding(
            padding: const EdgeInsets.only(
              bottom: 120,
            ), // leave space for player
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shuffle & Repeat
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          shuffle ? Icons.shuffle_on : Icons.shuffle,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () async {
                          setState(() => shuffle = !shuffle);
                          await spotify.toggleShuffle(shuffle);
                        },
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          repeat == 'off'
                              ? Icons.repeat
                              : repeat == 'track'
                              ? Icons.repeat_one
                              : Icons.repeat,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () async {
                          String nextRepeat;
                          if (repeat == 'off') {
                            nextRepeat = 'context';
                          } else if (repeat == 'context') {
                            nextRepeat = 'track';
                          } else {
                            nextRepeat = 'off';
                          }
                          setState(() => repeat = nextRepeat);
                          await spotify.setRepeat(nextRepeat);
                        },
                      ),
                      SizedBox(width: 16),
                      // Queue button
                      IconButton(
                        icon: Icon(
                          Icons.queue_music,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: _showQueueBottomSheet,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Playlists
                  loadingPlaylists
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Playlists',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...playlists.map(
                            (playlist) => ListTile(
                              leading:
                                  playlist['image'] != null
                                      ? Image.network(
                                        playlist['image'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      )
                                      : const Icon(Icons.music_note),
                              title: Text(
                                playlist['name'],
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              subtitle: Text(
                                'by ${playlist['owner']}',
                                style: TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              onTap: () async {
                                await spotify.playPlaylist(playlist['id']);
                                await _loadQueue();
                              },
                            ),
                          ),
                        ],
                      ),
                ],
              ),
            ),
          ),

          // Sticky Spotify player at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(12),
              child: SpotifyPlayer(spotify: spotify),
            ),
          ),
        ],
      ),
    );
  }
}
