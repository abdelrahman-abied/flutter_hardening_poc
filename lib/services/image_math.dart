// Article 3 — Image memory budgets.
//
// A decoded image lives in RAM as width * height * 4 bytes (RGBA), regardless
// of its compressed file size. This tiny model powers the on-screen calculator
// that shows the 48 MB-from-a-2 MB-JPEG blow-up and the savings from decoding
// to display size with cacheWidth.

class ImageMemory {
  final int width;
  final int height;
  const ImageMemory(this.width, this.height);

  /// Raw decoded bitmap size in bytes: w * h * 4 (8 bits per RGBA channel).
  int get decodedBytes => width * height * 4;

  double get decodedMB => decodedBytes / (1024 * 1024);

  /// Memory if we instead decode to [targetWidth] preserving aspect ratio.
  ImageMemory scaledTo(int targetWidth) {
    if (targetWidth >= width) return this;
    final targetHeight = (height * targetWidth / width).round();
    return ImageMemory(targetWidth, targetHeight);
  }

  /// How many times bigger this decode is vs a [targetWidth] decode.
  double wasteFactorVs(int targetWidth) {
    final scaled = scaledTo(targetWidth);
    if (scaled.decodedBytes == 0) return 0;
    return decodedBytes / scaled.decodedBytes;
  }
}
