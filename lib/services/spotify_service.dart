import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../secrets.dart';

class SpotifyService {
  static const String clientId = clientIdS;
  static const String clientSecret = clientSecretS;
  static const String redirectUri = "http://127.0.0.1:8580/callback";
  static const String scopes =
      "user-read-playback-state user-modify-playback-state user-read-currently-playing";

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiryTime;

  /// Initialize from saved prefs
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString("spotify_access_token");
    _refreshToken = prefs.getString("spotify_refresh_token");
    final expiryMillis = prefs.getInt("spotify_expiry");
    if (expiryMillis != null) {
      _expiryTime = DateTime.fromMillisecondsSinceEpoch(expiryMillis);
    }

    if (_accessToken != null && _expiryTime != null) {
      if (DateTime.now().isAfter(_expiryTime!)) {
        await refreshAccessToken();
      }
    }
  }

  /// Start Spotify OAuth login
  Future<void> authenticate() async {
    if (_accessToken != null &&
        _expiryTime != null &&
        DateTime.now().isBefore(_expiryTime!)) {
      return;
    }

    final authUrl =
        "https://accounts.spotify.com/authorize?client_id=$clientId"
        "&response_type=code"
        "&redirect_uri=$redirectUri"
        "&scope=$scopes";

    // Start local server to catch the redirect
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8580);

    // Open browser
    final uri = Uri.parse(authUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $uri');
    }

    // Wait for Spotify redirect
    final request = await server.first;
    final code = request.uri.queryParameters['code'];

    request.response
      ..statusCode = 200
      ..headers.set('Content-Type', 'text/html')
      ..write(
        '''<html><head><title>Spotify Login</title><script type="text/javascript">setTimeout(() => window.close(), 1000);</script></head></body></html>''',
      )
      ..close();

    await server.close();

    if (code == null) {
      throw Exception("No code received from Spotify");
    }

    await _requestTokens(code);
  }

  // Exchange code for tokens
  Future<void> _requestTokens(String code) async {
    final url = Uri.parse("https://accounts.spotify.com/api/token");
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization':
            'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to request tokens: ${response.body}");
    }

    final data = jsonDecode(response.body);
    _saveTokens(data);
  }

  // Refresh access token
  Future<void> refreshAccessToken() async {
  if (_refreshToken == null) {
    await authenticate();
    return;
  }

  final url = Uri.parse("https://accounts.spotify.com/api/token");
  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Authorization':
          'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
    },
    body: {
      'grant_type': 'refresh_token',
      'refresh_token': _refreshToken!,
    },
  );

  if (response.statusCode != 200) {
    // Refresh token is no longer valid
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("spotify_access_token");
    await prefs.remove("spotify_refresh_token");
    await prefs.remove("spotify_expiry");

    _accessToken = null;
    _refreshToken = null;
    _expiryTime = null;

    // Ask the user to log in again
    await authenticate();
    return;
  }

  final data = jsonDecode(response.body);
  _saveTokens(data, isRefresh: true);
}

  void _saveTokens(Map<String, dynamic> data, {bool isRefresh = false}) async {
    _accessToken = data['access_token'];
    if (!isRefresh) {
      _refreshToken = data['refresh_token'];
    }
    final expiresIn = data['expires_in'] ?? 3600;
    _expiryTime = DateTime.now().add(Duration(seconds: expiresIn));

    final prefs = await SharedPreferences.getInstance();
    prefs.setString("spotify_access_token", _accessToken!);
    if (_refreshToken != null) {
      prefs.setString("spotify_refresh_token", _refreshToken!);
    }
    prefs.setInt("spotify_expiry", _expiryTime!.millisecondsSinceEpoch);
  }

  // Ensure valid access token
  Future<void> _ensureToken() async {
  try {
    if (_accessToken == null) {
      await authenticate();
    } else if (_expiryTime != null &&
        DateTime.now().isAfter(_expiryTime!)) {
      await refreshAccessToken();
    }
  } catch (e) {
    _accessToken = null;
    _refreshToken = null;
    _expiryTime = null;
    rethrow; // or handle it gracefully
  }
}

  Future<List<Map<String, dynamic>>> getDevices() async {
    await _ensureToken();
    final url = Uri.parse("https://api.spotify.com/v1/me/player/devices");
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['devices'] as List)
          .map(
            (d) => {
              'id': d['id'],
              'name': d['name'],
              'type': d['type'], 
              'isActive': d['is_active'],
            },
          )
          .toList();
    }

    return [];
  }

  Future<void> transferPlayback(String deviceId) async {
    await _ensureToken();
    final url = Uri.parse("https://api.spotify.com/v1/me/player");
    await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'device_ids': [deviceId],
        'play': true,
      }),
    );
  }

  // Resume playback
  Future<void> resume() async {
    await _ensureToken();
    final url = Uri.parse("https://api.spotify.com/v1/me/player/play");
    await http.put(url, headers: {'Authorization': 'Bearer $_accessToken'});
  }

  // Skip to next track
  Future<void> nextTrack() async {
    await _ensureToken();
    final url = Uri.parse("https://api.spotify.com/v1/me/player/next");
    await http.post(url, headers: {'Authorization': 'Bearer $_accessToken'});
  }

  // Skip to previous track
  Future<void> previousTrack() async {
    await _ensureToken();
    final url = Uri.parse("https://api.spotify.com/v1/me/player/previous");
    await http.post(url, headers: {'Authorization': 'Bearer $_accessToken'});
  }

  // Pause playback
  Future<void> pause() async {
    await _ensureToken();
    final url = Uri.parse("https://api.spotify.com/v1/me/player/pause");
    await http.put(url, headers: {'Authorization': 'Bearer $_accessToken'});
  }

  Future<List<Map<String, dynamic>>> getUserPlaylists() async {
    await _ensureToken();
    final url = Uri.parse("https://api.spotify.com/v1/me/playlists?limit=50");
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['items'] as List)
          .map(
            (item) => {
              'id': item['id'],
              'name': item['name'],
              'owner': item['owner']['display_name'],
              'image':
                  (item['images'] as List).isNotEmpty
                      ? item['images'][0]['url']
                      : null,
            },
          )
          .toList();
    }

    return [];
  }

  Future<void> playPlaylist(String playlistId) async {
    await _ensureToken();
    final url = Uri.parse("https://api.spotify.com/v1/me/player/play");
    await http.put(
      url,
      headers: {'Authorization': 'Bearer $_accessToken'},
      body: jsonEncode({'context_uri': 'spotify:playlist:$playlistId'}),
    );
  }

  // Get the current queue
  Future<List<Map<String, dynamic>>> getQueue() async {
    await _ensureToken();
    final url = Uri.parse("https://api.spotify.com/v1/me/player/queue");
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['queue'] as List)
          .map(
            (track) => {
              'title': track['name'],
              'artist': (data['item']['artists'] as List)
    .map((artist) => artist['name'])
    .join(', '),
              'albumArt':
                  (track['album']['images'] as List).isNotEmpty
                      ? track['album']['images'][0]['url']
                      : null,
            },
          )
          .toList();
    }

    return [];
  }

  // Toggle shuffle
  Future<void> toggleShuffle(bool enable) async {
    await _ensureToken();
    final url = Uri.parse(
      "https://api.spotify.com/v1/me/player/shuffle?state=$enable",
    );
    await http.put(url, headers: {'Authorization': 'Bearer $_accessToken'});
  }

  // Set repeat mode
  Future<void> setRepeat(String mode) async {
    await _ensureToken();
    final url = Uri.parse(
      "https://api.spotify.com/v1/me/player/repeat?state=$mode",
    );
    await http.put(url, headers: {'Authorization': 'Bearer $_accessToken'});
  }

  // Get currently playing track
  Future<Map<String, dynamic>> getCurrentTrack() async {
    await _ensureToken();
    final url = Uri.parse(
      "https://api.spotify.com/v1/me/player/currently-playing",
    );
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $_accessToken'},
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      final data = jsonDecode(response.body);
      return {
        'title': data['item']['name'],
        'artist': (data['item']['artists'] as List)
    .map((artist) => artist['name'])
    .join(', '),
        'isPlaying': data['is_playing'],
        'albumArt': data['item']['album']['images'][0]['url'], 
        'progressMs': data['progress_ms'] ?? 0,
        'durationMs': data['item']['duration_ms'] ?? 0,
      };
    }

    return {
      'title': 'Not Playing',
      'artist': 'No Artist',
      'isPlaying': false,
      'albumArt': null,
    };
  }
}
