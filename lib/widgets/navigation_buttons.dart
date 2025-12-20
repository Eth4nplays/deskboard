import 'package:flutter/material.dart';
import 'dart:io';
import '../pages/spotifyplaylists.dart';

class NavigationButtons extends StatelessWidget {
  const NavigationButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavButton(icon: Icons.keyboard, onPressed: () => _executeONBOARD()),
        const SizedBox(width: 18),
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
          icon: Icons.settings_outlined,
          onPressed: () => _showSettingsMenu(context),
        ),
        const SizedBox(width: 18),
    _NavButton(
      icon: Icons.home, // Google Home icon (closest Material Icon)
      onPressed: () => _openGoogleHome(), // New function
    ),
      ],
    );
  }

  void _openGoogleHome() async {
    try {
      final result = await Process.run('bash', [
        '-c',
        'google-chrome --app=https://home.google.com/home/1-bdf6cb9325fe370b3f235819a2a73c5c6bb93224111176defe631af9c6a60aa8/automations'
      ]);

      if (result.exitCode != 0) {
        print('Error opening Google Home: ${result.stderr}');
      }
    } catch (e) {
      print('Error executing Google Home command: $e');
    }
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
              Icon(Icons.desktop_windows, size: 20),
              SizedBox(width: 8),
              Text('Desktop Mode'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          child: Row(
            children: const [
              Icon(Icons.brightness_medium, size: 20),
              SizedBox(width: 8),
              Text('Adjust Brightness'),
            ],
          ),
        ),
        const PopupMenuItem(value: 3, child: Text('Cancel')),
      ],
    );

    switch (selected) {
      case 1:
        exit(0);
      case 2:
        _showBrightnessControls(context);
        break;
      case 3:
        // Cancel
        break;
    }
  }

  void _executeONBOARD() async {
    try {
      ProcessResult result;

      if (Platform.isWindows) {
        // Use cmd for Windows
        result = await Process.run('cmd', [
          '/c',
          'echo onboard will open in linux build',
        ]);
      } else {
        // Use bash for Linux/macOS
        result = await Process.run('bash', ['-c', 'onboard']);
      }

      print('ONBOARD Command output: ${result.stdout}');
      print('ONBOARD Command error: ${result.stderr}');
      print('Exit code: ${result.exitCode}');
    } catch (e) {
      print('Error executing AC command: $e');
    }
  }

  void _showBrightnessControls(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Adjust Brightness',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.dark_mode, size: 32),
                        onPressed: () => _setBrightness('night'),
                      ),
    
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.light_mode, size: 32),
                        onPressed: () => _setBrightness('day'),
                      ),
   
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _setBrightness(String mode) async {
    if (!Platform.isLinux) {
      print('Brightness control is only supported on Linux');
      return;
    }

    try {
      final String command = mode == 'night'
          ? 'echo 26 > /sys/class/backlight/10-0045/brightness'
          : 'echo 255 > /sys/class/backlight/10-0045/brightness';

      final result = await Process.run('bash', ['-c', command]);
      
      if (result.exitCode != 0) {
        print('Error setting brightness: ${result.stderr}');
      }
    } catch (e) {
      print('Error executing brightness command: $e');
    }
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
