// Article 3 — proves the decoded-image memory math.

import 'package:flutter_test/flutter_test.dart';
import 'package:hardening_poc/services/image_math.dart';

void main() {
  test('decoded bytes = width * height * 4', () {
    expect(const ImageMemory(4032, 3024).decodedBytes, 48771072);
    expect(const ImageMemory(400, 300).decodedBytes, 480000);
  });

  test('decoding to a target width shrinks memory', () {
    const full = ImageMemory(4032, 3024);
    final scaled = full.scaledTo(800);
    expect(scaled.width, 800);
    expect(scaled.height, 600); // aspect ratio preserved
    expect(scaled.decodedBytes < full.decodedBytes, isTrue);
  });

  test('full decode wastes ~25x the memory a thumbnail needs', () {
    const full = ImageMemory(4032, 3024);
    expect(full.wasteFactorVs(800), greaterThan(20));
  });
}
