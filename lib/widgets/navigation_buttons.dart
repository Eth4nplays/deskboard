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
              Icon(Icons.desktop_windows, size: 20),
              SizedBox(width: 8),
              Text('Return to Desktop'),
            ],
          ),
        ),
        const PopupMenuItem(value: 3, child: Text('Cancel')),
      ],
    );

    switch (selected) {
      case 1:
        exit(0);
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
