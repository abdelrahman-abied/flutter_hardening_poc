// Article 7 — proves the inbound-URL chokepoint denies by default.

import 'package:flutter_test/flutter_test.dart';
import 'package:hardening_poc/services/link_guard.dart';

void main() {
  group('WebView navigation allow-list', () {
    test('allows an exact allow-listed https host', () {
      expect(LinkGuard.isAllowedWebUrl('https://help.example.com/faq'), isTrue);
    });

    test('rejects the suffix trick a naive endsWith() would accept', () {
      expect(LinkGuard.checkWebUrl('https://evil-example.com/faq'),
          LinkVerdict.disallowedHost);
      expect(LinkGuard.checkWebUrl('https://example.com.attacker.tld/faq'),
          LinkVerdict.disallowedHost);
    });

    test('rejects embedded credentials', () {
      expect(LinkGuard.checkWebUrl('https://example.com@evil.tld/faq'),
          LinkVerdict.embeddedCredentials);
    });

    test('rejects non-https schemes, including javascript: and file:', () {
      for (final url in [
        'javascript:AppBridge.postMessage("/settings/delete-account")',
        'file:///data/data/com.example/databases/app.db',
        'data:text/html,<script>1</script>',
        'http://example.com/faq',
      ]) {
        expect(LinkGuard.checkWebUrl(url), LinkVerdict.disallowedScheme,
            reason: '$url must not reach loadRequest');
      }
    });
  });

  group('deep-link allow-list', () {
    test('allows a published route on an allow-listed host', () {
      expect(LinkGuard.isAllowedDeepLink('https://example.com/orders'), isTrue);
    });

    test('allows a custom-scheme link to a published route', () {
      expect(LinkGuard.isAllowedDeepLink('myapp://reset-password'), isTrue);
    });

    test('rejects an unpublished route', () {
      expect(LinkGuard.checkDeepLink('https://example.com/admin/debug'),
          LinkVerdict.disallowedPath);
    });

    test('rejects a link carrying a credential — links select, not authorize', () {
      expect(
        LinkGuard.checkDeepLink('https://example.com/reset-password?token=abc123'),
        LinkVerdict.credentialInQuery,
      );
      expect(
        LinkGuard.checkDeepLink('myapp://reset-password?access_token=abc'),
        LinkVerdict.credentialInQuery,
      );
    });

    test('rejects an arbitrary foreign scheme', () {
      expect(LinkGuard.checkDeepLink('intent://scan/#Intent;scheme=zxing;end'),
          LinkVerdict.disallowedScheme);
    });

    test('rejects empty input', () {
      expect(LinkGuard.checkDeepLink(''), LinkVerdict.unparseable);
    });
  });
}
