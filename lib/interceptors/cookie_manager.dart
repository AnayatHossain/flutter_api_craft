import '../models/api_models.dart';

/// Minimal in-memory cookie jar.
/// Stores cookies per domain and injects them as a `Cookie` header.
class CookieManager {
  CookieManager._();
  static final CookieManager instance = CookieManager._();

  final Map<String, Map<String, String>> _jar = {};

  /// Store cookies received from a `Set-Cookie` header value for [domain].
  void storeCookies(String domain, String setCookieHeader) {
    _jar.putIfAbsent(domain, () => {});
    // Parse simple "name=value; ..." entries
    for (final part in setCookieHeader.split(',')) {
      final segments = part.trim().split(';');
      if (segments.isEmpty) continue;
      final nvp = segments.first.split('=');
      if (nvp.length >= 2) {
        final name = nvp[0].trim();
        final value = nvp.sublist(1).join('=').trim();
        _jar[domain]![name] = value;
      }
    }
  }

  /// Build the `Cookie` header value for [domain].
  String? buildCookieHeader(
      String domain, ApiCookies? config, Map<String, String>? extras) {
    final entries = <String, String>{};

    if (config?.enableCookieJar == true) {
      final stored = _jar[domain] ?? {};
      entries.addAll(stored);
    }

    if (extras != null) entries.addAll(extras);
    if (config?.extraCookies != null) entries.addAll(config!.extraCookies!);

    if (entries.isEmpty) return null;
    return entries.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  /// Persist cookies from response headers if not disabled.
  void handleResponseCookies(
      String domain, Map<String, String> responseHeaders, ApiCookies? config) {
    if (config?.disableCookiePersistence == true) return;
    final setCookie = responseHeaders['set-cookie'];
    if (setCookie != null) storeCookies(domain, setCookie);
  }

  void clearCookies([String? domain]) {
    if (domain != null) {
      _jar.remove(domain);
    } else {
      _jar.clear();
    }
  }
}