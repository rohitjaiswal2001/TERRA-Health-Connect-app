import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../models/connect_request.dart';

/// Listens for the deep link the website uses to launch this app and turns it
/// into a [ConnectRequest].
///
/// Handles both cold starts (app launched *by* the link) and warm links (app
/// already open when the link arrives).
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;

  /// Start listening. [onRequest] fires for every valid connect link, including
  /// the initial one that cold-started the app.
  Future<void> start(void Function(ConnectRequest request) onRequest) async {
    // Cold start: the link that launched the app (if any).
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _dispatch(initial, onRequest);
    } catch (e) {
      debugPrint('DeepLinkService: failed to read initial link — $e');
    }

    // Warm links while the app is running.
    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => _dispatch(uri, onRequest),
      onError: (Object e) => debugPrint('DeepLinkService: stream error — $e'),
    );
  }

  void _dispatch(Uri uri, void Function(ConnectRequest) onRequest) {
    debugPrint('DeepLinkService: received $uri');
    final request = ConnectRequest.fromUri(uri);
    if (request != null) onRequest(request);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
