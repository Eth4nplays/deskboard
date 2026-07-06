import 'package:flutter/material.dart';
import 'dart:io';
import '../pages/home_control.dart';
import '../pages/spotifyplaylists.dart';

class NavigationButtons extends StatelessWidget {
  const NavigationButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavButton(
          icon: Icons.music_note,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => MouseRegion(
                      cursor: SystemMouseCursors.none,
                      child: SpotifyPlaylistsPage(),
                    ),
              ),
            );
          },
        ),
        const SizedBox(width: 18),
        _NavButton(
          icon: Icons.home,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HomeControlPage()),
            );
          },
        ),
        const SizedBox(width: 18),
        _NavButton(
          icon: Icons.display_settings_outlined,
          onPressed: () {
            openChromiumStream();
          },
        ),
        const SizedBox(width: 18),
        _NavButton(
          icon: Icons.settings_outlined,
          onPressed: () => _showSettingsMenu(context),
        ),
      ],
    );
  }

  void _showSettingsMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);

    final selected = await showMenu<int>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + button.size.height,
        offset.dx + button.size.width,
        offset.dy,
      ),
      items: [
        PopupMenuItem(
          value: 1,
          child: Row(
            children: const [
              Icon(Icons.desktop_windows, size: 25),
              SizedBox(width: 8),
              Text('Desktop Mode'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: const [
              Icon(Icons.brightness_medium, size: 25),
              SizedBox(width: 8),
              Text('Adjust Brightness'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 3,
          child: Row(
            children: const [
              Icon(Icons.power_settings_new, size: 25),
              SizedBox(width: 8),
              Text('Power'),
            ],
          ),
        ),
        const PopupMenuItem(value: 4, child: Text('Cancel')),
      ],
    );

    switch (selected) {
      case 1:
        exit(0);
      case 2:
        if (context.mounted) {
          _showBrightnessControls(context);
        }
        break;
      case 3:
        if (context.mounted) {
          _shutdown(context);
        }
        break;
      case 4:
        // Cancel
        break;
    }
  }

  void _showBrightnessControls(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        double brightness = 255; // default value

        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: 260,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Adjust Brightness',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.dark_mode, size: 40),
                        onPressed: () {
                          setState(() => brightness = 20);
                          _setBrightnessValue(20);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.light_mode, size: 40),
                        onPressed: () {
                          setState(() => brightness = 255);
                          _setBrightnessValue(255);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Slider
                  Slider(
                    min: 20,
                    max: 255,
                    divisions: 235,
                    value: brightness,
                    label: brightness.round().toString(),
                    onChanged: (value) {
                      setState(() => brightness = value);
                      _setBrightnessValue(value.round());
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _setBrightnessValue(int value) async {
    if (!Platform.isLinux) {
      return;
    }

    try {
      final command = 'echo $value > /sys/class/backlight/10-0045/brightness';

      final result = await Process.run('bash', ['-c', command]);

      if (result.exitCode != 0) {}
    } catch (e) {
      SnackBar(content: Text('Failed to set brightness: $e'));
    }
  }
Future<void> openChromiumStream() async {
  const url = "http://127.0.0.1:8080/stream?token=umapyoi";

  await Process.run(
    "bash",
    [
      "-c",
      "chromium --kiosk --start-fullscreen --app=$url"
    ],
  );
}
  void _shutdown(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: 260,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Power Options',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.power_settings_new, size: 40),
                        onPressed: () async {
                          if (!Platform.isLinux) {
                            return;
                          }

                          try {
                            final command = 'shutdown now';

                            final result = await Process.run('bash', [
                              '-c',
                              command,
                            ]);

                            if (result.exitCode != 0) {}
                          } catch (e) {
                            SnackBar(content: Text('Failed to shutdown: $e'));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _NavButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(onPressed: onPressed, icon: Icon(icon), iconSize: 28);
  }
}
