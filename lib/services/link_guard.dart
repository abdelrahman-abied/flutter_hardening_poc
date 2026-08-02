// Article 7 — one validating chokepoint for every URL that enters the app from
// outside: deep links, push payloads, server-supplied links, WebView navigations.
//
// The rule: deny by default. A link may SELECT a destination; it may never
// CARRY an authorization.

/// Why a URL was rejected — useful both for tests and for telemetry.
enum LinkVerdict {
  allowed,
  unparseable,
  disallowedScheme,
  disallowedHost,
  embeddedCredentials,
  disallowedPath,
  credentialInQuery,
}

extension LinkVerdictX on LinkVerdict {
  bool get isAllowed => this == LinkVerdict.allowed;

  String get explanation => switch (this) {
        LinkVerdict.allowed => 'Allowed',
        LinkVerdict.unparseable => 'Not a parseable URI',
        LinkVerdict.disallowedScheme =>
          'Scheme not allow-listed (blocks javascript:, file:, data:, intent:)',
        LinkVerdict.disallowedHost =>
          'Host not on the allow-list (exact match — never endsWith)',
        LinkVerdict.embeddedCredentials =>
          'Embedded userInfo — the https://example.com@evil.tld/ trick',
        LinkVerdict.disallowedPath => 'Path is not a published route',
        LinkVerdict.credentialInQuery =>
          'Carries a credential in the query string — links select, they do not authorize',
      };
}

class LinkGuard {
  /// Exact hostnames only. A suffix check (`endsWith('example.com')`) would
  /// happily accept `evil-example.com` and `example.com.attacker.tld`.
  static const allowedHosts = <String>{'example.com', 'help.example.com'};

  /// Routes the app actually publishes. The router should never be handed a
  /// path that isn't on this list.
  static const allowedPaths = <String>{
    '/home',
    '/orders',
    '/faq',
    '/reset-password',
  };

  /// Query keys that must never appear in an inbound link. A token in a URL
  /// lands in browser history, referrer headers, and every proxy log en route.
  static const credentialKeys = <String>{
    'token',
    'access_token',
    'id_token',
    'password',
    'secret',
    'otp',
    'session',
  };

  /// `myapp://reset-password` parses with host `reset-password` and an EMPTY
  /// path — the single most common custom-scheme parsing bug. Normalize so the
  /// route allow-list sees `/reset-password` either way.
  static String effectivePath(Uri uri) {
    if (uri.scheme == 'https' || uri.scheme == 'http') return uri.path;
    if (uri.host.isEmpty) return uri.path;
    return '/${uri.host}${uri.path}';
  }

  /// Gate for anything a WebView is asked to load.
  ///
  /// [hosts] lets a specific surface narrow or substitute the allow-list — the
  /// WebView demo points at a host that actually resolves. It never *widens*
  /// the policy: the caller still supplies an explicit, closed set.
  static LinkVerdict checkWebUrl(String raw, {Set<String>? hosts}) {
    final allowed = hosts ?? allowedHosts;
    final uri = Uri.tryParse(raw);
    if (uri == null || raw.trim().isEmpty) return LinkVerdict.unparseable;

    // 1. Scheme allow-list. Blocks javascript:, file:, data:, content:, intent:.
    if (uri.scheme != 'https') return LinkVerdict.disallowedScheme;

    // 2. No embedded credentials. Checked BEFORE the host so the verdict names
    //    the real trick: in https://example.com@evil.tld/ the HOST is evil.tld
    //    and "example.com" is just userInfo — which is exactly what fools a
    //    human reading the URL.
    if (uri.userInfo.isNotEmpty) return LinkVerdict.embeddedCredentials;

    // 3. Host allow-list, exact match.
    if (!allowed.contains(uri.host.toLowerCase())) {
      return LinkVerdict.disallowedHost;
    }

    return LinkVerdict.allowed;
  }

  /// Gate for inbound deep links. Adds a route allow-list and rejects links
  /// that try to smuggle a credential.
  static LinkVerdict checkDeepLink(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || raw.trim().isEmpty) return LinkVerdict.unparseable;

    // Custom schemes are claimable by ANY app on the device, so they get the
    // same scrutiny as web URLs — and never carry authority on their own.
    final schemeOk = uri.scheme == 'https' || uri.scheme == 'myapp';
    if (!schemeOk) return LinkVerdict.disallowedScheme;

    if (uri.scheme == 'https') {
      final web = checkWebUrl(raw);
      if (!web.isAllowed) return web;
    }

    if (!allowedPaths.contains(effectivePath(uri))) {
      return LinkVerdict.disallowedPath;
    }

    final hasCredential = uri.queryParameters.keys
        .any((k) => credentialKeys.contains(k.toLowerCase()));
    if (hasCredential) return LinkVerdict.credentialInQuery;

    return LinkVerdict.allowed;
  }

  /// Convenience wrappers for call sites (e.g. a NavigationDelegate).
  static bool isAllowedWebUrl(String raw) => checkWebUrl(raw).isAllowed;

  static bool isAllowedDeepLink(String raw) => checkDeepLink(raw).isAllowed;
}
