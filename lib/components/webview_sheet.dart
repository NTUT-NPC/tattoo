import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class WebviewSheet extends StatefulWidget {
  const WebviewSheet({super.key, required this.url});

  final Uri url;

  static void show(BuildContext context, Uri url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => WebviewSheet(url: url),
      ),
    );
  }

  @override
  State<WebviewSheet> createState() => _WebviewSheetState();
}

class _WebviewSheetState extends State<WebviewSheet> {
  late final WebViewController _controller;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100.0;
            });
          },
          onPageFinished: (String url) {
            _controller.runJavaScript(
              "var style = document.createElement('style'); style.innerHTML = '::-webkit-scrollbar { display: none; }'; document.head.appendChild(style);",
            );
          },
        ),
      )
      ..setOnConsoleMessage((message) {})
      ..setOnJavaScriptAlertDialog((request) async {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(request.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      })
      ..loadRequest(widget.url);

    if (_controller.platform is AndroidWebViewController) {
      final androidController =
          _controller.platform as AndroidWebViewController;
      androidController.setVerticalScrollBarEnabled(false);
      androidController.setHorizontalScrollBarEnabled(false);
      androidController.setUseWideViewPort(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            SizedBox(
              height: 48,
              child: Stack(
                children: [
                  if (_progress < 1.0)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 2,
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
            // Webview
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}
