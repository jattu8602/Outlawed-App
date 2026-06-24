import 'package:app_links/app_links.dart';
import 'auth_service.dart';

class DeepLinkService {
  final AuthService _authService;
  final AppLinks _appLinks = AppLinks();
  bool _initialized = false;

  DeepLinkService(this._authService);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _processUri(initialUri);
    }

    _appLinks.uriLinkStream.listen(_processUri);
  }

  void _processUri(Uri uri) {
    if (uri.host == 'www.outlawed.in' || uri.host == 'outlawed.in') {
      final ref = uri.queryParameters['ref'];
      if (ref != null && ref.isNotEmpty) {
        _authService.setReferralCode(ref);
      }
    }
  }
}
