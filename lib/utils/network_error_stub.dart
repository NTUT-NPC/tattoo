/// Fallback for platforms where dart:io is unavailable (e.g. Flutter web).
bool isNativeNetworkError(Object error) => false;
