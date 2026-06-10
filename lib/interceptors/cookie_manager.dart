import '../models/api_models.dart';

/// A minimal in-memory cookie jar shared across all [FlutterApiCraft] calls.
///
/// When [ApiCookies.enableCookieJar] is `true`, the manager:
/// - Stores `Set-Cookie` values from response headers, keyed by domain.
/// - Injects a `Cookie` header into subsequent requests to the same domain.
///
/// Cookies are stored only in memory and are lost when the app process ends.
class CookieManager {
  CookieManager._();

  /// The singleton instance.
  static final CookieManager instance = CookieManager._();

  final Map<String, Map<String, String>> _jar = {};

  /// Parses [setCookieHeader] and stores the resulting name/value pairs
  /// under [domain].
  ///
  /// Handles comma-separated multi-cookie strings as produced by some servers.
  void storeCookies(String domain, String setCookieHeader) {
    _jar.putIfAbsent(domain, () => {});
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

  /// Builds the `Cookie` header value for [domain].
  ///
  /// Merges stored jar cookies (when [config.enableCookieJar] is `true`)
  /// with any [extras] and [config.extraCookies].
  ///
  /// Returns `null` when the combined cookie map is empty.
  String? buildCookieHeader(
    String domain,
    ApiCookies? config,
    Map<String, String>? extras,
  ) {
    final entries = <String, String>{};

    if (config?.enableCookieJar == true) {
      entries.addAll(_jar[domain] ?? {});
    }

    if (extras != null) entries.addAll(extras);
    if (config?.extraCookies != null) entries.addAll(config!.extraCookies!);

    if (entries.isEmpty) return null;
    return entries.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  /// Reads `Set-Cookie` from [responseHeaders] and persists the cookies for
  /// [domain], unless [config.disableCookiePersistence] is `true`.
  void handleResponseCookies(
    String domain,
    Map<String, String> responseHeaders,
    ApiCookies? config,
  ) {
    if (config?.disableCookiePersistence == true) return;
    final setCookie = responseHeaders['set-cookie'];
    if (setCookie != null) storeCookies(domain, setCookie);
  }

  /// Clears cookies for [domain], or clears the entire jar when [domain]
  /// is `null`.
  void clearCookies([String? domain]) {
    if (domain != null) {
      _jar.remove(domain);
    } else {
      _jar.clear();
    }
  }
}
