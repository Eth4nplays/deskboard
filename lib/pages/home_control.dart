import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class HomeControlPage extends StatelessWidget {
  const HomeControlPage({super.key});

  Future<void> _triggerScene(String webhookId) async {
    final url = Uri.parse('http://192.168.1.129:8123/api/webhook/$webhookId');
    try {
      await http.post(url);
    } catch (e) {
      debugPrint('Webhook failed: $e');
    }
  }

  void _setPiBrightness(int value) async {
    if (Platform.isLinux) {
      try {
        await Process.run('bash', [
          '-c',
          'echo $value > /sys/class/backlight/10-0045/brightness',
        ]);
      } catch (e) {
        debugPrint('Brightness error: $e');
      }
    }
  }

  void _launchFullWeb() async {
    await Process.start('chromium', [
      '--start-maximized',
      '--app=http://192.168.1.129:8123/dashboard-home/0',
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Control'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _CompactSceneTile(
                    label: 'Good Night',
                    icon: Icons.bedtime_outlined,
                    activeColor: Colors.indigoAccent,
                    onPressed: () {
                      _triggerScene('good_night_webhook');
                      _setPiBrightness(20);
                    },
                  ),
                  const SizedBox(height: 8),
                  _CompactSceneTile(
                    label: 'Casual',
                    icon: Icons.wb_sunny_outlined,
                    activeColor: Colors.orangeAccent,
                    onPressed: () {
                      _triggerScene('casual_lighting_webhook');
                      _setPiBrightness(255);
                    },
                  ),
                  const SizedBox(height: 8),
                  _CompactSceneTile(
                    label: 'Study',
                    icon: Icons.auto_stories_outlined,
                    activeColor: Colors.blueAccent,
                    onPressed: () {
                      _triggerScene('study_mode_webhook');
                      _setPiBrightness(150);
                    },
                  ),
                  const SizedBox(height: 8),
                  _CompactSceneTile(
                    label: 'All Off',
                    icon: Icons.power_settings_new,
                    activeColor: Colors.redAccent,
                    onPressed: () => _triggerScene('all_off_webhook'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Outlined "Open Web" Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              onPressed: _launchFullWeb,
              icon: Icon(
                Icons.open_in_browser,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                'Launch Home Assistant UI',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _CompactSceneTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color activeColor;
  final VoidCallback onPressed;

  const _CompactSceneTile({
    required this.label,
    required this.icon,
    required this.activeColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: activeColor),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }
}
