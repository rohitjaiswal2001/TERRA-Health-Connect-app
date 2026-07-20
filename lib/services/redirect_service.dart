import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';

/// Sends the member out of the app: back to the website when the sync is done,
/// or into the App Store / funnel when appropriate.
class RedirectService {
  const RedirectService();

  /// Return the member to the website. Uses [redirectUrl] supplied by the deep
  /// link when present, otherwise the configured site.
  Future<bool> returnToWebsite({String? redirectUrl}) {
    final target = (redirectUrl != null && redirectUrl.isNotEmpty)
        ? redirectUrl
        : AppConfig.websiteUrl;
    return _open(target);
  }

  /// Open the public funnel (used by the "not a member" screen).
  Future<bool> openFunnel() => _open(AppConfig.websiteUrl);

  /// Open the App Store listing.
  Future<bool> openAppStore() => _open(AppConfig.appStoreUrl);

  Future<bool> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('RedirectService: failed to open $url — $e');
      return false;
    }
  }
}
