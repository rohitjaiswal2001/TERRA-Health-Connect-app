import 'package:url_launcher/url_launcher.dart';

import '../core/config/app_config.dart';
import '../core/utils/app_logger.dart';

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

  /// Open this app's page in iOS Settings — where the member turns the camera
  /// back on after declining it, since iOS only ever asks once.
  Future<bool> openAppSettings() => _open('app-settings:');

  static const String _scope = 'Redirect';

  Future<bool> _open(String url) async {
    AppLog.step(_scope, 'leaving the app → $url');
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppLog.fail(_scope, 'not a valid URL: $url');
      return false;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      opened
          ? AppLog.ok(_scope, 'opened successfully')
          : AppLog.fail(_scope, 'the system refused to open it');
      return opened;
    } catch (e) {
      AppLog.fail(_scope, 'failed to open $url — $e');
      return false;
    }
  }
}
