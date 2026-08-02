// Article 8 — proves secrets are masked before a log line can leave the device.

import 'package:flutter_test/flutter_test.dart';
import 'package:hardening_poc/services/log_redactor.dart';

void main() {
  test('redacts a JWT anywhere in the line', () {
    const line =
        'auth ok eyJhbGciOiJIUzI1NiJ9.eyJyb2xlIjoidXNlciJ9.abc123 done';
    final out = LogRedactor.redact(line);
    expect(out, contains(LogRedactor.placeholder));
    expect(out, isNot(contains('eyJhbGciOiJIUzI1NiJ9')));
  });

  test('redacts a bearer token but keeps the scheme readable', () {
    final out = LogRedactor.redact('Authorization: Bearer sk_live_abcdef123456');
    expect(out, contains('Bearer'));
    expect(out, isNot(contains('sk_live_abcdef123456')));
  });

  test('redacts key=value secrets across separators and quoting styles', () {
    for (final line in [
      'token=abc123',
      'password: hunter2',
      '"secret": "s3cr3t"',
      "otp = '123456'",
      'api_key=AIzaSyExampleKey',
    ]) {
      final out = LogRedactor.redact(line);
      expect(out, contains(LogRedactor.placeholder), reason: 'failed on: $line');
      expect(LogRedactor.looksSensitive(out), isFalse,
          reason: 'still sensitive after redaction: $out');
    }
  });

  test('redacts card-number-shaped digit runs', () {
    final out = LogRedactor.redact('card=4111111111111111');
    expect(out, isNot(contains('4111111111111111')));
  });

  test('leaves benign lines untouched', () {
    const line = 'GET /health 200 in 4ms';
    expect(LogRedactor.redact(line), line);
    expect(LogRedactor.looksSensitive(line), isFalse);
  });

  test('a realistic multi-secret line comes out clean', () {
    const line =
        'POST /transfer ok user=amy token=eyJhbGciOiJIUzI1NiJ9.eyJhIjoxfQ.sig '
        'Authorization: Bearer abc123 card=4111111111111111';
    expect(LogRedactor.looksSensitive(line), isTrue);
    expect(LogRedactor.looksSensitive(LogRedactor.redact(line)), isFalse);
  });
}
