import 'dart:io';

/// Platform implementation for platforms with dart:io support.
bool isNativeNetworkError(Object error) {
  return error is SocketException ||
      error is HttpException ||
      error is HandshakeException ||
      error is TlsException;
}
