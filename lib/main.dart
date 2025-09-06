import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'services/spotify_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final spotify = SpotifyService();
  await spotify.init(); // initialize once

  runApp(
    Provider<SpotifyService>.value(value: spotify, child: const MainApp()),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      themeMode: ThemeMode.dark,
      home: MouseRegion(
        cursor: SystemMouseCursors.none,
        child: const HomePage(), // no need to pass spotify
      ),
    );
  }
}
