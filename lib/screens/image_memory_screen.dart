import 'package:flutter/material.dart';
import '../services/image_math.dart';

class ImageMemoryScreen extends StatefulWidget {
  const ImageMemoryScreen({super.key});
  @override
  State<ImageMemoryScreen> createState() => _ImageMemoryScreenState();
}

class _ImageMemoryScreenState extends State<ImageMemoryScreen> {
  double _width = 4032;
  double _height = 3024;
  double _target = 800;

  @override
  Widget build(BuildContext context) {
    final full = ImageMemory(_width.round(), _height.round());
    final scaled = full.scaledTo(_target.round());
    final waste = full.wasteFactorVs(_target.round());

    return Scaffold(
      appBar: AppBar(title: const Text('Image memory · Article 3')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Decoded RAM = width × height × 4 bytes (RGBA). '
              'File size on disk is irrelevant.'),
          const SizedBox(height: 16),
          _slider('Source width', _width, 100, 8000, (v) => setState(() => _width = v)),
          _slider('Source height', _height, 100, 8000, (v) => setState(() => _height = v)),
          _slider('Decode target width (cacheWidth)', _target, 100, 4000,
              (v) => setState(() => _target = v)),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line('Full decode', '${full.width}×${full.height}',
                      '${full.decodedMB.toStringAsFixed(1)} MB', Colors.red),
                  const Divider(),
                  _line('Decoded to target', '${scaled.width}×${scaled.height}',
                      '${scaled.decodedMB.toStringAsFixed(2)} MB', Colors.green),
                  const Divider(),
                  Text('Waste factor: ${waste.toStringAsFixed(0)}× more RAM '
                      'than the pixels on screen can show',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Fix: Image.network(url, cacheWidth: 800) or '
              'ResizeImage(provider, width: 800) — decode small in the first place.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.round()} px'),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }

  Widget _line(String label, String dims, String mb, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(dims, style: const TextStyle(fontFamily: 'monospace')),
        Text(mb, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
