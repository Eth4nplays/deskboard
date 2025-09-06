import 'package:flutter/material.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationButtons extends StatelessWidget {
  const NavigationButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NavButton(icon: Icons.keyboard, onPressed: () => _executeONBOARD()),
        const SizedBox(width: 18),
        _NavButton(icon: Icons.ac_unit, onPressed: () => _executeACCommand()),
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
        PopupMenuItem(
          value: 2,
          child: Row(
            children: const [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Edit AC Command'),
            ],
          ),
        ),
        const PopupMenuItem(value: 3, child: Text('Cancel')),
      ],
    );

    switch (selected) {
      case 1:
        exit(0);
        break;
      case 2:
        _editACCommand(context);
        break;
      case 3:
        // Cancel
        break;
    }
  }

  void _editACCommand(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final currentCommand = prefs.getString('ac_command') ?? '';
    final controller = TextEditingController(text: currentCommand);

    await showDialog(
      context: context,
      builder: (_) {
        final colorScheme = Theme.of(context).colorScheme;
        return AlertDialog(
          backgroundColor:
              colorScheme.surface, // optional: match dialog background
          title: Text(
            'Edit AC Command',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            style: TextStyle(
              color: colorScheme.onSurface, // text you type
            ),
            decoration: InputDecoration(
              hintText: 'Enter AC command',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant, // placeholder text
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await prefs.setString('ac_command', controller.text);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _executeACCommand() async {
    final prefs = await SharedPreferences.getInstance();
    final command = prefs.getString('ac_command');

    if (command != null && command.isNotEmpty) {
      try {
        ProcessResult result;

        if (Platform.isWindows) {
          // Use cmd for Windows
          result = await Process.run('cmd', ['/c', command]);
        } else {
          // Use bash for Linux/macOS
          result = await Process.run('bash', ['-c', command]);
        }

        print('AC Command output: ${result.stdout}');
        print('AC Command error: ${result.stderr}');
        print('Exit code: ${result.exitCode}');
      } catch (e) {
        print('Error executing AC command: $e');
      }
    } else {
      print('No AC command set.');
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
