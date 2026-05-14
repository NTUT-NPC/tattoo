import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class WebviewSheet extends StatefulWidget {
  const WebviewSheet({
    super.key,
    required this.url,
    this.redirectAfterFirstLoad,
    this.initialToastMessage,
    this.closeOnNtutLoggedOut = false,
  });

  final Uri url;
  final Uri? redirectAfterFirstLoad;
  final String? initialToastMessage;
  final bool closeOnNtutLoggedOut;

  static Future<T?> show<T>(
    BuildContext context,
    Uri url, {
    Uri? redirectAfterFirstLoad,
    String? initialToastMessage,
    bool closeOnNtutLoggedOut = false,
  }) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => WebviewSheet(
          url: url,
          redirectAfterFirstLoad: redirectAfterFirstLoad,
          initialToastMessage: initialToastMessage,
          closeOnNtutLoggedOut: closeOnNtutLoggedOut,
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
  bool _didCloseForNtutLoggedOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final message = widget.initialToastMessage;
      if (message == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: .floating,
          ),
        );
    });

    _controller = WebViewController()
      ..setJavaScriptMode(.unrestricted)
      ..addJavaScriptChannel(
        'TattooWebview',
        onMessageReceived: (message) {
          if (message.message == 'ntut-logged-out') {
            _closeForNtutLoggedOut();
          }
        },
      )
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
            if (redirectUrl != null && !_didRedirectAfterFirstLoad) {
              _didRedirectAfterFirstLoad = true;
              await _controller.loadRequest(redirectUrl);
              return;
            }

            await _installNtutLoggedOutDetector();
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

  void _closeForNtutLoggedOut() {
    if (!mounted || !widget.closeOnNtutLoggedOut || _didCloseForNtutLoggedOut) {
      return;
    }
    _didCloseForNtutLoggedOut = true;
    Navigator.of(context).pop();
  }

  Future<void> _installNtutLoggedOutDetector() async {
    if (!widget.closeOnNtutLoggedOut) return;
    try {
      await _controller.runJavaScript(r'''
(function () {
  function notifyIfLoggedOut() {
    var text = document.body ? (document.body.innerText || document.body.textContent || '') : '';
    if (text.indexOf('您尚未登入') !== -1) {
      TattooWebview.postMessage('ntut-logged-out');
    }
  }

  notifyIfLoggedOut();

  if (window.__tattooNtutLoggedOutObserverInstalled) {
    return;
  }
  window.__tattooNtutLoggedOutObserverInstalled = true;

  function observeBody() {
    if (!document.body) {
      return;
    }
    var observer = new MutationObserver(notifyIfLoggedOut);
    observer.observe(document.body, {
      childList: true,
      subtree: true,
      characterData: true
    });
  }

  if (document.body) {
    observeBody();
  } else {
    document.addEventListener('DOMContentLoaded', observeBody, { once: true });
  }
})();
''');
    } catch (_) {}
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
                      child: TextButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('登出'),
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
