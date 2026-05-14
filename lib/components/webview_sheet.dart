import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class WebviewSheet extends StatefulWidget {
  const WebviewSheet({
    super.key,
    required this.url,
    this.redirectAfterFirstLoad,
  });

  final Uri url;
  final Uri? redirectAfterFirstLoad;

  static Future<T?> show<T>(
    BuildContext context,
    Uri url, {
    Uri? redirectAfterFirstLoad,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => WebviewSheet(
          url: url,
          redirectAfterFirstLoad: redirectAfterFirstLoad,
        ),
      ),
    );
  }

  @override
  State<WebviewSheet> createState() => _WebviewSheetState();
}

class _WebviewSheetState extends State<WebviewSheet> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _didRedirectAfterFirstLoad = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (!mounted) return;
            setState(() {
              _progress = progress / 100.0;
            });
          },
          onPageFinished: (String url) async {
            try {
              await _controller.runJavaScript(
                "var style = document.createElement('style'); style.innerHTML = '::-webkit-scrollbar { display: none; }'; document.head.appendChild(style);",
              );
            } catch (_) {}

            final redirectUrl = widget.redirectAfterFirstLoad;
            if (redirectUrl == null || _didRedirectAfterFirstLoad) return;

            _didRedirectAfterFirstLoad = true;
            await _controller.loadRequest(redirectUrl);
          },
        ),
      )
      ..setOnConsoleMessage((message) {})
      ..setOnJavaScriptAlertDialog((request) async {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(request.message),
              behavior: .floating,
            ),
          );
          if (request.message.contains('登入失敗：取得的字串為空白或null') ||
              request.message.contains('登入失敗：找不到使用者')) {
            Navigator.of(context).pop();
          }
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canGoBack = await _controller.canGoBack();
        if (canGoBack) {
          await _controller.goBack();
        } else if (context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
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
      ),
    );
  }
}
