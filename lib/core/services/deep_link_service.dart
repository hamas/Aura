import 'dart:async';
import 'package:app_links/app_links.dart';
import '../../features/addons/data/datasources/stremio_addon_api.dart';
import '../../features/addons/presentation/bloc/addon_bloc.dart';
import '../../features/addons/presentation/bloc/addon_event.dart';

class DeepLinkService {
  final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  /// Extract a target manifest URL from any incoming deep link URI or string.
  static String? extractManifestUrl(Uri uri) {
    final uriString = uri.toString();

    // Check for aura://addon/install?url=...
    if (uri.scheme == 'aura' && uri.host == 'addon') {
      final targetUrl = uri.queryParameters['url'];
      if (targetUrl != null && targetUrl.isNotEmpty) {
        return StremioAddonApi.sanitizeManifestUrl(targetUrl);
      }
    }

    // Check for stremio:// scheme or https://...manifest.json
    if (uri.scheme == 'stremio' ||
        uriString.endsWith('manifest.json') ||
        uri.path.contains('manifest.json')) {
      return StremioAddonApi.sanitizeManifestUrl(uriString);
    }

    return null;
  }

  /// Start listening for incoming deep links and forward them to [AddonBloc].
  Future<void> init(AddonBloc addonBloc) async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri, addonBloc);
      }
    } catch (_) {
      // Ignored if platform fails to deliver initial link
    }

    _sub = _appLinks.uriLinkStream.listen((uri) {
      _handleUri(uri, addonBloc);
    }, onError: (_) {});
  }

  void _handleUri(Uri uri, AddonBloc addonBloc) {
    final manifestUrl = extractManifestUrl(uri);
    if (manifestUrl != null && manifestUrl.isNotEmpty) {
      addonBloc.add(InstallAddonFromUrlEvent(manifestUrl));
    }
  }

  void dispose() {
    _sub?.cancel();
  }
}
