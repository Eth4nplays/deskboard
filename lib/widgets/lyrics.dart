import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class LyricLine {
  final Duration time;
  final String text;

  LyricLine(this.time, this.text);
}

class SpotifyLyrics extends StatefulWidget {
  final String artist;
  final String title;
  final Duration currentPosition;
  final Function(bool hasLyrics) onLyricsStatusChanged;

  const SpotifyLyrics({
    super.key,
    required this.artist,
    required this.title,
    required this.currentPosition,
    required this.onLyricsStatusChanged,
  });

  @override
  State<SpotifyLyrics> createState() => _SpotifyLyricsState();
}

class _SpotifyLyricsState extends State<SpotifyLyrics> {
  List<LyricLine> _lyrics = [];
  bool _isLoading = false;

  final ItemScrollController _itemScrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  @override
  void didUpdateWidget(SpotifyLyrics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title || oldWidget.artist != widget.artist) {
      _fetchLyrics();
    }
    if (oldWidget.currentPosition != widget.currentPosition) {
      _scrollToCurrentLyric();
    }
  }

  Future<void> _fetchLyrics() async {
    setState(() {
      _isLoading = true;
      _lyrics = [];
    });
    try {
      final url = Uri.parse(
        'https://lrclib.net/api/get?artist_name=${Uri.encodeComponent(widget.artist)}&track_name=${Uri.encodeComponent(widget.title)}',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String syncedLyrics = data['syncedLyrics'] ?? "";

        RegExp regExp = RegExp(r"\[(\d+):(\d+\.\d+)\](.*)");
        final syncedMatches = regExp.allMatches(syncedLyrics);

        _lyrics =
            syncedMatches.map((m) {
              final min = m.group(1)!;
              final sec = m.group(2)!;
              final time = Duration(
                milliseconds:
                    (int.parse(min) * 60 * 1000 + double.parse(sec) * 1000)
                        .toInt(),
              );
              return LyricLine(time, m.group(3)!.trim());
            }).toList();
      }
    } catch (e) {
      _lyrics = [];
    }
    if (mounted) {
      setState(() => _isLoading = false);
      widget.onLyricsStatusChanged(_lyrics.isNotEmpty);
    }
  }

  int _getCurrentIndex() {
    if (_lyrics.isEmpty) return -1;
    for (int i = 0; i < _lyrics.length; i++) {
      if (_lyrics[i].time > widget.currentPosition) {
        return i == 0 ? 0 : i - 1;
      }
    }
    return _lyrics.length - 1;
  }

  void _scrollToCurrentLyric() {
    int index = _getCurrentIndex();
    if (index >= 0 && _itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        alignment: 0.5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Column(children: []);
    }
    if (_lyrics.isEmpty) {
      return const Column(children: []);
    }

    final currentIndex = _getCurrentIndex();

    return ScrollablePositionedList.builder(
      itemCount: _lyrics.length,
      itemScrollController: _itemScrollController,
      padding: EdgeInsets.symmetric(
        vertical: MediaQuery.of(context).size.height * 0.4,
      ),
      itemBuilder: (context, i) {
        final lyric = _lyrics[i];

        double opacity = 0.0;
        if (i == currentIndex) {
          opacity = 1.0;
        } else if ((i - currentIndex).abs() == 1) {
          opacity = 0.4;
        }

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Text(
              lyric.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                // Subtle shadow for better legibility against album art
                shadows: [
                  if (i == currentIndex)
                    const Shadow(blurRadius: 10, color: Colors.black45),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
