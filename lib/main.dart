import 'package:flutter/foundation.dart';
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

TextTheme poppinsWithFallback(TextTheme base) {
  if(kIsWeb){
    return base;
  }
  return GoogleFonts.poppinsTextTheme(base).apply(
    fontFamilyFallback: const [
      'Noto Sans CJK SC',
      'Noto Sans JP',
      'Noto Sans TC',
    ],
  );
}


class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = Theme.of(context).textTheme;

    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        textTheme: poppinsWithFallback(baseTextTheme),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          brightness: Brightness.dark,
        ),
        textTheme: poppinsWithFallback(ThemeData.dark().textTheme),
      ),
      themeMode: ThemeMode.dark,
      home: MouseRegion(
        cursor: SystemMouseCursors.none,
        child: const HomePage(),
      ),
    );
  }
}
