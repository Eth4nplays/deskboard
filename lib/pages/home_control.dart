import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeAssistantPage extends StatefulWidget {
  const HomeAssistantPage({super.key});

  @override
  State<HomeAssistantPage> createState() => _HomeAssistantPageState();
}

class _HomeAssistantPageState extends State<HomeAssistantPage> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            debugPrint("Loaded: $url");
          },
        ),
      )
      ..loadRequest(
        Uri.parse('http://192.168.1.129:8123/home/areas-bedroom'),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Control'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.reload(),
          ),
        ],
      ),
      body: SafeArea(
        child: WebViewWidget(controller: controller),
      ),
    );
  }
}