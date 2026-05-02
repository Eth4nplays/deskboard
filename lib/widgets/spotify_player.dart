import 'package:flutter/material.dart';

import '../services/spotify_service.dart';
import 'dart:async';

class SpotifyPlayer extends StatefulWidget {
  final SpotifyService spotify;
  final ValueChanged<Map<String, dynamic>>? onTrackUpdate;

  const SpotifyPlayer({
    super.key,
    required this.spotify,
    this.onTrackUpdate,
  });

  @override
  State<SpotifyPlayer> createState() => _SpotifyPlayerState();
}

class _SpotifyPlayerState extends State<SpotifyPlayer> {
  String songTitle = "Not Playing";
  String artistName = "No Artist";
  String? albumArtUrl;
  bool isPlaying = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadCurrentTrack();

    // poll every 5 seconds for updates
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadCurrentTrack();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _showDevicePicker() async {
    final devices = await widget.spotify.getDevices();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return ListView(
          children:
              devices.map((device) {
                return ListTile(
                  leading: Icon(
                    device['type'] == 'Smartphone'
                        ? Icons.phone_android
                        : device['type'] == 'Computer'
                        ? Icons.computer
                        : Icons.speaker,
                  ),
                  title: Text(device['name']),
                  trailing: device['isActive'] ? const Icon(Icons.check) : null,
                  onTap: () async {
                    Navigator.pop(context);
                    await widget.spotify.transferPlayback(device['id']);
                    await _loadCurrentTrack();
                  },
                );
              }).toList(),
        );
      },
    );
  }

  Future<void> _loadCurrentTrack() async {
    final track = await widget.spotify.getCurrentTrack();
    if (!mounted) return;
    setState(() {
      songTitle = track['title'];
      artistName = track['artist'];
      isPlaying = track['isPlaying'];
      albumArtUrl = track['albumArt'];
    });
    widget.onTrackUpdate?.call(track);
  }

  Future<void> _togglePlayPause() async {
    if (isPlaying) {
      await widget.spotify.pause();
    } else {
      // Play a test track or resume
      await widget.spotify.resume();
    }
    await _loadCurrentTrack();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.secondaryContainer,
        ),
        child: Row(
          children: [
            // Album art and song info
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image:
                          albumArtUrl != null
                              ? DecorationImage(
                                image: NetworkImage(albumArtUrl!),
                                fit: BoxFit.cover,
                              )
                              : null,
                      color:
                          albumArtUrl == null
                              ? Theme.of(context).colorScheme.surface
                              : null,
                    ),
                    child:
                        albumArtUrl == null
                            ? Icon(
                              Icons.music_note,
                              size: 24,
                              color: Theme.of(context).colorScheme.primary,
                            )
                            : null,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          songTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          artistName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(
                                  context,
                                ).colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.devices_rounded),
                  tooltip: "Select playback device",
                  onPressed: _showDevicePicker,
                ),

                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  onPressed: () async {
                    await widget.spotify.previousTrack();
                    await _loadCurrentTrack();
                  },
                ),
                const SizedBox(width: 4),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    color: Theme.of(context).colorScheme.onPrimary,
                    onPressed: _togglePlayPause,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: () async {
                    await widget.spotify.nextTrack();
                    await _loadCurrentTrack();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
