import 'dart:async';

import 'package:app_links/app_links.dart';

import '../core/utils/app_logger.dart';
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
      if (initial == null) {
        AppLog.step(_scope, 'no cold-start link (app opened directly)');
      } else {
        AppLog.ok(_scope, 'cold-start link: $initial');
        _dispatch(initial, onRequest);
      }
    } catch (e) {
      AppLog.fail(_scope, 'failed to read initial link — $e');
    }

    // Warm links while the app is running.
    _subscription = _appLinks.uriLinkStream.listen(
      (uri) => _dispatch(uri, onRequest),
      onError: (Object e) => AppLog.fail(_scope, 'stream error — $e'),
    );
  }

  static const String _scope = 'DeepLink';

  void _dispatch(Uri uri, void Function(ConnectRequest) onRequest) {
    AppLog.step(_scope, 'received $uri');
    final request = ConnectRequest.fromUri(uri);
    if (request == null) {
      AppLog.warn(_scope, 'ignored — not a valid connect link (no token?)');
      return;
    }
    onRequest(request);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
